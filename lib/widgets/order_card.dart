import 'package:flutter/material.dart';
import 'dart:async';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../providers/language_provider.dart';

/// Card widget displaying a complete order with fabric entries,
/// lengths, multipliers, and an optional action button.
class OrderCard extends StatelessWidget {
  final Order order;
  final bool showDoneButton;
  final bool showStatus;
  final VoidCallback? onDone;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;
  final VoidCallback? onResume;
  final bool isSent;

  const OrderCard({
    super.key,
    required this.order,
    this.showDoneButton = false,
    this.showStatus = false,
    this.onDone,
    this.onRestore,
    this.onDelete,
    this.onResume,
    this.isSent = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd – HH:mm');

    final isAr = order.receiverName.isEmpty; // simple language fallback check if needed, or we can check via Localizations.
    final isOrangeDraft = order.isDraft;

    return Card(
      color: isOrangeDraft
          ? Colors.orange.withValues(alpha: 0.05)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOrangeDraft
              ? Colors.orange.withValues(alpha: 0.4)
              : AppTheme.borderSubtle,
          width: isOrangeDraft ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOrangeDraft
                        ? Colors.orange.withValues(alpha: 0.12)
                        : AppTheme.accentAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOrangeDraft
                        ? Icons.folder_shared_rounded
                        : Icons.receipt_long_rounded,
                    color: isOrangeDraft ? Colors.orange : AppTheme.accentAmber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOrangeDraft
                            ? (isSent
                                ? 'تنبيه: مسودة مرسلة (Alert: Sent Draft)'
                                : 'تنبيه: مسودة واردة (Alert: Incoming Draft)')
                            : (isSent
                                ? 'إلى (To): ${order.receiverName}'
                                : 'من (From): ${order.senderName}'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isOrangeDraft ? Colors.orange : AppTheme.textPrimary,
                        ),
                      ),
                      if (isOrangeDraft) ...[
                        const SizedBox(height: 2),
                        Text(
                          isSent
                              ? 'المستلم (Receiver): ${order.receiverName}'
                              : 'المرسل (Sender): ${order.senderName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      if (order.customerName != null && order.customerName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'الزبون: ${order.customerName}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentAmber,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showStatus) ...[
                  _StatusBadge(status: order.status),
                  if (onRestore != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.restore_rounded, color: AppTheme.accentAmber, size: 20),
                      tooltip: 'إعادة فتح الطلب (Restore)',
                      onPressed: onRestore,
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceElevated,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ],
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                      tooltip: 'حذف الطلب نهائياً',
                      onPressed: onDelete,
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.errorSurface,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ],
                ],
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: AppTheme.borderSubtle, height: 1),
            const SizedBox(height: 16),

            // ─── Fabric Entries ────────────────────────────────
            ...order.fabrics.asMap().entries.map((entry) {
              final idx = entry.key;
              final fabric = entry.value;
              return _FabricSection(
                fabric: fabric,
                index: idx,
                isLast: idx == order.fabrics.length - 1,
              );
            }),

