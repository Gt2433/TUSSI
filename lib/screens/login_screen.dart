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

  bool _isRegistering = false;
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
      // If no activation code, show WhatsApp dialog instead
      if (_activationCodeController.text.trim().isEmpty) {
        _showNoCodeDialog();
        return;
      }

      await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        activationCode: _activationCodeController.text.trim(),
        photoBase64: _profilePhotoBase64,
      );
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
      final code = _activationCodeController.text.trim();
      if (code.isEmpty) {
        _showNoCodeDialog();
        return;
      }
      
      await authProvider.signInWithGoogle(activationCode: code);
    } else {
      final result = await authProvider.signInWithGoogle();
      if (result == 'need-activation-code') {
        _showGoogleActivationDialog();
      }
    }
  }

  void _showGoogleActivationDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('تفعيل الحساب باستخدام Google'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هذا الحساب غير مسجل بعد في النظام. يرجى إدخال كود التفعيل/الدعوة الخاص بك لإكمال عملية إنشاء الحساب:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'كود التفعيل (مثال: FN-123456)',
                prefixIcon: Icon(Icons.vpn_key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Provider.of<app_auth.AuthProvider>(context, listen: false).signOut();
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(ctx).pop();
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingCtx) => const Center(child: CircularProgressIndicator()),
                );

                await Provider.of<app_auth.AuthProvider>(context, listen: false)
                    .signInWithGoogle(activationCode: code);

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('تفعيل ودخول'),
          ),
        ],
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
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.accentAmber.withValues(alpha: 0.12),
                                        AppTheme.accentAmber.withValues(alpha: 0.03),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.accentAmber.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.card_membership_rounded,
                                            color: AppTheme.accentAmber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isAr ? 'أسعار خطط الاشتراك' : 'Subscription Plans',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Column(
                                        children: [
                                          // Monthly Plan
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceDark.withValues(alpha: 0.4),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        isAr ? 'الاشتراك الشهري' : 'Monthly Plan',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppTheme.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        isAr ? 'تجديد تلقائي شهرياً' : 'Renewed monthly',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: AppTheme.textMuted,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      isAr ? '2,000 د.ج' : '2,000 DZD',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppTheme.accentAmber,
                                                      ),
                                                    ),
                                                    Text(
                                                      isAr ? 'شهرياً' : '/ month',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          // Yearly Plan (Best Choice)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentAmber.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: AppTheme.accentAmber.withValues(alpha: 0.3),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Wrap(
                                                        spacing: 6,
                                                        runSpacing: 4,
                                                        crossAxisAlignment: WrapCrossAlignment.center,
                                                        children: [
                                                          Text(
                                                            isAr ? 'الاشتراك السنوي' : 'Yearly Plan',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                              color: AppTheme.textPrimary,
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: AppTheme.accentAmber,
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: Text(
                                                              isAr ? 'الأكثر توفيراً' : 'Best Value',
                                                              style: const TextStyle(
                                                                fontSize: 8,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.black,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        isAr ? 'اشتراك كامل لمدة 12 شهراً' : '12 months full access',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: AppTheme.textSecondary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      isAr ? '50,000 د.ج' : '50,000 DZD',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppTheme.accentAmber,
                                                      ),
                                                    ),
                                                    Text(
                                                      isAr ? 'سنوياً' : '/ year',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          // Lifetime Plan (Ultimate)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                            decoration: BoxDecoration(
                                              color: const Color(0x1F9C27B0),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: const Color(0xFF9C27B0),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Wrap(
                                                        spacing: 6,
                                                        runSpacing: 4,
                                                        crossAxisAlignment: WrapCrossAlignment.center,
                                                        children: [
                                                          Text(
                                                            isAr ? 'الاشتراك الدائم' : 'Lifetime Plan',
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF9C27B0),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: Text(
                                                              isAr ? 'مدى الحياة' : 'Lifetime',
                                                              style: const TextStyle(
                                                                fontSize: 8,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        isAr ? 'شراء لمرة واحدة وتفعيل دائم' : 'One-time payment, lifetime use',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: AppTheme.textSecondary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      isAr ? '120,000 د.ج' : '120,000 DZD',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w800,
                                                        color: Color(0xFFBA68C8),
                                                      ),
                                                    ),
                                                    Text(
                                                      isAr ? 'دفعة واحدة' : 'One-time',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // WhatsApp Direct Request Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 36,
                                        child: ElevatedButton.icon(
                                          onPressed: _openWhatsApp,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF25D366),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: EdgeInsets.zero,
                                            elevation: 0,
                                          ),
                                          icon: const Icon(Icons.chat_rounded, size: 14),
                                          label: Text(
                                            isAr ? 'طلب كود التفعيل والاشتراك' : 'Get Activation Code',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),

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

                              // ── Activation Code (register only) ──
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: _isRegistering
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            controller:
                                                _activationCodeController,
                                            textCapitalization:
                                                TextCapitalization.characters,
                                            decoration: InputDecoration(
                                              labelText: isAr
                                                  ? 'كود التفعيل'
                                                  : 'Activation Code',
                                              hintText: isAr
                                                  ? 'مثال: FN-128456'
                                                  : 'e.g. FN-128456',
                                              prefixIcon: Icon(
                                                Icons.vpn_key_rounded,
                                                color: AppTheme.accentAmber,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: BorderSide(
                                                  color: AppTheme.accentAmber
                                                      .withValues(alpha: 0.4),
                                                  width: 1.5,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                borderSide: BorderSide(
                                                  color: AppTheme.accentAmber,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          // "No code?" link
                                          GestureDetector(
                                            onTap: _showNoCodeDialog,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.chat_rounded,
                                                  size: 16,
                                                  color: const Color(0xFF25D366),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  isAr
                                                      ? 'ليس لديك كود؟ تواصل معنا'
                                                      : "No code? Contact us",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        const Color(0xFF25D366),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
                                    setState(() {
                                      _isRegistering = !_isRegistering;
                                      _activationCodeController.clear();
                                      authProvider.clearError();
                                    });
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
}
