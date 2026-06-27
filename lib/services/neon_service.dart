import 'dart:convert';
import 'package:postgres/postgres.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/document_model.dart';
import '../models/tour_model.dart';
import '../models/stundenzettel_model.dart';

class NeonService {
  static Future<T> _withConnection<T>(
      Future<T> Function(Connection conn) action) async {
    final uri = Uri.parse(AppConfig.neonConnectionString);
    final endpoint = Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'neondb',
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.split(':').length > 1
          ? uri.userInfo.split(':').last
          : '',
    );

    final conn = await Connection.open(
      endpoint,
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );
    try {
      return await action(conn);
    } finally {
      await conn.close();
    }
  }

  // ─── USERS ───────────────────────────────────────────────────────

  static Future<List<UserModel>> getEmployees() async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        "SELECT * FROM users WHERE role = 'employee' ORDER BY name ASC",
      );
      return result.map((row) => UserModel.fromJson(row.toColumnMap())).toList();
    });
  }

  static Future<List<UserModel>> getAllUsers() async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        "SELECT * FROM users ORDER BY name ASC",
      );
      return result.map((row) => UserModel.fromJson(row.toColumnMap())).toList();
    });
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('SELECT * FROM users WHERE email = @email LIMIT 1'),
        parameters: {'email': email},
      );
      if (result.isEmpty) return null;
      return UserModel.fromJson(result.first.toColumnMap());
    });
  }

  static Future<UserModel?> getUserById(String id) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('SELECT * FROM users WHERE id = @id::uuid LIMIT 1'),
        parameters: {'id': id},
      );
      if (result.isEmpty) return null;
      return UserModel.fromJson(result.first.toColumnMap());
    });
  }

  static Future<UserModel?> verifyLogin(String email, String passwordHash) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('SELECT * FROM users WHERE email = @email AND password_hash = @hash LIMIT 1'),
        parameters: {'email': email, 'hash': passwordHash},
      );
      if (result.isEmpty) return null;
      return UserModel.fromJson(result.first.toColumnMap());
    });
  }

  static Future<UserModel> createUser({
    required String name,
    required String email,
    required String passwordHash,
    required String role,
    String? phone,
  }) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          INSERT INTO users (name, email, password_hash, role, phone)
          VALUES (@name, @email, @password_hash, @role, @phone)
          RETURNING *
        '''),
        parameters: {
          'name': name,
          'email': email,
          'password_hash': passwordHash,
          'role': role,
          'phone': phone,
        },
      );
      return UserModel.fromJson(result.first.toColumnMap());
    });
  }

  static Future<void> deleteUser(String id) async {
    await _withConnection((conn) async {
      await conn.execute(
        Sql.named('DELETE FROM users WHERE id = @id::uuid'),
        parameters: {'id': id},
      );
    });
  }

  // ─── DOCUMENTS ───────────────────────────────────────────────────

  static Future<List<DocumentModel>> getDocuments({
    required String employeeId,
    required int folderId,
  }) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          SELECT * FROM employee_documents 
          WHERE employee_id = @employee_id::uuid AND folder_id = @folder_id
          ORDER BY created_at DESC
        '''),
        parameters: {
          'employee_id': employeeId,
          'folder_id': folderId,
        },
      );
      return result.map((row) => DocumentModel.fromJson(row.toColumnMap())).toList();
    });
  }

  static Future<Map<int, int>> getDocumentCountsByEmployee(
      String employeeId) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          SELECT folder_id, COUNT(*) as count 
          FROM employee_documents 
          WHERE employee_id = @employee_id::uuid
          GROUP BY folder_id
        '''),
        parameters: {'employee_id': employeeId},
      );
      final Map<int, int> counts = {};
      for (final row in result) {
        counts[row[0] as int] = (row[1] as int);
      }
      return counts;
    });
  }

  static Future<DocumentModel> uploadDocument({
    required String employeeId,
    required int folderId,
    required String fileName,
    required String fileType,
    required String fileData,
    required String uploadedBy,
  }) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          INSERT INTO employee_documents 
          (employee_id, folder_id, file_name, file_type, file_data, uploaded_by)
          VALUES (@employee_id::uuid, @folder_id, @file_name, @file_type, @file_data, @uploaded_by::uuid)
          RETURNING *
        '''),
        parameters: {
          'employee_id': employeeId,
          'folder_id': folderId,
          'file_name': fileName,
          'file_type': fileType,
          'file_data': fileData,
          'uploaded_by': uploadedBy,
        },
      );
      return DocumentModel.fromJson(result.first.toColumnMap());
    });
  }

  static Future<void> deleteDocument(String id) async {
    await _withConnection((conn) async {
      await conn.execute(
        Sql.named('DELETE FROM employee_documents WHERE id = @id::uuid'),
        parameters: {'id': id},
      );
    });
  }

  // ─── TOURS ───────────────────────────────────────────────────────

  static Future<TourModel?> getTourById(String id) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('SELECT * FROM tours WHERE id = @id::uuid LIMIT 1'),
        parameters: {'id': id},
      );
      if (result.isEmpty) return null;
      return TourModel.fromJson(result.first.toColumnMap());
    });
  }

  static Future<List<TourModel>> getTours({String? driverId}) async {
    return _withConnection((conn) async {
      String query = 'SELECT * FROM tours ORDER BY tour_date DESC';
      Map<String, dynamic> params = {};
      
      if (driverId != null) {
        query = 'SELECT * FROM tours WHERE driver_id = @driver_id::uuid ORDER BY tour_date DESC';
        params = {'driver_id': driverId};
      }
      
      final result = await conn.execute(Sql.named(query), parameters: params);
      return result.map((row) => TourModel.fromJson(row.toColumnMap())).toList();
    });
  }

  static Future<TourModel> createTour({
    required DateTime tourDate,
    required String locationName,
    required String address,
    String? description,
    String? driverId,
    required String createdBy,
  }) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          INSERT INTO tours 
          (tour_date, location_name, address, description, driver_id, status, created_by)
          VALUES (@tour_date, @location_name, @address, @description, @driver_id::uuid, 'pending', @created_by::uuid)
          RETURNING *
        '''),
        parameters: {
          'tour_date': tourDate.toIso8601String().split('T').first,
          'location_name': locationName,
          'address': address,
          'description': description,
          'driver_id': driverId,
          'created_by': createdBy,
        },
      );
      return TourModel.fromJson(result.first.toColumnMap());
    });
  }

  static Future<void> updateTourStatus({
    required String tourId,
    required TourStatus status,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) async {
    await _withConnection((conn) async {
      String query = 'UPDATE tours SET status = @status';
      final params = <String, dynamic>{
        'id': tourId,
        'status': status.value,
      };

      if (acceptedAt != null) {
        query += ', accepted_at = @accepted_at';
        params['accepted_at'] = acceptedAt.toIso8601String();
      }
      if (completedAt != null) {
        query += ', completed_at = @completed_at';
        params['completed_at'] = completedAt.toIso8601String();
      }

      query += ' WHERE id = @id::uuid';
      await conn.execute(Sql.named(query), parameters: params);
    });
  }

  static Future<void> deleteTour(String id) async {
    await _withConnection((conn) async {
      await conn.execute(
        Sql.named('DELETE FROM tours WHERE id = @id::uuid'),
        parameters: {'id': id},
      );
    });
  }

  // ─── STUNDENZETTEL ────────────────────────────────────────────────

  static Future<List<StundenzettelModel>> getStundenzettels({
    String? employeeId,
  }) async {
    return _withConnection((conn) async {
      String query = 'SELECT * FROM stundenzettels ORDER BY year DESC, month DESC';
      Map<String, dynamic> params = {};

      if (employeeId != null) {
        query = 'SELECT * FROM stundenzettels WHERE employee_id = @employee_id::uuid ORDER BY year DESC, month DESC';
        params = {'employee_id': employeeId};
      }

      final result = await conn.execute(Sql.named(query), parameters: params);
      return result.map((row) => StundenzettelModel.fromJson(row.toColumnMap())).toList();
    });
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
    return _withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          INSERT INTO stundenzettels 
          (employee_id, month, year, total_days, total_hours, work_entries, status, created_by)
          VALUES (@employee_id::uuid, @month, @year, @total_days, @total_hours, @work_entries::jsonb, 'draft', @created_by::uuid)
          RETURNING *
        '''),
        parameters: {
          'employee_id': employeeId,
          'month': month,
          'year': year,
          'total_days': totalDays,
          'total_hours': totalHours,
          'work_entries': json.encode(workEntries.map((e) => e.toJson()).toList()),
          'created_by': createdBy,
        },
      );
      return StundenzettelModel.fromJson(result.first.toColumnMap());
    });
  }

  static Future<void> signStundenzettelAdmin({
    required String id,
    required String signature,
  }) async {
    await _withConnection((conn) async {
      await conn.execute(
        Sql.named('''
          UPDATE stundenzettels 
          SET admin_signature = @signature, admin_signed_at = @signed_at, status = 'admin_signed'
          WHERE id = @id::uuid
        '''),
        parameters: {
          'id': id,
          'signature': signature,
          'signed_at': DateTime.now().toIso8601String(),
        },
      );
    });
  }

  static Future<void> signStundenzettelEmployee({
    required String id,
    required String signature,
  }) async {
    await _withConnection((conn) async {
      await conn.execute(
        Sql.named('''
          UPDATE stundenzettels 
          SET employee_signature = @signature, employee_signed_at = @signed_at, status = 'completed'
          WHERE id = @id::uuid
        '''),
        parameters: {
          'id': id,
          'signature': signature,
          'signed_at': DateTime.now().toIso8601String(),
        },
      );
    });
  }

  static Future<StundenzettelModel?> getStundenzettelById(String id) async {
    return _withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('SELECT * FROM stundenzettels WHERE id = @id::uuid LIMIT 1'),
        parameters: {'id': id},
      );
      if (result.isEmpty) return null;
      return StundenzettelModel.fromJson(result.first.toColumnMap());
    });
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  final String table;

  ApiException(this.statusCode, this.body, this.table);

  @override
  String toString() =>
      'Verbindungsfehler: Database Connection Error - $body';
}
