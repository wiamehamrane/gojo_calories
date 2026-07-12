import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';

class ReferralsScreen extends ConsumerStatefulWidget {
  const ReferralsScreen({super.key});

  @override
  ConsumerState<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends ConsumerState<ReferralsScreen> {
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
      final result = await ref.read(referralsRepositoryProvider).getMyReferrals();
      setState(() { _data = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _copyCode(String code) {
    final lang = ref.read(localeProvider);
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(Translations.t(lang, 'code_copied')),
          ],
        ),
        backgroundColor: Colors.black,
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
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            surfaceTintColor: AppColors.surface,
            leading: IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              Translations.t(lang, 'referrals'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.textPrimary,
                    strokeWidth: 2,
                  ),
                )
              : _error != null
                  ? _buildError(lang)
                  : RefreshIndicator(
                      color: AppColors.textPrimary,
                      onRefresh: _fetchData,
                      child: _buildContent(context, lang),
                    ),
        );
      },
    );
  }

  Widget _buildError(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.wifiOff, size: 40, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 16),
            Text(
              Translations.t(lang, 'could_not_load_referrals'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _fetchData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(Translations.t(lang, 'retry'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, String lang) {
    String t(String k) => Translations.t(lang, k);
    final balance = (_data?['balance'] as num?)?.toDouble() ?? 0.0;
    final totalEarned = (_data?['total_earned'] as num?)?.toDouble() ?? 0.0;
    final totalReferrals = _data?['total_referrals'] as int? ?? 0;
    final totalWithdrawn = (_data?['total_withdrawn'] as num?)?.toDouble() ?? 0.0;
    final code = _data?['referral_code'] as String? ?? '------';
    final history = (_data?['referral_history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final withdrawals = (_data?['withdrawal_history'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // ── Hero Balance Card ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.gift, color: Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      t('available_balance'),
                      style: const TextStyle(fontSize: 13, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t('total_earned_prefix')} \$${totalEarned.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, color: Colors.white38),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: balance > 0 ? () => _showWithdrawSheet(lang) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: balance > 0 ? Colors.white : Colors.white.withValues(alpha: 0.15),
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
                          color: balance > 0 ? Colors.black : Colors.white38,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          balance > 0 ? t('withdraw_earnings') : t('no_balance_withdraw'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: balance > 0 ? Colors.black : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Stats Row ──────────────────────────────────────────────────
          Row(
            children: [
              _StatCard(icon: LucideIcons.users, value: '$totalReferrals', label: t('friends_stat')),
              const SizedBox(width: 10),
              _StatCard(icon: LucideIcons.trendingUp, value: '\$${totalEarned.toStringAsFixed(0)}', label: t('earned_stat')),
              const SizedBox(width: 10),
              _StatCard(icon: LucideIcons.banknote, value: '\$${totalWithdrawn.toStringAsFixed(0)}', label: t('paid_out_stat')),
            ],
          ),
          const SizedBox(height: 20),

          // ── Referral Code ──────────────────────────────────────────────
          _SectionLabel(t('your_referral_code')),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _copyCode(code),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.copy, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  t('referral_code_hint'),
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF888888), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── How it works ───────────────────────────────────────────────
          _SectionLabel(t('how_it_works')),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE8E8E8)),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StepRow(
                  num: '01',
                  icon: LucideIcons.share2,
                  title: t('how_step1_title'),
                  subtitle: t('how_step1_desc'),
                ),
                const _Divider(),
                _StepRow(
                  num: '02',
                  icon: LucideIcons.userPlus,
                  title: t('how_step2_title'),
                  subtitle: t('how_step2_desc'),
                ),
                const _Divider(),
                _StepRow(
                  num: '03',
                  icon: LucideIcons.dollarSign,
                  title: t('how_step3_title'),
                  subtitle: t('how_step3_desc'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Referral History ───────────────────────────────────────────
          if (history.isNotEmpty) ...[
            _SectionLabel(t('friends_joined')),
            _ReferralHistoryCard(items: history, lang: lang),
            const SizedBox(height: 20),
          ],

          // ── Withdrawal History ─────────────────────────────────────────
          if (withdrawals.isNotEmpty) ...[
            _SectionLabel(t('withdrawal_history')),
            _WithdrawalHistoryCard(items: withdrawals, lang: lang),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF888888), letterSpacing: 0.5),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(color: Color(0xFFEEEEEE), height: 24, thickness: 1);
}

class _StepRow extends StatelessWidget {
  final String num;
  final IconData icon;
  final String title;
  final String subtitle;
  const _StepRow({required this.num, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(num, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReferralHistoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String lang;
  const _ReferralHistoryCard({required this.items, required this.lang});

  String _fmt(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month - 1]} ${dt.day}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final name = item['referred_name'] as String? ?? Translations.t(lang, 'friend_default');
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'F',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text(_fmt(item['created_at'] as String?), style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.textPrimary, borderRadius: BorderRadius.circular(20)),
                      child: Text('+\$1.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.surface)),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1) Divider(height: 1, color: AppColors.border, indent: 64),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _WithdrawalHistoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String lang;
  const _WithdrawalHistoryCard({required this.items, required this.lang});

  String _fmt(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final w = e.value;
          final amount = (w['amount'] as num?)?.toDouble() ?? 0.0;
          final method = w['method'] as String? ?? Translations.t(lang, 'paypal');
          final isPaid = w['status'] == 'paid';
          String t(String k) => Translations.t(lang, k);
          final methodLabel = method == 'Bank Transfer' ? t('bank_transfer') : t('paypal');

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.black : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPaid ? LucideIcons.circleCheck : LucideIcons.clock,
                        size: 18,
                        color: isPaid ? Colors.white : const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('withdrawn_via')
                                .replaceAll('{amount}', '\$${amount.toStringAsFixed(2)}')
                                .replaceAll('{method}', methodLabel),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text(_fmt(w['created_at'] as String?),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.black : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPaid ? t('paid') : t('pending'),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPaid ? Colors.white : const Color(0xFF888888)),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1) const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 68),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Withdraw Sheet ───────────────────────────────────────────────────────────

class _WithdrawSheet extends ConsumerStatefulWidget {
  final double maxAmount;
  final VoidCallback onSuccess;
  final String lang;
  const _WithdrawSheet({required this.maxAmount, required this.onSuccess, required this.lang});

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
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
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    String t(String k) => Translations.t(widget.lang, k);
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) { setState(() => _error = t('valid_amount_required')); return; }
    if (amount > widget.maxAmount) {
      setState(() => _error = t('amount_exceeds_balance').replaceAll('{amount}', '\$${widget.maxAmount.toStringAsFixed(2)}'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(referralsRepositoryProvider).requestWithdrawal(
            amount: amount,
            method: _method,
          );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translations.t(widget.lang, 'withdrawal_submitted')),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() { _loading = false; _error = e.toString().replaceAll('DioException', '').trim(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    String t(String k) => Translations.t(widget.lang, k);
    final mq = MediaQuery.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: mq.viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Text(t('withdraw_earnings_title'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            t('balance_amount').replaceAll('{amount}', '\$${widget.maxAmount.toStringAsFixed(2)}'),
            style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 24),
          Text(t('amount'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF888888))),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.textPrimary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          Text(t('method'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF888888))),
          const SizedBox(height: 8),
          Row(
            children: [
              ('PayPal', t('paypal')),
              ('Bank Transfer', t('bank_transfer')),
            ].map((entry) {
              final m = entry.$1;
              final label = entry.$2;
              final selected = _method == m;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _method = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: m == 'PayPal' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: selected ? Colors.black : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : const Color(0xFF888888),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFCC0000)), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loading ? null : _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 54,
              decoration: BoxDecoration(
                color: _loading ? const Color(0xFFDDDDDD) : Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                _loading ? t('submitting') : t('submit_request'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _loading ? const Color(0xFF888888) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
