import 'package:flutter/material.dart';
import '../i18n/app_localizations.dart';

/// Returns null = cancel, false = delete only this item, true = delete entire series/plan.
Future<bool?> showDeleteExpenseChoiceDialog(
  BuildContext context, {
  required String title,
  required String singleLabel,
  required String seriesLabel,
  String? warning,
}) async {
  return showDialog<bool?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: warning != null ? Text(warning) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppLocalizations.of(ctx).cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(singleLabel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(seriesLabel),
        ),
      ],
    ),
  );
}

Future<bool> showConfirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        ),
      ) ??
      false;
}
