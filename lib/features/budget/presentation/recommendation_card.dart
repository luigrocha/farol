import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls whether the user has clicked "Get AI Recommendation" this session.
final aiRecRequestedProvider = StateProvider.autoDispose<bool>((ref) => false);

/// The full AI recommendation UI: button → loading → card (or error).
/// Only renders when overflow is true OR no goals exist.
class AiRecommendationSection extends ConsumerWidget {
  const AiRecommendationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AI recommendations have been removed.
    return const SizedBox.shrink();
  }
}
