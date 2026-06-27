import 'package:flutter/material.dart';
import '../config/theme.dart';

class TourModel {
  final String id;
  final DateTime tourDate;
  final String locationName;
  final String address;
  final String? description;
  final String? driverId;
  final String? driverName;
  final TourStatus status;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? createdBy;
  final DateTime createdAt;

  TourModel({
    required this.id,
    required this.tourDate,
    required this.locationName,
    required this.address,
    this.description,
    this.driverId,
    this.driverName,
    required this.status,
    this.acceptedAt,
    this.completedAt,
    this.createdBy,
    required this.createdAt,
  });

  bool get isPending => status == TourStatus.pending;
  bool get isAccepted => status == TourStatus.accepted;
  bool get isInProgress => status == TourStatus.inProgress;
  bool get isCompleted => status == TourStatus.completed;

  factory TourModel.fromJson(Map<String, dynamic> json) {
    return TourModel(
      id: json['id'] ?? '',
      tourDate: json['tour_date'] is DateTime 
          ? json['tour_date'] 
          : (DateTime.tryParse(json['tour_date']?.toString() ?? '') ?? DateTime.now()),
      locationName: json['location_name'] ?? '',
      address: json['address'] ?? '',
      description: json['description'],
      driverId: json['driver_id'],
      driverName: json['driver_name'],
      status: TourStatus.fromString(json['status'] ?? 'pending'),
      acceptedAt: json['accepted_at'] is DateTime 
          ? json['accepted_at'] 
          : DateTime.tryParse(json['accepted_at']?.toString() ?? ''),
      completedAt: json['completed_at'] is DateTime 
          ? json['completed_at'] 
          : DateTime.tryParse(json['completed_at']?.toString() ?? ''),
      createdBy: json['created_by'],
      createdAt: json['created_at'] is DateTime 
          ? json['created_at'] 
          : (DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'tour_date': tourDate.toIso8601String().split('T').first,
        'location_name': locationName,
        'address': address,
        if (description != null) 'description': description,
        if (driverId != null) 'driver_id': driverId,
        'status': status.value,
        if (createdBy != null) 'created_by': createdBy,
      };

  TourModel copyWith({
    TourStatus? status,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return TourModel(
      id: id,
      tourDate: tourDate,
      locationName: locationName,
      address: address,
      description: description,
      driverId: driverId,
      driverName: driverName,
      status: status ?? this.status,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}

enum TourStatus {
  pending('pending', 'Ausstehend'),
  accepted('accepted', 'Angenommen'),
  inProgress('in_progress', 'In Bearbeitung'),
  completed('completed', 'Abgeschlossen');

  final String value;
  final String label;

  const TourStatus(this.value, this.label);

  static TourStatus fromString(String s) {
    return TourStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => TourStatus.pending,
    );
  }

  Color get color {
    switch (this) {
      case TourStatus.pending:
        return AppTheme.warning;
      case TourStatus.accepted:
        return AppTheme.info;
      case TourStatus.inProgress:
        return AppTheme.goldPrimary;
      case TourStatus.completed:
        return AppTheme.success;
    }
  }
}
