import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../widgets/valley_snackbar.dart';

/// The vouchers a customer can use, with the code ready to copy.
class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  List<dynamic> _offers = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.dio.get('/offers');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() {
          _offers = res.data['offers'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ValleySnack.error(context, friendlyApiError(e, 'Could not load your vouchers.'));
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ValleySnack.success(context, '$code copied — paste it at checkout');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
        title: const Text('My Vouchers'),
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        elevation: 1,
      ),
      body: _loading
          ? const ValleyLoaderScreen(label: 'Loading your vouchers...')
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppTheme.primaryOrange,
              child: _offers.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                      children: [_buildEmpty(isDark)],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      itemCount: _offers.length,
                      itemBuilder: (_, i) => _buildVoucherCard(_offers[i], isDark),
                    ),
            ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.local_offer_outlined,
              size: 42,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
          const SizedBox(height: 14),
          Text(
            'No vouchers right now',
            style: AppTheme.displayFont(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'New offers land here as soon as dispatch publishes them.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyFont(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(dynamic offer, bool isDark) {
    final code = (offer['code'] ?? '').toString();
    final title = (offer['title'] ?? 'Offer').toString();
    final description = (offer['description'] ?? '').toString();
    final discountType = (offer['discountType'] ?? '').toString();
    final discountValue = (offer['discountValue'] as num?)?.toDouble() ?? 0;
    final minOrder = (offer['minOrderValue'] as num?)?.toDouble() ?? 0;
    final endDate = offer['endDate'];

    final headline = discountType == 'percentage'
        ? '${discountValue.toStringAsFixed(0)}% OFF'
        : 'Rs. ${discountValue.toStringAsFixed(0)} OFF';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // The value band, so the saving reads first.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryOrange, AppTheme.primaryDeep],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: AppTheme.displayFont(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyFont(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    style: AppTheme.bodyFont(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkBgDevice
                              : AppTheme.lightBgDevice,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sell_outlined,
                                size: 15, color: AppTheme.primaryOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                code,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.displayFont(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: code.isEmpty ? null : () => _copyCode(code),
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryOrange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        textStyle: AppTheme.displayFont(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (minOrder > 0)
                      _buildMetaChip(
                        'Min Rs. ${minOrder.toStringAsFixed(0)}',
                        Icons.shopping_bag_outlined,
                        isDark,
                      ),
                    if (endDate != null)
                      _buildMetaChip(
                        'Till ${_formatDate(endDate)}',
                        Icons.schedule_rounded,
                        isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBgDevice : AppTheme.lightBgDevice,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.bodyFont(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic raw) {
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return '';
    return DateFormat('d MMM').format(parsed.toLocal());
  }
}
