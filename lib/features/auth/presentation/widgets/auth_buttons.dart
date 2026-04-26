import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_providers.dart';
import '../../../../core/widgets/farol_snackbar.dart';

/// A helper widget to handle authentication actions.
/// Can be used inside existing Stitch-based UIs.
class AuthActionHandler extends ConsumerWidget {
  final Widget child;
  final String? successMessage;

  const AuthActionHandler({
    super.key,
    required this.child,
    this.successMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, current) {
      if (current.hasError) {
        context.showErrorSnackBar(current.error!);
        return;
      }

      // Detect loading → success transition
      if (previous?.isLoading == true && current.hasValue) {
        final msg = successMessage;
        if (msg != null) {
          context.showSuccessSnackBar(msg);
        }
        // Clear the auth stack and let AppEntryPoint route to the right screen
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });

    return Stack(
      children: [
        child,
        if (ref.watch(authControllerProvider).isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

/// Example of how to connect an existing button to the AuthController
class SocialAuthButton extends ConsumerWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String label;

  const SocialAuthButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: ref.watch(authControllerProvider).isLoading ? null : onPressed,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
