import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';

class HelpGuideScreen extends StatefulWidget {
  const HelpGuideScreen({super.key});

  @override
  State<HelpGuideScreen> createState() => _HelpGuideScreenState();
}

class _HelpGuideScreenState extends State<HelpGuideScreen> {
  int _activeCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';
    
    final categories = [
      {
        'title': isAr ? 'الطلب الجديد' : 'New Order',
        'icon': Icons.add_task_rounded,
      },
      {
        'title': isAr ? 'الطلب الصوتي السريع' : 'Voice Quick Order',
        'icon': Icons.mic_rounded,
      },
      {
        'title': isAr ? 'إدارة الأقمشة' : 'Fabric Management',
        'icon': Icons.layers_outlined,
      },
      {
        'title': isAr ? 'المظهر الذكي واللغات' : 'Smart Theme & Lang',
        'icon': Icons.style_rounded,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'دليل الاستخدام التفاعلي' : 'Interactive User Guide'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Premium category selector tabs
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = _activeCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 16,
                          color: isSelected ? AppTheme.surfaceDark : AppTheme.accentAmber,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isSelected ? AppTheme.surfaceDark : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.accentAmber,
                    backgroundColor: AppTheme.surfaceCard,
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : AppTheme.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _activeCategoryIndex = index;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          
          // Main Content Container
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCategoryContent(_activeCategoryIndex, isAr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(int index, bool isAr) {
    switch (index) {
      case 0:
        return _buildNewOrderGuide(isAr);
      case 1:
        return _buildVoiceOrderGuide(isAr);
      case 2:
        return _buildFabricGuide(isAr);
      case 3:
        return _buildThemeLangGuide(isAr);
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. New Order Category
  Widget _buildNewOrderGuide(bool isAr) {
    return ListView(
      key: const ValueKey('new_order_guide'),
      padding: const EdgeInsets.all(16),
      children: [
        _buildInstructionCard(
          title: isAr ? 'دليل الإرسال من الصفر (خمس خطوات)' : 'Step-by-step Guide from Scratch',
          description: isAr
              ? 'تعلّم كيف تقوم بإنشاء طلبية جديدة وإرسالها بالكامل في ثوانٍ معدودة:'
              : 'Learn how to create and send a complete order from scratch in seconds:',
          visual: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepRow(
                stepNum: '1',
                title: isAr ? 'انتقل إلى تبويب "طلب جديد"' : 'Go to "New Order" tab',
                desc: isAr ? 'انقر على أيقونة الإضافة في الشريط السفلي للتطبيق.' : 'Tap the plus/add icon in the bottom navigation bar.',
                icon: Icons.add_box_rounded,
              ),
              _buildStepLine(),
              _buildStepRow(
                stepNum: '2',
                title: isAr ? 'اختر أو أضف نوع القماش' : 'Select or add fabric type',
                desc: isAr ? 'اختر القماش من القائمة، أو انقر (+) لإضافة قماش جديد وسعره.' : 'Select fabric, or click (+) to add a new type and its price.',
                icon: Icons.add_circle_outline_rounded,
              ),
              _buildStepLine(),
              _buildStepRow(
                stepNum: '3',
                title: isAr ? 'أدخل أطوال الأمتار' : 'Key in the lengths',
                desc: isAr ? 'استخدم الأزرار السريعة أو لوحة المفاتيح لإدخال الأمتار ثم انقر حفظ.' : 'Use quick buttons or key in meters, then click save.',
                icon: Icons.edit_note_rounded,
              ),
              _buildStepLine(),
              _buildStepRow(
                stepNum: '4',
                title: isAr ? 'انقر على "إرسال الطلب"' : 'Tap "Send Order"',
                desc: isAr ? 'اضغط على زر الإرسال الطويل أسفل الشاشة للمتابعة.' : 'Click the long send button at the bottom of the screen.',
                icon: Icons.send_rounded,
              ),
              _buildStepLine(),
              _buildStepRow(
                stepNum: '5',
                title: isAr ? 'اختر المستلم وأرسل الطلب' : 'Select recipient and send',
                desc: isAr ? 'ابحث عن اسم العميل/المستودع في قائمة الأسماء وانقر فوقه للإرسال فوراً.' : 'Search user or warehouse name in the list, then tap to send instantly.',
                icon: Icons.person_search_rounded,
              ),
            ],
          ),
        ),
        _buildInstructionCard(
          title: isAr ? '1. إضافة وحساب الأمتار' : '1. Add and Calculate Meters',
          description: isAr 
              ? 'اضغط على زر الإضافة الدائري لاختيار القماش، ثم انقر على أزرار الأطوال السريعة لحساب إجمالي الأمتار فوراً.'
              : 'Tap the circular add button to select a fabric, then click the quick length buttons to calculate total meters instantly.',
          visual: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: AppTheme.accentAmber, size: 24),
                    const SizedBox(width: 8),
                    Text(isAr ? 'إضافة قماش' : 'Add Fabric', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, color: AppTheme.textMuted),
              const SizedBox(width: 12),
              _buildMockChip('30 +'),
              const SizedBox(width: 6),
              _buildMockChip('50 +'),
            ],
          ),
        ),
        _buildInstructionCard(
          title: isAr ? '2. التراجع الفوري واسترجاع الأمتار' : '2. Instant Undo & Restoration',
          description: isAr 
              ? 'إذا قمت بمسح الأمتار أو حذف كرت قماش بالخطأ، سيظهر زر استرجاع الأمتار أو زر تراجع في شريط التنبيهات فوراً لاستعادة حساباتك بنقرة واحدة.'
              : 'If you accidentally clear lengths or delete a fabric card, a "Restore Lengths" button or "Undo" snackbar will appear immediately to recover your numbers in one tap.',
          visual: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.undo_rounded, color: AppTheme.accentAmber, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isAr ? 'استرجاع الأمتار' : 'Restore Lengths',
                      style: TextStyle(fontSize: 12, color: AppTheme.accentAmber, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildInstructionCard(
          title: isAr ? '3. زر تفريغ الأمتار والمسح الآمن' : '3. Safe Clearing Button',
          description: isAr 
              ? 'تم تصغير زر مسح الأطوال إلى أيقونة تحديث صغيرة لتفادي الضغط بالخطأ عند إدخال الطلبية.'
              : 'The clear lengths button has been minimized to a small refresh icon to prevent accidental triggers while building the order.',
          visual: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Icon(Icons.refresh_rounded, color: AppTheme.textMuted, size: 18),
          ),
        ),
        _buildInstructionCard(
          title: isAr ? '4. زر أرسل المسودة الأيقوني (البرتقالي)' : '4. Orange Send Draft Button',
          description: isAr
              ? 'بجانب زر إرسال الطلب، تجد زراً برتقالياً صغيراً يحمل أيقونة الملف (📁). اضغط عليه لحفظ وإرسال الطلبية كمسودة معلقة (Draft) إلى مدير المحل أو العمال، لمراجعتها واستئنافها لاحقاً.'
              : 'Next to the "Send Order" button, there is a small orange button with a folder icon (📁). Tap it to save and send the order as a draft to the manager or staff, to be reviewed or resumed later.',
          visual: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_shared_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // 2. Voice Order Category
  Widget _buildVoiceOrderGuide(bool isAr) {
    return ListView(
      key: const ValueKey('voice_order_guide'),
      padding: const EdgeInsets.all(16),
      children: [
        _buildInstructionCard(
          title: isAr ? '1. تسجيل الطلب الصوتي' : '1. Record Voice Order',
          description: isAr 
              ? 'اضغط مطولاً على زر الميكروفون لتسجيل مواصفات الطلب بدلاً من الكتابة اليدوية.'
              : 'Hold down the microphone button to dictate the order parameters instead of manual typing.',
          visual: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
          ),
        ),
        _buildInstructionCard(
          title: isAr ? '2. التشغيل الذكي والإيقاف المؤقت' : '2. Smart Resume after Pause',
          description: isAr 
              ? 'عند إيقاف المقطع الصوتي مؤقتاً، يمكنك إعادة تشغيله ليكمل من نفس النقطة التي توقف عندها دون البدء من الأول.'
              : 'When you pause the voice clip, pressing play again will resume from that exact second rather than resetting to the beginning.',
          visual: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMockIconButton(Icons.play_arrow_rounded, Colors.green),
              const SizedBox(width: 12),
              _buildMockIconButton(Icons.pause_rounded, AppTheme.accentAmber),
            ],
          ),
        ),
        _buildInstructionCard(
          title: isAr ? '3. تسريع المقطع الصوتي' : '3. Audio Speed Adjustment',
          description: isAr 
              ? 'اضغط على أزرار السرعة لتسريع تشغيل الصوت وسماع تفاصيل الطلبية بوقت أقل (مثل 1.3x أو 1.5x أو 2.0x).'
              : 'Tap speed chips to accelerate audio playback and listen to order voice notes faster (such as 1.3x, 1.5x, or 2.0x).',
          visual: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMockSpeedChip('1x', false),
              const SizedBox(width: 8),
              _buildMockSpeedChip('1.3x', true),
              const SizedBox(width: 8),
              _buildMockSpeedChip('1.5x', false),
              const SizedBox(width: 8),
              _buildMockSpeedChip('2.0x', false),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Fabric Management Category
  Widget _buildFabricGuide(bool isAr) {
    return ListView(
      key: const ValueKey('fabric_guide'),
      padding: const EdgeInsets.all(16),
      children: [
        _buildInstructionCard(
          title: isAr ? '1. إضافة قماش من الإعدادات' : '1. Add Fabric from Settings',
          description: isAr 
              ? 'اذهب للإعدادات واضغط "إجراءات القماش السريعة" ثم "إضافة قماش جديد" لتسجيل قماش جديد وسعره لكي يظهر لكافة العمال تلقائياً.'
              : 'Go to Settings -> Fabric Actions and tap "Add New Fabric" to quickly list a fabric type with its price to all devices.',
          visual: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: AppTheme.accentAmber, size: 20),
                    const SizedBox(width: 8),
                    Text(isAr ? 'إضافة قماش جديد' : 'Add New Fabric', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildInstructionCard(
          title: isAr ? '2. تعديل الاسم، السعر، والحذف السريع' : '2. Edit Name, Price & Delete',
          description: isAr 
              ? 'من خلال "إجراءات القماش السريعة" بالإعدادات، يمكنك بسهولة تعديل وتحديث أسعار الأقمشة، تعديل المسميات، أو إزالة قماش من النظام.'
              : 'Through the "Fabric Quick Actions" menu in settings, you can easily adjust fabric pricing, modify names, or remove products.',
          visual: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMockActionIcon(Icons.drive_file_rename_outline_rounded, isAr ? 'تعديل الاسم' : 'Rename'),
              const SizedBox(width: 12),
              _buildMockActionIcon(Icons.edit_note_rounded, isAr ? 'تعديل السعر' : 'Edit Price'),
              const SizedBox(width: 12),
              _buildMockActionIcon(Icons.texture_rounded, isAr ? 'حذف القماش' : 'Delete', isDanger: true),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Smart Theme & Language Category
  Widget _buildThemeLangGuide(bool isAr) {
    return ListView(
      key: const ValueKey('theme_lang_guide'),
      padding: const EdgeInsets.all(16),
      children: [
        _buildInstructionCard(
          title: isAr ? '1. الوضع التلقائي الذكي' : '1. Smart Scheduler Theme',
          description: isAr 
              ? 'قم بتفعيل "الوضع الذكي التلقائي" وحدد وقت شروق الشمس وغروبها، ليقوم التطبيق بالتحول للوضع المضيء نهاراً والوضع المظلم ليلاً تلقائياً.'
              : 'Enable "Smart Auto Mode" and pick custom morning/evening hours so the app adjusts between light and dark themes on schedule automatically.',
          visual: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    Text(isAr ? 'بدء المضيء ☀️' : 'Light starts ☀️', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    const Text('06:00 AM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.swap_horiz_rounded, color: AppTheme.accentAmber),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    Text(isAr ? 'بدء المظلم 🌙' : 'Dark starts 🌙', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    const Text('06:00 PM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildInstructionCard(
          title: isAr ? '2. دعم متعدد اللغات (5 لغات)' : '2. Language Selection (5 Languages)',
          description: isAr 
              ? 'يدعم التطبيق خمس لغات رئيسية: العربية، الإنجليزية، الفرنسية، الإسبانية، والصينية. اختر لغتك المفضلة واضغط حفظ.'
              : 'The app natively supports 5 major languages: Arabic, English, French, Spanish, and Chinese. Select your lang and click Save.',
          visual: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMockLangBadge('العربية'),
              const SizedBox(width: 6),
              _buildMockLangBadge('Français'),
              const SizedBox(width: 6),
              _buildMockLangBadge('中文 (Chinese)'),
            ],
          ),
        ),
        _buildInstructionCard(
          title: isAr ? '3. تشغيل وضع الأوفلاين (دون اتصال)' : '3. Offline Mode & Syncing',
          description: isAr
              ? 'عند انقطاع الإنترنت أو الكهرباء، انقر على أيقونة الشبكة بالأعلى للتحويل للوضع دون اتصال. يمكنك تسجيل طلباتك وحفظها محلياً، وعند عودة الشبكة، أوقف الأوفلاين واضغط "مزامنة الآن" لرفعها للسيرفر فوراً.'
              : 'When internet or power goes out, tap the status icon in the App Bar to switch to Offline mode. You can write and save orders locally. Once connection is restored, disable offline mode and click "Sync Now" to upload everything.',
          visual: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isAr ? 'الوضع دون اتصال نشط 🔴' : 'Offline Mode Active 🔴',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Visual Helper Widgets
  Widget _buildInstructionCard({
    required String title,
    required String description,
    required Widget visual,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.accentAmber,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Center(child: visual),
        ],
      ),
    );
  }

  Widget _buildMockChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildMockIconButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildMockSpeedChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.accentAmber : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.surfaceDark : AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMockActionIcon(IconData icon, String label, {bool isDanger = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDanger ? AppTheme.error.withValues(alpha: 0.1) : AppTheme.accentAmber.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDanger ? AppTheme.error : AppTheme.accentAmber, size: 18),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildMockLangBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildStepRow({
    required String stepNum,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.accentAmber,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNum,
            style: TextStyle(
              color: AppTheme.surfaceDark,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: AppTheme.accentAmber),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 11, top: 4, bottom: 4),
      width: 2,
      height: 18,
      color: AppTheme.borderSubtle,
    );
  }
}
