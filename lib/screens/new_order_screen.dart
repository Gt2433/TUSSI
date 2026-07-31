import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart' as app_auth;
import '../providers/language_provider.dart';
import '../providers/order_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/fabric_entry_card.dart';
import '../widgets/send_order_dialog.dart';
import '../widgets/voice_note_recorder.dart';

/// Screen for building and sending a new order.
/// Supports multiple fabric entries with lengths and multipliers.
class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final TextEditingController _customerNameController = TextEditingController();

  // --- Quick Order Recording State variables ---
  final AudioRecorder _quickAudioRecorder = AudioRecorder();
  AudioPlayer? _quickAudioPlayer;
  bool _isQuickRecording = false;
  bool _isQuickPaused = false;
  bool _hasQuickRecordedAudio = false;
  bool _quickIsPlaying = false;
  bool _quickIsPaused = false;
  int _quickRecordDurationSec = 0;
  Timer? _quickRecordTimer;
  String? _quickVoicePath;
  StreamSubscription? _quickPlayerCompleteSub;

  @override
  void initState() {
    super.initState();
    _quickAudioPlayer = AudioPlayer();
    _quickPlayerCompleteSub = _quickAudioPlayer?.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _quickIsPlaying = false;
          _quickIsPaused = false;
        });
      }
    });

    // Initialize with one empty fabric entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      if (!provider.hasEntries) {
        provider.initNewOrder();
      }
    });
  }

  @override
  void dispose() {
    _quickRecordTimer?.cancel();
    _quickPlayerCompleteSub?.cancel();
    _quickAudioRecorder.dispose();
    _quickAudioPlayer?.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  // --- Quick Order Helper Functions ---

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Future<void> _startQuickRecording() async {
    if (_isQuickRecording) return;
    try {
      if (await _quickAudioRecorder.hasPermission()) {
        String path = 'temp_quick_voice_note.m4a';
        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          path = '${tempDir.path}/temp_quick_voice_note.m4a';
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
        AudioEncoder encoder = AudioEncoder.aacLc;
        if (kIsWeb) {
          if (await _quickAudioRecorder.isEncoderSupported(AudioEncoder.opus)) {
            encoder = AudioEncoder.opus;
          } else if (await _quickAudioRecorder.isEncoderSupported(AudioEncoder.wav)) {
            encoder = AudioEncoder.wav;
          }
        }

        await _quickAudioRecorder.start(
          RecordConfig(
            encoder: encoder,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 16000,
          ),
          path: path,
        );

        _quickRecordDurationSec = 0;
        _quickRecordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted && !_isQuickPaused) {
            setState(() {
              _quickRecordDurationSec++;
            });
          }
        });

        setState(() {
          _isQuickRecording = true;
          _isQuickPaused = false;
          _hasQuickRecordedAudio = false;
          _quickVoicePath = null;
        });
      } else {
        _showSnackBar('مطلوب إذن الميكروفون لتسجيل الصوت.', isError: true);
      }
    } catch (e) {
      _showSnackBar('خطأ أثناء بدء التسجيل: $e', isError: true);
    }
  }

  Future<void> _stopQuickRecording() async {
    if (!_isQuickRecording) return;
    _quickRecordTimer?.cancel();
    try {
      final path = await _quickAudioRecorder.stop();
      setState(() {
        _isQuickRecording = false;
        _isQuickPaused = false;
        _hasQuickRecordedAudio = path != null;
        _quickVoicePath = path;
      });

      if (path != null) {
        Uint8List bytes;
        if (kIsWeb) {
          final response = await http.get(Uri.parse(path));
          bytes = response.bodyBytes;
        } else {
          final file = File(path);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
          } else {
            return;
          }
        }
        final base64String = base64Encode(bytes);
        if (mounted) {
          Provider.of<OrderProvider>(context, listen: false)
              .setVoiceNoteBase64(base64String);
        }
      }
    } catch (e) {
      _showSnackBar('خطأ أثناء إيقاف التسجيل: $e', isError: true);
    }
  }

  Future<void> _toggleQuickPause() async {
    if (!_isQuickRecording) return;
    try {
      if (_isQuickPaused) {
        await _quickAudioRecorder.resume();
        setState(() => _isQuickPaused = false);
      } else {
        await _quickAudioRecorder.pause();
        setState(() => _isQuickPaused = true);
      }
    } catch (e) {
      _showSnackBar('خطأ في الإيقاف المؤقت: $e', isError: true);
    }
  }

  Future<void> _deleteQuickRecord() async {
    _quickRecordTimer?.cancel();
    if (_isQuickRecording) {
      try {
        await _quickAudioRecorder.stop();
      } catch (_) {}
    }
    if (_quickIsPlaying) {
      try {
        await _quickAudioPlayer?.stop();
      } catch (_) {}
    }

    Provider.of<OrderProvider>(context, listen: false).setVoiceNoteBase64(null);

    setState(() {
      _isQuickRecording = false;
      _isQuickPaused = false;
      _hasQuickRecordedAudio = false;
      _quickIsPlaying = false;
      _quickIsPaused = false;
      _quickRecordDurationSec = 0;
      _quickVoicePath = null;
    });
  }

  Future<void> _playPauseQuickPreview() async {
    final base64String = Provider.of<OrderProvider>(context, listen: false).draftVoiceNoteBase64;
    if (base64String == null || base64String.isEmpty) return;

    if (_quickIsPlaying) {
      await _quickAudioPlayer?.pause();
      setState(() {
        _quickIsPlaying = false;
        _quickIsPaused = true;
      });
    } else {
      try {
        if (_quickIsPaused) {
          await _quickAudioPlayer?.resume();
        } else {
          final bytes = base64Decode(base64String);
          await _quickAudioPlayer?.stop();
          await _quickAudioPlayer?.play(BytesSource(Uint8List.fromList(bytes)));
        }
        setState(() {
          _quickIsPlaying = true;
          _quickIsPaused = false;
        });
      } catch (e) {
        _showSnackBar('خطأ في تشغيل الصوت: $e', isError: true);
      }
    }
  }

  Future<void> _sendQuickOrder() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);

    if (orderProvider.draftVoiceNoteBase64 == null || orderProvider.draftVoiceNoteBase64!.isEmpty) {
      _showSnackBar('يرجى تسجيل الرسالة الصوتية أولاً.', isError: true);
      return;
    }

    final selectedUsers = await SendOrderDialog.show(
      context,
      authProvider.user!.uid,
      shopId: authProvider.appUser?.shopId ?? '',
    );

    if (selectedUsers == null || selectedUsers.isEmpty || !mounted) return;

    final success = await orderProvider.sendOrder(
      senderId: authProvider.user!.uid,
      senderName: authProvider.displayName,
      receiverIds: selectedUsers.map((u) => u.uid).toList(),
      receiverNames: selectedUsers.map((u) => u.displayName).toList(),
      shopId: authProvider.appUser?.shopId ?? '',
      isQuickOrder: true,
    );

    if (mounted) {
      if (success) {
        _deleteQuickRecord();
        final names = selectedUsers.map((u) => u.displayName).join(', ');
        _showSnackBar(
          '${context.tr('order_sent_to')} $names ✓',
          isError: false,
        );
      } else {
        _showSnackBar(
          orderProvider.error ?? context.tr('failed_send'),
          isError: true,
        );
      }
    }
  }

  Future<void> _sendOrder() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    // Validate first
    final validationError = orderProvider.validateOrder();
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    if (orderProvider.isOffline) {
      final isAr = context.tr('tab_orders') == 'الطلبيات';
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isAr ? 'حفظ الطلب دون اتصال' : 'Save Order Offline'),
          content: Text(isAr 
              ? 'هل تود حفظ هذه الطلبية محلياً؟ سيتم تخزينها بأمان على هذا الجهاز وتكون جاهزة للمزامنة فور الاتصال بالإنترنت.'
              : 'Do you want to save this order locally? It will be safely stored on this device and ready to sync once internet is connected.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentAmber,
                foregroundColor: AppTheme.surfaceDark,
              ),
              child: Text(isAr ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await orderProvider.saveOfflineOrder(
          senderId: authProvider.user!.uid,
          senderName: authProvider.displayName,
          customerName: _customerNameController.text.trim(),
          shopId: authProvider.appUser?.shopId ?? '',
          isDraft: false,
        );
        _customerNameController.clear();
        _showSnackBar(
          isAr ? 'تم حفظ الطلبية محلياً بنجاح (دون اتصال) ✓' : 'Order saved locally successfully (Offline) ✓',
          isError: false,
        );
      }
      return;
    }

    // Show receiver selection dialog
    final selectedUsers = await SendOrderDialog.show(
      context,
      authProvider.user!.uid,
      shopId: authProvider.appUser?.shopId ?? '',
    );

    if (selectedUsers == null || selectedUsers.isEmpty || !mounted) return;

    // Send the order
    final success = await orderProvider.sendOrder(
      senderId: authProvider.user!.uid,
      senderName: authProvider.displayName,
      receiverIds: selectedUsers.map((u) => u.uid).toList(),
      receiverNames: selectedUsers.map((u) => u.displayName).toList(),
      customerName: _customerNameController.text.trim(),
      shopId: authProvider.appUser?.shopId ?? '',
    );

    if (mounted) {
      if (success) {
        _customerNameController.clear();
        final names = selectedUsers.map((u) => u.displayName).join(', ');
        _showSnackBar(
          '${context.tr('order_sent_to')} $names ✓',
          isError: false,
        );
      } else {
        _showSnackBar(
          orderProvider.error ?? context.tr('failed_send'),
          isError: true,
        );
      }
    }
  }

  Future<void> _sendDraft() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    // Validate first
    final validationError = orderProvider.validateOrder();
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    if (orderProvider.isOffline) {
      final isAr = context.tr('tab_orders') == 'الطلبيات';
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isAr ? 'حفظ المسودة دون اتصال' : 'Save Draft Offline'),
          content: Text(isAr 
              ? 'هل تود حفظ هذه المسودة محلياً؟ سيتم تخزينها بأمان على هذا الجهاز وتكون جاهزة للمزامنة فور الاتصال بالإنترنت.'
              : 'Do you want to save this draft locally? It will be safely stored on this device and ready to sync once internet is connected.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentAmber,
                foregroundColor: AppTheme.surfaceDark,
              ),
              child: Text(isAr ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await orderProvider.saveOfflineOrder(
          senderId: authProvider.user!.uid,
          senderName: authProvider.displayName,
          customerName: _customerNameController.text.trim(),
          shopId: authProvider.appUser?.shopId ?? '',
          isDraft: true,
        );
        _customerNameController.clear();
        _showSnackBar(
          isAr ? 'تم حفظ المسودة محلياً بنجاح (دون اتصال) ✓' : 'Draft saved locally successfully (Offline) ✓',
          isError: false,
        );
      }
      return;
    }

    // Show receiver selection dialog in Single Select mode
    final selectedUsers = await SendOrderDialog.show(
      context,
      authProvider.user!.uid,
      shopId: authProvider.appUser?.shopId ?? '',
      isSingleSelect: true,
    );

    if (selectedUsers == null || selectedUsers.isEmpty || !mounted) return;
    final selectedUser = selectedUsers.first;

    // Send the draft (set isDraft to true)
    final success = await orderProvider.sendOrder(
      senderId: authProvider.user!.uid,
      senderName: authProvider.displayName,
      receiverIds: [selectedUser.uid],
      receiverNames: [selectedUser.displayName],
      customerName: _customerNameController.text.trim(),
      shopId: authProvider.appUser?.shopId ?? '',
      isDraft: true,
    );

    if (mounted) {
      if (success) {
        _customerNameController.clear();
        final isAr = context.tr('tab_orders') == 'الطلبيات';
        _showSnackBar(
          isAr 
              ? 'تم إرسال المسودة إلى ${selectedUser.displayName} ✓'
              : 'Draft sent to ${selectedUser.displayName} ✓',
          isError: false,
        );
      } else {
        _showSnackBar(
          orderProvider.error ?? context.tr('failed_send'),
          isError: true,
        );
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: isError ? AppTheme.error : AppTheme.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorSurface : AppTheme.successSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    if (orderProvider.draftCustomerName != _customerNameController.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && orderProvider.draftCustomerName != _customerNameController.text) {
          _customerNameController.text = orderProvider.draftCustomerName;
        }
      });
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Custom TabBar inside NewOrderScreen to toggle between Normal and Quick Order
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppTheme.accentAmber,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: isAr ? 'طلب عادي' : 'Normal Order'),
                  Tab(text: isAr ? 'طلب سريع' : 'Quick Order'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: Normal Order
                _buildNormalOrderTab(context, orderProvider, isAr),
                
                // Tab 2: Quick Order
                _buildQuickOrderTab(context, orderProvider, isAr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalOrderTab(BuildContext context, OrderProvider orderProvider, bool isAr) {
    return Stack(
      children: [
        // ─── Main Content ────────────────────────────────────
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customerNameController,
                          onChanged: (val) {
                            orderProvider.draftCustomerName = val;
                          },
                          decoration: InputDecoration(
                            labelText: context.tr('customer_name') ?? 'اسم الزبون (اختياري)',
                            hintText: context.tr('customer_hint') ?? 'أدخل اسم الزبون',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const VoiceNoteRecorder(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildOrderSummaryCard(context, orderProvider),
                  const SizedBox(height: 16),

                  // Fabric entry cards
                  ...orderProvider.fabricEntries.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FabricEntryCard(
                        key: ValueKey('fabric_${entry.key}'),
                        entryIndex: entry.key,
                        canRemove: orderProvider.fabricEntries.length > 1,
                      ),
                    );
                  }),

                  // Add another fabric button
                  OutlinedButton.icon(
                    onPressed: () => orderProvider.addFabricEntry(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(context.tr('add_another_fabric')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 52),
                      side: BorderSide(
                        color: AppTheme.accentAmber.withValues(alpha: 0.4),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),

        // ─── Send Order Button (Fixed Bottom) ────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(color: AppTheme.borderSubtle),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Send Draft Button (Minimized to icon only)
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: IconButton(
                      onPressed: orderProvider.isSending ? null : _sendDraft,
                      icon: const Icon(Icons.folder_shared_rounded, size: 20),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send Order Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: orderProvider.isSending ? null : _sendOrder,
                      icon: orderProvider.isSending
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.surfaceDark,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        orderProvider.isSending
                            ? context.tr('sending')
                            : context.tr('send_order'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickOrderTab(BuildContext context, OrderProvider orderProvider, bool isAr) {
    return Stack(
      children: [
        // Center Recording UI
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isQuickRecording
                    ? (isAr ? 'جاري التسجيل...' : 'Recording...')
                    : (_hasQuickRecordedAudio
                        ? (isAr ? 'تم تسجيل الرسالة بنجاح' : 'Recording complete')
                        : (isAr ? 'انقر على المايك لبدء الطلب السريع' : 'Tap mic to start Quick Order')),
                style: TextStyle(
                  fontSize: 16,
                  color: _isQuickRecording && !_isQuickPaused
                      ? AppTheme.error
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              
              _buildMicAnimationPill(context, orderProvider, isAr),
            ],
          ),
        ),
        
        // Bottom Send Button (Only shown when recording is complete)
        if (_hasQuickRecordedAudio)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(color: AppTheme.borderSubtle),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: orderProvider.isSending ? null : _sendQuickOrder,
                    icon: orderProvider.isSending
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.surfaceDark,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      orderProvider.isSending
                          ? context.tr('sending')
                          : (isAr ? 'إرسال الطلب السريع' : 'Send Quick Order'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.accentAmber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMicAnimationPill(BuildContext context, OrderProvider orderProvider, bool isAr) {
    final isRecording = _isQuickRecording;
    final pillWidth = isRecording ? 320.0 : (_hasQuickRecordedAudio ? 240.0 : 75.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: const Cubic(0.34, 1.56, 0.64, 1),
          width: pillWidth,
          height: 75.0,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color(0xFF1A1A1A)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 35,
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Delete Button (Left side)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: const Cubic(0.34, 1.56, 0.64, 1),
                left: (isRecording || _hasQuickRecordedAudio) ? 15.0 : 12.5,
                child: AnimatedScale(
                  scale: (isRecording || _hasQuickRecordedAudio) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedOpacity(
                    opacity: (isRecording || _hasQuickRecordedAudio) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: _deleteQuickRecord,
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF2A2A), size: 22),
                      ),
                    ),
                  ),
                ),
              ),

              // Left Waveform (Only visible when recording)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: const Cubic(0.34, 1.56, 0.64, 1),
                left: isRecording ? 72.0 : 12.5,
                child: AnimatedOpacity(
                  opacity: isRecording ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: WaveBar(isRecording: isRecording && !_isQuickPaused),
                ),
              ),

              // Center Action Button (Mic / Stop / Play-Pause)
              GestureDetector(
                onTap: () {
                  if (isRecording) {
                    _stopQuickRecording();
                  } else if (_hasQuickRecordedAudio) {
                    _playPauseQuickPreview();
                  } else {
                    _startQuickRecording();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecording 
                        ? const Color(0xFFFF2A2A) 
                        : (_hasQuickRecordedAudio ? const Color(0xFF10B981) : Colors.white),
                    gradient: isRecording
                        ? const LinearGradient(
                            colors: [Color(0xFFFF2A2A), Color(0xFFD10000)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    boxShadow: [
                      if (isRecording)
                        BoxShadow(
                          color: const Color(0xFFFF2A2A).withOpacity(0.5),
                          blurRadius: 25,
                          spreadRadius: 2,
                        )
                      else if (_hasQuickRecordedAudio && _quickIsPlaying)
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.5),
                          blurRadius: 25,
                          spreadRadius: 2,
                        )
                      else
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                    ],
                  ),
                  child: Icon(
                    isRecording 
                        ? Icons.stop_rounded 
                        : (_hasQuickRecordedAudio 
                            ? (_quickIsPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded) 
                            : Icons.mic_rounded),
                    color: isRecording || _hasQuickRecordedAudio ? Colors.white : Colors.black,
                    size: 32,
                  ),
                ),
              ),

              // Right Waveform (Only visible when recording)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: const Cubic(0.34, 1.56, 0.64, 1),
                right: isRecording ? 72.0 : 12.5,
                child: AnimatedOpacity(
                  opacity: isRecording ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: WaveBar(isRecording: isRecording && !_isQuickPaused),
                ),
              ),

              // Send/Action Button (Right side)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: const Cubic(0.34, 1.56, 0.64, 1),
                right: (isRecording || _hasQuickRecordedAudio) ? 15.0 : 12.5,
                child: AnimatedScale(
                  scale: (isRecording || _hasQuickRecordedAudio) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedOpacity(
                    opacity: (isRecording || _hasQuickRecordedAudio) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: () {
                        if (isRecording) {
                          _stopQuickRecording().then((_) {
                            _sendQuickOrder();
                          });
                        } else if (_hasQuickRecordedAudio) {
                          _sendQuickOrder();
                        }
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Status Area (Dot + Timer)
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          child: (isRecording || _hasQuickRecordedAudio)
              ? Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isRecording && !_isQuickPaused) ...[
                        const BlinkDot(),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _formatDuration(_quickRecordDurationSec),
                        style: const TextStyle(
                          color: Color(0xFFE0E0E0),
                          fontSize: 22,
                          fontFamily: 'Courier New',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, OrderProvider orderProvider) {
    final fabricEntries = orderProvider.fabricEntries;
    final grandTotalRolls = fabricEntries.fold<int>(0, (sum, entry) => sum + entry.sequence.length);

    final totalMeters = fabricEntries
        .where((e) => e.unit == 'meter')
        .fold<double>(0.0, (sum, e) => sum + e.sequence.fold<double>(0.0, (s, val) => s + val));

    final totalKgs = fabricEntries
        .where((e) => e.unit == 'kg')
        .fold<double>(0.0, (sum, e) => sum + e.sequence.fold<double>(0.0, (s, val) => s + val));

    final totalYards = fabricEntries
        .where((e) => e.unit == 'yard')
        .fold<double>(0.0, (sum, e) => sum + e.sequence.fold<double>(0.0, (s, val) => s + val));

    final grandTotalPrice = fabricEntries.fold<double>(
      0.0,
      (sum, entry) {
        final qty = entry.sequence.fold<double>(0.0, (s, val) => s + val);
        return sum + (qty * entry.price);
      },
    );

    final formattedTotalPrice = NumberFormat('#,##0.##', 'en_US').format(grandTotalPrice);
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final currency = isAr ? 'د.ج' : 'DA';

    // Build the quantity text
    List<String> qtyParts = [];
    if (totalMeters > 0) {
      qtyParts.add('${totalMeters.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} m');
    }
    if (totalKgs > 0) {
      qtyParts.add('${totalKgs.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg');
    }
    if (totalYards > 0) {
      qtyParts.add('${totalYards.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} yd');
    }
    String qtyText = qtyParts.isEmpty ? '0' : qtyParts.join(' + ');

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.accentAmber.withValues(alpha: 0.05),
      elevation: 0,
      child: InkWell(
        onTap: () => _showOrderSummaryDetailsSheet(context, orderProvider),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentAmber.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.summarize_rounded,
                    color: AppTheme.accentAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'إجمالي الطلبية' : 'Order Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentAmberLight,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.zoom_in_rounded,
                    size: 16,
                    color: AppTheme.accentAmber.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // Rolls Count
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isAr ? 'اللفات' : 'Rolls',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.layers_rounded, size: 14, color: AppTheme.accentAmber),
                            const SizedBox(width: 4),
                            Text(
                              '$grandTotalRolls',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppTheme.borderSubtle),
                  // Total Quantity
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isAr ? 'إجمالي الكمية' : 'Total Qty',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.straighten_rounded, size: 14, color: AppTheme.accentAmber),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                qtyText,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppTheme.borderSubtle),
                  // Total Price
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isAr ? 'السعر الإجمالي' : 'Total Price',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.monetization_on_rounded, size: 14, color: AppTheme.accentAmber),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$formattedTotalPrice $currency',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderSummaryDetailsSheet(BuildContext context, OrderProvider orderProvider) {
    final fabricEntries = orderProvider.fabricEntries;
    final grandTotalRolls = fabricEntries.fold<int>(0, (sum, entry) => sum + entry.sequence.length);

    final totalMeters = fabricEntries
        .where((e) => e.unit == 'meter')
        .fold<double>(0.0, (sum, e) => sum + e.sequence.fold<double>(0.0, (s, val) => s + val));

    final totalKgs = fabricEntries
        .where((e) => e.unit == 'kg')
        .fold<double>(0.0, (sum, e) => sum + e.sequence.fold<double>(0.0, (s, val) => s + val));

    final totalYards = fabricEntries
        .where((e) => e.unit == 'yard')
        .fold<double>(0.0, (sum, e) => sum + e.sequence.fold<double>(0.0, (s, val) => s + val));

    final grandTotalPrice = fabricEntries.fold<double>(
      0.0,
      (sum, entry) {
        final qty = entry.sequence.fold<double>(0.0, (s, val) => s + val);
        return sum + (qty * entry.price);
      },
    );

    final formattedTotalPrice = NumberFormat('#,##0.##', 'en_US').format(grandTotalPrice);
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    final currency = isAr ? 'د.ج' : 'DA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'تفاصيل إجمالي الطلبية' : 'Order Summary Details',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(isAr ? 'الأنواع' : 'Types', '${fabricEntries.where((e) => e.fabricType.isNotEmpty).length}', Icons.texture_rounded),
                        _buildMetricCol(isAr ? 'اللفات' : 'Rolls', '$grandTotalRolls', Icons.layers_rounded),
                        if (totalMeters > 0)
                          _buildMetricCol(isAr ? 'المجموع (م)' : 'Total (m)', '${totalMeters.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} m', Icons.straighten_rounded),
                        if (totalKgs > 0)
                          _buildMetricCol(isAr ? 'المجموع (كغ)' : 'Total (kg)', '${totalKgs.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg', Icons.scale_rounded),
                        if (totalYards > 0)
                          _buildMetricCol(isAr ? 'المجموع (يارد)' : 'Total (yd)', '${totalYards.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} yd', Icons.straighten_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isAr ? 'تفاصيل كل قماش:' : 'Fabric Breakdown:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: fabricEntries.length,
                      itemBuilder: (context, idx) {
                        final entry = fabricEntries[idx];
                        if (entry.fabricType.isEmpty) return const SizedBox.shrink();

                        final totalQty = entry.sequence.fold(0.0, (sum, val) => sum + val);
                        final totalPrice = totalQty * entry.price;
                        final formattedSubtotal = NumberFormat('#,##0.##', 'en_US').format(totalPrice);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.fabricType,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${entry.price.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${entry.unit == 'kg' ? 'DA/kg' : 'DA/m'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.accentAmber,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (entry.sequence.isNotEmpty) ...[
                                Text(
                                  '${isAr ? "اللفات" : "Rolls"} (${entry.sequence.length}):',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: (entry.lengths.entries.toList()..sort((a, b) {
                                    final double valA = double.tryParse(a.key) ?? 0.0;
                                    final double valB = double.tryParse(b.key) ?? 0.0;
                                    return valB.compareTo(valA);
                                  })).map((e) {
                                    final displayVal = double.tryParse(e.key);
                                    final displayStr = displayVal != null && displayVal == displayVal.roundToDouble()
                                        ? displayVal.toInt().toString()
                                        : e.key;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.borderSubtle),
                                      ),
                                      child: Text(
                                        e.value > 1 ? '$displayStr ×${e.value}' : displayStr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${isAr ? "الكمية:" : "Quantity:"} ${totalQty.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${entry.unit == 'kg' ? "kg" : "m"}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${isAr ? "المجموع:" : "Subtotal:"} $formattedSubtotal $currency',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentAmberLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'الإجمالي الكلي:' : 'Grand Total:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$formattedTotalPrice $currency',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCol(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}

class WaveBar extends StatefulWidget {
  final bool isRecording;
  const WaveBar({super.key, required this.isRecording});

  @override
  State<WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<WaveBar> {
  final List<double> _heights = [4.0, 4.0, 4.0, 4.0];
  Timer? _timer;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.isRecording) {
      _startAnim();
    }
  }

  void _startAnim() {
    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < 4; i++) {
            _heights[i] = _random.nextDouble() * 24.0 + 4.0;
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(WaveBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _startAnim();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _timer?.cancel();
      setState(() {
        _heights.fillRange(0, 4, 4.0);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _heights.map((h) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 4,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFF2A2A),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }
}

class BlinkDot extends StatefulWidget {
  const BlinkDot({super.key});

  @override
  State<BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<BlinkDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFFF2A2A),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
