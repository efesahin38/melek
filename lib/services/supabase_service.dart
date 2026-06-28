import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/document_model.dart';
import '../models/tour_model.dart';
import '../models/stundenzettel_model.dart';

class SupabaseService {
  static final _supabase = Supabase.instance.client;

  // ─── USERS ───────────────────────────────────────────────────────

  static Future<List<UserModel>> getEmployees() async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('role', 'employee')
        .order('name', ascending: true);
    return data.map((e) => UserModel.fromJson(e)).toList();
  }

  static Future<List<UserModel>> getAllUsers() async {
    final data = await _supabase
        .from('users')
        .select()
        .order('name', ascending: true);
    return data.map((e) => UserModel.fromJson(e)).toList();
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('email', email)
        .limit(1);
    if (data.isEmpty) return null;
    return UserModel.fromJson(data.first);
  }

  static Future<UserModel?> getUserById(String id) async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('id', id)
        .limit(1);
    if (data.isEmpty) return null;
    return UserModel.fromJson(data.first);
  }

  static Future<UserModel?> verifyLogin(String email, String passwordHash) async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('email', email)
        .eq('password_hash', passwordHash)
        .limit(1);
    if (data.isEmpty) return null;
    return UserModel.fromJson(data.first);
  }

  static Future<UserModel> createUser({
    required String name,
    required String email,
    required String passwordHash,
    required String role,
    String? phone,
  }) async {
    final data = await _supabase.from('users').insert({
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'role': role,
      if (phone != null) 'phone': phone,
    }).select();
    return UserModel.fromJson(data.first);
  }

  static Future<void> deleteUser(String id) async {
    await _supabase.from('users').delete().eq('id', id);
  }

  // ─── DOCUMENTS ───────────────────────────────────────────────────

  static Future<List<DocumentModel>> getDocuments({
    required String employeeId,
    required int folderId,
  }) async {
    final data = await _supabase
        .from('employee_documents')
        .select()
        .eq('employee_id', employeeId)
        .eq('folder_id', folderId)
        .order('created_at', ascending: false);
    return data.map((e) => DocumentModel.fromJson(e)).toList();
  }

  static Future<Map<int, int>> getDocumentCountsByEmployee(String employeeId) async {
    final data = await _supabase
        .from('employee_documents')
        .select('folder_id')
        .eq('employee_id', employeeId);
    
    final Map<int, int> counts = {};
    for (final row in data) {
      final folderId = row['folder_id'] as int;
      counts[folderId] = (counts[folderId] ?? 0) + 1;
    }
    return counts;
  }

  static Future<DocumentModel> uploadDocument({
    required String employeeId,
    required int folderId,
    required String fileName,
    required String fileType,
    required String fileData,
    required String uploadedBy,
  }) async {
    final data = await _supabase.from('employee_documents').insert({
      'employee_id': employeeId,
      'folder_id': folderId,
      'file_name': fileName,
      'file_type': fileType,
      'file_data': fileData,
      'uploaded_by': uploadedBy,
    }).select();
    return DocumentModel.fromJson(data.first);
  }

  static Future<void> deleteDocument(String id) async {
    await _supabase.from('employee_documents').delete().eq('id', id);
  }

  // ─── TOURS ───────────────────────────────────────────────────────

  static Future<TourModel?> getTourById(String id) async {
    final data = await _supabase
        .from('tours')
        .select()
        .eq('id', id)
        .limit(1);
    if (data.isEmpty) return null;
    return TourModel.fromJson(data.first);
  }

  static Future<List<TourModel>> getTours({String? driverId}) async {
    var query = _supabase.from('tours').select();
    if (driverId != null) {
      query = query.eq('driver_id', driverId);
    }
    final data = await query.order('tour_date', ascending: false);
    return data.map((e) => TourModel.fromJson(e)).toList();
  }

  static Future<TourModel> createTour({
    required DateTime tourDate,
    required String locationName,
    required String address,
    String? description,
    String? driverId,
    required String createdBy,
  }) async {
    final data = await _supabase.from('tours').insert({
      'tour_date': tourDate.toIso8601String().split('T').first,
      'location_name': locationName,
      'address': address,
      if (description != null) 'description': description,
      if (driverId != null) 'driver_id': driverId,
      'status': 'pending',
      'created_by': createdBy,
    }).select();
    return TourModel.fromJson(data.first);
  }

  static Future<void> updateTourStatus({
    required String tourId,
    required TourStatus status,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) async {
    final updates = <String, dynamic>{
      'status': status.value,
    };
    if (acceptedAt != null) {
      updates['accepted_at'] = acceptedAt.toIso8601String();
    }
    if (completedAt != null) {
      updates['completed_at'] = completedAt.toIso8601String();
    }
    await _supabase.from('tours').update(updates).eq('id', tourId);
  }

  static Future<void> deleteTour(String id) async {
    await _supabase.from('tours').delete().eq('id', id);
  }

  // ─── STUNDENZETTEL ────────────────────────────────────────────────

  static Future<List<StundenzettelModel>> getStundenzettels({
    String? employeeId,
  }) async {
    var query = _supabase.from('stundenzettels').select();
        
    if (employeeId != null) {
      query = query.eq('employee_id', employeeId);
    }
    final data = await query.order('year', ascending: false).order('month', ascending: false);
    return data.map((e) => StundenzettelModel.fromJson(e)).toList();
  }

  static Future<StundenzettelModel> createStundenzettel({
    required String employeeId,
    required int month,
    required int year,
    required int totalDays,
    required double totalHours,
    required List<WorkEntry> workEntries,
    required String createdBy,
  }) async {
    final data = await _supabase.from('stundenzettels').insert({
      'employee_id': employeeId,
      'month': month,
      'year': year,
      'total_days': totalDays,
      'total_hours': totalHours,
      'work_entries': workEntries.map((e) => e.toJson()).toList(),
      'status': 'draft',
      'created_by': createdBy,
    }).select();
    return StundenzettelModel.fromJson(data.first);
  }

  static Future<void> signStundenzettelAdmin({
    required String id,
    required String signature,
  }) async {
    await _supabase.from('stundenzettels').update({
      'admin_signature': signature,
      'admin_signed_at': DateTime.now().toIso8601String(),
      'status': 'admin_signed',
    }).eq('id', id);
  }

  static Future<void> signStundenzettelEmployee({
    required String id,
    required String signature,
  }) async {
    await _supabase.from('stundenzettels').update({
      'employee_signature': signature,
      'employee_signed_at': DateTime.now().toIso8601String(),
      'status': 'completed',
    }).eq('id', id);
  }

  static Future<StundenzettelModel?> getStundenzettelById(String id) async {
    final data = await _supabase
        .from('stundenzettels')
        .select()
        .eq('id', id)
        .limit(1);
    if (data.isEmpty) return null;
    return StundenzettelModel.fromJson(data.first);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  final String table;

  ApiException(this.statusCode, this.body, this.table);

  @override
  String toString() =>
      'Verbindungsfehler: Supabase Connection Error - $body';
}
