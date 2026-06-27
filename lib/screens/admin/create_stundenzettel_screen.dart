import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../models/stundenzettel_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/neon_service.dart';
import '../../widgets/gold_button.dart';

// ── Local form model ─────────────────────────────────────────────────────────

class _WorkEntryForm {
  DateTime date;
  final TextEditingController start;
  final TextEditingController end;
  final TextEditingController breakMins;
  final TextEditingController note;

  _WorkEntryForm({
    required this.date,
    String startInit = '08:00',
    String endInit = '17:00',
    String breakInit = '30',
  })  : start = TextEditingController(text: startInit),
        end = TextEditingController(text: endInit),
        breakMins = TextEditingController(text: breakInit),
        note = TextEditingController();

  void dispose() {
    start.dispose();
    end.dispose();
    note.dispose();
  }

  /// Returns null if times cannot be parsed, else the difference in hours.
  double? get computedHours {
    final s = _parseTime(start.text);
    final e = _parseTime(end.text);
    if (s == null || e == null) return null;
    final b = int.tryParse(breakMins.text.trim()) ?? 0;
    final diff = e.inMinutes - s.inMinutes - b;
    if (diff <= 0) return null;
    return diff / 60.0;
  }

  static Duration? _parseTime(String t) {
    final parts = t.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return Duration(hours: h, minutes: m);
  }
}

// ── Screen ───────────────────────────────────────────────────────────────────

class CreateStundenzettelScreen extends StatefulWidget {
  const CreateStundenzettelScreen({super.key});

  @override
  State<CreateStundenzettelScreen> createState() =>
      _CreateStundenzettelScreenState();
}

