import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isGoogleInitialized = false;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    if (!_isGoogleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: '368377187521-ome7jektnf3333e7bgfplntvamnknpcp.apps.googleusercontent.com',
      );
      _isGoogleInitialized = true;
    }
    final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Register a new account and save user data to Firestore
  Future<UserCredential> register({
    required String email,
    required String password,
    required String displayName,
    String? photoBase64,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Update display name in Firebase Auth
    await credential.user?.updateDisplayName(displayName.trim());

    // Save user to Firestore users collection
    final appUser = AppUser(
      uid: credential.user!.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      password: password,
      photoBase64: photoBase64,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(appUser.toMap());

    return credential;
  }

  /// Create only a Firebase Auth account (no Firestore save).
  /// Used during activation-code-based registration where Firestore
  /// is populated via FirestoreService.registerShopAndAdmin instead.
  Future<UserCredential> createAuthUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    return credential;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  /// Get current user's display name from Firestore
  Future<String> getCurrentUserDisplayName() async {
    final user = _auth.currentUser;
    if (user == null) return 'Unknown';

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return doc.data()?['displayName'] ?? user.displayName ?? 'Unknown';
    }
    return user.displayName ?? 'Unknown';
  }

  /// Get AppUser data from Firestore
  Future<AppUser?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }

  /// Update user profile photo in Firestore
  Future<void> updateProfilePhoto(String uid, String? photoBase64) async {
    await _firestore.collection('users').doc(uid).set({
      'photoBase64': photoBase64,
    }, SetOptions(merge: true));
  }

  /// Delete user account permanently from Firestore and Firebase Auth.
  /// If Auth deletion fails, the Firestore user document is restored.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    // Cache the current Firestore user data for rollback in case Auth deletion fails
    final doc = await _firestore.collection('users').doc(uid).get();
    final userData = doc.data();

    // 1. Delete from Firestore users collection
    await _firestore.collection('users').doc(uid).delete();

    try {
      // 2. Delete from Firebase Auth
      await user.delete();
    } catch (e) {
      // 3. Rollback Firestore deletion if Auth deletion fails (e.g. requires-recent-login)
      if (userData != null) {
        await _firestore.collection('users').doc(uid).set(userData);
      }
      rethrow;
    }
  }

  /// Update user password in Firestore
  Future<void> updateUserPassword(String uid, String password) async {
    await _firestore.collection('users').doc(uid).set({
      'password': password,
    }, SetOptions(merge: true));
  }

  /// Update user display name in Firebase Auth and Firestore
  Future<void> updateDisplayName(String uid, String displayName) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName.trim());
    }
    await _firestore.collection('users').doc(uid).set({
      'displayName': displayName.trim(),
    }, SetOptions(merge: true));
  }

  /// Update user password in Firebase Auth and Firestore
  Future<void> updatePassword(String uid, String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
    await _firestore.collection('users').doc(uid).set({
      'password': newPassword,
    }, SetOptions(merge: true));
  }
}
