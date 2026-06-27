import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'admin/admin_shell.dart';
import 'employee/employee_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    if (auth.status == AuthStatus.loading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return auth.status == AuthStatus.loading;
      });
    }

    if (!mounted) return;
    if (auth.status == AuthStatus.loggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              auth.isAdmin ? const AdminShell() : const EmployeeShell(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo glow
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldPrimary.withOpacity(0.4),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            size: 70,
                            color: AppTheme.bgDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.goldGradient.createShader(bounds),
                    child: const Text(
                      'MELEK',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mitarbeiter Management',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.goldPrimary.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
