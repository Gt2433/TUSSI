import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/image_cropper_dialog.dart';

const String _kWhatsAppNumber = '213655603829';

/// Login & Registration screen with activation-code based sign-up.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _activationCodeController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopCodeController = TextEditingController();

  bool _isRegistering = false;
  int _shopRegistrationMode = 0; // 0 = Create Shop, 1 = Join Shop by Code
  bool _obscurePassword = true;
  String? _profilePhotoBase64;

  Future<void> _pickProfileImage() async {
    final isAr = Provider.of<LanguageProvider>(context, listen: false).language == AppLanguage.ar;
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    isAr ? 'اختر مصدر الصورة' : 'Select image source',
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
                    child: Icon(Icons.camera_alt_rounded, color: AppTheme.accentAmber),
                  ),
                  title: Text(isAr ? 'الكاميرا' : 'Camera', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                    child: Icon(Icons.photo_library_rounded, color: AppTheme.accentAmber),
                  ),
                  title: Text(isAr ? 'المعرض' : 'Gallery', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

      if (!mounted) return;

      final Uint8List? croppedBytes = await showDialog<Uint8List>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ImageCropperDialog(imageBytes: originalBytes),
      );

      if (croppedBytes != null) {
        setState(() {
          _profilePhotoBase64 = base64Encode(croppedBytes);
        });
      }
    }
  }

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _activationCodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Open WhatsApp ───────────────────────────────────────────
  Future<void> _openWhatsApp() async {
    const message =
        'السلام عليكم، أريد الاشتراك في تطبيق tussi والحصول على كود التفعيل.';
    final encodedMessage = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$_kWhatsAppNumber?text=$encodedMessage');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Show WhatsApp No-Code Dialog ───────────────────────────
  void _showNoCodeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surfaceCard,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: Color(0xFF25D366),
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ليس لديك كود تفعيل؟',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'للحصول على كود التفعيل وتفعيل محلك في التطبيق، تواصل مع مشرف التطبيق عبر الواتساب.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text(
                    'تواصل معنا عبر واتساب',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _openWhatsApp();
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'لدي كود — أدخله الآن',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Submit ──────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    if (_isRegistering) {
      if (_shopRegistrationMode == 0) {
        await authProvider.signUpCreateShop(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          shopName: _shopNameController.text.trim(),
          photoBase64: _profilePhotoBase64,
        );
      } else {
        await authProvider.signUpJoinShop(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          shopCode: _shopCodeController.text.trim(),
          photoBase64: _profilePhotoBase64,
        );
      }
    } else {
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  // ─── Google Sign In ──────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    
    authProvider.clearError();

    if (_isRegistering) {
      if (_shopRegistrationMode == 0 && _shopNameController.text.trim().isNotEmpty) {
        await authProvider.signInWithGoogleCreateShop(
          shopName: _shopNameController.text.trim(),
        );
      } else if (_shopRegistrationMode == 1 && _shopCodeController.text.trim().isNotEmpty) {
        await authProvider.signInWithGoogleJoinShop(
          shopCode: _shopCodeController.text.trim(),
        );
      } else {
        _showGoogleShopSetupDialog();
      }
    } else {
      final result = await authProvider.signInWithGoogle();
      if (result == 'need-shop-setup') {
        _showGoogleShopSetupDialog();
      }
    }
  }

  // ─── Google Shop Setup Dialog (Create Shop or Join Shop) ────
  void _showGoogleShopSetupDialog() {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final shopNameCtrl = TextEditingController();
    final shopCodeCtrl = TextEditingController();
    int mode = 0; // 0 = Create, 1 = Join

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppTheme.surfaceCard,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.storefront_rounded, color: AppTheme.accentAmber, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr('welcome_choose_account_type'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Mode Selector Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDlgState(() => mode = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: mode == 0 ? AppTheme.accentAmber : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              context.tr('create_new_shop'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: mode == 0 ? Colors.black : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDlgState(() => mode = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: mode == 1 ? AppTheme.accentAmber : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              context.tr('join_existing_shop'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: mode == 1 ? Colors.black : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                if (mode == 0) ...[
                  TextField(
                    controller: shopNameCtrl,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: context.tr('shop_name_label'),
                      hintText: '...',
                      prefixIcon: Icon(Icons.storefront_rounded, color: AppTheme.accentAmber),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: shopCodeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: context.tr('shop_code_label'),
                      hintText: 'SHOP-XXXX',
                      prefixIcon: Icon(Icons.qr_code_rounded, color: AppTheme.accentAmber),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.of(dlgCtx).pop();
                          await authProvider.signOut();
                        },
                        child: Text(context.tr('cancel'), style: TextStyle(color: AppTheme.textMuted)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentAmber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (mode == 0) {
                            final name = shopNameCtrl.text.trim();
                            if (name.isNotEmpty) {
                              Navigator.of(dlgCtx).pop();
                              await authProvider.signInWithGoogleCreateShop(shopName: name);
                            }
                          } else {
                            final code = shopCodeCtrl.text.trim();
                            if (code.isNotEmpty) {
                              Navigator.of(dlgCtx).pop();
                              await authProvider.signInWithGoogleJoinShop(shopCode: code);
                            }
                          }
                        },
                        child: Text(context.tr('done_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.surfaceGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.04),

                      // ─── Language Selector Bar ────────────
                      _buildLanguageSelector(context),

                      const SizedBox(height: 12),

                      // ─── Logo ──────────────────────────────
                      Hero(
                        tag: 'logo',
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceCard,
                            border: Border.all(
                              color: AppTheme.borderSubtle,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentAmber
                                    .withValues(alpha: 0.1),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Transform.scale(
                              scale: 1.45,
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.store_rounded,
                                  size: 60,
                                  color: AppTheme.accentAmber,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ─── App Name ──────────────────────────
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppTheme.accentGradient.createShader(bounds),
                        child: const Text(
                          'TUSSI',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fabric Management System',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ─── Form Card ─────────────────────────
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.borderSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                _isRegistering
                                    ? (isAr ? 'إنشاء حساب جديد' : 'Create Account')
                                    : context.tr('login'),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_isRegistering) ...[
                                const SizedBox(height: 20),
                                Center(
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundColor: AppTheme.surfaceDark,
                                        backgroundImage: _profilePhotoBase64 != null
                                            ? MemoryImage(base64Decode(_profilePhotoBase64!))
                                            : null,
                                        child: _profilePhotoBase64 == null
                                            ? Icon(Icons.person_rounded, size: 50, color: AppTheme.textMuted)
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: InkWell(
                                          onTap: _pickProfileImage,
                                          borderRadius: BorderRadius.circular(20),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentAmber,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppTheme.surfaceCard, width: 2),
                                            ),
                                            child: Icon(
                                              Icons.camera_alt_rounded,
                                              size: 18,
                                              color: AppTheme.surfaceDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_isRegistering) ...[
                                const SizedBox(height: 16),
                                // ─── Shop Mode Selector (إنشاء محل / انضمام لمحل) ─────
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceDark,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.borderSubtle),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _shopRegistrationMode = 0),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: _shopRegistrationMode == 0
                                                  ? AppTheme.accentAmber
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              isAr ? '🏬 إنشاء محل جديد' : 'Create Shop',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _shopRegistrationMode == 0
                                                    ? Colors.black
                                                    : AppTheme.textMuted,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _shopRegistrationMode = 1),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: _shopRegistrationMode == 1
                                                  ? AppTheme.accentAmber
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              isAr ? '🔗 انضمام لمحل' : 'Join Shop',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _shopRegistrationMode == 1
                                                    ? Colors.black
                                                    : AppTheme.textMuted,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),

                              // ── Name field (register only) ─
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: _isRegistering
                                    ? Column(
                                        children: [
                                          TextFormField(
                                            controller: _nameController,
                                            textDirection: TextDirection.rtl,
                                            decoration: InputDecoration(
                                              labelText:
                                                  context.tr('full_name'),
                                              hintText:
                                                  context.tr('enter_name'),
                                              prefixIcon: const Icon(
                                                  Icons.person_outline_rounded),
                                            ),
                                            validator: (v) {
                                              if (_isRegistering &&
                                                  (v == null || v.isEmpty)) {
                                                return context
                                                    .tr('required_name');
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              // ── Email ──────────────────────
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: context.tr('email'),
                                  hintText: 'example@email.com',
                                  prefixIcon:
                                      const Icon(Icons.email_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return context.tr('required_email');
                                  }
                                  if (!v.contains('@')) {
                                    return context.tr('invalid_email');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Password ───────────────────
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: context.tr('password'),
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                      Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: AppTheme.textMuted,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return context.tr('required_password');
                                  }
                                  if (v.length < 6) {
                                    return context.tr('weak_password');
                                  }
                                  return null;
                                },
                              ),

                              // ── Shop Name or Shop Code Input (register only) ──
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: _isRegistering
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          if (_shopRegistrationMode == 0) ...[
                                            TextFormField(
                                              controller: _shopNameController,
                                              textDirection: TextDirection.rtl,
                                              decoration: InputDecoration(
                                                labelText: context.tr('shop_name_label'),
                                                hintText: '...',
                                                prefixIcon: Icon(
                                                  Icons.storefront_rounded,
                                                  color: AppTheme.accentAmber,
                                                ),
                                              ),
                                              validator: (v) {
                                                if (_isRegistering && _shopRegistrationMode == 0 && (v == null || v.trim().isEmpty)) {
                                                  return context.tr('shop_name_label');
                                                }
                                                return null;
                                              },
                                            ),
                                          ] else ...[
                                            TextFormField(
                                              controller: _shopCodeController,
                                              textCapitalization: TextCapitalization.characters,
                                              decoration: InputDecoration(
                                                labelText: context.tr('shop_code_label'),
                                                hintText: 'SHOP-XXXX',
                                                prefixIcon: Icon(
                                                  Icons.qr_code_rounded,
                                                  color: AppTheme.accentAmber,
                                                ),
                                              ),
                                              validator: (v) {
                                                if (_isRegistering && _shopRegistrationMode == 1 && (v == null || v.trim().isEmpty)) {
                                                  return context.tr('shop_code_label');
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),

                              // ── Error message ──────────────
                              if (authProvider.error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorSurface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.error
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: AppTheme.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          authProvider.error!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // ── Submit button ──────────────
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : _submit,
                                  child: authProvider.isLoading
                                      ? SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppTheme.surfaceDark,
                                          ),
                                        )
                                      : Text(
                                          _isRegistering
                                              ? (isAr
                                                  ? 'إنشاء الحساب'
                                                  : 'Create Account')
                                              : context.tr('login'),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Or Continue With ──
                              Row(
                                children: [
                                  Expanded(child: Divider(color: AppTheme.borderSubtle)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      isAr ? 'أو تسجيل الدخول عبر' : 'Or continue with',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: AppTheme.borderSubtle)),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // ── Google Sign In Button ──
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : _handleGoogleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppTheme.borderSubtle, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    backgroundColor: AppTheme.surfaceElevated,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/google_logo.png',
                                        width: 20,
                                        height: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        isAr ? 'الدخول باستخدام Google' : 'Sign in with Google',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Toggle login/register ──────
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    if (!_isRegistering) {
                                      _showShopChoiceDialog();
                                    } else {
                                      setState(() {
                                        _isRegistering = false;
                                        authProvider.clearError();
                                      });
                                    }
                                  },
                                  child: Text(
                                    _isRegistering
                                        ? context.tr('already_have_account')
                                        : context.tr('dont_have_account'),
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.06),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Language Selector Widget ─────────────────────────────
  Widget _buildLanguageSelector(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();

    final languages = [
      {'code': AppLanguage.ar, 'label': 'العربية', 'flag': '🇩🇿'},
      {'code': AppLanguage.fr, 'label': 'Français', 'flag': '🇫🇷'},
      {'code': AppLanguage.en, 'label': 'English', 'flag': '🇬🇧'},
      {'code': AppLanguage.es, 'label': 'Español', 'flag': '🇪🇸'},
      {'code': AppLanguage.zh, 'label': '中文', 'flag': '🇨🇳'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language_rounded, size: 18, color: AppTheme.accentAmber),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<AppLanguage>(
              value: langProvider.language,
              dropdownColor: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.accentAmber, size: 20),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              items: languages.map((item) {
                final lang = item['code'] as AppLanguage;
                final label = item['label'] as String;
                final flag = item['flag'] as String;
                return DropdownMenuItem<AppLanguage>(
                  value: lang,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newLang) {
                if (newLang != null) {
                  langProvider.setLanguage(newLang);
                  langProvider.saveLanguage();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Show Shop Choice Popup Modal ───────────────────────────
  void _showShopChoiceDialog() {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surfaceCard,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.storefront_rounded, color: AppTheme.accentAmber, size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('welcome_choose_account_type'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Option 1: Create New Shop Card
              InkWell(
                onTap: () {
                  Navigator.of(dlgCtx).pop();
                  setState(() {
                    _isRegistering = true;
                    _shopRegistrationMode = 0;
                    authProvider.clearError();
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentAmber, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_business_rounded, color: Colors.black, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('create_new_shop'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              context.tr('shop_owner_desc'),
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Join Existing Shop Card
              InkWell(
                onTap: () {
                  Navigator.of(dlgCtx).pop();
                  setState(() {
                    _isRegistering = true;
                    _shopRegistrationMode = 1;
                    authProvider.clearError();
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSubtle, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Icon(Icons.qr_code_rounded, color: AppTheme.accentAmber, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('join_existing_shop'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              context.tr('shop_worker_desc'),
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.of(dlgCtx).pop(),
                child: Text(
                  context.tr('cancel'),
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