            // ─── Order Summary Boxes ────────────────────────────
            Builder(
              builder: (context) {
                double totalMeters = 0.0;
                double totalKgs = 0.0;
                int totalCylinders = 0;
                double totalPrice = 0.0;

                for (final fabric in order.fabrics) {
                  final fabricQty = fabric.sequence.fold(0.0, (sum, val) => sum + val);
                  totalCylinders += fabric.sequence.length;
                  totalPrice += fabricQty * fabric.price;
                  if (fabric.unit == 'kg') {
                    totalKgs += fabricQty;
                  } else {
                    totalMeters += fabricQty;
                  }
                }

                String qtyText = '';
                if (totalMeters > 0 && totalKgs > 0) {
                  qtyText = '${totalMeters.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} m + ${totalKgs.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg';
                } else if (totalMeters > 0) {
                  qtyText = '${totalMeters.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} m';
                } else if (totalKgs > 0) {
                  qtyText = '${totalKgs.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg';
                } else {
                  qtyText = '0';
                }

                final formattedPrice = NumberFormat('#,##0.##', 'en_US').format(totalPrice);

                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'إجمالي الأسطوانات',
                                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$totalCylinders',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 24, color: AppTheme.borderSubtle),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'إجمالي الكمية',
                                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  qtyText,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 24, color: AppTheme.borderSubtle),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'إجمالي السعر',
                                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$formattedPrice د.ج',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Voice Note Player
            if (order.voiceNoteBase64 != null && order.voiceNoteBase64!.isNotEmpty)
              _OrderVoiceNotePlayer(base64String: order.voiceNoteBase64!),

            // ─── Done/Resume/Recall Buttons ─────────────────────
            if (showDoneButton || onResume != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (isSent && onResume != null) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onResume,
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        label: const Text('تعديل / سحب  Edit / Recall'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentAmber,
                          foregroundColor: AppTheme.surfaceDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ] else ...[
                    if (isOrangeDraft && onResume != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onResume,
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text('استئناف  Resume'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                    if (!isOrangeDraft && showDoneButton) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onDone,
                          icon: const Icon(Icons.check_circle_rounded, size: 20),
                          label: const Text('تم  Done'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: AppTheme.surfaceDark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FabricSection extends StatelessWidget {
  final FabricEntry fabric;
  final int index;
  final bool isLast;

  const _FabricSection({
    required this.fabric,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fabric type label
        Row(
          children: [
            Icon(
              Icons.texture_rounded,
              size: 16,
              color: AppTheme.accentAmberLight,
            ),
            const SizedBox(width: 8),
            Text(
              fabric.fabricType,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Lengths with multipliers
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (fabric.lengths.entries.toList()..sort((a, b) {
            final double valA = double.tryParse(a.key) ?? 0.0;
            final double valB = double.tryParse(b.key) ?? 0.0;
            return valB.compareTo(valA);
          })).map((e) {
            final length = e.key;
            final multiplier = e.value;
            // Format length display
            final displayLength = double.tryParse(length);
            final lengthText = displayLength != null &&
                    displayLength == displayLength.roundToDouble()
                ? displayLength.toInt().toString()
                : length;
            final unitSuffix = fabric.unit == 'kg' ? ' kg' : ' m';
            final textToDisplay = '$lengthText$unitSuffix';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    textToDisplay,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (multiplier > 1) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '×$multiplier',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.surfaceDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Fabric Summary
        Builder(
          builder: (context) {
            final fabricQty = fabric.sequence.fold(0.0, (sum, val) => sum + val);
            final fabricCylinders = fabric.sequence.length;
            final fabricPrice = fabricQty * fabric.price;
            final formattedPrice = NumberFormat('#,##0.##', 'en_US').format(fabricPrice);
            final formattedUnitPrice = NumberFormat('#,##0.##', 'en_US').format(fabric.price);
            final unitText = fabric.unit == 'kg' ? 'كغ' : 'متر';

            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'السعر الفردي',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$formattedUnitPrice د.ج/$unitText',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 16, color: AppTheme.borderSubtle.withValues(alpha: 0.5)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'الأسطوانات',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$fabricCylinders',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 16, color: AppTheme.borderSubtle.withValues(alpha: 0.5)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'الكمية',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${fabricQty.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${fabric.unit == 'kg' ? 'kg' : 'm'}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 16, color: AppTheme.borderSubtle.withValues(alpha: 0.5)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'السعر الإجمالي',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$formattedPrice د.ج',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        if (!isLast) ...[
          const SizedBox(height: 14),
          Divider(
            color: AppTheme.borderSubtle.withValues(alpha: 0.5),
            height: 1,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'done';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDone
            ? AppTheme.successSurface
            : AppTheme.accentAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isDone ? 'تم ✓' : 'قيد الانتظار',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDone ? AppTheme.success : AppTheme.accentAmber,
        ),
      ),
    );
  }
}

class _OrderVoiceNotePlayer extends StatefulWidget {
  final String base64String;

  const _OrderVoiceNotePlayer({required this.base64String});

  @override
  State<_OrderVoiceNotePlayer> createState() => _OrderVoiceNotePlayerState();
}

class _OrderVoiceNotePlayerState extends State<_OrderVoiceNotePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _compSub;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _posSub = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _compSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _compSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      try {
        final bytes = base64Decode(widget.base64String);
        await _audioPlayer.stop();
        await _audioPlayer.play(BytesSource(Uint8List.fromList(bytes)));
        if (mounted) setState(() => _isPlaying = true);
      } catch (e) {
        print('Playback error: $e');
      }
    }
  }

  String _formatDuration(Duration d) {
    final seconds = d.inSeconds;
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: AppTheme.accentAmber,
              size: 32,
            ),
            onPressed: _playPause,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                    activeTrackColor: AppTheme.accentAmber,
                    inactiveTrackColor: AppTheme.borderSubtle,
                    thumbColor: AppTheme.accentAmber,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble(),
                    max: _duration.inMilliseconds.toDouble().clamp(0.1, double.infinity),
                    onChanged: (val) async {
                      final target = Duration(milliseconds: val.toInt());
                      await _audioPlayer.seek(target);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
