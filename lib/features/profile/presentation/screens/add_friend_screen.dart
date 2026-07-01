import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../social/presentation/providers/friends_provider.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _searchController = TextEditingController();
  List<UserSearchResult> _results = [];
  bool _searching = false;

  Future<void> _doSearch(String query) async {
    if (query.length < 2) return;
    setState(() => _searching = true);
    final results = await ref.read(friendsProvider.notifier).searchUsers(query);
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add to Circle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                if (val.length >= 2) _doSearch(val);
              },
            ),
          ),
          if (_searching)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
          if (!_searching && _results.isEmpty && _searchController.text.length >= 2)
            const Expanded(child: Center(child: Text('No users found'))),
          if (!_searching && _results.isNotEmpty)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length,
                separatorBuilder: (context, index) => const Divider(color: AppColors.border),
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        user.name != null && user.name!.isNotEmpty ? user.name![0].toUpperCase() : '👤',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(user.name ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.inactive)),
                    trailing: user.isFriend 
                      ? const Icon(LucideIcons.circleCheck, color: Colors.green, size: 22)
                      : ElevatedButton(
                          onPressed: () async {
                            final success = await ref.read(friendsProvider.notifier).addFriend(user.id);
                            if (success) _doSearch(_searchController.text);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Add', style: TextStyle(fontSize: 12)),
                        ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
