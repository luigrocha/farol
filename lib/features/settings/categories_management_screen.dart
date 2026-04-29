import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/category.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/farol_colors.dart';
import '../../design/farol_colors.dart' as tokens;
import '../../core/i18n/app_localizations.dart';
import '../../core/widgets/farol_snackbar.dart';

class CategoriesManagementScreen extends ConsumerWidget {
  const CategoriesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      backgroundColor: colors.surfaceLow,
      appBar: AppBar(
        title: Text(
          l10n.categories,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 48, color: colors.onSurfaceFaint),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noCategoriesFound,
                    style: TextStyle(color: colors.onSurfaceSoft),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showCategoryDialog(context, ref),
                    child: Text(l10n.addFirstCategory),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final list = List<Category>.from(categories);
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              ref.read(categoryNotifierProvider.notifier).reorder(list);
            },
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryTile(
                key: ValueKey(category.id),
                category: category,
                onEdit: () => _showCategoryDialog(context, ref, category: category),
                onDelete: category.isSystem 
                    ? null 
                    : () => _confirmDelete(context, ref, category),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        backgroundColor: tokens.FarolColors.navy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {Category? category}) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Category category) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.deleteCategory} ${category.name}?'),
        content: Text(l10n.deleteCategoryDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: tokens.FarolColors.coral),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(categoryNotifierProvider.notifier).delete(category.id);
      if (context.mounted) {
        context.showSuccessSnackBar(l10n.categoryDeleted);
      }
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _CategoryTile({
    super.key,
    required this.category,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surfaceLow,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              category.emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        subtitle: Text(
          category.dbValue,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceFaint,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.isSwile)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.FarolColors.beam.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SWILE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: tokens.FarolColors.beam,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              color: colors.onSurfaceSoft,
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                color: tokens.FarolColors.coral.withValues(alpha: 0.7),
              ),
            const Icon(Icons.drag_indicator, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  final Category? category;

  const _CategoryDialog({this.category});

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emojiController;
  late bool _isSwile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _emojiController = TextEditingController(text: widget.category?.emoji ?? '📁');
    _isSwile = widget.category?.isSwile ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final emoji = _emojiController.text.trim();
      final dbValue = widget.category?.dbValue ?? name.toUpperCase().replaceAll(' ', '_');

      final category = widget.category?.copyWith(
            name: name,
            emoji: emoji,
            isSwile: _isSwile,
          ) ??
          Category(
            dbValue: dbValue,
            name: name,
            emoji: emoji,
            isSwile: _isSwile,
            isSystem: false,
            orderIndex: 99, // Will be placed at the end
          );

      if (widget.category != null) {
        await ref.read(categoryNotifierProvider.notifier).save(category);
      } else {
        await ref.read(categoryNotifierProvider.notifier).add(category);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.pop(context);
        context.showSuccessSnackBar(
          widget.category != null ? l10n.categoryUpdated : l10n.categoryAdded,
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.category != null ? l10n.editCategory : l10n.newCategory),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emojiController,
                decoration: InputDecoration(
                  labelText: l10n.categoryEmoji,
                  hintText: l10n.categoryEmojiHint,
                ),
                validator: (v) => v == null || v.isEmpty ? l10n.required : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.categoryName,
                  hintText: l10n.categoryNameHint,
                ),
                validator: (v) => v == null || v.isEmpty ? l10n.required : null,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(l10n.swileCategory),
                subtitle: Text(l10n.swileCategoryDesc),
                value: _isSwile,
                onChanged: widget.category?.isSystem == true 
                    ? null 
                    : (v) => setState(() => _isSwile = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.FarolColors.navy,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n.save),
        ),
      ],
    );
  }
}
