import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../auth.dart';
import '../config.dart';
import '../ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  bool _obscure = true;
  String? _err;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _err = null; });
    try {
      await context.read<AuthProvider>().login(_email.text, _pass.text);
    } on ApiException catch (e) {
      setState(() => _err = e.message);
    } catch (_) {
      setState(() => _err = 'Gagal terhubung ke server. Cek koneksi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final host = Config.baseHost.replaceAll('https://', '').replaceAll('http://', '');
    return Scaffold(
      body: Stack(
        children: [
          // ── Hero gradient dengan lingkaran cahaya dekoratif ──
          Container(
            height: MediaQuery.of(context).size.height * 0.46,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(top: -60, right: -40, child: _blob(180, 0.16)),
                Positioned(top: 80, left: -50, child: _blob(140, 0.12)),
                Positioned(bottom: 40, right: 30, child: _blob(70, 0.14)),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(screenPad(context) + 4, 8, screenPad(context) + 4, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppTheme.glassGradient,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 22),
                  const Text('Selamat datang 👋',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Absen Kehadiran',
                      style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.05)),
                  const SizedBox(height: 6),
                  Text('Andromeda · masuk pakai akun kamu',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                  const SizedBox(height: 32),
                  // ── Kartu form yang melayang ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.rXl),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Masuk ke Akun',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.ink, letterSpacing: -0.3)),
                          const SizedBox(height: 4),
                          const Text('Isi kredensial kamu untuk lanjut',
                              style: TextStyle(fontSize: 13, color: AppTheme.muted)),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Email wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _pass,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: _err == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.danger.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(AppTheme.rSm),
                                      ),
                                      child: Row(children: [
                                        const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(_err ?? '', style: const TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w600))),
                                      ]),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 22),
                          _GradientButton(
                            busy: _busy,
                            onPressed: _submit,
                            icon: Icons.login_rounded,
                            label: 'Masuk',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text('v1.0 · $host',
                        style: const TextStyle(color: AppTheme.muted, fontSize: 11.5, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: alpha), shape: BoxShape.circle),
      );
}

/// Tombol utama bergradien dengan glow — dipakai di beberapa layar.
class _GradientButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  const _GradientButton({required this.busy, required this.onPressed, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: busy ? 0.7 : 1,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(AppTheme.rSm),
          boxShadow: AppTheme.glow(AppTheme.primary),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: BorderRadius.circular(AppTheme.rSm),
            child: Center(
              child: busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
