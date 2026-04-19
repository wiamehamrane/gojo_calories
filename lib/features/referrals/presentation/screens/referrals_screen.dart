import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/network/referrals_api.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/localization/translations.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ReferralsApi.getMyReferrals();
      setState(() { _data = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _copyCode(String lang) {
    final code = _data?['referral_code'] as String? ?? '';
    Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Translations.t(lang, 'your_referral_code')),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWithdrawSheet(String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(
        maxAmount: (_data?['balance'] as num?)?.toDouble() ?? 0.0,
        onSuccess: _fetchData,
        lang: lang,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final lang = ref.watch(localeProvider);
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              Translations.t(lang, 'referrals'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            centerTitle: true,
          ),
          body: _loading
              ? _buildSkeleton()
              : _error != null
                  ? _buildError(lang)
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _fetchData,
                      child: _buildContent(lang),
                    ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.wifiOff, size: 48, color: AppColors.inactive),
            const SizedBox(height: 16),
            Text(
              Translations.t(lang, 'error'),
              style: AppTextStyles.sectionHeader,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              Translations.t(lang, 'retry'),
              style: AppTextStyles.bodyRegular,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _PrimaryButton(label: Translations.t(lang, 'retry'), onTap: _fetchData),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String lang) {
    final balance = (_data?['balance'] as num?)?.toDouble() ?? 0.0;
    final totalEarned = (_data?['total_earned'] as num?)?.toDouble() ?? 0.0;
    final totalReferrals = _data?['total_referrals'] as int? ?? 0;
    final totalWithdrawn = (_data?['total_withdrawn'] as num?)?.toDouble() ?? 0.0;
    final code = _data?['referral_code'] as String? ?? '------';
    final history = (_data?['referral_history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final withdrawals = (_data?['withdrawal_history'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // ── Hero Earnings Card ────────────────────────────────────────────
          _HeroEarningsCard(
            balance: balance,
            totalEarned: totalEarned,
            onWithdraw: balance > 0 ? () => _showWithdrawSheet(lang) : null,
          ),

          const SizedBox(height: 20),

          // ── Stats Row ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _StatCard(label: Translations.t(lang, 'friends_stat'), value: '$totalReferrals', icon: LucideIcons.users)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: Translations.t(lang, 'earned_stat'), value: '\$${totalEarned.toStringAsFixed(2)}', icon: LucideIcons.trendingUp)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: Translations.t(lang, 'paid_out_stat'), value: '\$${totalWithdrawn.toStringAsFixed(2)}', icon: LucideIcons.badgeCheck)),
            ],
          ),

          const SizedBox(height: 24),

          // ── Referral Code ─────────────────────────────────────────────────
          _SectionLabel(Translations.t(lang, 'your_referral_code')),
          _ReferralCodeCard(code: code, onCopy: () => _copyCode(lang)),

          const SizedBox(height: 24),

          // ── How it works ──────────────────────────────────────────────────
          _HowItWorksCard(),

          const SizedBox(height: 24),

          // ── Referral History ──────────────────────────────────────────────
          if (history.isNotEmpty) ...[
            _SectionLabel(Translations.t(lang, 'friends_joined')),
            _ReferralHistoryCard(items: history),
            const SizedBox(height: 24),
          ],

          // ── Withdrawal History ────────────────────────────────────────────
          if (withdrawals.isNotEmpty) ...[
            _SectionLabel(Translations.t(lang, 'withdrawal_history')),
            _WithdrawalHistoryCard(items: withdrawals),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Hero Earnings Card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroEarningsCard extends StatelessWidget {
  final double balance;
  final double totalEarned;
  final VoidCallback? onWithdraw;

  const _HeroEarningsCard({
    required this.balance,
    required this.totalEarned,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B4CC), Color(0xFF007D8F)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B4CC).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(LucideIcons.gift, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text(
                'Referral balance',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 48, fontWeight: FontWeight.w800,
              color: Colors.white, height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total earned: \$${totalEarned.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onWithdraw,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: onWithdraw != null ? Colors.white : Colors.white30,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.arrowDownToLine,
                    size: 16,
                    color: onWithdraw != null ? AppColors.primaryDark : Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    onWithdraw != null ? 'Withdraw Earnings' : 'No balance to withdraw',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: onWithdraw != null ? AppColors.primaryDark : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodyRegular),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Referral Code Card
// ─────────────────────────────────────────────────────────────────────────────

class _ReferralCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;

  const _ReferralCodeCard({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Code display
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: 4,
                  ),
                ),
                GestureDetector(
                  onTap: onCopy,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.copy, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Share this code with friends. You earn \$1 for every friend who signs up with it.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// How It Works Card
// ─────────────────────────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (LucideIcons.share2, 'Share your code', 'Send it to friends via any app'),
      (LucideIcons.userPlus, 'Friend signs up', 'They enter your code at registration'),
      (LucideIcons.dollarSign, 'Earn \$1', 'Instantly credited to your balance'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(s.$1, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text(s.$3, style: AppTextStyles.bodyRegular),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Referral History Card
// ─────────────────────────────────────────────────────────────────────────────

class _ReferralHistoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _ReferralHistoryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final name = item['referred_name'] as String? ?? 'Friend';
          final date = _formatDate(item['created_at'] as String?);
          final amount = (item['amount'] as num?)?.toDouble() ?? 1.0;

          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'F',
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                subtitle: Text(date, style: AppTextStyles.bodyRegular),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+\$${amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
              if (i < items.length - 1)
                const Divider(color: AppColors.border, height: 1, indent: 60),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Withdrawal History Card
// ─────────────────────────────────────────────────────────────────────────────

class _WithdrawalHistoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _WithdrawalHistoryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final w = entry.value;
          final amount = (w['amount'] as num?)?.toDouble() ?? 0.0;
          final method = w['method'] as String? ?? 'PayPal';
          final status = w['status'] as String? ?? 'pending';
          final date = _formatDate(w['created_at'] as String?);
          final isPaid = status == 'paid';

          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isPaid ? AppColors.primaryLight : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPaid ? LucideIcons.circleCheck : LucideIcons.clock,
                    size: 20,
                    color: isPaid ? AppColors.primary : AppColors.fire,
                  ),
                ),
                title: Text(
                  '\$${amount.toStringAsFixed(2)} via $method',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                subtitle: Text(date, style: AppTextStyles.bodyRegular),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? AppColors.primaryLight : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: isPaid ? AppColors.primaryDark : AppColors.fire,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
              if (i < items.length - 1)
                const Divider(color: AppColors.border, height: 1, indent: 68),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Withdraw Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _WithdrawSheet extends StatefulWidget {
  final double maxAmount;
  final VoidCallback onSuccess;
  final String lang;

  const _WithdrawSheet({required this.maxAmount, required this.onSuccess, required this.lang});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amountCtrl = TextEditingController();
  String _method = 'PayPal';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.maxAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid amount.');
      return;
    }
    if (amount > widget.maxAmount) {
      setState(() => _error = 'Amount exceeds your balance of \$${widget.maxAmount.toStringAsFixed(2)}.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await ReferralsApi.requestWithdrawal(amount: amount, method: _method);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Withdrawal request submitted!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('DioException', '').replaceAll('[', '').replaceAll(']', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: mq.viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Withdraw Earnings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Available balance: \$${widget.maxAmount.toStringAsFixed(2)}',
            style: AppTextStyles.bodyRegular,
          ),
          const SizedBox(height: 24),

          // Amount field
          const Text('Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Method selector
          const Text('Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: ['PayPal', 'Bank Transfer'].map((m) {
              final selected = _method == m;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _method = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: m == 'PayPal' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryLight : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      m,
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: const TextStyle(fontSize: 13, color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),

          _PrimaryButton(
            label: _loading ? 'Submitting…' : 'Submit Request',
            onTap: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inactive),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PrimaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  colors: [Color(0xFF00B4CC), Color(0xFF007D8F)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: onTap == null ? AppColors.border : null,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.buttonLabel.copyWith(
            color: onTap != null ? Colors.white : AppColors.inactive,
          ),
        ),
      ),
    );
  }
}