class _CreateStundenzettelScreenState
    extends State<CreateStundenzettelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weeklyHoursCtrl = TextEditingController(text: '40');

  List<UserModel> _employees = [];
  UserModel? _selectedEmployee;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<_WorkEntryForm> _entries = [];

  bool _isLoadingEmployees = true;
  bool _isSubmitting = false;

  static const _monthNames = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _weeklyHoursCtrl.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await NeonService.getEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
          _isLoadingEmployees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingEmployees = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Fehler beim Laden der Mitarbeiter: ${e.toString()}')),
        );
      }
    }
  }

  void _addEntry() {
    setState(() {
      _entries.add(_WorkEntryForm(date: DateTime.now()));
    });
  }

  void _autoFillDays() {
    final weekly = double.tryParse(_weeklyHoursCtrl.text.trim()) ?? 40.0;
    final daily = weekly / 5.0; 

    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    
    setState(() {
      _entries.clear();
      for (int i = 1; i <= daysInMonth; i++) {
        final d = DateTime(_selectedYear, _selectedMonth, i);
        if (d.weekday >= 1 && d.weekday <= 5) {
          String start = '10:00';
          String end = '18:30';
          String breakMins = '30';

          if (daily == 8.0) {
            start = '10:00';
            end = '18:30';
            breakMins = '30';
          } else if (daily == 4.0) {
            start = '10:00';
            end = '14:00';
            breakMins = '0';
          } else {
             final totalMinutes = (daily * 60).round();
             final breakMinutes = totalMinutes >= 360 ? 30 : 0; 
             final endMinutes = 10 * 60 + totalMinutes + breakMinutes;
             final endH = endMinutes ~/ 60;
             final endM = endMinutes % 60;
             start = '10:00';
             end = '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
             breakMins = breakMinutes.toString();
          }

          _entries.add(_WorkEntryForm(
            date: d,
            startInit: start,
            endInit: end,
            breakInit: breakMins,
          ));
        }
      }
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _entries[index].dispose();
      _entries.removeAt(index);
    });
  }

  Future<void> _pickDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entries[index].date,
      firstDate: DateTime(_selectedYear - 1),
      lastDate: DateTime(_selectedYear + 1, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.goldPrimary,
              onPrimary: AppTheme.bgDark,
              surface: AppTheme.bgCard,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _entries[index].date = picked);
    }
  }

  double get _totalHours {
    return _entries.fold(0.0, (sum, e) => sum + (e.computedHours ?? 0.0));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Mitarbeiter auswählen.')),
      );
      return;
    }

    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bitte mindestens einen Arbeitstag hinzufügen.')),
      );
      return;
    }

    // Validate all entries
    for (int i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (e.start.text.trim().isEmpty || e.end.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Eintrag ${i + 1}: Bitte Start- und Endzeit eingeben.')),
        );
        return;
      }
      if (e.computedHours == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Eintrag ${i + 1}: Ungültige Zeiten. Format: HH:mm, Ende > Start.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      final adminId = authProvider.user?.id ?? '';

      final workEntries = _entries.map((e) {
        return WorkEntry(
          date: e.date,
          startTime: e.start.text.trim(),
          endTime: e.end.text.trim(),
          hours: e.computedHours!,
          note: e.note.text.trim().isEmpty ? null : e.note.text.trim(),
        );
      }).toList();

      await NeonService.createStundenzettel(
        employeeId: _selectedEmployee!.id,
        month: _selectedMonth,
        year: _selectedYear,
        totalDays: _entries.length,
        totalHours: _totalHours,
        workEntries: workEntries,
        createdBy: adminId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stundenzettel erfolgreich erstellt!'),
            backgroundColor: AppTheme.successBg,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Fehler beim Erstellen: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - 2 + i);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Stundenzettel erstellen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingEmployees
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.goldPrimary),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Employee Dropdown ──────────────────────────
                    _buildSectionTitle('Mitarbeiter auswählen'),
                    const SizedBox(height: 10),
                    _buildEmployeeDropdown(),
                    const SizedBox(height: 20),

                    // ── Month / Year ───────────────────────────────
                    _buildSectionTitle('Monat & Jahr'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildMonthDropdown()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildYearDropdown(years),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Auto Fill ──────────────────────────────────
                    _buildSectionTitle('Automatisch Ausfüllen'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weeklyHoursCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Wochenstunden (z.B. 40)',
                              prefixIcon: const Icon(Icons.timer_rounded, color: AppTheme.goldPrimary, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppTheme.bgCardElevated,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GoldButton(
                          label: 'Generieren',
                          icon: Icons.auto_awesome_rounded,
                          onPressed: _autoFillDays,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Work entries ───────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildSectionTitle(
                              'Arbeitstage hinzufügen'),
                        ),
                        GoldButton(
                          label: 'Tag hinzufügen',
                          icon: Icons.add,
                          outline: true,
                          onPressed: _addEntry,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_entries.isEmpty)
                      _buildEmptyEntriesHint()
                    else
                      ...List.generate(
                          _entries.length,
                          (i) => _buildEntryCard(i)),

                    const SizedBox(height: 20),

                    // ── Summary ────────────────────────────────────
                    if (_entries.isNotEmpty) ...[
                      _buildSummaryCard(),
                      const SizedBox(height: 20),
                    ],

                    // ── Submit ─────────────────────────────────────
                    GoldButton(
                      label: 'Stundenzettel erstellen',
                      icon: Icons.check_rounded,
                      isLoading: _isSubmitting,
                      width: double.infinity,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeDropdown() {
    return DropdownButtonFormField<UserModel>(
      value: _selectedEmployee,
      dropdownColor: AppTheme.bgCardElevated,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Mitarbeiter wählen…',
        prefixIcon: const Icon(Icons.person_rounded,
            color: AppTheme.goldPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.goldPrimary, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.bgCardElevated,
      ),
      items: _employees.map((emp) {
        return DropdownMenuItem<UserModel>(
          value: emp,
          child: Text(emp.name),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedEmployee = val),
      validator: (val) =>
          val == null ? 'Bitte Mitarbeiter auswählen' : null,
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedMonth,
      dropdownColor: AppTheme.bgCardElevated,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: _dropdownDecoration('Monat'),
      items: List.generate(12, (i) {
        return DropdownMenuItem<int>(
          value: i + 1,
          child: Text(_monthNames[i]),
        );
      }),
      onChanged: (val) {
        if (val != null) setState(() => _selectedMonth = val);
      },
    );
  }

  Widget _buildYearDropdown(List<int> years) {
    return DropdownButtonFormField<int>(
      value: _selectedYear,
      dropdownColor: AppTheme.bgCardElevated,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: _dropdownDecoration('Jahr'),
      items: years.map((y) {
        return DropdownMenuItem<int>(
          value: y,
          child: Text(y.toString()),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedYear = val);
      },
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 2),
      ),
      filled: true,
      fillColor: AppTheme.bgCardElevated,
    );
  }

  Widget _buildEmptyEntriesHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.add_circle_outline_rounded,
              color: AppTheme.textMuted, size: 36),
          const SizedBox(height: 10),
          const Text(
            'Noch keine Arbeitstage',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tippen Sie auf „Tag hinzufügen"',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(int index) {
    final entry = _entries[index];
    final dateFormat = DateFormat('dd.MM.yyyy');
    final computedH = entry.computedHours;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.goldGlow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Tag ${index + 1}',
                  style: const TextStyle(
                    color: AppTheme.textGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (computedH != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${computedH.toStringAsFixed(1)} Std.',
                  style: const TextStyle(
                    color: AppTheme.goldPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.error, size: 20),
                onPressed: () => _removeEntry(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Date picker ─────────────────────────────────────────
          InkWell(
            onTap: () => _pickDate(index),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgCardElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppTheme.goldPrimary, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    dateFormat.format(entry.date),
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_calendar_rounded,
                      color: AppTheme.textMuted, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Start / End ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildTimeField(
                  controller: entry.start,
                  hint: '08:00',
                  label: 'Beginn',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimeField(
                  controller: entry.end,
                  hint: '17:00',
                  label: 'Ende',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBreakField(
                  controller: entry.breakMins,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Note ────────────────────────────────────────────────
          TextFormField(
            controller: entry.note,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Notiz…',
              hintStyle:
                  const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.note_outlined,
                  color: AppTheme.textMuted, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppTheme.goldPrimary, width: 1.5),
              ),
              filled: true,
              fillColor: AppTheme.bgCardElevated,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      style:
          const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      keyboardType: TextInputType.datetime,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        hintStyle:
            const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        labelStyle:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        prefixIcon: const Icon(Icons.access_time_rounded,
            color: AppTheme.goldPrimary, size: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppTheme.goldPrimary, width: 1.5),
        ),
        filled: true,
        fillColor: AppTheme.bgCardElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
      ),
    );
  }

  Widget _buildBreakField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Pause (min)',
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        prefixIcon: const Icon(Icons.coffee_rounded, color: AppTheme.goldPrimary, size: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.goldPrimary, width: 1.5),
        ),
        filled: true,
        fillColor: AppTheme.bgCardElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalH = _totalHours;
    final totalD = _entries.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.goldGradientSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zusammenfassung',
            style: TextStyle(
              color: AppTheme.textGold,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  Icons.calendar_today_rounded,
                  'Gesamte Tage',
                  '$totalD Tage',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _summaryItem(
                  Icons.access_time_rounded,
                  'Gesamte Stunden',
                  '${totalH.toStringAsFixed(1)} Std.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.goldPrimary, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textGold,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
