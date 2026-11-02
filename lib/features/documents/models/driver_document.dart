import 'package:flutter/material.dart';

enum DocumentStatus {
  verified,
  underReview,
  pending,
  rejected,
  expired,
}

enum DocumentCategory {
  driverIdentity,
  vehicleCompliance,
  insuranceAndLegal,
}

class DriverDocument {
  final String id;
  final String title;
  final String subtitle;
  final String documentCode;
  final DocumentCategory category;
  DocumentStatus status;
  final IconData icon;
  final bool isRequired;
  final String? documentNumber;
  final DateTime? expiryDate;
  final String? sampleAssetPath;
  String? uploadedFileName;
  String? uploadedFileSize;
  DateTime? uploadedAt;
  final String? rejectionReason;

  DriverDocument({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.documentCode,
    required this.category,
    required this.status,
    required this.icon,
    this.isRequired = true,
    this.documentNumber,
    this.expiryDate,
    this.sampleAssetPath,
    this.uploadedFileName,
    this.uploadedFileSize,
    this.uploadedAt,
    this.rejectionReason,
  });

  bool get isUploaded =>
      status == DocumentStatus.verified ||
      status == DocumentStatus.underReview ||
      uploadedFileName != null;

  Color get statusColor {
    switch (status) {
      case DocumentStatus.verified:
        return const Color(0xFF10B981); // Emerald green
      case DocumentStatus.underReview:
        return const Color(0xFF38BDF8); // Sky blue
      case DocumentStatus.pending:
        return const Color(0xFFFF521B); // Brand orange
      case DocumentStatus.rejected:
        return const Color(0xFFEF4444); // Red
      case DocumentStatus.expired:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  String get statusLabel {
    switch (status) {
      case DocumentStatus.verified:
        return 'VERIFIED';
      case DocumentStatus.underReview:
        return 'IN REVIEW';
      case DocumentStatus.pending:
        return 'ACTION REQUIRED';
      case DocumentStatus.rejected:
        return 'RE-UPLOAD NEEDED';
      case DocumentStatus.expired:
        return 'EXPIRED';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case DocumentStatus.verified:
        return Icons.verified_rounded;
      case DocumentStatus.underReview:
        return Icons.hourglass_top_rounded;
      case DocumentStatus.pending:
        return Icons.upload_file_rounded;
      case DocumentStatus.rejected:
        return Icons.error_outline_rounded;
      case DocumentStatus.expired:
        return Icons.warning_amber_rounded;
    }
  }

  DriverDocument copyWith({
    DocumentStatus? status,
    String? uploadedFileName,
    String? uploadedFileSize,
    DateTime? uploadedAt,
  }) {
    return DriverDocument(
      id: id,
      title: title,
      subtitle: subtitle,
      documentCode: documentCode,
      category: category,
      status: status ?? this.status,
      icon: icon,
      isRequired: isRequired,
      documentNumber: documentNumber,
      expiryDate: expiryDate,
      sampleAssetPath: sampleAssetPath,
      uploadedFileName: uploadedFileName ?? this.uploadedFileName,
      uploadedFileSize: uploadedFileSize ?? this.uploadedFileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      rejectionReason: rejectionReason,
    );
  }
}
