import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../providers/language_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// Dialog for selecting receiver users to route an order to.
/// Supports both multiple selections (checkboxes) and single selection.
/// Only shows users that belong to the same shop (shopId).
class SendOrderDialog extends StatefulWidget {
  final String currentUserId;
  final String shopId;
  final bool isSingleSelect;

  const SendOrderDialog({
    super.key,
    required this.currentUserId,
    required this.shopId,
    this.isSingleSelect = false,
  });

  /// Shows the dialog and returns the selected users list, or null if cancelled.
  static Future<List<AppUser>?> show(
    BuildContext context,
    String currentUserId, {
    required String shopId,
    bool isSingleSelect = false,
  }) {
    return showDialog<List<AppUser>>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => SendOrderDialog(
        currentUserId: currentUserId,
        shopId: shopId,
        isSingleSelect: isSingleSelect,
      ),
    );
  }

  @override
  State<SendOrderDialog> createState() => _SendOrderDialogState();
}

class _SendOrderDialogState extends State<SendOrderDialog>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Stream<List<AppUser>> _usersStream;
  String _searchQuery = '';
  final List<AppUser> _selectedUsers = [];

  @override
  void initState() {
    super.initState();
    _usersStream = _firestoreService.streamUsersInShop(widget.shopId);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ──────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.isSingleSelect
                            ? Colors.orange.withValues(alpha: 0.12)
                            : AppTheme.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.isSingleSelect
                            ? Icons.drafts_rounded
                            : Icons.send_rounded,
                        color: widget.isSingleSelect ? Colors.orange : AppTheme.accentAmber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      widget.isSingleSelect
                          ? (isAr ? 'إرسال المسودة إلى...' : 'Send Draft to...')
                          : (isAr ? 'إرسال الطلبية إلى...' : 'Send Order to...'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ─── Search Field ────────────────────────────
                TextField(
                  decoration: InputDecoration(
                    hintText: context.tr('search_user'),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppTheme.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),

                const SizedBox(height: 12),

                // ─── Users List ──────────────────────────────
                Expanded(
                  child: StreamBuilder<List<AppUser>>(
                    stream: _usersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            context.tr('error_loading_orders'),
                            style: TextStyle(color: AppTheme.error),
                          ),
                        );
                      }

                      final allUsers = snapshot.data ?? [];
                      final filteredUsers = allUsers.where((user) {
                        if (_searchQuery.isEmpty) return true;
                        return user.displayName
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            user.email.toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (filteredUsers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 48,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.tr('no_users_found'),
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final allSelected = filteredUsers.isNotEmpty &&
                          filteredUsers.every((u) => _selectedUsers.any((su) => su.uid == u.uid));

                      return Column(
                        children: [
                          // Select All Checkbox (Only for Multi-Select)
                          if (!widget.isSingleSelect) ...[
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (allSelected) {
                                    for (final u in filteredUsers) {
                                      _selectedUsers.removeWhere((su) => su.uid == u.uid);
                                    }
                                  } else {
                                    for (final u in filteredUsers) {
                                      if (!_selectedUsers.any((su) => su.uid == u.uid)) {
                                        _selectedUsers.add(u);
                                      }
                                    }
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      allSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                      color: allSelected ? AppTheme.accentAmber : AppTheme.textMuted,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isAr ? 'تحديد الكل' : 'Select All',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_selectedUsers.length} ${isAr ? "محدد" : "selected"}',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(),
                          ],
                          Expanded(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredUsers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final isCurrentUser = user.uid == widget.currentUserId;
                                final isSelected = _selectedUsers.any((su) => su.uid == user.uid);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      if (widget.isSingleSelect) {
                                        Navigator.of(context).pop([user]);
                                      } else {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedUsers.removeWhere((su) => su.uid == user.uid);
                                          } else {
                                            _selectedUsers.add(user);
                                          }
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (widget.isSingleSelect ? Colors.orange : AppTheme.accentAmber).withValues(alpha: 0.08)
                                            : AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected
                                              ? (widget.isSingleSelect ? Colors.orange : AppTheme.accentAmber).withValues(alpha: 0.3)
                                              : AppTheme.borderSubtle,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: isCurrentUser
                                                ? (widget.isSingleSelect ? Colors.orange : AppTheme.accentAmber)
                                                : AppTheme.surfaceCard,
                                            backgroundImage: user.photoBase64 != null &&
                                                    user.photoBase64!.isNotEmpty
                                                ? MemoryImage(base64Decode(user.photoBase64!))
                                                : null,
                                            child: user.photoBase64 == null ||
                                                    user.photoBase64!.isEmpty
                                                ? Text(
                                                    user.displayName.isNotEmpty
                                                        ? user.displayName[0].toUpperCase()
                                                        : '?',
                                                    style: TextStyle(
                                                      color: isCurrentUser
                                                          ? AppTheme.surfaceDark
                                                          : AppTheme.textPrimary,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      user.displayName,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (isCurrentUser) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 1,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: (widget.isSingleSelect ? Colors.orange : AppTheme.accentAmber).withValues(alpha: 0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          context.tr('you'),
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w600,
                                                            color: widget.isSingleSelect ? Colors.orange : AppTheme.accentAmber,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  user.email,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            widget.isSingleSelect
                                                ? Icons.arrow_forward_ios_rounded
                                                : (isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded),
                                            color: isSelected
                                                ? (widget.isSingleSelect ? Colors.orange : AppTheme.accentAmber)
                                                : AppTheme.textMuted,
                                            size: widget.isSingleSelect ? 16 : 22,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // ─── Actions Row ─────────────────────────────
                if (widget.isSingleSelect) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.tr('cancel')),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.tr('cancel')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedUsers.isEmpty
                              ? null
                              : () => Navigator.of(context).pop(_selectedUsers),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentAmber,
                            foregroundColor: AppTheme.surfaceDark,
                          ),
                          child: Text(
                            isAr ? 'إرسال (${_selectedUsers.length})' : 'Send (${_selectedUsers.length})',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
