import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/providers.dart';

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider).value ?? false;
    final syncStatus = ref.watch(syncStatusProvider).value;
    final pendingCount = syncStatus?.pendingCount ?? 0;

    if (!isOffline && pendingCount == 0) return const SizedBox.shrink();

    final (bgColor, icon, message) = isOffline
        ? (
            const Color(0xFF37474F),
            Icons.wifi_off_rounded,
            'Sem conexão · Os dados serão sincronizados ao reconectar',
          )
        : (
            const Color(0xFF00897B),
            Icons.sync_rounded,
            '$pendingCount operaç${pendingCount == 1 ? 'ão' : 'ões'} sendo sincronizada${pendingCount == 1 ? '' : 's'}...',
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Row(children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ]),
      ),
    );
  }
}
