import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/valley_snackbar.dart';
import 'raise_issue_screen.dart';

/// Help and emergency contacts, in one place.
///
/// The hotline used to copy a number to the clipboard and leave the person to
/// paste it into the dialler themselves; every line here places the call or
/// opens the right app directly.
class SupportScreen extends StatefulWidget {
  /// Riders get the dispatch framing, customers the delivery one.
  final bool isRider;

  const SupportScreen({super.key, this.isRider = false});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final ApiClient _api = ApiClient();

  // Fallbacks stand in until settings load, so the page is never a dead end.
  String _phone = '+977-9801234567';
  String _email = 'orders@valleyexpress.com.np';

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    try {
      final res = await _api.dio.get('/settings');
      if (!mounted) return;
      final data = res.data['setting'] ?? res.data['settings'];
      if (data is Map) {
        setState(() {
          _phone = (data['contactPhone'] ?? _phone).toString();
          _email = (data['contactEmail'] ?? _email).toString();
        });
      }
    } catch (_) {
      // Keep the fallbacks; support must stay reachable even if settings fail.
    }
  }

  Future<void> _open(Uri uri, String failure) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) ValleySnack.error(context, failure);
    } catch (_) {
      if (mounted) ValleySnack.error(context, failure);
    }
  }

  String get _dialable => _phone.replaceAll(RegExp(r'[^0-9+]'), '');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
        title: const Text('Help & Emergency'),
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _buildEmergencyCard(isDark),
          const SizedBox(height: 16),
          Text(
            'OTHER WAYS TO REACH US',
            style: AppTheme.displayFont(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
          ),
          const SizedBox(height: 8),
          _buildActionTile(
            icon: Icons.phone_in_talk_rounded,
            colour: AppTheme.successGreen,
            title: 'Call operations',
            subtitle: _phone,
            isDark: isDark,
            onTap: () => _open(
              Uri(scheme: 'tel', path: _dialable),
              'No dialler available on this device.',
            ),
          ),
          _buildActionTile(
            icon: Icons.mail_outline_rounded,
            colour: AppTheme.navyBrand,
            title: 'Email support',
            subtitle: _email,
            isDark: isDark,
            onTap: () => _open(
              Uri(scheme: 'mailto', path: _email),
              'No email app available on this device.',
            ),
          ),
          _buildActionTile(
            icon: Icons.report_problem_outlined,
            colour: AppTheme.primaryOrange,
            title: 'Raise an issue',
            subtitle: widget.isRider
                ? 'Report a problem with a delivery, customer or the app'
                : 'Report a problem with an order or the app',
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RaiseIssueScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildHours(isDark),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryOrange, AppTheme.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.primaryGlow,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.emergency_share_rounded,
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  widget.isRider
                      ? 'Emergency dispatch hotline'
                      : 'Emergency support line',
                  style: AppTheme.displayFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.isRider
                ? 'For accidents, unsafe drop-offs or anything that cannot wait. '
                    'Operations answers around the clock.'
                : 'For anything urgent with a live order. Operations answers '
                    'around the clock.',
            style: AppTheme.bodyFont(
              fontSize: 12,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _open(
                Uri(scheme: 'tel', path: _dialable),
                'No dialler available on this device.',
              ),
              icon: const Icon(Icons.call_rounded, size: 18),
              label: Text(
                'Call now',
                style: AppTheme.displayFont(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryDeep,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color colour,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: colour.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: colour, size: 19),
        ),
        title: Text(
          title,
          style: AppTheme.displayFont(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyFont(
            fontSize: 11.5,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 19,
          color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
        ),
      ),
    );
  }

  Widget _buildHours(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_rounded, size: 17, color: AppTheme.navyBrand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Deliveries run 8:00 PM to 4:00 AM across Kathmandu, Lalitpur and '
              'Bhaktapur. The emergency line is answered at any hour.',
              style: AppTheme.bodyFont(
                fontSize: 11.5,
                height: 1.45,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
