import 'package:flutter/material.dart';
import '../models/driver_document.dart';
import '../widgets/document_card.dart';
import '../widgets/document_preview_dialog.dart';
import '../widgets/upload_modal_bottom_sheet.dart';

class DriverDocumentUploadScreen extends StatefulWidget {
  const DriverDocumentUploadScreen({super.key});

  @override
  State<DriverDocumentUploadScreen> createState() =>
      _DriverDocumentUploadScreenState();
}

class _DriverDocumentUploadScreenState
    extends State<DriverDocumentUploadScreen> {
  DocumentCategory? _selectedCategory; // null = All

  late List<DriverDocument> _documents;

  @override
  void initState() {
    super.initState();
    _initDefaultDocuments();
  }

  void _initDefaultDocuments() {
    _documents = [
      DriverDocument(
        id: 'cdl_01',
        title: 'Commercial Driver License (CDL)',
        subtitle: 'Valid State CDL (Class A/B) with towing & air brake endorsement',
        documentCode: 'DOC-CDL-01',
        category: DocumentCategory.driverIdentity,
        status: DocumentStatus.verified,
        icon: Icons.badge_outlined,
        isRequired: true,
        documentNumber: 'CDL-882910-TX',
        expiryDate: DateTime(2028, 11, 24),
        uploadedFileName: 'cdl_front_back_scan.jpg',
        uploadedFileSize: '2.4 MB',
        uploadedAt: DateTime.now().subtract(const Duration(days: 42)),
      ),
      DriverDocument(
        id: 'reg_02',
        title: 'Vehicle Registration (RC)',
        subtitle: 'State DMV commercial cab card for 2024 Peterbilt 337',
        documentCode: 'DOC-REG-02',
        category: DocumentCategory.vehicleCompliance,
        status: DocumentStatus.verified,
        icon: Icons.local_shipping_outlined,
        isRequired: true,
        documentNumber: 'REG-TX-77492',
        expiryDate: DateTime(2027, 4, 15),
        uploadedFileName: 'peterbilt_cab_card_certified.pdf',
        uploadedFileSize: '1.9 MB',
        uploadedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      DriverDocument(
        id: 'pan_03',
        title: 'PAN Card / Tax Identification',
        subtitle: 'Government issued Permanent Account Number for payouts',
        documentCode: 'DOC-PAN-03',
        category: DocumentCategory.driverIdentity,
        status: DocumentStatus.verified,
        icon: Icons.credit_card_rounded,
        isRequired: true,
        documentNumber: 'ABCDE1234F',
        uploadedFileName: 'pan_card_verified.jpg',
        uploadedFileSize: '1.2 MB',
        uploadedAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      DriverDocument(
        id: 'ins_04',
        title: 'Commercial Towing Liability (\$1M)',
        subtitle: 'Certificate of Insurance (COI) with on-hook & garagekeepers coverage',
        documentCode: 'DOC-INS-04',
        category: DocumentCategory.insuranceAndLegal,
        status: DocumentStatus.verified,
        icon: Icons.shield_outlined,
        isRequired: true,
        documentNumber: 'POL-PROGRESSIVE-8941',
        expiryDate: DateTime(2027, 8, 30),
        uploadedFileName: 'coi_commercial_liability.pdf',
        uploadedFileSize: '3.1 MB',
        uploadedAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      DriverDocument(
        id: 'dot_05',
        title: 'Annual DOT Safety Inspection',
        subtitle: '49 CFR Part 396 safety certificate for brakes, tires, and winch hydraulic',
        documentCode: 'DOC-DOT-05',
        category: DocumentCategory.vehicleCompliance,
        status: DocumentStatus.pending,
        icon: Icons.fact_check_outlined,
        isRequired: true,
        documentNumber: 'DOT-INSP-2026',
        expiryDate: DateTime(2026, 12, 1),
      ),
    ];
  }

  int get _verifiedCount =>
      _documents.where((d) => d.status == DocumentStatus.verified).length;

  int get _totalCount => _documents.length;

  double get _completionPercent =>
      _totalCount == 0 ? 0 : _verifiedCount / _totalCount;

  List<DriverDocument> get _filteredDocuments {
    if (_selectedCategory == null) return _documents;
    return _documents
        .where((d) => d.category == _selectedCategory)
        .toList();
  }

  void _handleUpload(DriverDocument doc) {
    UploadModalBottomSheet.show(
      context,
      document: doc,
      onUploadComplete: (fileName, fileSize) {
        setState(() {
          doc.status = DocumentStatus.underReview;
          doc.uploadedFileName = fileName;
          doc.uploadedFileSize = fileSize;
          doc.uploadedAt = DateTime.now();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${doc.title} uploaded for review!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePreview(DriverDocument doc) {
    DocumentPreviewDialog.show(
      context,
      document: doc,
      onReplace: () => _handleUpload(doc),
    );
  }

  void _submitAllDocuments() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFECFDF5),
                  border: Border.all(
                    color: const Color(0xFFA7F3D0),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF10B981),
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Submission Sent for Approval',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your documents have been encrypted and queued for Compliance verification. Verification typically takes 2-4 business hours.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Return to Profile',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComplianceHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text(
                  'Compliance Guidelines',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHelpPoint(
              '1. Clear Framing',
              'Take photos in good lighting without flash glare. All four edges of the card must be visible.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              '2. Expiration Date Validity',
              'Ensure all licenses, inspections, and insurance policies are current with at least 30 days remaining.',
            ),
            const SizedBox(height: 12),
            _buildHelpPoint(
              '3. Name Matching',
              'Driver legal name on license must match your profile and commercial liability certificate.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Got It', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpPoint(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Documents (RC, DL, PAN)',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.black,
            ),
            tooltip: 'Guidelines',
            onPressed: _showComplianceHelp,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Verification Progress Header
                    _buildVerificationProgressCard(),
                    const SizedBox(height: 18),

                    // 2. Category Filter Pills
                    _buildCategoryFilterRow(),
                    const SizedBox(height: 18),

                    // 3. Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'REQUIRED CREDENTIALS (${_filteredDocuments.length})',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '${_documents.where((d) => d.status == DocumentStatus.pending).length} Pending Upload',
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 4. Document Cards List
                    ..._filteredDocuments.map(
                      (doc) => DocumentCard(
                        key: ValueKey(doc.id),
                        document: doc,
                        onUpload: () => _handleUpload(doc),
                        onPreview: () => _handlePreview(doc),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // 5. Bottom Sticky Submission CTA
            _buildStickyBottomCta(),
          ],
        ),
      ),
    );
  }

  // Top Verification Status Banner
  Widget _buildVerificationProgressCard() {
    final int percentInt = (_completionPercent * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: CircularProgressIndicator(
                      value: _completionPercent,
                      strokeWidth: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                  Text(
                    '$percentInt%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),

              // Status Summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'FLEET COMPLIANCE',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_verifiedCount of $_totalCount Credentials Verified',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _completionPercent == 1.0
                          ? 'All documents active & verified!'
                          : 'Upload 1 more document for full dispatch priority.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),

          // Security Trust Stamp
          const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF10B981),
                size: 13,
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  '256-Bit SSL Encrypted Vault',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.verified_rounded,
                color: Color(0xFF38BDF8),
                size: 13,
              ),
              SizedBox(width: 5),
              Text(
                'DOT Compliant',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Category Filter Row
  Widget _buildCategoryFilterRow() {
    final categories = [
      {'label': 'All (5)', 'cat': null},
      {'label': 'Identity (2)', 'cat': DocumentCategory.driverIdentity},
      {'label': 'Vehicle (2)', 'cat': DocumentCategory.vehicleCompliance},
      {'label': 'Insurance (1)', 'cat': DocumentCategory.insuranceAndLegal},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((c) {
          final isSelected = _selectedCategory == c['cat'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                c['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              selectedColor: Colors.black,
              backgroundColor: const Color(0xFFF1F5F9),
              side: BorderSide(
                color: isSelected ? Colors.black : const Color(0xFFE2E8F0),
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = c['cat'] as DocumentCategory?;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // Sticky Bottom Bar
  Widget _buildStickyBottomCta() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _submitAllDocuments,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'SUBMIT DOCUMENTS FOR APPROVAL',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
