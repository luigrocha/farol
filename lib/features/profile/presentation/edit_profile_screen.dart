import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/widgets/farol_snackbar.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../../core/theme/farol_colors.dart';
import 'profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _avatarCtrl;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  void _initControllers(String? name, String? avatarUrl) {
    if (_initialized) return;
    _nameCtrl = TextEditingController(text: name ?? '');
    _avatarCtrl = TextEditingController(text: avatarUrl ?? '');
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    await ref.read(profileControllerProvider.notifier).saveProfile(
          uid: uid,
          name: _nameCtrl.text.trim(),
          avatarUrl: _avatarCtrl.text.trim().isEmpty ? null : _avatarCtrl.text.trim(),
        );

    if (mounted && !ref.read(profileControllerProvider).hasError) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final profileAsync = ref.watch(currentProfileProvider);
    final controllerState = ref.watch(profileControllerProvider);

    ref.listen<AsyncValue<void>>(profileControllerProvider, (_, state) {
      if (state.hasError) {
        context.showErrorSnackBar(state.error!);
      }
    });

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (profile) {
        _initControllers(profile?.displayName, profile?.photoUrl);
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(l10n.editProfile, style: const TextStyle(fontWeight: FontWeight.w700)),
            leading: const BackButton(),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _AvatarPreview(url: _avatarCtrl.text),
                const SizedBox(height: 24),
                _Field(
                  controller: _nameCtrl,
                  label: l10n.translate('name'),
                  icon: Icons.person_outline,
                  fillColor: colors.surfaceLowest,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.translate('name_required') : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: _avatarCtrl,
                  label: l10n.translate('avatar_optional'),
                  icon: Icons.image_outlined,
                  fillColor: colors.surfaceLowest,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: controllerState.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.FarolColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: controllerState.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  final String url;
  const _AvatarPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircleAvatar(
        radius: 44,
        backgroundColor: const Color(0xFF244A72),
        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
        child: url.isEmpty ? const Icon(Icons.person, size: 44, color: Colors.white) : null,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color fillColor;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.fillColor,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: tokens.FarolColors.navy, width: 1.5)),
      ),
    );
  }
}
