import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Fabric Types ──────────────────────────────────────────────

  /// Stream all fabric types (dynamic, globally shared)
  /// Stream all fabric types for a specific shop
  Stream<List<FabricType>> streamFabricTypes(String shopId) {
    return _firestore
        .collection('fabric_types')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => FabricType.fromMap(d.data())).toList();
          list.sort((a, b) => a.name.compareTo(b.name));
          return list;
        });
  }

  /// Add a new fabric type with its selling unit and price for a specific shop
  Future<void> addFabricType(String name, String unit, double price, String shopId) async {
    // Check for duplicates
    final existing = await _firestore
        .collection('fabric_types')
        .where('shopId', isEqualTo: shopId)
        .where('name', isEqualTo: name.trim())
        .get();

    if (existing.docs.isEmpty) {
      await _firestore.collection('fabric_types').add({
        'name': name.trim(),
        'unit': unit,
        'price': price,
        'shopId': shopId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Delete a fabric type for a specific shop
  Future<void> deleteFabricType(String name, String shopId) async {
    final docs = await _firestore
        .collection('fabric_types')
        .where('shopId', isEqualTo: shopId)
        .get();
        
    final targetName = name.trim().toLowerCase();
    for (final doc in docs.docs) {
      final docName = (doc.data()['name'] as String? ?? '').trim().toLowerCase();
      if (docName == targetName) {
        await doc.reference.delete();
      }
    }
  }

  /// Update the price of a fabric type for a specific shop
  Future<void> updateFabricPrice(String name, double newPrice, String shopId) async {
    final docs = await _firestore
        .collection('fabric_types')
        .where('shopId', isEqualTo: shopId)
        .get();
        
    final targetName = name.trim().toLowerCase();
    for (final doc in docs.docs) {
      final docName = (doc.data()['name'] as String? ?? '').trim().toLowerCase();
      if (docName == targetName) {
        await doc.reference.update({'price': newPrice});
      }
    }
  }

  // ─── Saved Lengths (Fabric-Specific Sync) ─────────────────────

  /// Stream all globally saved lengths (deprecated)
  Stream<List<double>> streamSavedLengths() {
    return Stream.value([]);
  }

  /// Add a length to the global saved_lengths collection (deprecated)
  Future<void> addSavedLength(double length) async {}

  /// Delete a length from the global saved_lengths collection (deprecated)
  Future<void> deleteSavedLength(double length) async {}

  /// Stream saved lengths for a specific fabric type
  /// Stream saved lengths for a specific fabric type in a specific shop
  Stream<List<double>> streamSavedLengthsForFabric(String fabricTypeName, String shopId) {
    if (fabricTypeName.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('fabric_types')
        .where('shopId', isEqualTo: shopId)
        .where('name', isEqualTo: fabricTypeName)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return [];
      final data = snap.docs.first.data();
      final list = (data['savedLengths'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [];
      list.sort();
      return list;
    });
  }

  /// Add a length to a specific fabric type's savedLengths list for a specific shop
  Future<void> addSavedLengthForFabric(String fabricTypeName, double length, String shopId) async {
    if (fabricTypeName.isEmpty) return;
    final docs = await _firestore
        .collection('fabric_types')
        .where('shopId', isEqualTo: shopId)
        .where('name', isEqualTo: fabricTypeName)
        .get();

    if (docs.docs.isNotEmpty) {
      final docRef = docs.docs.first.reference;
      final data = docs.docs.first.data();
      final list = List<double>.from(
        (data['savedLengths'] as List<dynamic>?)?.map((e) => (e as num).toDouble()) ?? []
      );

      if (!list.contains(length)) {
        list.add(length);
        list.sort();
        await docRef.update({'savedLengths': list});
      }
    }
  }

  /// Delete a length from a specific fabric type's savedLengths list for a specific shop
  Future<void> deleteSavedLengthForFabric(String fabricTypeName, double length, String shopId) async {
    if (fabricTypeName.isEmpty) return;
    final docs = await _firestore
        .collection('fabric_types')
        .where('shopId', isEqualTo: shopId)
        .where('name', isEqualTo: fabricTypeName)
        .get();

    if (docs.docs.isNotEmpty) {
      final docRef = docs.docs.first.reference;
      final data = docs.docs.first.data();
      final list = List<double>.from(
        (data['savedLengths'] as List<dynamic>?)?.map((e) => (e as num).toDouble()) ?? []
      );

      if (list.contains(length)) {
        list.remove(length);
        await docRef.update({'savedLengths': list});
      }
    }
  }

  /// Clear all global saved lengths in the 'saved_lengths' collection
  Future<void> clearAllGlobalSavedLengths() async {
    final docs = await _firestore.collection('saved_lengths').get();
    final batch = _firestore.batch();
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    if (docs.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  // ─── Users ─────────────────────────────────────────────────────

  /// Get FCM token for a user
  Future<String?> getUserFcmToken(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['fcmToken'] as String?;
    }
    return null;
  }

  /// Fetch all registered users
  Future<List<AppUser>> getAllUsers() async {
    final snap = await _firestore
        .collection('users')
        .orderBy('displayName')
        .get();

    return snap.docs
        .map((d) => AppUser.fromMap(d.data()))
        .toList();
  }

  /// Stream all registered users
  Stream<List<AppUser>> streamAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('displayName')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppUser.fromMap(d.data()))
            .toList());
  }

  /// Fetch all users in a specific shop
  Future<List<AppUser>> getUsersInShop(String shopId) async {
    final snap = await _firestore
        .collection('users')
        .where('shopId', isEqualTo: shopId)
        .get();

    final list = snap.docs
        .map((d) => AppUser.fromMap(d.data()))
        .toList();
    list.sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

  /// Stream all users in a specific shop
  Stream<List<AppUser>> streamUsersInShop(String shopId) {
    return _firestore
        .collection('users')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => AppUser.fromMap(d.data()))
              .toList();
          list.sort((a, b) => a.displayName.compareTo(b.displayName));
          return list;
        });
  }

  // ─── Orders ────────────────────────────────────────────────────

  /// Create a new order
  Future<void> createOrder(Order order) async {
    await _firestore.collection('orders').doc(order.id).set(order.toMap());
  }

  /// Stream pending orders for a specific receiver
  Stream<List<Order>> streamOrdersForReceiver(String receiverId) {
    return _firestore
        .collection('orders')
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Order.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Stream pending orders sent by the current user
  Stream<List<Order>> streamOrdersForSender(String senderId) {
    return _firestore
        .collection('orders')
        .where('senderId', isEqualTo: senderId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Order.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Mark an order as done and move to history, and delete other broadcasted pending copies
  Future<void> markOrderDoneGroup(Order order) async {
    final now = DateTime.now();
    final expireAt = now.add(const Duration(days: 30));

    // 1. Mark this specific order copy as done
    await _firestore.collection('orders').doc(order.id).update({
      'status': 'done',
      'completedAt': Timestamp.fromDate(now),
      'expireAt': Timestamp.fromDate(expireAt),
    });

    // 2. Delete all other pending copies in the same broadcast group
    if (order.broadcastGroupId != null && order.broadcastGroupId!.isNotEmpty) {
      final docs = await _firestore
          .collection('orders')
          .where('broadcastGroupId', isEqualTo: order.broadcastGroupId)
          .where('status', isEqualTo: 'pending')
          .get();
      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        if (doc.id != order.id) {
          batch.delete(doc.reference);
        }
      }
      if (docs.docs.length > 1) {
        await batch.commit();
      }
    }
  }

  /// Mark an order as done and move to history (legacy fallback)
  Future<void> markOrderDone(String orderId) async {
    final now = DateTime.now();
    final expireAt = now.add(const Duration(days: 30));

    await _firestore.collection('orders').doc(orderId).update({
      'status': 'done',
      'completedAt': Timestamp.fromDate(now),
      'expireAt': Timestamp.fromDate(expireAt),
    });
  }

  /// Stream order history (done orders) for a specific shop
  Stream<List<Order>> streamOrderHistory(String shopId) {
    return _firestore
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'done')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Order.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) {
            final aTime = a.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  /// Clean up orders older than 30 days (client-side TTL fallback)
  Future<int> cleanupExpiredOrders() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final doneOrders = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'done')
        .get();

    final expiredDocs = doneOrders.docs.where((doc) {
      final completedAt = (doc.data()['completedAt'] as Timestamp?)?.toDate();
      return completedAt != null && completedAt.isBefore(cutoff);
    }).toList();

    final batch = _firestore.batch();
    for (final doc in expiredDocs) {
      batch.delete(doc.reference);
    }

    if (expiredDocs.isNotEmpty) {
      await batch.commit();
    }

    return expiredDocs.length;
  }

  /// Restore an order from done to pending and remove completed/expiry times
  Future<void> restoreOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'pending',
      'completedAt': FieldValue.delete(),
      'expireAt': FieldValue.delete(),
    });
  }

  /// Delete all pending copies of the order in the same broadcast group (when resumed)
  Future<void> deleteOrderGroup(Order order) async {
    if (order.broadcastGroupId != null && order.broadcastGroupId!.isNotEmpty) {
      final docs = await _firestore
          .collection('orders')
          .where('broadcastGroupId', isEqualTo: order.broadcastGroupId)
          .get();
      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      if (docs.docs.isNotEmpty) {
        await batch.commit();
      }
    } else {
      await deleteOrder(order.id);
    }
  }

  /// Delete a single order from the database
  Future<void> deleteOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).delete();
  }

  /// Clear all completed orders in order history
  Future<void> clearAllHistory() async {
    final docs = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'done')
        .get();

    final batch = _firestore.batch();
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    if (docs.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  // ─── Shop & Code Verification ──────────────────────────────────

  /// Generate a new activation code for a given shop name and duration (Super Admin only)
  Future<String> generateActivationCode(String shopName, int durationSeconds) async {
    final rand = DateTime.now().millisecondsSinceEpoch.toString();
    final code = 'FN-${rand.substring(rand.length - 6)}';
    
    await _firestore.collection('activation_codes').doc(code).set({
      'code': code,
      'shopName': shopName.trim(),
      'isUsed': false,
      'durationSeconds': durationSeconds,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  /// Stream all activation codes
  Stream<List<Map<String, dynamic>>> streamAllActivationCodes() {
    return _firestore
        .collection('activation_codes')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['code'] = d.id;
              return data;
            }).toList());
  }

  /// Stream all registered shops
  Stream<List<Map<String, dynamic>>> streamAllShops() {
    return _firestore
        .collection('shops')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id; // Ensure 'id' is always populated
              return data;
            }).toList());
  }

  /// Delete a shop permanently (Super Admin only)
  Future<void> deleteShop(String shopId) async {
    if (shopId.isEmpty) return;
    
    // 1. Get all users associated with this shop
    final usersQuery = await _firestore
        .collection('users')
        .where('shopId', isEqualTo: shopId)
        .get();

    final batch = _firestore.batch();

    // 2. Add users deletion to batch (excluding super admins)
    for (final doc in usersQuery.docs) {
      final userData = doc.data();
      final role = userData['role'] as String?;
      final email = userData['email'] as String?;
      if (role == 'super_admin' || email == 'hhcgjvhcnk@gmail.com') {
        // Do not delete super admin users! Just reset their shopId
        batch.update(doc.reference, {'shopId': FieldValue.delete()});
      } else {
        batch.delete(doc.reference);
      }
    }

    // 3. Add shop deletion to batch
    batch.delete(_firestore.collection('shops').doc(shopId));

    await batch.commit();
  }

  /// Recreate super admin document if missing
  Future<void> recreateSuperAdmin(String uid, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email.trim(),
      'displayName': 'المدير العام',
      'role': 'super_admin',
      'shopId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete an activation code (Super Admin only)
  Future<void> deleteActivationCode(String code) async {
    await _firestore.collection('activation_codes').doc(code.trim().toUpperCase()).delete();
  }

  /// Check if an activation code is valid
  Future<DocumentSnapshot?> checkActivationCode(String code) async {
    if (code.isEmpty) return null;
    final doc = await _firestore.collection('activation_codes').doc(code.trim().toUpperCase()).get();
    if (doc.exists) {
      return doc;
    }
    return null;
  }

  /// Check if a shop invite code is valid and returns the shop document if found
  Future<DocumentSnapshot?> checkInviteCode(String inviteCode) async {
    if (inviteCode.isEmpty) return null;
    final query = await _firestore
        .collection('shops')
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }
    return null;
  }

  String _generateRandomInviteCode() {
    final rand = DateTime.now().millisecondsSinceEpoch.toString();
    return 'FN-${rand.substring(rand.length - 6)}';
  }

  /// Register a new shop and set the admin account details in Firestore, or join an existing shop if code was already used
  Future<void> registerShopAndAdmin({
    required String activationCode,
    required String adminUid,
    required String adminEmail,
    required String adminName,
    required String shopName,
    String? password,
    String? photoBase64,
  }) async {
    final codeRef = _firestore.collection('activation_codes').doc(activationCode.trim().toUpperCase());
    final codeDoc = await codeRef.get();
    final codeData = codeDoc.data() as Map<String, dynamic>?;
 
    final bool isAlreadyUsed = codeData?['isUsed'] as bool? ?? false;
    final String? existingShopId = codeData?['shopId'] as String?;
 
    if (isAlreadyUsed && existingShopId != null) {
      // The shop already exists. Join this user as a shop employee.
      await _firestore.collection('users').doc(adminUid).set({
        'uid': adminUid,
        'email': adminEmail.trim(),
        'displayName': adminName.trim(),
        'password': password,
        'role': 'shop_employee',
        'shopId': existingShopId,
        'photoBase64': photoBase64,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }
 
    final int durationSeconds = codeData?['durationSeconds'] as int? ?? 0;
    final batch = _firestore.batch();
 
    // 1. Create Shop doc
    final shopId = _firestore.collection('shops').doc().id;
    final inviteCode = _generateRandomInviteCode();
    final shopRef = _firestore.collection('shops').doc(shopId);
    batch.set(shopRef, {
      'id': shopId,
      'name': shopName.trim(),
      'inviteCode': inviteCode,
      'ownerId': adminUid,
      'isActive': true,
      'subscriptionExpiresAt': Timestamp.fromDate(DateTime.now().add(Duration(seconds: durationSeconds))),
      'createdAt': FieldValue.serverTimestamp(),
    });
 
    // 2. Mark activation code as used
    batch.update(codeRef, {
      'isUsed': true,
      'usedBy': adminUid,
      'usedAt': FieldValue.serverTimestamp(),
      'shopId': shopId,
    });
 
    // 3. Create admin user doc
    final userRef = _firestore.collection('users').doc(adminUid);
    batch.set(userRef, {
      'uid': adminUid,
      'email': adminEmail.trim(),
      'displayName': adminName.trim(),
      'password': password,
      'role': 'shop_admin',
      'shopId': shopId,
      'photoBase64': photoBase64,
      'createdAt': FieldValue.serverTimestamp(),
    });
 
    await batch.commit();
  }

  /// Register an employee and associate them with a shop via invite code
  Future<void> registerEmployee({
    required String inviteCode,
    required String employeeUid,
    required String employeeEmail,
    required String employeeName,
    String? password,
    String? photoBase64,
  }) async {
    final shopDoc = await checkInviteCode(inviteCode);
    if (shopDoc == null) {
      throw Exception('كود الدعوة غير صالح أو منتهي الصلاحية');
    }

    final shopId = shopDoc.id;

    await _firestore.collection('users').doc(employeeUid).set({
      'uid': employeeUid,
      'email': employeeEmail.trim(),
      'displayName': employeeName.trim(),
      'password': password,
      'role': 'shop_employee',
      'shopId': shopId,
      'photoBase64': photoBase64,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Publish a new app update (Super Admin only)
  Future<void> publishAppUpdate(String version, String url) async {
    await _firestore.collection('app_updates').doc('latest').set({
      'version': version.trim(),
      'url': url.trim(),
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream the latest app update
  Stream<Map<String, dynamic>?> streamLatestAppUpdate() {
    return _firestore
        .collection('app_updates')
        .doc('latest')
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Stream details of a specific shop
  Stream<Map<String, dynamic>?> streamShopDetails(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Update shop subscription details (Super Admin only)
  Future<void> updateShopSubscription(String shopId, DateTime expiresAt, bool isActive) async {
    await _firestore.collection('shops').doc(shopId).update({
      'subscriptionExpiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
    });
  }
}
