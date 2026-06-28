import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/gold_button.dart';

class AddMitarbeiterScreen extends StatefulWidget {
  const AddMitarbeiterScreen({super.key});

  @override
  State<AddMitarbeiterScreen> createState() => _AddMitarbeiterScreenState();
}

class _AddMitarbeiterScreenState extends State<AddMitarbeiterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'employee';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _telefonCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.createUser(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().toLowerCase(),
        passwordHash: AuthService.hashPassword(_passCtrl.text),
        role: _selectedRole,
        phone: _telefonCtrl.text.trim().isEmpty
            ? null
            : _telefonCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppTheme.success),
              SizedBox(width: 12),
              Text(
                'Mitarbeiter erfolgreich hinzugefügt',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.bgCardElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Fehler: ${e.toString()}',
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.goldPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mitarbeiter hinzufügen',
          style: TextStyle(
            color: AppTheme.textGold,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.borderGold,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Container(
            decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Card ───────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradientSubtle,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderGold),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.goldShadow,
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: AppTheme.bgDark,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Neuer Mitarbeiter',
                                  style: TextStyle(
                                    color: AppTheme.textGold,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Füllen Sie alle Pflichtfelder aus',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Persönliche Daten ─────────────────────────────
                    _SectionLabel(
                        label: 'Persönliche Daten',
                        icon: Icons.badge_rounded),

                    const SizedBox(height: 12),

                    // Name
                    _FormCard(
                      child: TextFormField(
                        controller: _nameCtrl,
                        style:
                            const TextStyle(color: AppTheme.textPrimary),
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          hintText: 'Vor- und Nachname',
                          prefixIcon:
                              Icon(Icons.person_outline_rounded),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name ist erforderlich';
                          }
                          if (v.trim().length < 2) {
                            return 'Name muss mindestens 2 Zeichen haben';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // E-Mail
                    _FormCard(
                      child: TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style:
                            const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'E-Mail *',
                          hintText: 'mitarbeiter@melek.de',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'E-Mail ist erforderlich';
                          }
                          final emailRegex =
                              RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                          if (!emailRegex.hasMatch(v.trim())) {
                            return 'Gültige E-Mail-Adresse eingeben';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Telefon
                    _FormCard(
                      child: TextFormField(
                        controller: _telefonCtrl,
                        keyboardType: TextInputType.phone,
                        style:
                            const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Telefon',
                          hintText: '+49 123 456789 (optional)',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Zugangsdaten ──────────────────────────────────
                    _SectionLabel(
                        label: 'Zugangsdaten',
                        icon: Icons.lock_outline_rounded),

                    const SizedBox(height: 12),

                    // Passwort
                    _FormCard(
                      child: TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        style:
                            const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Passwort *',
                          hintText: 'Mindestens 6 Zeichen',
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscurePass = !_obscurePass),
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Passwort ist erforderlich';
                          }
                          if (v.length < 6) {
                            return 'Passwort muss mindestens 6 Zeichen haben';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Passwort bestätigen
                    _FormCard(
                      child: TextFormField(
                        controller: _passConfirmCtrl,
                        obscureText: _obscureConfirm,
                        style:
                            const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Passwort bestätigen *',
                          hintText: 'Passwort wiederholen',
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Bitte Passwort bestätigen';
                          }
                          if (v != _passCtrl.text) {
                            return 'Passwörter stimmen nicht überein';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Rolle ─────────────────────────────────────────
                    _SectionLabel(
                        label: 'Rolle', icon: Icons.manage_accounts_rounded),

                    const SizedBox(height: 12),

                    _FormCard(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        dropdownColor: AppTheme.bgCardElevated,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.goldPrimary,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Rolle *',
                          prefixIcon:
                              Icon(Icons.manage_accounts_rounded),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'employee',
                            child: Text('Mitarbeiter'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                        validator: (v) =>
                            v == null ? 'Bitte eine Rolle auswählen' : null,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Submit ────────────────────────────────────────
                    GoldButton(
                      label: _isLoading
                          ? 'Wird gespeichert…'
                          : 'Mitarbeiter hinzufügen',
                      icon: Icons.check_rounded,
                      isLoading: _isLoading,
                      width: double.infinity,
                      onPressed: _submit,
                    ),

                    const SizedBox(height: 12),

                    GoldButton(
                      label: 'Abbrechen',
                      outline: true,
                      width: double.infinity,
                      onPressed: () => Navigator.pop(context),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.goldPrimary, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textGold,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.borderGold, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGold),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIconColor: AppTheme.goldPrimary,
            labelStyle: TextStyle(color: AppTheme.textSecondary),
            hintStyle: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        child: child,
      ),
    );
  }
}
