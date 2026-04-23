import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';
import 'widgets/auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  void _forgotPassword() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      ref.read(authControllerProvider.notifier).sendPasswordResetEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery email sent')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: AuthActionHandler(
        successMessage: 'Welcome back!',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      _emailRegex.hasMatch(v ?? '') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (v) => (v?.length ?? 0) >= 6 ? null : 'Minimum 6 characters',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: ref.watch(authControllerProvider).isLoading ? null : _submit,
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: ref.watch(authControllerProvider).isLoading ? null : _forgotPassword,
                  child: const Text('Forgot password?'),
                ),
                const SizedBox(height: 32),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Or sign in with'),
                  ),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 32),
                SocialAuthButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                  icon: const Icon(Icons.g_mobiledata, size: 32),
                  label: 'Google',
                ),
                const SizedBox(height: 12),
                SocialAuthButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).signInWithApple(),
                  icon: const Icon(Icons.apple, size: 24),
                  label: 'Apple',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
