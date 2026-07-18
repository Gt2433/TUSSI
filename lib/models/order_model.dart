import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a fabric type with its name, selling unit ('meter' or 'kg'), and price.
class FabricType {
  final String name;
  final String unit; // 'meter' or 'kg'
  final double price;
  final List<double> savedLengths;

  FabricType({
    required this.name,
    required this.unit,
    required this.price,
    List<double>? savedLengths,
  }) : savedLengths = savedLengths ?? const [];

  factory FabricType.fromMap(Map<String, dynamic> map) {
    return FabricType(
      name: map['name'] ?? '',
      unit: map['unit'] ?? 'meter',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      savedLengths: (map['savedLengths'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'price': price,
      'savedLengths': savedLengths,
    };
  }
}

/// Represents a single fabric entry within an order.
/// Each entry has a fabric type, custom price, and a map of lengths to their multiplier counts.
class FabricEntry {
  String fabricType;
  String unit; // 'meter' or 'kg'
  double price;
  // Key: length (as double), Value: multiplier count
  Map<String, int> lengths;
  // Sequence of lengths in the order they were added
  List<double> sequence;

  FabricEntry({
    required this.fabricType,
    this.unit = 'meter',
    this.price = 0.0,
    Map<String, int>? lengths,
    List<double>? sequence,
  })  : lengths = lengths ?? {},
        sequence = sequence ?? [];

  /// Add a length or increment its multiplier
  void addLength(double length) {
    final key = length.toStringAsFixed(1);
    lengths[key] = (lengths[key] ?? 0) + 1;
    sequence.add(length);
  }

  /// Remove one multiplier of a length
  void removeLength(double length) {
    final key = length.toStringAsFixed(1);
    if (lengths.containsKey(key)) {
      lengths[key] = lengths[key]! - 1;
      if (lengths[key]! <= 0) {
        lengths.remove(key);
      }
      final idx = sequence.lastIndexOf(length);
      if (idx != -1) {
        sequence.removeAt(idx);
      }
    }
  }

  factory FabricEntry.fromMap(Map<String, dynamic> map) {
    final rawLengths = map['lengths'] as Map<String, dynamic>? ?? {};
    final rawSequence = map['sequence'] as List<dynamic>? ?? [];
    return FabricEntry(
      fabricType: map['fabricType'] ?? '',
      unit: map['unit'] ?? 'meter',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      lengths: rawLengths.map((key, value) => MapEntry(key, (value as num).toInt())),
      sequence: rawSequence.map((e) => (e as num).toDouble()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fabricType': fabricType,
      'unit': unit,
      'price': price,
      'lengths': lengths,
      'sequence': sequence,
    };
  }
}

/// Represents a complete order with one or more fabric entries.
class Order {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String? customerName;
  final List<FabricEntry> fabrics;
  final DateTime createdAt;
  final String status; // 'pending' | 'done'
  final DateTime? completedAt;
  final DateTime? expireAt;
  final String? broadcastGroupId;
  final bool isDraft;
  final String? voiceNoteBase64;
  final String? shopId;

  Order({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    this.customerName,
    required this.fabrics,
    required this.createdAt,
    this.status = 'pending',
    this.completedAt,
    this.expireAt,
    this.broadcastGroupId,
    this.isDraft = false,
    this.voiceNoteBase64,
    this.shopId,
  });

  factory Order.fromMap(Map<String, dynamic> map, String docId) {
    final fabricsList = (map['fabrics'] as List<dynamic>? ?? [])
        .map((f) => FabricEntry.fromMap(f as Map<String, dynamic>))
        .toList();

    return Order(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      customerName: map['customerName'],
      fabrics: fabricsList,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      expireAt: (map['expireAt'] as Timestamp?)?.toDate(),
      broadcastGroupId: map['broadcastGroupId'],
      isDraft: map['isDraft'] ?? false,
      voiceNoteBase64: map['voiceNoteBase64'],
      shopId: map['shopId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      if (customerName != null) 'customerName': customerName,
      'fabrics': fabrics.map((f) => f.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (expireAt != null) 'expireAt': Timestamp.fromDate(expireAt!),
      if (broadcastGroupId != null) 'broadcastGroupId': broadcastGroupId,
      'isDraft': isDraft,
      if (voiceNoteBase64 != null) 'voiceNoteBase64': voiceNoteBase64,
      if (shopId != null) 'shopId': shopId,
    };
  }
}
