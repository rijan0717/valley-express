import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';
import '../../core/image_compress.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../widgets/valley_snackbar.dart';

class RaiseIssueScreen extends StatefulWidget {
  final String userRole; // 'customer' | 'rider'

  const RaiseIssueScreen({
    super.key,
    this.userRole = 'customer',
  });

  @override
  State<RaiseIssueScreen> createState() => _RaiseIssueScreenState();
}

class _RaiseIssueScreenState extends State<RaiseIssueScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;

  // Form state
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'delivery';
  String? _screenshotBase64;
  bool _submitting = false;
  String? _titleError;
  String? _descError;

  // My issues state
  List<dynamic> _myIssues = [];
  bool _loadingIssues = true;

  final List<Map<String, String>> _categories = [
    {'id': 'delivery', 'label': 'Delivery Delay / Issue'},
    {'id': 'payment', 'label': 'Payment / Cash Discrepancy'},
    {'id': 'order', 'label': 'Wrong or Damaged Item'},
    {'id': 'app_bug', 'label': 'App Glitch or Bug'},
    {'id': 'rider_behavior', 'label': 'Rider Conduct'},
    {'id': 'customer_behavior', 'label': 'Customer Issue'},
    {'id': 'vehicle_breakdown', 'label': 'Vehicle / Road Breakdown'},
    {'id': 'other', 'label': 'Other Operational Concern'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMyIssues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyIssues() async {
    setState(() => _loadingIssues = true);
    try {
      final res = await _api.dio.get('/issues/my');
      if (res.statusCode == 200 && res.data['success'] == true) {
        if (mounted) {
          setState(() {
            _myIssues = res.data['issues'] ?? [];
            _loadingIssues = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingIssues = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingIssues = false);
    }
  }

  Future<void> _pickScreenshot(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 80,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final dataUrl = await ImageCompress.toDataUrl(
        bytes,
        maxEdge: ImageCompress.attachmentEdge,
      );
      if (!mounted) return;
      setState(() {
        _screenshotBase64 = dataUrl;
      });
    } catch (e) {
      if (mounted) {
        ValleySnackbar.error(context, 'Could not attach screenshot. Please try again.');
      }
    }
  }

  bool _validateForm() {
    bool valid = true;
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      setState(() => _titleError = 'Please enter an issue title');
      valid = false;
    } else if (title.length < 3) {
      setState(() => _titleError = 'Title must be at least 3 characters');
      valid = false;
    } else {
      setState(() => _titleError = null);
    }

    if (desc.isEmpty) {
      setState(() => _descError = 'Please provide details about what happened');
      valid = false;
    } else if (desc.length < 10) {
      setState(() => _descError = 'Description must be at least 10 characters');
      valid = false;
    } else {
      setState(() => _descError = null);
    }

    return valid;
  }

  Future<void> _submitIssue() async {
    if (!_validateForm()) return;

    setState(() => _submitting = true);
    try {
      final payload = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'screenshot': _screenshotBase64,
      };

      final res = await _api.dio.post('/issues', data: payload);
      if (res.statusCode == 201 && res.data['success'] == true) {
        final ticketNo = res.data['issue']?['ticketNo'] ?? '';
        if (mounted) {
          _titleController.clear();
          _descController.clear();
          setState(() {
            _screenshotBase64 = null;
            _submitting = false;
          });

          // Show confirmation modal
          _showSuccessModal(ticketNo);
          _fetchMyIssues();
          _tabController.animateTo(1); // Switch to My Issues tab
        }
      } else {
        if (mounted) {
          setState(() => _submitting = false);
          ValleySnackbar.error(context, res.data['message'] ?? 'Could not submit issue');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ValleySnackbar.error(context, 'Error submitting report. Please check connection.');
      }
    }
  }

  void _showSuccessModal(String ticketNo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Text('Issue Submitted', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your ticket #$ticketNo has been created and sent directly to Operations Dispatch & Admin.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003893).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Once the admin reviews or resolves your issue, their action note and status will appear automatically under the "My Tickets" tab.',
                style: TextStyle(fontSize: 12, color: Color(0xFF003893), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('View My Tickets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Attach Screenshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryOrange),
                title: const Text('Take Photo / Camera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickScreenshot(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF003893)),
                title: const Text('Choose from Gallery / Screenshots'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickScreenshot(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageLightbox(String imageUri) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUri.startsWith('data:')
                  ? Image.memory(
                      base64Decode(imageUri.split(',').last),
                      fit: BoxFit.contain,
                    )
                  : Image.network(imageUri, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
        title: Text(
          widget.userRole == 'rider' ? 'Raise Incident / Issue' : 'Raise an Issue / Help Ticket',
          style: AppTheme.displayFont(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryOrange,
          indicatorWeight: 3,
          tabs: [
            const Tab(text: 'Submit New Issue'),
            Tab(text: 'My Tickets (${_myIssues.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormTab(isDark),
          _buildMyIssuesTab(isDark),
        ],
      ),
    );
  }

  Widget _buildFormTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Guidance Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.userRole == 'rider'
                      ? 'Report route delays, payment disputes, vehicle breakdowns, or store stock issues directly to Operations Dispatch.'
                      : 'Having trouble with your order, payment, delivery, or app? Submit a ticket and our support team will update you on the resolution.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF1E40AF),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Category Selection
        Text(
          'ISSUE CATEGORY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              dropdownColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: _categories.map((c) {
                return DropdownMenuItem<String>(
                  value: c['id'],
                  child: Text(
                    c['label']!,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title Input
        Text(
          'ISSUE TITLE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: widget.userRole == 'rider'
                ? 'e.g., Customer not answering call at Thamel gate'
                : 'e.g., Missing chilled Red Bull from order #VX-4821',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            errorText: _titleError,
            filled: true,
            fillColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Description Input
        Text(
          'DETAILED DESCRIPTION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          maxLines: 5,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Please describe the incident, order number, amount, or error encountered in detail...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            errorText: _descError,
            filled: true,
            fillColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Screenshot Attachment Area
        Text(
          'SCREENSHOT / PHOTO (OPTIONAL)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        if (_screenshotBase64 == null) ...[
          InkWell(
            onTap: _showAttachmentOptions,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorderCard : Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_rounded, size: 36, color: AppTheme.primaryOrange.withOpacity(0.8)),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to attach screenshot or photo',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Supports JPEG, PNG up to 5MB',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade400),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(_screenshotBase64!.split(',').last),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Screenshot Attached', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      SizedBox(height: 2),
                      Text('Ready to submit with issue', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _screenshotBase64 = null),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 26),

        // Submit Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          onPressed: _submitting ? null : _submitIssue,
          child: _submitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
                  'Submit Issue Report',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMyIssuesTab(bool isDark) {
    if (_loadingIssues) {
      return const Center(child: ValleyLoader(size: 64, label: 'Loading your tickets...'));
    }

    if (_myIssues.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_turned_in_outlined, size: 54, color: Colors.grey),
              const SizedBox(height: 14),
              const Text(
                'No Issues Reported Yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'When you report a problem, it will be tracked here until resolved and cleared by admin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ValleyRefresh(
      onRefresh: _fetchMyIssues,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myIssues.length,
        itemBuilder: (ctx, idx) {
          final issue = _myIssues[idx];
          return _buildIssueCard(issue, isDark);
        },
      ),
    );
  }

  Widget _buildIssueCard(Map<String, dynamic> issue, bool isDark) {
    final status = issue['status'] ?? 'pending';
    final ticketNo = issue['ticketNo'] ?? 'ISS-000';
    final title = issue['title'] ?? 'Support Ticket';
    final desc = issue['description'] ?? '';
    final adminNote = issue['adminNote'] ?? '';
    final screenshot = issue['screenshot'];
    final createdAt = issue['createdAt'] ?? '';

    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;
    String statusLabel;

    switch (status) {
      case 'investigating':
        badgeBg = const Color(0xFF3B82F6).withOpacity(0.12);
        badgeText = const Color(0xFF1D4ED8);
        badgeIcon = Icons.search_rounded;
        statusLabel = 'Under Investigation';
        break;
      case 'resolved':
        badgeBg = const Color(0xFF10B981).withOpacity(0.12);
        badgeText = const Color(0xFF047857);
        badgeIcon = Icons.check_circle_rounded;
        statusLabel = 'Resolved';
        break;
      case 'rejected':
        badgeBg = Colors.grey.withOpacity(0.15);
        badgeText = Colors.grey.shade800;
        badgeIcon = Icons.cancel_outlined;
        statusLabel = 'Closed';
        break;
      case 'pending':
      default:
        badgeBg = const Color(0xFFF59E0B).withOpacity(0.12);
        badgeText = const Color(0xFFB45309);
        badgeIcon = Icons.hourglass_top_rounded;
        statusLabel = 'Under Review';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ticket No & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$ticketNo',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeText),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(color: badgeText, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              height: 1.4,
            ),
          ),

          // Screenshot thumbnail if available
          if (screenshot != null && screenshot.toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showImageLightbox(screenshot.toString()),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: screenshot.toString().startsWith('data:')
                        ? Image.memory(
                            base64Decode(screenshot.toString().split(',').last),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : Image.network(screenshot.toString(), width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tap to view attached screenshot',
                    style: TextStyle(fontSize: 11, color: AppTheme.primaryOrange, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],

          // Admin Resolution Note (What has been done)
          if (adminNote.toString().trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ADMIN UPDATE & RESOLUTION:',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    adminNote.toString(),
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF065F46), height: 1.3),
                  ),
                ],
              ),
            ),
          ],

          // Footer info
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                'Archived by admin on resolve',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
