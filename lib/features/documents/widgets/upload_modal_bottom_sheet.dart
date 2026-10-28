import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/driver_colors.dart';
import '../models/driver_document.dart';

class UploadModalBottomSheet extends StatefulWidget {
  final DriverDocument document;
  final Function(String fileName, String fileSize) onUploadComplete;

  const UploadModalBottomSheet({
    super.key,
    required this.document,
    required this.onUploadComplete,
  });

  static Future<void> show(
    BuildContext context, {
    required DriverDocument document,
    required Function(String fileName, String fileSize) onUploadComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UploadModalBottomSheet(
        document: document,
        onUploadComplete: onUploadComplete,
      ),
    );
  }

  @override
  State<UploadModalBottomSheet> createState() => _UploadModalBottomSheetState();
}

class _UploadModalBottomSheetState extends State<UploadModalBottomSheet> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = 'Compressing image...';
  Timer? _progressTimer;

  void _simulateUpload(String method, String extension) {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.15;
      _uploadStatus = 'Scanning document edge lines...';
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 140), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _uploadProgress += 0.18;
        if (_uploadProgress >= 0.5 && _uploadProgress < 0.8) {
          _uploadStatus = 'Encrypting & uploading securely...';
        } else if (_uploadProgress >= 0.8) {
          _uploadStatus = 'Verifying OCR legibility...';
        }

        if (_uploadProgress >= 1.0) {
          timer.cancel();
          _uploadProgress = 1.0;
          _uploadStatus = 'Upload Complete!';
          
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) {
              final fileName = '${widget.document.documentCode.toLowerCase()}_verified_$method.$extension';
              final fileSize = '${(1.8 + (widget.document.id.hashCode % 12) / 10).toStringAsFixed(1)} MB';
              widget.onUploadComplete(fileName, fileSize);
              Navigator.of(context).pop();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DriverColors.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DriverColors.primaryOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DriverColors.primaryOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  widget.document.icon,
                  color: DriverColors.primaryOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.document.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Document Code: ${widget.document.documentCode}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Uploading State Indicator
          if (_isUploading) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DriverColors.bgDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: DriverColors.primaryOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _uploadStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: DriverColors.primaryOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _uploadProgress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        DriverColors.primaryOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '256-Bit SSL Encrypted Fleet Upload',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Guidelines Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1B2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DriverColors.borderDark),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF38BDF8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ensure all 4 corners are visible with no glare. Formats: JPG, PNG, PDF (Max 15MB).',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Option 1: Take Photo (Camera)
            _buildUploadOption(
              icon: Icons.camera_alt_rounded,
              title: 'Take Document Photo',
              subtitle: 'Capture directly using phone camera with smart edge guide',
              color: DriverColors.primaryOrange,
              onTap: () => _simulateUpload('cam', 'jpg'),
            ),
            const SizedBox(height: 10),

            // Option 2: Gallery
            _buildUploadOption(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Select existing clear photo from device photos',
              color: const Color(0xFF38BDF8),
              onTap: () => _simulateUpload('gallery', 'png'),
            ),
            const SizedBox(height: 10),

            // Option 3: PDF / Files
            _buildUploadOption(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Upload PDF or Scanned Document',
              subtitle: 'Import certified digital statement or policy scan',
              color: const Color(0xFF10B981),
              onTap: () => _simulateUpload('document', 'pdf'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: DriverColors.bgDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DriverColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
