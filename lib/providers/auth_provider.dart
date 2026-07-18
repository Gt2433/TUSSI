import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  AppUser? _appUser;
  String _displayName = '';
  bool _isLoading = true;
  bool _isInitializing = true;
  bool _isPhotoLoading = false;
  String? _error;
  late StreamSubscription<User?> _authSub;

  AuthProvider() {
    _authSub = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  // ─── Getters ───────────────────────────────────────────────────
  User? get user => _user;
  AppUser? get appUser => _appUser;
  String get displayName => _displayName;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isPhotoLoading => _isPhotoLoading;
  bool get isAuthenticated => _user != null && _appUser != null;
  String? get error => _error;

  // ─── Auth State Listener ──────────────────────────────────────
  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      _displayName = await _authService.getCurrentUserDisplayName();
      final dbUser = await _authService.getUserData(user.uid);
      if (dbUser != null) {
        _appUser = dbUser;
        // Update FCM Token in Firestore for push notifications
        FcmService().updateToken(user.uid);
      } else {
        _appUser = null;
        if (!_isLoading) {
          await _authService.signOut();
          _user = null;
        }
      }
    } else {
      _displayName = '';
      _appUser = null;
    }
    _isLoading = false;
    _isInitializing = false;
    notifyListeners();
  }

  // ─── Reload User Data ──────────────────────────────────────────
  Future<void> reloadUser() async {
    if (_user != null) {
      _appUser = await _authService.getUserData(_user!.uid);
      notifyListeners();
    }
  }

  // ─── Sign In ──────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signIn(email: email, password: password);
      if (credential.user != null) {
        await _authService.updateUserPassword(credential.user!.uid, password);
        _appUser = await _authService.getUserData(credential.user!.uid);
      }
      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Register with Activation Code or Invite Code ────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required String activationCode,
    String? photoBase64,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    UserCredential? credential;
    try {
      // 1. Create Firebase Auth user first to get authenticated!
      credential = await _authService.createAuthUser(
        email: email,
        password: password,
        displayName: displayName,
      );

      final uid = credential.user!.uid;

      // 2. Now check if it is a shop activation code
      final codeDoc = await _firestoreService.checkActivationCode(activationCode);

      if (codeDoc != null) {
        // This is a shop activation code!
        final codeData = codeDoc.data() as Map<String, dynamic>?;
        final shopName = (codeData?['shopName'] as String?) ?? displayName;

        // Register shop + link admin user in Firestore (with default fabrics)
        await _firestoreService.registerShopAndAdmin(
          activationCode: activationCode,
          adminUid: uid,
          adminEmail: email,
          adminName: displayName,
          shopName: shopName,
          password: password,
        );

        // Load fresh user data
        _user = credential.user;
        _displayName = displayName.trim();
        _appUser = await _authService.getUserData(uid);
        _error = null;
        return true;
      }

      // 3. If not an activation code, check if it is a shop invite code (FN-XXXXXX)
      final shopDoc = await _firestoreService.checkInviteCode(activationCode);
      if (shopDoc != null) {
        // This is a shop invite code! Register as employee.
        await _firestoreService.registerEmployee(
          inviteCode: activationCode,
          employeeUid: uid,
          employeeEmail: email,
          employeeName: displayName,
          password: password,
          photoBase64: photoBase64,
        );

        // Load fresh user data
        _user = credential.user;
        _displayName = displayName.trim();
        _appUser = await _authService.getUserData(uid);
        _error = null;
        return true;
      }

      // If neither matches, delete the created Auth user and return error
      await credential.user!.delete();
      _error = 'كود التفعيل أو كود الدعوة غير صالح. تواصل مع المشرف.';
      return false;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      return false;
    } catch (e) {
      if (credential != null && credential.user != null) {
        try {
          await credential.user!.delete();
        } catch (_) {}
      }
      _error = 'حدث خطأ أثناء التسجيل: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ─── Clear Error ──────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Map Firebase Auth Errors ─────────────────────────────────
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهاد الايميل';
      case 'wrong-password':
        return 'كلمة المرور خاطئة';
      case 'email-already-in-use':
        return 'هاد الايميل موجود بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة. استخدم 6 أحرف على الأقل.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صالحة.';
      case 'too-many-requests':
        return 'محاولات كثيرة خاطئة. يرجى المحاولة لاحقاً.';
      case 'invalid-credential':
        return 'خطأ في البريد الإلكتروني أو كلمة المرور.';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالإنترنت، يرجى التحقق من الشبكة.';
      case 'requires-recent-login':
        return 'الرجاء تسجيل الخروج وإعادة تسجيل الدخول للتحقق من هويتك لتطبيق هذا الإجراء.';
      default:
        return 'خطأ في الاتصال أو التحقق: $code';
    }
  }

  // ─── Update Profile Photo ─────────────────────────────────────
  Future<bool> updateProfilePhoto(String? photoBase64) async {
    if (_user == null) return false;
    _isPhotoLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateProfilePhoto(_user!.uid, photoBase64);
      _appUser = await _authService.getUserData(_user!.uid);
      _error = null;
      return true;
    } catch (e) {
      _error = 'حدث خطأ أثناء تحديث الصورة الشخصية: $e';
      return false;
    } finally {
      _isPhotoLoading = false;
      notifyListeners();
    }
  }

  // ─── Delete Account Permanently ────────────────────────────────
  Future<bool> deleteAccount() async {
    if (_user == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.deleteAccount();
      _user = null;
      _appUser = null;
      _displayName = '';
      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      return false;
    } catch (e) {
      _error = 'حدث خطأ غير متوقع أثناء حذف الحساب: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Switch Shop (Super Admin only) ────────────────────────────
  Future<bool> switchShop(String? shopId) async {
    if (_user == null) return false;
    _error = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'shopId': shopId});
          
      _appUser = await _authService.getUserData(_user!.uid);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'حدث خطأ أثناء تبديل المحل: $e';
      notifyListeners();
      return false;
    }
  }

  // ─── Update Display Name ──────────────────────────────────────
  Future<bool> updateDisplayName(String newName) async {
    if (_user == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateDisplayName(_user!.uid, newName);
      _displayName = newName.trim();
      _appUser = await _authService.getUserData(_user!.uid);
      _error = null;
      return true;
    } catch (e) {
      _error = 'حدث خطأ أثناء تحديث الاسم: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Update Password ──────────────────────────────────────────
  Future<bool> updatePassword(String newPassword) async {
    if (_user == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updatePassword(_user!.uid, newPassword);
      _appUser = await _authService.getUserData(_user!.uid);
      _error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      return false;
    } catch (e) {
      _error = 'حدث خطأ أثناء تحديث كلمة المرور: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Sign In with Google ──────────────────────────────────────
  Future<String?> signInWithGoogle({String? activationCode}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      User? currentUser = _user;

      if (currentUser == null) {
        final credential = await _authService.signInWithGoogle();
        if (credential == null || credential.user == null) {
          _isLoading = false;
          notifyListeners();
          return null;
        }
        currentUser = credential.user;
      }

      final uid = currentUser!.uid;
      final email = currentUser.email ?? '';
      final displayName = currentUser.displayName ?? 'User';
      final photoBase64 = currentUser.photoURL != null ? await _fetchBase64Image(currentUser.photoURL!) : null;

      final dbUser = await _authService.getUserData(uid);
      if (dbUser != null) {
        _user = currentUser;
        _appUser = dbUser;
        _displayName = dbUser.displayName;
        await FcmService().updateToken(uid);
        _isLoading = false;
        notifyListeners();
        return 'success';
      }

      if (activationCode == null || activationCode.trim().isEmpty) {
        _user = currentUser;
        _isLoading = false;
        notifyListeners();
        return 'need-activation-code';
      }

      final code = activationCode.trim();
      final codeDoc = await _firestoreService.checkActivationCode(code);

      if (codeDoc != null) {
        final codeData = codeDoc.data() as Map<String, dynamic>?;
        final shopName = (codeData?['shopName'] as String?) ?? displayName;

        await _firestoreService.registerShopAndAdmin(
          activationCode: code,
          adminUid: uid,
          adminEmail: email,
          adminName: displayName,
          shopName: shopName,
          password: 'google_sign_in',
        );

        _user = currentUser;
        _displayName = displayName;
        _appUser = await _authService.getUserData(uid);
        _isLoading = false;
        notifyListeners();
        return 'success';
      }

      final shopDoc = await _firestoreService.checkInviteCode(code);
      if (shopDoc != null) {
        await _firestoreService.registerEmployee(
          inviteCode: code,
          employeeUid: uid,
          employeeEmail: email,
          employeeName: displayName,
          password: 'google_sign_in',
          photoBase64: photoBase64,
        );

        _user = currentUser;
        _displayName = displayName;
        _appUser = await _authService.getUserData(uid);
        _isLoading = false;
        notifyListeners();
        return 'success';
      }

      await currentUser.delete();
      await _authService.signOut();
      _user = null;
      _appUser = null;
      _error = 'كود التفعيل أو كود الدعوة غير صالح.';
      _isLoading = false;
      notifyListeners();
      return 'invalid-code';

    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return 'error';
    } catch (e) {
      _error = 'حدث خطأ أثناء تسجيل الدخول باستخدام Google: $e';
      _isLoading = false;
      notifyListeners();
      return 'error';
    }
  }

  Future<String?> _fetchBase64Image(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
