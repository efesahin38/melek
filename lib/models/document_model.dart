class DocumentFolder {
  final int id;
  final String name;
  final String icon;

  const DocumentFolder({
    required this.id,
    required this.name,
    required this.icon,
  });

  // 11 sabit klasör - fotoğraftaki gibi
  static const List<DocumentFolder> defaultFolders = [
    DocumentFolder(id: 1, name: 'Arbeitsvertrag', icon: '📄'),
    DocumentFolder(id: 2, name: 'Personaldokumente', icon: '🪪'),
    DocumentFolder(id: 3, name: 'Gehaltsabrechnung', icon: '💰'),
    DocumentFolder(id: 4, name: 'Krankenversicherung', icon: '🏥'),
    DocumentFolder(id: 5, name: 'Steuerunterlagen', icon: '🧾'),
    DocumentFolder(id: 6, name: 'Bescheinigungen', icon: '✅'),
    DocumentFolder(id: 7, name: 'Führerschein / Qualifikation', icon: '🚗'),
    DocumentFolder(id: 8, name: 'Arbeitszeit & Urlaub', icon: '📅'),
    DocumentFolder(id: 9, name: 'Abmahnungen / Disziplin', icon: '⚠️'),
    DocumentFolder(id: 10, name: 'Sonstige Dokumente', icon: '📁'),
    DocumentFolder(id: 11, name: 'Arbeitszeitnachweis', icon: '📋'),
  ];
}

class DocumentModel {
  final String id;
  final String employeeId;
  final int folderId;
  final String fileName;
  final String? fileData; // base64
  final String? fileUrl;
  final String fileType;
  final String uploadedBy;
  final DateTime createdAt;

  DocumentModel({
    required this.id,
    required this.employeeId,
    required this.folderId,
    required this.fileName,
    this.fileData,
    this.fileUrl,
    required this.fileType,
    required this.uploadedBy,
    required this.createdAt,
  });

  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  bool get isPdf => fileType.toLowerCase().contains('pdf');
  bool get isImage =>
      fileType.toLowerCase().contains('image') ||
      fileType.toLowerCase().contains('jpg') ||
      fileType.toLowerCase().contains('png') ||
      fileType.toLowerCase().contains('jpeg');

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      folderId: json['folder_id'] ?? 1,
      fileName: json['file_name'] ?? '',
      fileData: json['file_data'],
      fileUrl: json['file_url'],
      fileType: json['file_type'] ?? 'application/octet-stream',
      uploadedBy: json['uploaded_by'] ?? '',
      createdAt: json['created_at'] is DateTime 
          ? json['created_at'] 
          : (DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'employee_id': employeeId,
        'folder_id': folderId,
        'file_name': fileName,
        if (fileData != null) 'file_data': fileData,
        if (fileUrl != null) 'file_url': fileUrl,
        'file_type': fileType,
        'uploaded_by': uploadedBy,
      };
}
