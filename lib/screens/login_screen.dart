import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/gold_button.dart';
import 'admin/admin_shell.dart';
import 'employee/employee_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              auth.isAdmin ? const AdminShell() : const EmployeeShell(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ?? 'Anmeldung fehlgeschlagen.',
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          backgroundColor: AppTheme.errorBg,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      // Logo
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.goldPrimary.withOpacity(0.4),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  'assets/icon/app_icon.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.goldGradient,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(
                                      Icons.local_shipping_rounded,
                                      size: 50,
                                      color: AppTheme.bgDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.goldGradient.createShader(bounds),
                              child: const Text(
                                'MELEK',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mitarbeiter Management',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Form card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.borderGold),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Anmelden',
                              style: TextStyle(
                                color: AppTheme.textGold,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mit Ihren Zugangsdaten anmelden',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'E-Mail',
                                hintText: 'beispiel@melek.de',
                                prefixIcon:
                                    Icon(Icons.email_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'E-Mail eingeben';
                                }
                                if (!v.contains('@')) {
                                  return 'Gültige E-Mail eingeben';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscurePass,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Passwort',
                                hintText: '••••••••',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass,
                                  ),
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Passwort eingeben';
                                }
                                if (v.length < 4) {
                                  return 'Mindestens 4 Zeichen';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 28),
                            // Login button
                            GoldButton(
                              label: 'Anmelden',
                              icon: Icons.login_rounded,
                              isLoading: _isLoading,
                              width: double.infinity,
                              onPressed: _login,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'MELEK v1.0 – Mitarbeiter Management System',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
