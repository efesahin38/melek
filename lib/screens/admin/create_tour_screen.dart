import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/neon_service.dart';
import '../../widgets/gold_button.dart';

class CreateTourScreen extends StatefulWidget {
  final String adminId;

  const CreateTourScreen({super.key, required this.adminId});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<UserModel> _employees = [];
  UserModel? _selectedDriver;
  bool _isLoading = false;
  bool _isLoadingEmployees = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final emps = await NeonService.getEmployees();
      setState(() {
        _employees = emps;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() => _isLoadingEmployees = false);
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _addressCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.goldPrimary,
            onPrimary: AppTheme.bgDark,
            surface: AppTheme.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _createTour() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await NeonService.createTour(
        tourDate: _selectedDate,
        locationName: _locationCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        driverId: _selectedDriver?.id,
        createdBy: widget.adminId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tour erfolgreich erstellt!'),
            backgroundColor: AppTheme.successBg,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: ${e.toString()}'),
            backgroundColor: AppTheme.errorBg,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Tour erstellen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Date picker card
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderGold),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: AppTheme.bgDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tour-Datum',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, dd. MMMM yyyy', 'de_DE')
                                .format(_selectedDate),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit_calendar_rounded,
                        color: AppTheme.goldPrimary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Form fields card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _locationCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Standort / Mekan Adı',
                        hintText: 'z.B. Lager Berlin',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Standortname eingeben'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        hintText: 'Straße, PLZ, Stadt',
                        prefixIcon: Icon(Icons.map_rounded),
                      ),
                      maxLines: 2,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Adresse eingeben'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionCtrl,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Beschreibung (optional)',
                        hintText: 'Zusätzliche Informationen...',
                        prefixIcon: Icon(Icons.description_rounded),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Driver selection
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fahrer auswählen',
                      style: TextStyle(
                        color: AppTheme.textGold,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nach der Auswahl erhält der Mitarbeiter eine Benachrichtigung.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingEmployees)
                      const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.goldPrimary),
                      )
                    else
                      DropdownButtonFormField<UserModel>(
                        value: _selectedDriver,
                        dropdownColor: AppTheme.bgCardElevated,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Fahrer',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        items: [
                          const DropdownMenuItem<UserModel>(
                            value: null,
                            child: Text(
                              'Kein Fahrer',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          ..._employees.map((emp) => DropdownMenuItem(
                                value: emp,
                                child: Text(emp.name),
                              )),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedDriver = val),
                      ),
                    if (_selectedDriver != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.infoBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.info.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_rounded,
                                color: AppTheme.info, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedDriver!.name} wird benachrichtigt',
                              style: const TextStyle(
                                  color: AppTheme.info, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              GoldButton(
                label: 'Tour erstellen',
                icon: Icons.add_location_alt_rounded,
                isLoading: _isLoading,
                width: double.infinity,
                onPressed: _createTour,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
