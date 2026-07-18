import 'package:flutter/material.dart';
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

  // ─── Add another fabric entry ─────────────────────────────────
  void addFabricEntry() {
    _fabricEntries.add(FabricEntry(fabricType: '', price: 0.0));
    notifyListeners();
  }

  // ─── Remove a fabric entry ────────────────────────────────────
  void removeFabricEntry(int index) {
    if (_fabricEntries.length > 1) {
      _fabricEntries.removeAt(index);
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
        _fabricEntries[index].lengths.clear();
        _fabricEntries[index].sequence.clear();
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
      _fabricEntries[entryIndex].lengths.clear();
      _fabricEntries[entryIndex].sequence.clear();
      notifyListeners();
    }
  }

  // ─── Validate the order before sending ────────────────────────
  String? validateOrder() {
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
  }) async {
    final validationError = validateOrder();
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
          fabrics: List.from(_fabricEntries),
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
}
