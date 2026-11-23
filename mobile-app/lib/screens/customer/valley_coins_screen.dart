import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../widgets/valley_loader.dart';
import '../../widgets/valley_snackbar.dart';

/// Valley Coins: the balance, what it is worth, and where it came from.
class ValleyCoinsScreen extends StatefulWidget {
  const ValleyCoinsScreen({super.key});

  @override
  State<ValleyCoinsScreen> createState() => _ValleyCoinsScreenState();
}

class _ValleyCoinsScreenState extends State<ValleyCoinsScreen> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  int _balance = 0;
  double _balanceValue = 0;
  int _totalEarned = 0;
  int _totalSpent = 0;
  int _rupeesPerCoin = 10;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await _api.dio.get('/coins/me');
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() {
          _balance = (res.data['balance'] as num?)?.toInt() ?? 0;
          _balanceValue = (res.data['balanceValue'] as num?)?.toDouble() ?? 0;
          _totalEarned = (res.data['totalEarned'] as num?)?.toInt() ?? 0;
          _totalSpent = (res.data['totalSpent'] as num?)?.toInt() ?? 0;
          _rupeesPerCoin = (res.data['rupeesPerCoin'] as num?)?.toInt() ?? 10;
          _transactions = res.data['transactions'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ValleySnack.error(context, friendlyApiError(e, 'Could not load your coins.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgApp : AppTheme.lightBgApp,
      appBar: AppBar(
        title: const Text('Valley Coins'),
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        elevation: 1,
      ),
      body: _loading
          ? const ValleyLoaderScreen(label: 'Loading your coins...')
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppTheme.primaryOrange,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _buildBalanceCard(isDark),
                  const SizedBox(height: 14),
                  _buildTotalsRow(isDark),
                  const SizedBox(height: 14),
                  _buildHowItWorks(isDark),
                  const SizedBox(height: 18),
                  Text(
                    'HISTORY',
                    style: AppTheme.displayFont(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    _buildEmptyHistory(isDark)
                  else
                    ..._transactions.map((t) => _buildLedgerRow(t, isDark)),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.monetization_on_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Valley Coin Balance',
                style: AppTheme.displayFont(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_balance',
                style: AppTheme.displayFont(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _balance == 1 ? 'coin' : 'coins',
                style: AppTheme.bodyFont(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Worth Rs. ${_balanceValue.toStringAsFixed(2)} off a future order',
            style: AppTheme.bodyFont(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildTotalTile(
            label: 'Earned',
            value: '$_totalEarned',
            icon: Icons.arrow_downward_rounded,
            colour: AppTheme.successGreen,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTotalTile(
            label: 'Spent',
            value: '$_totalSpent',
            icon: Icons.arrow_upward_rounded,
            colour: AppTheme.navyBrand,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalTile({
    required String label,
    required String value,
    required IconData icon,
    required Color colour,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: colour),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTheme.displayFont(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          Text(
            '$label lifetime',
            style: AppTheme.bodyFont(
              fontSize: 11,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(bool isDark) {
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
          const Icon(Icons.info_outline_rounded,
              size: 17, color: AppTheme.navyBrand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Every Rs. $_rupeesPerCoin you spend earns 1 Valley Coin, added once '
              'your order is delivered. Coins come off a future bill.',
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

  Widget _buildEmptyHistory(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.savings_outlined,
              size: 38,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
          const SizedBox(height: 12),
          Text(
            'No coins yet',
            style: AppTheme.displayFont(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your first delivered order starts the balance.',
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

  Widget _buildLedgerRow(dynamic t, bool isDark) {
    final coins = (t['coins'] as num?)?.toInt() ?? 0;
    final credited = coins >= 0;
    final type = (t['type'] ?? '').toString();
    final orderNo = (t['orderNo'] ?? '').toString();

    Color colour;
    IconData icon;
    switch (type) {
      case 'earned':
        colour = AppTheme.successGreen;
        icon = Icons.add_rounded;
        break;
      case 'spent':
        colour = AppTheme.navyBrand;
        icon = Icons.remove_rounded;
        break;
      case 'reversed':
        colour = AppTheme.danger;
        icon = Icons.undo_rounded;
        break;
      default:
        colour = AppTheme.primaryOrange;
        icon = Icons.tune_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderCard : AppTheme.lightBorderCard,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: colour),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelFor(type, orderNo),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.displayFont(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(t['createdAt']),
                  style: AppTheme.bodyFont(
                    fontSize: 10.5,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${credited ? '+' : ''}$coins',
            style: AppTheme.displayFont(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colour,
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(String type, String orderNo) {
    final suffix = orderNo.isNotEmpty ? ' • $orderNo' : '';
    switch (type) {
      case 'earned':
        return 'Earned on delivery$suffix';
      case 'spent':
        return 'Redeemed$suffix';
      case 'reversed':
        return 'Reversed$suffix';
      default:
        return 'Adjustment$suffix';
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return '';
    return DateFormat('d MMM yyyy, h:mm a').format(parsed.toLocal());
  }
}
