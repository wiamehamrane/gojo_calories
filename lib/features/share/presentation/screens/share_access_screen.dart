import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/share_repository.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';

final shareRepositoryProvider = Provider((ref) => ShareRepository());

class ShareAccessScreen extends ConsumerStatefulWidget {
  const ShareAccessScreen({super.key});

  @override
  ConsumerState<ShareAccessScreen> createState() => _ShareAccessScreenState();
}

class _ShareAccessScreenState extends ConsumerState<ShareAccessScreen> {
  final _emailCtrl = TextEditingController();
  final _acceptCtrl = TextEditingController();
  final _inviteButtonKey = GlobalKey();
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic>? _data;
  String? _error;

  Rect? _shareOrigin() {
    final box =
        _inviteButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size == Size.zero) {
      final size = MediaQuery.sizeOf(context);
      return Rect.fromLTWH(0, size.height - 1, size.width, 1);
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _acceptCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(shareRepositoryProvider).getMyShares();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppErrorHandler.message(e);
        _loading = false;
      });
    }
  }

  String _shareMessage(String link, String token) {
    final lang = ref.read(localeProvider);
    return Translations.t(lang, 'share_invite_message')
        .replaceAll('{link}', link)
        .replaceAll('{token}', token);
  }

  Future<void> _invite() async {
    final lang = ref.read(localeProvider);
    setState(() => _submitting = true);
    try {
      final result = await ref.read(shareRepositoryProvider).invite(
            email:
                _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          );
      _emailCtrl.clear();
      final link = result['share_link'] as String? ?? '';
      final token = result['token'] as String? ?? '';
      if (link.isNotEmpty) {
        final message = _shareMessage(link, token);
        await Clipboard.setData(ClipboardData(text: link));
        try {
          await Share.share(
            message,
            sharePositionOrigin: _shareOrigin(),
          );
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.t(lang, 'share_invite_ready')),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorHandler.message(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _revoke(String id) async {
    try {
      await ref.read(shareRepositoryProvider).revoke(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorHandler.message(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _cancelPending(String id) async {
    final lang = ref.read(localeProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Translations.t(lang, 'share_cancel_invite_title')),
        content: Text(Translations.t(lang, 'share_cancel_invite_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(Translations.t(lang, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              Translations.t(lang, 'share_cancel_invite'),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _revoke(id);
  }

  String? _extractToken(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri != null) {
      final fromQuery = uri.queryParameters['token'];
      if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    }
    // Raw token from landing page / clipboard
    if (!text.contains(' ') && text.length >= 8) return text;
    return null;
  }

  void _openAcceptInvite() {
    final lang = ref.read(localeProvider);
    final token = _extractToken(_acceptCtrl.text);
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.t(lang, 'share_invalid_invite')),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    _acceptCtrl.clear();
    context.push('${RoutePaths.shareJoin}?token=${Uri.encodeQueryComponent(token)}');
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('share_access_title')),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.profile);
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: Text(t('retry'))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      Text(
                        t('share_access_subtitle'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle(t('share_invite_section')),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: t('share_email_optional'),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: _inviteButtonKey,
                        onPressed: _submitting ? null : _invite,
                        icon: const Icon(LucideIcons.link),
                        label: Text(
                          _submitting ? t('loading') : t('share_create_invite'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _sectionTitle(t('share_have_invite')),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _acceptCtrl,
                        decoration: InputDecoration(
                          hintText: t('share_paste_invite'),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _openAcceptInvite,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(t('share_open_invite')),
                      ),
                      const SizedBox(height: 28),
                      _sectionTitle(t('share_my_clients')),
                      const SizedBox(height: 8),
                      ..._clientTiles(t),
                      const SizedBox(height: 24),
                      _sectionTitle(t('share_who_can_see')),
                      const SizedBox(height: 8),
                      ..._coachTiles(t),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  List<Widget> _clientTiles(String Function(String) t) {
    final list = (_data?['as_viewer'] as List?) ?? [];
    final active = list.where((e) => e['status'] == 'active').toList();
    final pending = list.where((e) => e['status'] == 'pending').toList();

    if (active.isEmpty && pending.isEmpty) {
      return [
        _emptyCard(t('share_no_clients')),
      ];
    }

    return [
      ...active.map((raw) {
        final g = Map<String, dynamic>.from(raw as Map);
        final owner = Map<String, dynamic>.from(g['owner'] as Map? ?? {});
        final name = (owner['name'] as String?)?.trim().isNotEmpty == true
            ? owner['name'] as String
            : (owner['email'] as String? ?? t('share_client'));
        final ownerId = owner['user_id'] as String?;
        return _card(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(LucideIcons.user, color: AppColors.primaryDark),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(t('share_active_access')),
            trailing: const Icon(LucideIcons.chevronRight, size: 18),
            onTap: ownerId == null
                ? null
                : () => context.push(
                      RoutePaths.shareClientDiary.replaceFirst(':id', ownerId),
                      extra: {'name': name},
                    ),
          ),
        );
      }),
      ...pending.map((raw) {
        final g = Map<String, dynamic>.from(raw as Map);
        final link = g['share_link'] as String? ?? '';
        final id = g['id'] as String;
        return _card(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.clock, color: AppColors.inactive),
            title: Text(
              (g['invite_email'] as String?) ?? t('share_pending_invite'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(t('share_waiting_accept')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: t('share_link_copied'),
                  icon: const Icon(LucideIcons.copy, size: 18),
                  onPressed: link.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: link));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t('share_link_copied'))),
                          );
                        },
                ),
                IconButton(
                  tooltip: t('share_cancel_invite'),
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  onPressed: () => _cancelPending(id),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }

  List<Widget> _coachTiles(String Function(String) t) {
    final list = (_data?['as_owner'] as List?) ?? [];
    if (list.isEmpty) {
      return [_emptyCard(t('share_no_coaches'))];
    }
    return list.map((raw) {
      final g = Map<String, dynamic>.from(raw as Map);
      final viewer = Map<String, dynamic>.from(g['viewer'] as Map? ?? {});
      final name = (viewer['name'] as String?)?.trim().isNotEmpty == true
          ? viewer['name'] as String
          : (viewer['email'] as String? ?? t('share_viewer'));
      final id = g['id'] as String;
      return _card(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: AppColors.surfaceMuted,
            child: Icon(LucideIcons.eye, color: AppColors.textSecondary),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(t('share_can_see_your_diary')),
          trailing: TextButton(
            onPressed: () => _revoke(id),
            child: Text(
              t('share_revoke'),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _emptyCard(String text) {
    return _card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
