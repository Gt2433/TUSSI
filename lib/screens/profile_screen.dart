import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/image_cropper_dialog.dart';

/// Screen displaying user profile details and offering sign out.
/// Features a masked password (showing first/last characters only) and base64 avatar decoding.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _maskPassword(String? password) {
    if (password == null || password.isEmpty) {
      return '••••••••';
    }
    if (password.length <= 2) {
      return password;
    }
    final firstChar = password[0];
    final lastChar = password[password.length - 1];
    final middleMask = '•' * (password.length - 2);
    return '$firstChar$middleMask$lastChar';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appUser = authProvider.appUser;

    final displayName = appUser?.displayName ?? authProvider.displayName;
    final email = appUser?.email ?? authProvider.user?.email ?? '';
    final passwordText = _maskPassword(appUser?.password);
    final photoBase64 = appUser?.photoBase64;
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        children: [
          // ─── Top Header Card ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentAmber.withValues(alpha: 0.12),
                  AppTheme.surfaceElevated,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.accentAmber.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentAmber.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppTheme.accentAmber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('tab_profile'),
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('user_account'),
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'نشط' : 'Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Profile Picture Card ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar with glowing ring
                GestureDetector(
                  onTap: authProvider.isPhotoLoading
                      ? null
                      : () => _updatePhoto(context, authProvider),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              AppTheme.accentAmber,
                              AppTheme.accentAmberLight,
                              AppTheme.accentAmber,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentAmber.withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: AppTheme.surfaceElevated,
                          backgroundImage:
                              photoBase64 != null &&
                                      photoBase64.isNotEmpty &&
                                      !authProvider.isPhotoLoading
                                  ? MemoryImage(base64Decode(photoBase64))
                                  : null,
                          child: (photoBase64 == null || photoBase64.isEmpty) &&
                                  !authProvider.isPhotoLoading
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentAmber,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (authProvider.isPhotoLoading)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accentAmber,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.surfaceCard,
                              width: 2.5,
                            ),
                          ),
                          child: Icon(
                            authProvider.isPhotoLoading
                                ? Icons.hourglass_empty_rounded
                                : Icons.camera_alt_rounded,
                            size: 16,
                            color: AppTheme.surfaceDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Display Name & Email
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // ─── Quick Actions Row (ترتيب جديد للأزرار) ───────────
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickActionButton(
                      icon: Icons.edit_rounded,
                      label: isAr ? 'تعديل الاسم' : 'Edit Name',
                      onTap: () => _showEditNameDialog(context, authProvider, displayName),
                    ),
                    _buildQuickActionButton(
                      icon: Icons.lock_outline_rounded,
                      label: isAr ? 'كلمة المرور' : 'Password',
                      onTap: () => _showEditPasswordDialog(context, authProvider),
                    ),
                    _buildQuickActionButton(
                      icon: Icons.photo_camera_outlined,
                      label: isAr ? 'الصورة' : 'Photo',
                      onTap: () => _updatePhoto(context, authProvider),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── Account Info Details Card ─────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.person_outline_rounded,
                  label: context.tr('full_name'),
                  value: displayName,
                  onEdit: () =>
                      _showEditNameDialog(context, authProvider, displayName),
                ),
                Divider(height: 1, indent: 64, endIndent: 16, color: AppTheme.borderSubtle),
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: context.tr('email'),
                  value: email,
                ),
                Divider(height: 1, indent: 64, endIndent: 16, color: AppTheme.borderSubtle),
                _buildInfoRow(
                  icon: Icons.lock_outline_rounded,
                  label: context.tr('password'),
                  value: passwordText,
                  isPassword: true,
                  onEdit: () => _showEditPasswordDialog(context, authProvider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ─── Reordered Bottom Actions (Sign Out & Delete Account) ────
          // 1. Sign Out Button (Primary Red Accent)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showSignOutDialog(context, authProvider),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(context.tr('sign_out')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error.withValues(alpha: 0.15),
                foregroundColor: AppTheme.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                side: BorderSide(
                  color: AppTheme.error.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Delete Account Button (Secondary/Warning Text Button)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showDeleteAccountDialog(context, authProvider),
              icon: Icon(
                Icons.delete_forever_outlined,
                color: AppTheme.textMuted,
                size: 18,
              ),
              label: Text(
                context.tr('delete_account'),
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.accentAmber),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isPassword = false,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isPassword ? AppTheme.error : AppTheme.accentAmber,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    letterSpacing: isPassword ? 2 : 0,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    AuthProvider authProvider,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('edit_name')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: context.tr('enter_name')),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(ctx).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingCtx) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final success = await authProvider.updateDisplayName(newName);

                if (context.mounted) {
                  Navigator.of(context).pop();
                }

                if (success) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('name_update_success')),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authProvider.error ?? 'فشل تحديث الاسم'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  void _showEditPasswordDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('edit_password')),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: context.tr('enter_new_password'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPassword = controller.text;
              if (newPassword.length >= 6) {
                Navigator.of(ctx).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingCtx) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final success = await authProvider.updatePassword(newPassword);

                if (context.mounted) {
                  Navigator.of(context).pop();
                }

                if (success) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('password_update_success')),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          authProvider.error ?? 'فشل تغيير كلمة المرور',
                        ),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('weak_password')),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('sign_out')),
        content: Text(context.tr('sign_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePhoto(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    try {
      if (!context.mounted) return;

      // Show bottom sheet to select image source
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: AppTheme.surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      ctx.tr('select_image_source'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: AppTheme.accentAmber,
                      ),
                    ),
                    title: Text(
                      ctx.tr('camera'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.photo_library_rounded,
                        color: AppTheme.accentAmber,
                      ),
                    ),
                    title: Text(
                      ctx.tr('gallery'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final Uint8List originalBytes = await pickedFile.readAsBytes();

        if (!context.mounted) return;

        // Show image cropper dialog
        final Uint8List? croppedBytes = await showDialog<Uint8List>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ImageCropperDialog(imageBytes: originalBytes),
        );

        if (croppedBytes != null) {
          final String base64Image = base64Encode(croppedBytes);
          final success = await authProvider.updateProfilePhoto(base64Image);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('photo_update_success'))),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authProvider.error ?? context.tr('photo_update_failed'),
                ),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showDeleteAccountDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            const SizedBox(width: 10),
            Expanded(child: Text(context.tr('delete_account'))),
          ],
        ),
        content: Text(
          context.tr('delete_account_confirm') +
              '\n\n' +
              context.tr('delete_account_warn'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingCtx) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final success = await authProvider.deleteAccount();

              if (context.mounted) {
                Navigator.of(context).pop();
              }

              if (success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('delete_success'))),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        authProvider.error ?? context.tr('delete_failed'),
                      ),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('yes_delete')),
          ),
        ],
      ),
    );
  }
}
