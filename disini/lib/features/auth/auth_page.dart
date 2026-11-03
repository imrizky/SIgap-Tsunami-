import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/sigap_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.service,
    this.initialRegister = false,
  });

  final SigapService service;
  final bool initialRegister;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  late bool _isRegister;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialRegister;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final entrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceFade = entrance;
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, .06),
      end: Offset.zero,
    ).animate(entrance);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    if (_busy) return;
    _form.currentState?.reset();
    setState(() {
      _isRegister = !_isRegister;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || _form.currentState?.validate() != true) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final AppUser user = _isRegister
          ? await widget.service.register(
              _name.text.trim(),
              _email.text.trim(),
              _password.text,
            )
          : await widget.service.login(_email.text.trim(), _password.text);

      if (mounted) Navigator.pop(context, user);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2453E6);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _entranceFade,
            child: SlideTransition(
              position: _entranceSlide,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: ScaleTransition(
                            scale: Tween<double>(begin: .82, end: 1).animate(
                              CurvedAnimation(
                                parent: _entranceController,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primary.withValues(alpha: .2),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.tsunami_rounded,
                                size: 50,
                                color: primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, .12),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: Text(
                            _isRegister
                                ? 'Daftar Akun'
                                : 'Masuk ke Sigap Tsunami',
                            key: ValueKey('title-$_isRegister'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            _isRegister
                                ? 'Daftar sebagai warga untuk akses evakuasi & darurat.'
                                : 'Sistem Informasi, Evakuasi, dan Kesiapsiagaan.',
                            key: ValueKey('subtitle-$_isRegister'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _error == null
                              ? const SizedBox.shrink(key: ValueKey('no-error'))
                              : Padding(
                                  key: const ValueKey('auth-error'),
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _ErrorNotice(message: _error!),
                                ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          child: _isRegister
                              ? Padding(
                                  key: const ValueKey('registration-name'),
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: TextFormField(
                                    key: const ValueKey('auth-name'),
                                    controller: _name,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    decoration: _inputDecoration(
                                      'Nama Lengkap',
                                      Icons.person_outline,
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Nama wajib diisi.'
                                        : null,
                                  ),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('no-registration-name'),
                                ),
                        ),
                        TextFormField(
                          key: const ValueKey('auth-email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          decoration: _inputDecoration(
                            'Email',
                            Icons.email_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi.';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Format email tidak valid.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const ValueKey('auth-password'),
                          controller: _password,
                          obscureText: _obscurePassword,
                          textInputAction: _isRegister
                              ? TextInputAction.next
                              : TextInputAction.done,
                          autofillHints: [
                            _isRegister
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          onFieldSubmitted: _isRegister
                              ? null
                              : (_) => _submit(),
                          decoration:
                              _inputDecoration(
                                'Password',
                                Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Tampilkan password'
                                      : 'Sembunyikan password',
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password wajib diisi.';
                            }
                            if (value.length < 8) {
                              return 'Password minimal 8 karakter.';
                            }
                            return null;
                          },
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          child: _isRegister
                              ? Padding(
                                  key: const ValueKey('registration-confirm'),
                                  padding: const EdgeInsets.only(top: 14),
                                  child: TextFormField(
                                    key: const ValueKey('auth-confirm'),
                                    controller: _confirmPassword,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: _inputDecoration(
                                      'Konfirmasi Password',
                                      Icons.lock_reset,
                                    ),
                                    validator: (value) =>
                                        value != _password.text
                                        ? 'Password tidak cocok.'
                                        : null,
                                  ),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('no-registration-confirm'),
                                ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const ValueKey('auth-submit'),
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primary.withValues(
                              alpha: .65,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: _busy
                                ? const SizedBox(
                                    key: ValueKey('auth-loading'),
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isRegister ? 'Daftar' : 'Masuk',
                                    key: ValueKey('submit-label-$_isRegister'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _isRegister
                                    ? 'Sudah punya akun? '
                                    : 'Belum punya akun? ',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            TextButton(
                              key: const ValueKey('auth-mode-toggle'),
                              onPressed: _busy ? null : _toggleMode,
                              child: Text(
                                _isRegister ? 'Masuk' : 'Daftar Sekarang',
                                style: const TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!_isRegister && kDebugMode) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Akun Demo Pengujian Role:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _DemoChip(
                                      label: 'Warga',
                                      onTap: () => _fillDemo('warga'),
                                    ),
                                    _DemoChip(
                                      label: 'Relawan',
                                      onTap: () => _fillDemo('relawan'),
                                    ),
                                    _DemoChip(
                                      label: 'Petugas',
                                      onTap: () => _fillDemo('petugas'),
                                    ),
                                    _DemoChip(
                                      label: 'Admin',
                                      onTap: () => _fillDemo('admin'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  void _fillDemo(String role) {
    _email.text = '$role@sigap.test';
    _password.text = 'password123';
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          '$label (auto-fill)',
          style: const TextStyle(fontSize: 10, color: Color(0xFF1E60EC)),
        ),
      ),
    );
  }
}
