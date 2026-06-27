class WorkEntry {
  final DateTime date;
  final String startTime;
  final String endTime;
  final double hours;
  final String? note;

  WorkEntry({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.hours,
    this.note,
  });

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'start_time': startTime,
        'end_time': endTime,
        'hours': hours,
        if (note != null) 'note': note,
      };
}

enum StundenzettelStatus {
  draft('draft', 'Entwurf'),
  adminSigned('admin_signed', 'Admin unterschrieben'),
  completed('completed', 'Abgeschlossen');

  final String value;
  final String label;

  const StundenzettelStatus(this.value, this.label);

  static StundenzettelStatus fromString(String s) {
    return StundenzettelStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => StundenzettelStatus.draft,
    );
  }
}

class StundenzettelModel {
  final String id;
  final String employeeId;
  final String? employeeName;
  final int month;
  final int year;
  final int? totalDays;
  final double? totalHours;
  final List<WorkEntry> workEntries;
  final String? adminSignature; // base64
  final String? employeeSignature; // base64
  final DateTime? adminSignedAt;
  final DateTime? employeeSignedAt;
  final StundenzettelStatus status;
  final String? createdBy;
  final DateTime createdAt;

  StundenzettelModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.month,
    required this.year,
    this.totalDays,
    this.totalHours,
    required this.workEntries,
    this.adminSignature,
    this.employeeSignature,
    this.adminSignedAt,
    this.employeeSignedAt,
    required this.status,
    this.createdBy,
    required this.createdAt,
  });

  String get monthYearLabel {
    const months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];
    return '${months[month - 1]} $year';
  }

  bool get isFullySigned =>
      adminSignature != null && employeeSignature != null;

  factory StundenzettelModel.fromJson(Map<String, dynamic> json) {
    List<WorkEntry> entries = [];
    if (json['work_entries'] != null) {
      final rawEntries = json['work_entries'];
      if (rawEntries is List) {
        entries = rawEntries
            .map((e) => WorkEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return StundenzettelModel(
      id: json['id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      employeeName: json['employee_name'],
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      totalDays: json['total_days'],
      totalHours: json['total_hours'] is num
          ? (json['total_hours'] as num).toDouble()
          : (json['total_hours'] != null
              ? double.tryParse(json['total_hours'].toString())
              : null),
      workEntries: entries,
      adminSignature: json['admin_signature'],
      adminSignedAt: json['admin_signed_at'] is DateTime 
          ? json['admin_signed_at'] 
          : DateTime.tryParse(json['admin_signed_at']?.toString() ?? ''),
      employeeSignature: json['employee_signature'],
      employeeSignedAt: json['employee_signed_at'] is DateTime 
          ? json['employee_signed_at'] 
          : DateTime.tryParse(json['employee_signed_at']?.toString() ?? ''),
      status: StundenzettelStatus.fromString(json['status'] ?? 'draft'),
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] is DateTime 
          ? json['created_at'] 
          : (DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'employee_id': employeeId,
        'month': month,
        'year': year,
        if (totalDays != null) 'total_days': totalDays,
        if (totalHours != null) 'total_hours': totalHours,
        'work_entries': workEntries.map((e) => e.toJson()).toList(),
        'status': status.value,
        if (createdBy != null) 'created_by': createdBy,
      };
}
