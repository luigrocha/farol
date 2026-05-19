import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/domain/entities/workspace_activity.dart';
import '../../core/models/member_display.dart';
import '../../core/services/financial_calculator_service.dart';

/// One row in the activity feed.
///
/// Layout:
///   [avatar] [action line]              [time ago]
///            [entity label · amount]
class ActivityFeedTile extends StatelessWidget {
  const ActivityFeedTile({
    super.key,
    required this.activity,
    required this.currentUserId,
    this.display,
  });

  final WorkspaceActivity activity;
  final String currentUserId;
  final MemberDisplay? display; // null while loading or unknown user

  bool get _isSelf => activity.userId == currentUserId;

  String get _authorName {
    if (_isSelf) return 'Você';
    return display?.displayName ?? '${activity.userId.substring(0, 8)}…';
  }

  String get _actionLine {
    return switch (activity.action) {
      'added_expense' =>
        _isSelf ? 'Você adicionou despesa' : 'adicionou despesa',
      'deleted_expense' => _isSelf ? 'Você removeu despesa' : 'removeu despesa',
      'added_recurring' =>
        _isSelf ? 'Você adicionou recorrência' : 'adicionou recorrência',
      'deleted_recurring' =>
        _isSelf ? 'Você removeu recorrência' : 'removeu recorrência',
      'added_installment' =>
        _isSelf ? 'Você adicionou parcelamento' : 'adicionou parcelamento',
      'deleted_installment' =>
        _isSelf ? 'Você removeu parcelamento' : 'removeu parcelamento',
      _ => activity.action,
    };
  }

  IconData get _actionIcon => switch (activity.action) {
        'added_expense' => Icons.add_circle_outline,
        'deleted_expense' => Icons.remove_circle_outline,
        'added_recurring' => Icons.repeat,
        'deleted_recurring' => Icons.repeat_one_outlined,
        'added_installment' => Icons.credit_card_outlined,
        'deleted_installment' => Icons.credit_card_off_outlined,
        _ => Icons.history,
      };

  Color _actionColor(ColorScheme cs) =>
      activity.isDeletion ? cs.error : cs.primary;

  String _timeAgo() {
    final diff = DateTime.now().difference(activity.createdAt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    if (diff.inDays == 1) return 'ontem';
    return '${diff.inDays}d atrás';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avatarColor =
        display?.avatarColor ?? avatarColorForUserId(activity.userId);
    final initials =
        display?.initials ?? activity.userId.substring(0, 2).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ──
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarColor,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ── Content ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action line
                Row(
                  children: [
                    if (!_isSelf) ...[
                      Text(
                        _authorName,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        _isSelf ? _actionLine : _actionLine,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Entity label + amount
                Row(
                  children: [
                    Icon(
                      _actionIcon,
                      size: 14,
                      color: _actionColor(cs),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.entityLabel ?? activity.entityType,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (activity.amount != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        FinancialCalculatorService.formatBRL(activity.amount!),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: activity.isDeletion ? cs.error : cs.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Time ──
          Text(
            _timeAgo(),
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
