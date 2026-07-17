import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../auth/presentation/providers/iap_provider.dart';
import '../../data/clan_repository.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/store_price_format.dart';

final clanRepositoryProvider = Provider((ref) => ClanRepository());

class ClanScreen extends ConsumerStatefulWidget {
  const ClanScreen({super.key});

  @override
  ConsumerState<ClanScreen> createState() => _ClanScreenState();
}

class _ClanScreenState extends ConsumerState<ClanScreen> {
  final _emailController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic>? _data;
  String? _error;
  String? _localAddonPrice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocalAddonPrice(String? productId) async {
    if (productId == null) {
      if (mounted) setState(() => _localAddonPrice = null);
      return;
    }
    try {
      final product =
          await ref.read(iapServiceProvider).loadClanAddonProduct(productId);
      if (!mounted) return;
      setState(() {
        _localAddonPrice =
            product != null ? StorePriceFormat.display(product) : null;
      });
    } catch (_) {
      if (mounted) setState(() => _localAddonPrice = null);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(clanRepositoryProvider).getMyClan();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
      final clan = data['clan'] as Map<String, dynamic>?;
      await _resolveLocalAddonPrice(clan?['addon_product_id'] as String?);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _invite() async {
    final lang = ref.read(localeProvider);
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final result = await ref.read(clanRepositoryProvider).inviteMember(email);
      _emailController.clear();
      if (!mounted) return;
      final link = result['share_link'] as String?;
      if (link != null) {
        await Clipboard.setData(ClipboardData(text: link));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.t(lang, 'clan_invite_sent')),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _purchaseAddon(String? productId) async {
    if (productId == null) return;
    final iap = ref.read(iapServiceProvider);
    final product = await iap.loadClanAddonProduct(productId);
    if (product == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clan add-on not available in the store yet.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await iap.buySubscription(product);
  }

  Future<void> _removeMember(String userId) async {
    setState(() => _submitting = true);
    try {
      await ref.read(clanRepositoryProvider).removeMember(userId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('clan_title')),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        t('clan_subtitle'),
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_data?['has_clan'] != true) ...[
                        _InfoCard(
                          icon: LucideIcons.info,
                          text: t('clan_requires_subscription'),
                        ),
                      ] else ...[
                        _buildClanContent(t),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildClanContent(String Function(String) t) {
    final clan = _data!['clan'] as Map<String, dynamic>;
    final isOwner = clan['is_owner'] == true;
    final members = (clan['members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final invites = (clan['pending_invites'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final pendingSlots = clan['pending_addon_slots'] as int? ?? 0;
    // Prefer store-localized price only — never fall back to server USD.
    final addonPrice = _localAddonPrice;
    final addonProductId = clan['addon_product_id'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          icon: LucideIcons.users,
          text: '${t('clan_plan')}: ${clan['plan_id']} · ${members.length}/${clan['max_members']} ${t('clan_members')}',
        ),
        const SizedBox(height: 16),
        ...members.map((m) => _MemberTile(
              name: m['name'] as String? ?? m['email'] as String? ?? 'Member',
              role: m['role'] as String? ?? 'member',
              active: m['addon_active'] == true || m['role'] == 'owner',
              onRemove: isOwner && m['role'] == 'member'
                  ? () => _removeMember(m['user_id'] as String)
                  : null,
            )),
        if (invites.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(t('clan_pending_invites'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...invites.map(
            (i) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(i['email'] as String? ?? ''),
              subtitle: Text(t('clan_waiting_accept')),
            ),
          ),
        ],
        if (isOwner) ...[
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: t('clan_invite_email'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _submitting ? null : _invite,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(t('clan_send_invite')),
          ),
          if (pendingSlots > 0 && addonProductId != null) ...[
            const SizedBox(height: 24),
            _InfoCard(
              icon: LucideIcons.creditCard,
              text: '${t('clan_activate_prompt')} ${addonPrice ?? ''}',
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _submitting ? null : () => _purchaseAddon(addonProductId),
              child: Text(t('clan_purchase_addon')),
            ),
          ],
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.name,
    required this.role,
    required this.active,
    this.onRemove,
  });

  final String name;
  final String role;
  final bool active;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  role == 'owner' ? 'Owner' : (active ? 'Active' : 'Pending payment'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(LucideIcons.userMinus, size: 18),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
