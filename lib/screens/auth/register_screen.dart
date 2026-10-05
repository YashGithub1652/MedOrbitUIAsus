import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _agreed = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please agree to Terms of Service'),
          backgroundColor: CrevaColors.error));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authProvider.notifier).register({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'date_of_birth': _dobCtrl.text,
    });
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: CrevaColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                const Text('CREVA',
                    style: TextStyle(
                        color: CrevaColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                const SizedBox(height: 24),
                const Text('Create your account',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: CrevaColors.textPrimary)),
                const SizedBox(height: 6),
                const Text(
                  'Enter your details to start your wellness journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: CrevaColors.textSecondary,
                      height: 1.5),
                ),
                const SizedBox(height: 28),

                const _FieldLabel('FULL NAME'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(hintText: 'Enter your full name'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Name required' : null,
                ),
                const SizedBox(height: 16),

                const _FieldLabel('EMAIL ADDRESS'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(hintText: 'name@example.com'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const _FieldLabel('DATE OF BIRTH'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dobCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'dd-mm-yyyy',
                    suffixIcon: Icon(Icons.calendar_today_outlined,
                        size: 18, color: CrevaColors.textTertiary),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime(1990),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) {
                      _dobCtrl.text =
                          '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
                    }
                  },
                ),
                const SizedBox(height: 16),

                const _FieldLabel('PASSWORD'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: CrevaColors.textTertiary),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 8) return 'Min 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Must be at least 8 characters with a number and symbol.',
                    style: TextStyle(
                        fontSize: 11, color: CrevaColors.textTertiary),
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () => setState(() => _agreed = !_agreed),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) =>
                            setState(() => _agreed = v ?? false),
                        activeColor: CrevaColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text.rich(TextSpan(children: [
                          TextSpan(
                              text: 'I agree to the ',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: CrevaColors.textSecondary,
                                  height: 1.5)),
                          TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: CrevaColors.primary,
                                  fontWeight: FontWeight.w600)),
                          TextSpan(
                              text: ' and ',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: CrevaColors.textSecondary)),
                          TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: CrevaColors.primary,
                                  fontWeight: FontWeight.w600)),
                          TextSpan(
                              text:
                                  ', including how CREVA handles my health data.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: CrevaColors.textSecondary)),
                        ])),
                      ),
                    ],
                  ),
                ),

                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          CrevaColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: CrevaColors.error
                              .withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: CrevaColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(auth.error!,
                              style: const TextStyle(
                                  color: CrevaColors.error,
                                  fontSize: 12))),
                    ]),
                  ),
                ],
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CrevaColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Create Account',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Or sign up with',
                    style: TextStyle(
                        color: CrevaColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                final ok = await ref
                                    .read(authProvider.notifier)
                                    .signInWithGoogle();
                                if (ok && mounted) context.go('/home');
                              },
                        icon: const Icon(Icons.g_mobiledata,
                            color: Color(0xFF4285F4), size: 22),
                        label: const Text('Google',
                            style: TextStyle(
                                color: CrevaColors.textPrimary,
                                fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: CrevaColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.apple,
                            color: CrevaColors.textPrimary, size: 20),
                        label: const Text('Apple',
                            style: TextStyle(
                                color: CrevaColors.textPrimary,
                                fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: CrevaColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Text.rich(TextSpan(children: [
                    TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                            color: CrevaColors.textSecondary,
                            fontSize: 13)),
                    TextSpan(
                        text: 'Log In',
                        style: TextStyle(
                            color: CrevaColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                color: CrevaColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );
}