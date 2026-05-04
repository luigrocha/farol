import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/widgets/farol_snackbar.dart';
import '../../../core/theme/farol_colors.dart';
import '../../../design/farol_colors.dart' as tokens;
import '../../auth/presentation/password_reset_screen.dart';
import '../data/profile_repository.dart';
import 'profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _jobTitleCtrl;
  late final TextEditingController _companyCtrl;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _jobTitleCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  void _initControllers(UserProfile? profile) {
    if (_initialized) return;
    _nameCtrl = TextEditingController(text: profile?.displayName ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    _jobTitleCtrl = TextEditingController(text: profile?.jobTitle ?? '');
    _companyCtrl = TextEditingController(text: profile?.company ?? '');
    _initialized = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    await ref.read(profileControllerProvider.notifier).saveProfile(
          uid: uid,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          jobTitle: _jobTitleCtrl.text.trim().isEmpty ? null : _jobTitleCtrl.text.trim(),
          company: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
        );

    if (mounted && !ref.read(profileControllerProvider).hasError) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: tokens.FarolColors.coral),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      await ref.read(profileControllerProvider.notifier).deleteAccount(uid);
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentProfileProvider);
    final controllerState = ref.watch(profileControllerProvider);

    ref.listen<AsyncValue<void>>(profileControllerProvider, (_, state) {
      if (state.hasError) context.showErrorSnackBar(state.error!);
    });

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (profile) {
        _initControllers(profile);
        final email = Supabase.instance.client.auth.currentUser?.email ?? profile?.email ?? '';
        final initials = _initials(profile?.displayName ?? email);

        return Scaffold(
          backgroundColor: colors.surfaceLow,
          appBar: AppBar(
            backgroundColor: colors.surfaceLowest,
            elevation: 0,
            centerTitle: true,
            title: Text(
              l10n.editProfile,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            leading: const BackButton(),
            actions: [
              TextButton(
                onPressed: controllerState.isLoading ? null : _submit,
                child: controllerState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.save,
                        style: const TextStyle(
                          color: tokens.FarolColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _AvatarSection(
                  initials: initials,
                  photoUrl: profile?.photoUrl,
                ),
                const SizedBox(height: 28),
                _SectionCard(
                  title: l10n.personalData,
                  children: [
                    _EditRow(
                      controller: _nameCtrl,
                      label: l10n.name,
                      icon: Icons.person_outline,
                      colors: colors,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
                    ),
                    _Divider(),
                    _ReadOnlyRow(
                      label: l10n.cpfLabel,
                      value: _maskCpf(profile?.cpf),
                      icon: Icons.lock_outline,
                      colors: colors,
                    ),
                    _Divider(),
                    _ReadOnlyRow(
                      label: l10n.email,
                      value: email,
                      icon: Icons.email_outlined,
                      colors: colors,
                      verified: profile?.emailVerified ?? false,
                    ),
                    _Divider(),
                    _EditRow(
                      controller: _phoneCtrl,
                      label: l10n.phone,
                      icon: Icons.phone_outlined,
                      colors: colors,
                      keyboardType: TextInputType.phone,
                      trailing: (profile?.phoneVerified ?? false)
                          ? _VerifiedBadge(label: l10n.verified)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: l10n.professionalProfile,
                  children: [
                    _EditRow(
                      controller: _jobTitleCtrl,
                      label: l10n.jobTitle,
                      icon: Icons.work_outline,
                      colors: colors,
                    ),
                    _Divider(),
                    _EditRow(
                      controller: _companyCtrl,
                      label: l10n.company,
                      icon: Icons.business_outlined,
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: l10n.security,
                  children: [
                    _ActionRow(
                      label: l10n.changePassword,
                      icon: Icons.lock_outline,
                      colors: colors,
                      onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
              ),
                    ),
                    _Divider(),
                    _ActionRow(
                      label: l10n.manage2fa,
                      icon: Icons.security_outlined,
                      colors: colors,
                      onTap: () {/* TODO: 2FA management */},
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _DeleteAccountButton(
                  label: l10n.deleteAccount,
                  onTap: () => _confirmDeleteAccount(context, l10n),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _maskCpf(String? cpf) {
    if (cpf == null || cpf.isEmpty) return '—';
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return cpf;
    return '${digits.substring(0, 3)}.***.***-${digits.substring(9)}';
  }
}

// ─── Avatar Section ───────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final String initials;
  final String? photoUrl;

  const _AvatarSection({required this.initials, this.photoUrl});

  bool _isValidUrl(String? url) =>
      url != null && (url.startsWith('http://') || url.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: tokens.FarolColors.navy,
            backgroundImage: _isValidUrl(photoUrl)
                ? NetworkImage(photoUrl!)
                : null,
            child: !_isValidUrl(photoUrl)
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: tokens.FarolColors.beam,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: colors.onSurfaceFaint,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceLowest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ─── Edit Row ─────────────────────────────────────────────────────────────────

class _EditRow extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FarolColors colors;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Widget? trailing;

  const _EditRow({
    required this.controller,
    required this.label,
    required this.icon,
    required this.colors,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceSoft),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              style: TextStyle(fontSize: 15, color: colors.onSurface),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(fontSize: 13, color: colors.onSurfaceSoft),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

// ─── Read-Only Row ────────────────────────────────────────────────────────────

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final FarolColors colors;
  final bool verified;

  const _ReadOnlyRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: colors.onSurfaceFaint)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, color: colors.onSurfaceMuted)),
              ],
            ),
          ),
          if (verified) _VerifiedBadge(label: AppLocalizations.of(context).verified),
        ],
      ),
    );
  }
}

// ─── Action Row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final FarolColors colors;
  final VoidCallback onTap;

  const _ActionRow({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.onSurfaceSoft),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: colors.onSurface))),
            Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceFaint),
          ],
        ),
      ),
    );
  }
}

// ─── Verified Badge ───────────────────────────────────────────────────────────

class _VerifiedBadge extends StatelessWidget {
  final String label;
  const _VerifiedBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 14, color: tokens.FarolColors.tide),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: tokens.FarolColors.tide,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 46,
      endIndent: 0,
      color: context.colors.onSurfaceFaint.withValues(alpha: 0.15),
    );
  }
}

// ─── Delete Account Button ────────────────────────────────────────────────────

class _DeleteAccountButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DeleteAccountButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.delete_outline, size: 18, color: tokens.FarolColors.coral),
      label: Text(label, style: const TextStyle(color: tokens.FarolColors.coral, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: tokens.FarolColors.coral, width: 1),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: tokens.FarolColors.lErrorSoft,
      ),
    );
  }
}
