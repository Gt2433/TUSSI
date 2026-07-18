import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/order_provider.dart';
import '../providers/language_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'length_button.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

/// Summary card widget for building a single fabric entry within an order.
/// Tap opens the full editor sheet to set details, lengths, and quick-select buttons.
class FabricEntryCard extends StatefulWidget {
  final int entryIndex;
  final bool canRemove;

  const FabricEntryCard({
    super.key,
    required this.entryIndex,
    this.canRemove = false,
  });

  @override
  State<FabricEntryCard> createState() => _FabricEntryCardState();
}

class _FabricEntryCardState extends State<FabricEntryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openEditorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _FabricEditorSheet(
          entryIndex: widget.entryIndex,
          canRemove: widget.canRemove,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final entry = widget.entryIndex < provider.fabricEntries.length
        ? provider.fabricEntries[widget.entryIndex]
        : null;

    if (entry == null) return const SizedBox.shrink();

    final totalQuantity = entry.sequence.fold(0.0, (sum, val) => sum + val);
    final totalPrice = totalQuantity * entry.price;
    final formattedPrice = NumberFormat('#,##0.##', 'en_US').format(totalPrice);
    final isAr = Provider.of<LanguageProvider>(context, listen: false).language == AppLanguage.ar;
    final currency = isAr ? 'د.ج' : 'DA';

    final hasFabric = entry.fabricType.isNotEmpty;
    final rollsCount = entry.sequence.length;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          onTap: () => _openEditorSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon / Index Badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasFabric
                        ? AppTheme.accentAmber.withValues(alpha: 0.12)
                        : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${widget.entryIndex + 1}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: hasFabric ? AppTheme.accentAmber : AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Summary details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasFabric ? entry.fabricType : context.tr('select_fabric_type'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: hasFabric ? AppTheme.textPrimary : AppTheme.textMuted,
                          fontStyle: hasFabric ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (hasFabric) ...[
                        Text(
                          '$rollsCount ${isAr ? "لفات" : "rolls"} • '
                          '${totalQuantity.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}${entry.unit == 'kg' ? ' kg' : ' m'} • '
                          '$formattedPrice $currency',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Text(
                          isAr ? 'انقر لتهيئة القماش والأطوال' : 'Tap to set fabric and lengths',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Edit Button Icon
                Icon(
                  Icons.edit_note_rounded,
                  color: AppTheme.accentAmber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                // Delete/Clear Button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    size: 20,
                  ),
                  onPressed: () {
                    if (widget.canRemove) {
                      provider.removeFabricEntry(widget.entryIndex);
                    } else {
                      provider.clearEntryLengths(widget.entryIndex);
                      provider.updateFabricType(widget.entryIndex, '', 'meter', 0.0);
                    }
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.errorSurface,
                    padding: const EdgeInsets.all(6),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal Sheet representing the full Editor for a single fabric entry.
class _FabricEditorSheet extends StatefulWidget {
  final int entryIndex;
  final bool canRemove;

  const _FabricEditorSheet({
    required this.entryIndex,
    required this.canRemove,
  });

  @override
  State<_FabricEditorSheet> createState() => _FabricEditorSheetState();
}

class _FabricEditorSheetState extends State<_FabricEditorSheet> {
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  Stream<List<FabricType>>? _fabricTypesStream;
  Stream<List<double>>? _savedLengthsStream;
  String? _lastFabricType;
  String? _shopId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      if (widget.entryIndex < provider.fabricEntries.length) {
        final entry = provider.fabricEntries[widget.entryIndex];
        if (entry.fabricType.isNotEmpty) {
          _priceController.text = entry.price.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
        }
      }
    });
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addLength(OrderProvider provider, double length) {
    final shopId = Provider.of<app_auth.AuthProvider>(context, listen: false).appUser?.shopId ?? '';
    provider.addLengthToEntry(widget.entryIndex, length, shopId);
  }

  void _addManualLength(OrderProvider provider) {
    final text = _lengthController.text.trim();
    if (text.isEmpty) return;

    final length = double.tryParse(text);
    if (length == null || length <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('valid_positive_number'))),
      );
      return;
    }

    _addLength(provider, length);
    _lengthController.clear();
  }

  void _showSearchableFabricPicker(
    BuildContext context,
    List<FabricType> fabricTypes,
    FabricEntry entry,
    OrderProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredTypes = fabricTypes.where((type) {
              return type.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            final isAr = Provider.of<LanguageProvider>(context, listen: false).language == AppLanguage.ar;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('select_fabric_type'),
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
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: context.tr('search_fabric'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: filteredTypes.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                isAr ? 'لم يتم العثور على أقمشة' : 'No fabrics found',
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredTypes.length,
                            itemBuilder: (context, idx) {
                              final type = filteredTypes[idx];
                              final isSelected = type.name == entry.fabricType;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                title: Text(
                                  type.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.accentAmber : AppTheme.textPrimary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(isAr ? 'حذف القماش' : 'Delete Fabric'),
                                            content: Text(isAr 
                                                ? 'هل أنت متأكد من حذف نوع القماش "${type.name}" نهائياً من قاعدة البيانات؟' 
                                                : 'Are you sure you want to delete fabric "${type.name}" permanently from the database?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                child: Text(isAr ? 'إلغاء' : 'Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.of(ctx).pop(true),
                                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                                child: Text(isAr ? 'حذف' : 'Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          final shopId = Provider.of<app_auth.AuthProvider>(context, listen: false).appUser?.shopId ?? '';
                                          await _firestoreService.deleteFabricType(type.name, shopId);
                                          // Update state
                                          setState(() {
                                            fabricTypes.removeWhere((t) => t.name == type.name);
                                          });
                                        }
                                      },
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded, color: AppTheme.accentAmber),
                                  ],
                                ),
                                onTap: () {
                                  provider.updateFabricType(
                                    widget.entryIndex,
                                    type.name,
                                    type.unit,
                                    type.price,
                                  );
                                  _priceController.text = type.price
                                      .toStringAsFixed(1)
                                      .replaceAll(RegExp(r'\.0$'), '');
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final entry = widget.entryIndex < provider.fabricEntries.length
        ? provider.fabricEntries[widget.entryIndex]
        : null;

    if (entry == null) return const SizedBox.shrink();

    // Lazily initialize streams to avoid recreating Firestore listeners on every keystroke
    if (_shopId == null) {
      _shopId = Provider.of<app_auth.AuthProvider>(context, listen: false).appUser?.shopId ?? '';
      _fabricTypesStream = _firestoreService.streamFabricTypes(_shopId!);
    }

    if (entry.fabricType != _lastFabricType) {
      _lastFabricType = entry.fabricType;
      _savedLengthsStream = _firestoreService.streamSavedLengthsForFabric(_lastFabricType!, _shopId!);
    }

    return StreamBuilder<List<FabricType>>(
      stream: _fabricTypesStream,
      builder: (context, snapshot) {
        final fabricTypes = snapshot.data ?? [];
        final isAr = Provider.of<LanguageProvider>(context, listen: false).language == AppLanguage.ar;

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.texture_rounded,
                        color: AppTheme.accentAmber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${context.tr('fabric')} ${widget.entryIndex + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Fabric Type Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('fabric_type'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showSearchableFabricPicker(
                              context,
                              fabricTypes,
                              entry,
                              provider,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                hintText: context.tr('select_fabric_type'),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                suffixIcon: Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: AppTheme.textSecondary,
                                  size: 28,
                                ),
                              ),
                              isEmpty: entry.fabricType.isEmpty,
                              child: Text(
                                entry.fabricType,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: entry.fabricType.isNotEmpty
                                      ? AppTheme.textPrimary
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _AddFabricTypeButton(
                          firestoreService: _firestoreService,
                          entryIndex: widget.entryIndex,
                          priceController: _priceController,
                          shopId: Provider.of<app_auth.AuthProvider>(context, listen: false).appUser?.shopId ?? '',
                        ),
                      ],
                    ),
                    if (entry.fabricType.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        isAr ? 'سعر القماش لهذه الطلبية' : 'Fabric price for this order',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: isAr ? 'أدخل سعر مخصص' : 'Enter custom price',
                          suffixText: entry.unit == 'kg' ? 'DA/kg' : 'DA/m',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (val) {
                          final parsedPrice = double.tryParse(val) ?? 0.0;
                          provider.updateFabricPrice(widget.entryIndex, parsedPrice);
                        },
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // Length / Weight Input
                Text(
                  entry.unit == 'kg'
                      ? context.tr('kg_weight_roll')
                      : context.tr('meters_roll_length'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lengthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: entry.unit == 'kg'
                              ? context.tr('enter_weight_hint')
                              : context.tr('enter_length_hint'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _addManualLength(provider),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _addManualLength(provider),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      child: const Icon(Icons.add_rounded, size: 22),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quick-Select Length/Weight Buttons
                StreamBuilder<List<double>>(
                  stream: _savedLengthsStream,
                  builder: (context, snapshot) {
                    final savedLengths = snapshot.data ?? [];

                    if (savedLengths.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          context.tr('write_length_quick'),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('saved_lengths'),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: savedLengths.map((length) {
                            final key = length.toStringAsFixed(1);
                            final multiplier = entry.lengths[key] ?? 0;

                            return LengthButton(
                              length: length,
                              unit: entry.unit,
                              multiplier: multiplier,
                              onTap: () => _addLength(provider, length),
                              onLongPress: () {
                                if (multiplier > 0) {
                                  provider.removeLengthFromEntry(
                                      widget.entryIndex, length);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),

                // Selected Lengths Summary
                if (entry.lengths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentAmber.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('selected_lengths'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.accentAmber,
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  provider.clearEntryLengths(widget.entryIndex),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 14,
                                    color: AppTheme.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.tr('clear_lengths'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: (entry.lengths.entries.toList()..sort((a, b) {
                            final double valA = double.tryParse(a.key) ?? 0.0;
                            final double valB = double.tryParse(b.key) ?? 0.0;
                            return valB.compareTo(valA);
                          })).map((e) {
                            final displayLength = double.tryParse(e.key);
                            final lengthText = displayLength != null &&
                                    displayLength ==
                                        displayLength.roundToDouble()
                                ? displayLength.toInt().toString()
                                : e.key;
                            final displayLengthText = lengthText;

                            return Text(
                              e.value > 1
                                  ? '$displayLengthText ×${e.value}'
                                  : displayLengthText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                // Calculations Summary
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final totalQuantity = entry.sequence.fold(0.0, (sum, val) => sum + val);
                    final totalPrice = totalQuantity * entry.price;
                    final formattedPrice = NumberFormat('#,##0.##', 'en_US').format(totalPrice);
                    final currency = Provider.of<LanguageProvider>(context, listen: false).language == AppLanguage.ar ? 'د.ج' : 'DA';

                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  context.tr('rolls_count'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.layers_rounded,
                                        size: 14,
                                        color: AppTheme.accentAmber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${entry.sequence.length}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  context.tr('total_quantity'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.straighten_rounded,
                                        size: 14,
                                        color: AppTheme.accentAmber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${totalQuantity.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}${entry.unit == 'kg' ? ' kg' : ' m'}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  context.tr('total_price'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.monetization_on_rounded,
                                        size: 14,
                                        color: AppTheme.accentAmber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$formattedPrice $currency',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Input Sequence list
                if (entry.sequence.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    context.tr('input_sequence'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: entry.sequence.length,
                      itemBuilder: (context, idx) {
                        final val = entry.sequence[idx];
                        final isLast = idx == entry.sequence.length - 1;
                        final displayLength = val == val.roundToDouble() ? val.toInt().toString() : val.toString();

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isLast
                                    ? AppTheme.accentAmber
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isLast
                                      ? AppTheme.accentAmber
                                      : AppTheme.borderSubtle,
                                  width: isLast ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '#${idx + 1}: ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isLast ? AppTheme.surfaceDark : AppTheme.textMuted,
                                    ),
                                  ),
                                  Text(
                                    displayLength,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isLast ? AppTheme.surfaceDark : AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (isLast) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceDark.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        context.tr('last_added'),
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.surfaceDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!isLast) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Done / Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentAmber,
                      foregroundColor: AppTheme.surfaceDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isAr ? 'تأكيد وحفظ' : 'Confirm & Save',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small button to add a new fabric type to Firestore
class _AddFabricTypeButton extends StatelessWidget {
  final FirestoreService firestoreService;
  final int entryIndex;
  final TextEditingController priceController;
  final String shopId;

  const _AddFabricTypeButton({
    required this.firestoreService,
    required this.entryIndex,
    required this.priceController,
    required this.shopId,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.add_circle_outline_rounded,
        color: AppTheme.accentAmber,
        size: 28,
      ),
      onPressed: () => _showAddDialog(context),
      tooltip: context.tr('add_new_fabric_type'),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        String? localUnit;
        String? validationError;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.tr('add_new_fabric_type')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: context.tr('fabric_type_name'),
                      ),
                      onChanged: (_) {
                        if (validationError != null) {
                          setState(() {
                            validationError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: context.tr('fabric_price'),
                      ),
                      onChanged: (_) {
                        if (validationError != null) {
                          setState(() {
                            validationError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      context.tr('unit_choice'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: Text(context.tr('meter_label')),
                      value: 'meter',
                      groupValue: localUnit,
                      activeColor: AppTheme.accentAmber,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          localUnit = val;
                          validationError = null;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(context.tr('kg_label')),
                      value: 'kg',
                      groupValue: localUnit,
                      activeColor: AppTheme.accentAmber,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          localUnit = val;
                          validationError = null;
                        });
                      },
                    ),
                    if (validationError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        validationError!,
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final priceText = priceController.text.trim();
                    if (name.isEmpty) {
                      setState(() {
                        validationError = context.tr('fabric_name_required');
                      });
                      return;
                    }
                    if (priceText.isEmpty) {
                      setState(() {
                        validationError = context.tr('fabric_price_required');
                      });
                      return;
                    }
                    final price = double.tryParse(priceText);
                    if (price == null || price <= 0) {
                      setState(() {
                        validationError = context.tr('invalid_price');
                      });
                      return;
                    }
                    if (localUnit == null) {
                      setState(() {
                        validationError = context.tr('required_unit');
                      });
                      return;
                    }
                    firestoreService.addFabricType(name, localUnit!, price, shopId);

                    
                    // Directly select the newly created fabric in the current entry
                    final provider = Provider.of<OrderProvider>(context, listen: false);
                    provider.updateFabricType(entryIndex, name, localUnit!, price);
                    
                    // Directly update the parent's price controller!
                    priceController.text = price.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
                    
                    Navigator.of(ctx).pop();
                  },
                  child: Text(context.tr('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
