/// AppLifecycleService — Enterprise-grade app lifecycle & recovery manager.
///
/// Problem this solves:
///   After the app is idle, loses focus, or returns from background, Riverpod
///   autoDispose providers may have been cleaned up while the widget tree was
///   still alive (Offstage screens). When the app resumes and triggers a
///   rebuild, providers restart in AsyncLoading state → entire UI appears gray.
///
/// Solution:
///   1. Track the last time the app went inactive.
///   2. On resume, if the app was inactive longer than [staleTtl], invalidate
///      the key stream providers so they re-fetch with fresh data.
///   3. Use a short debounce so rapid focus-in/out cycles don't thrash.
///   4. Re-sync the workspace realtime service after provider invalidation.
///   5. Reset realtime retry flags so providers re-enter WebSocket mode.
///
/// Usage:
///   AppLifecycleService.instance.onPause();          // from didChangeAppLifecycleState
///   AppLifecycleService.instance.onResume(container); // from didChangeAppLifecycleState
library app_lifecycle_service;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/providers.dart';
import '../providers/workspace_providers.dart'
    show activeWorkspaceProvider, isSharedWorkspaceProvider;
import 'workspace_realtime_service.dart';

class AppLifecycleService {
  AppLifecycleService._();
  static final AppLifecycleService instance = AppLifecycleService._();

  /// After this long in the background, treat stream data as stale and
  /// force a fresh re-subscription to all Supabase streams.
  static const staleTtl = Duration(minutes: 2);

  /// Debounce rapid resume events (tab switches, brief focus loss on desktop/web).
  static const _debounceDuration = Duration(milliseconds: 600);

  DateTime? _pausedAt;
  Timer? _debounceTimer;

  // ── Called from MainShell when app enters background / loses focus ────────

  void onPause() {
    _pausedAt = DateTime.now();
    _debounceTimer?.cancel();
    debugPrint('[Lifecycle] ⏸ App paused at ${_pausedAt?.toIso8601String()}');
  }

  // ── Called from MainShell when app returns to foreground ─────────────────

  void onResume(ProviderContainer container) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () => _doResume(container));
  }

  void _doResume(ProviderContainer container) {
    final pausedAt = _pausedAt;
    final now = DateTime.now();
    final elapsed = pausedAt != null
        ? now.difference(pausedAt)
        : staleTtl + const Duration(seconds: 1); // treat first resume as stale

    debugPrint('[Lifecycle] ▶ App resumed — was inactive for ${elapsed.inSeconds}s');

    if (elapsed >= staleTtl) {
      debugPrint('[Lifecycle] ♻ Data stale — invalidating stream providers');
      _invalidateStreams(container);
    } else {
      debugPrint('[Lifecycle] ✓ Data fresh (${elapsed.inSeconds}s < ${staleTtl.inSeconds}s threshold)');
    }

    // Always re-sync realtime channel regardless of data staleness
    _resyncRealtime(container);

    _pausedAt = null;
  }

  // ── Stream provider invalidation ──────────────────────────────────────────

  void _invalidateStreams(ProviderContainer container) {
    // 1. Reset realtime state flags so providers re-enter WebSocket mode
    _tryInvalidate(container, realtimeActiveProvider,
        resetState: (_) => container.read(realtimeActiveProvider.notifier).state = true);
    _tryInvalidate(container, realtimeMaxRetriesReachedProvider,
        resetState: (_) => container.read(realtimeMaxRetriesReachedProvider.notifier).state = false);

    // 2. Invalidate root stream providers (Supabase websocket connections)
    _tryInvalidate(container, allExpensesStreamProvider);
    _tryInvalidate(container, allIncomesStreamProvider);
    _tryInvalidate(container, categoriesStreamProvider);
    _tryInvalidate(container, investmentsProvider);
    _tryInvalidate(container, budgetGoalsProvider);
    _tryInvalidate(container, installmentPlansStreamProvider);
    _tryInvalidate(container, activeInstallmentPlansProvider);
  }

  void _tryInvalidate(
    ProviderContainer container,
    ProviderOrFamily provider, {
    void Function(ProviderContainer)? resetState,
  }) {
    try {
      resetState?.call(container);
      container.invalidate(provider);
    } catch (e) {
      debugPrint('[Lifecycle] Could not invalidate $provider: $e');
    }
  }

  // ── Realtime re-sync ──────────────────────────────────────────────────────

  void _resyncRealtime(ProviderContainer container) {
    try {
      final wsAsync = container.read(activeWorkspaceProvider);
      final ws = wsAsync.valueOrNull;
      final isShared = container.read(isSharedWorkspaceProvider);
      final uid = Supabase.instance.client.auth.currentUser?.id;

      if (ws != null && isShared && uid != null) {
        WorkspaceRealtimeService.instance.setWorkspace(ws.id, uid);
      } else {
        WorkspaceRealtimeService.instance.resume();
      }
    } catch (e) {
      debugPrint('[Lifecycle] Realtime re-sync error: $e');
    }
  }
}
