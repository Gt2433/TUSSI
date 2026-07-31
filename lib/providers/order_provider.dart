import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';
import '../services/audio_service.dart';
import '../services/fcm_service.dart';

/// Provider managing order building state.
/// Handles adding fabric entries, lengths with multipliers,
/// and submitting orders.
class OrderProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<FabricEntry> _fabricEntries = [];
  bool _isSending = false;
  String? _error;
  String _draftCustomerName = '';
  String? _draftVoiceNoteBase64;
  
  bool _isOffline = false;
  List<Order> _offlineOrders = [];
  bool _isSyncing = false;

  bool get isOffline => _isOffline;
  List<Order> get offlineOrders => _offlineOrders;
  bool get isSyncing => _isSyncing;

  Timer? _connectivityTimer;

  OrderProvider() {
    _loadOfflineData();
    startConnectivityCheck();
  }

  void startConnectivityCheck() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final hasNet = await _checkInternetConnection();
      if (!hasNet && !_isOffline) {
        _isOffline = true;
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('offline_mode', true);
      } else if (hasNet && _isOffline) {
        _isOffline = false;
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('offline_mode', false);
      }
    });
  }

  Future<bool> _checkInternetConnection() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOffline = prefs.getBool('offline_mode') ?? false;
      
      final savedJson = prefs.getString('offline_orders');
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson);
        _offlineOrders = list.map((item) => Order.fromJsonMap(item as Map<String, dynamic>)).toList();
      }
      notifyListeners();
    } catch (e) {
      print('Error loading offline data: $e');
    }
  }

  Future<void> toggleOffline(bool val) async {
    _isOffline = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', val);
  }

  Future<void> _saveOfflineOrdersToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _offlineOrders.map((o) => o.toJsonMap()).toList();
      await prefs.setString('offline_orders', jsonEncode(list));
    } catch (e) {
      print('Error saving offline orders: $e');
    }
  }

  Future<void> saveOfflineOrder({
    required String senderId,
    required String senderName,
    required String customerName,
    required String shopId,
    bool isDraft = false,
  }) async {
    final baseId = DateTime.now().millisecondsSinceEpoch.toString();
    final newOfflineOrder = Order(
      id: 'offline_${baseId}',
      senderId: senderId,
      senderName: senderName,
      receiverId: senderId,
      receiverName: senderName,
      customerName: customerName,
      fabrics: List.from(_fabricEntries),
      createdAt: DateTime.now(),
      status: 'pending',
      broadcastGroupId: baseId,
      isDraft: isDraft,
      voiceNoteBase64: _draftVoiceNoteBase64,
      shopId: shopId,
    );

    _offlineOrders.add(newOfflineOrder);
    notifyListeners();

    await _saveOfflineOrdersToPrefs();

    // Reset fields
    _fabricEntries = [FabricEntry(fabricType: '', price: 0.0)];
    _draftCustomerName = '';
    _draftVoiceNoteBase64 = null;
    AudioService.playSend();
    notifyListeners();
  }

  Future<void> removeOfflineOrder(String id) async {
    _offlineOrders.removeWhere((o) => o.id == id);
    notifyListeners();
    await _saveOfflineOrdersToPrefs();
  }

  Future<bool> syncOfflineOrders() async {
    if (_offlineOrders.isEmpty) return true;
    _isSyncing = true;
    _error = null;
    notifyListeners();

    try {
      final List<Order> toSync = List.from(_offlineOrders);
      for (final order in toSync) {
        final finalOrder = Order(
          id: order.id.replaceFirst('offline_', 'sync_'),
          senderId: order.senderId,
          senderName: order.senderName,
          receiverId: order.receiverId,
          receiverName: order.receiverName,
          customerName: order.customerName,
          fabrics: order.fabrics,
          createdAt: order.createdAt,
          status: order.status,
          broadcastGroupId: order.broadcastGroupId,
          isDraft: order.isDraft,
          voiceNoteBase64: order.voiceNoteBase64,
          shopId: order.shopId,
        );

        await _firestoreService.createOrder(finalOrder);

        try {
          final rToken = await _firestoreService.getUserFcmToken(order.receiverId);
          if (rToken != null && rToken.isNotEmpty) {
            await FcmService().sendNotification(
              receiverToken: rToken,
              senderName: order.senderName,
              orderId: finalOrder.id,
            );
          }
        } catch (_) {}

        _offlineOrders.removeWhere((o) => o.id == order.id);
        await _saveOfflineOrdersToPrefs();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Sync failed: ${e.toString()}';
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ─── Getters ───────────────────────────────────────────────────
  List<FabricEntry> get fabricEntries => _fabricEntries;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get hasEntries => _fabricEntries.isNotEmpty;
  String get draftCustomerName => _draftCustomerName;
  String? get draftVoiceNoteBase64 => _draftVoiceNoteBase64;

  void setVoiceNoteBase64(String? base64) {
    _draftVoiceNoteBase64 = base64;
    notifyListeners();
  }

  set draftCustomerName(String val) {
    if (_draftCustomerName != val) {
      _draftCustomerName = val;
      notifyListeners();
    }
  }

  // ─── Initialize with one empty entry ──────────────────────────
  void initNewOrder() {
    _fabricEntries = [FabricEntry(fabricType: '', price: 0.0)];
    _draftCustomerName = '';
    _draftVoiceNoteBase64 = null;
    _error = null;
    notifyListeners();
  }

  FabricEntry? _lastRemovedEntry;
  int? _lastRemovedEntryIndex;

  bool get hasRemovedEntryBackup => _lastRemovedEntry != null;

  // ─── Add another fabric entry ─────────────────────────────────
  void addFabricEntry() {
    _fabricEntries.add(FabricEntry(fabricType: '', price: 0.0));
    notifyListeners();
  }

  // ─── Remove a fabric entry ────────────────────────────────────
  void removeFabricEntry(int index) {
    if (_fabricEntries.length > 1) {
      _lastRemovedEntry = _fabricEntries[index];
      _lastRemovedEntryIndex = index;
      _fabricEntries.removeAt(index);
      notifyListeners();
    }
  }

  // ─── Restore last removed fabric entry ────────────────────────
  void restoreRemovedFabricEntry() {
    if (_lastRemovedEntry != null && _lastRemovedEntryIndex != null) {
      final insertIndex = _lastRemovedEntryIndex!.clamp(0, _fabricEntries.length);
      _fabricEntries.insert(insertIndex, _lastRemovedEntry!);
      _lastRemovedEntry = null;
      _lastRemovedEntryIndex = null;
      notifyListeners();
    }
  }

  // ─── Update fabric type and price for an entry ──────────────────
  void updateFabricType(int index, String fabricType, String unit, double price) {
    if (index < _fabricEntries.length) {
      if (_fabricEntries[index].fabricType != fabricType) {
        _fabricEntries[index].fabricType = fabricType;
        _fabricEntries[index].unit = unit;
        _fabricEntries[index].price = price;
        _fabricEntries[index].clearLengths();
      } else {
        _fabricEntries[index].unit = unit;
        _fabricEntries[index].price = price;
      }
      notifyListeners();
    }
  }

  // ─── Update custom price for an entry ──────────────────────────
  void updateFabricPrice(int index, double price) {
    if (index < _fabricEntries.length) {
      _fabricEntries[index].price = price;
      notifyListeners();
    }
  }

  // ─── Add length to a fabric entry (increments multiplier) ─────
  Future<void> addLengthToEntry(int entryIndex, double length, String shopId) async {
    if (entryIndex < _fabricEntries.length) {
      final entry = _fabricEntries[entryIndex];
      entry.addLength(length);

      // Save to fabric-specific savedLengths list if fabric is selected
      if (entry.fabricType.isNotEmpty) {
        await _firestoreService.addSavedLengthForFabric(entry.fabricType, length, shopId);
      }

      notifyListeners();
    }
  }

  // ─── Remove one multiplier of a length ────────────────────────
  void removeLengthFromEntry(int entryIndex, double length) {
    if (entryIndex < _fabricEntries.length) {
      _fabricEntries[entryIndex].removeLength(length);
      notifyListeners();
    }
  }

  // ─── Clear a specific entry's lengths ─────────────────────────
  void clearEntryLengths(int entryIndex) {
    if (entryIndex < _fabricEntries.length) {
      _fabricEntries[entryIndex].clearLengths();
      notifyListeners();
    }
  }

  // ─── Restore a specific entry's lengths from backup ───────────
  void restoreEntryLengths(int entryIndex) {
    if (entryIndex < _fabricEntries.length) {
      _fabricEntries[entryIndex].restoreBackup();
      notifyListeners();
    }
  }

  // ─── Validate the order before sending ────────────────────────
  String? validateOrder({bool isQuickOrder = false}) {
    if (isQuickOrder) {
      if (_draftVoiceNoteBase64 == null || _draftVoiceNoteBase64!.isEmpty) {
        return 'يرجى تسجيل الملاحظة الصوتية أولاً.';
      }
      return null;
    }

    if (_fabricEntries.isEmpty) {
      return 'Add at least one fabric entry.';
    }

    for (int i = 0; i < _fabricEntries.length; i++) {
      final entry = _fabricEntries[i];
      if (entry.fabricType.isEmpty) {
        return 'Select a fabric type for entry ${i + 1}.';
      }
      if (entry.lengths.isEmpty) {
        return 'Add at least one length for "${entry.fabricType}".';
      }
    }

    return null;
  }

  // ─── Send the order ─────────────────────────────────
  // ─── Send the order to one or more receivers ──────────────
  Future<bool> sendOrder({
    required String senderId,
    required String senderName,
    required List<String> receiverIds,
    required List<String> receiverNames,
    required String shopId,
    String? customerName,
    bool isDraft = false,
    bool isQuickOrder = false,
  }) async {
    final validationError = validateOrder(isQuickOrder: isQuickOrder);
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return false;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final baseId = DateTime.now().millisecondsSinceEpoch.toString();

      for (int i = 0; i < receiverIds.length; i++) {
        final rId = receiverIds[i];
        final rName = receiverNames[i];
        final order = Order(
          id: '${baseId}_$rId',
          senderId: senderId,
          senderName: senderName,
          receiverId: rId,
          receiverName: rName,
          customerName: customerName,
          fabrics: isQuickOrder ? [] : List.from(_fabricEntries),
          createdAt: DateTime.now(),
          status: 'pending',
          broadcastGroupId: baseId,
          isDraft: isDraft,
          voiceNoteBase64: _draftVoiceNoteBase64,
          shopId: shopId,
        );
        await _firestoreService.createOrder(order);

        // Fetch receiver's FCM Token and send push notification
        try {
          final rToken = await _firestoreService.getUserFcmToken(rId);
          if (rToken != null && rToken.isNotEmpty) {
            await FcmService().sendNotification(
              receiverToken: rToken,
              senderName: senderName,
              orderId: order.id,
            );
          }
        } catch (fcmError) {
          print('Failed to send FCM push notification: $fcmError');
        }
      }

      // Reset the form
      _fabricEntries = [FabricEntry(fabricType: '', price: 0.0)];
      _draftCustomerName = '';
      _draftVoiceNoteBase64 = null;
      _error = null;
      AudioService.playSend();
      return true;
    } catch (e) {
      _error = 'Failed to send order: ${e.toString()}';
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ─── Clear Error ──────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Reset ────────────────────────────────────────────────────
  void reset() {
    _fabricEntries = [];
    _draftCustomerName = '';
    _draftVoiceNoteBase64 = null;
    _isSending = false;
    _error = null;
    notifyListeners();
  }

  // ─── Load order into draft to resume ───────────────────────────
  void loadOrder(Order order) {
    _fabricEntries = order.fabrics.map((f) {
      return FabricEntry(
        fabricType: f.fabricType,
        unit: f.unit,
        price: f.price,
        lengths: Map<String, int>.from(f.lengths),
        sequence: List<double>.from(f.sequence),
      );
    }).toList();
    _draftCustomerName = order.customerName ?? '';
    _draftVoiceNoteBase64 = order.voiceNoteBase64;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }
}
