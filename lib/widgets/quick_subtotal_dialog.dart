import 'dart:collection';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<void> showQuickSubtotalDialog({
  required BuildContext context,
  required String fabricType,
  required String unit,
  required double price,
  required List<double> sequence,
}) async {
  if (sequence.isEmpty) return;

  final isAr = Localizations.localeOf(context).languageCode == 'ar';

  await showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surfaceDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _QuickSubtotalSheet(
      fabricType: fabricType,
      unit: unit,
      price: price,
      sequence: sequence,
      isAr: isAr,
    ),
  );
}

class _QuickSubtotalSheet extends StatefulWidget {
  final String fabricType;
  final String unit;
  final double price;
  final List<double> sequence;
  final bool isAr;

  const _QuickSubtotalSheet({
    required this.fabricType,
    required this.unit,
    required this.price,
    required this.sequence,
    required this.isAr,
  });

  @override
  State<_QuickSubtotalSheet> createState() => _QuickSubtotalSheetState();
}

class _QuickSubtotalSheetState extends State<_QuickSubtotalSheet> {
  late Set<int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    final total = widget.sequence.length;
    final defaultCount = total > 5 ? 5 : total;
    _selectedIndices = SplayTreeSet.from(
      List.generate(defaultCount, (i) => total - 1 - i),
    );
  }

  void _selectLastNRolls(int n) {
    final total = widget.sequence.length;
    final count = n.clamp(1, total);
    setState(() {
      _selectedIndices = SplayTreeSet.from(
        List.generate(count, (i) => total - 1 - i),
      );
    });
  }

  void _selectAllRolls() {
    setState(() {
      _selectedIndices = SplayTreeSet.from(
        List.generate(widget.sequence.length, (i) => i),
      );
    });
  }

  bool _isLastN(int n) {
    final total = widget.sequence.length;
    if (total < n) return false;
    for (int i = 0; i < n; i++) {
      if (!_selectedIndices.contains(total - 1 - i)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final totalRolls = widget.sequence.length;
    final totalAllQty = widget.sequence.fold(0.0, (sum, v) => sum + v);

    double subtotalQty = 0.0;
    for (final idx in _selectedIndices) {
      if (idx >= 0 && idx < widget.sequence.length) {
        subtotalQty += widget.sequence[idx];
      }
    }
    final subtotalPrice = subtotalQty * widget.price;
    final percentage = totalAllQty > 0 ? (subtotalQty / totalAllQty * 100) : 0.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.calculate_rounded, color: AppTheme.accentAmber, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isAr ? 'حساب مجموع جزئي للأسطوانات' : 'Roll Subtotal Calculator',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              widget.fabricType,
                              style: TextStyle(fontSize: 12, color: AppTheme.accentAmber),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Preset Buttons
            Text(
              widget.isAr ? 'اختيار سريع لأحدث الأسطوانات:' : 'Quick select recent rolls:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PresetChip(
                    label: widget.isAr ? 'أحدث 3 أسطوانات' : 'Last 3',
                    selected: _selectedIndices.length == 3 && _isLastN(3),
                    onTap: () => _selectLastNRolls(3),
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: widget.isAr ? 'أحدث 5 أسطوانات' : 'Last 5',
                    selected: _selectedIndices.length == 5 && _isLastN(5),
                    onTap: () => _selectLastNRolls(5),
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: widget.isAr ? 'أحدث 10 أسطوانات' : 'Last 10',
                    selected: _selectedIndices.length == 10 && _isLastN(10),
                    onTap: () => _selectLastNRolls(10),
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: widget.isAr ? 'كل الأسطوانات ($totalRolls)' : 'All ($totalRolls)',
                    selected: _selectedIndices.length == totalRolls,
                    onTap: _selectAllRolls,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rolls Selection List
            Text(
              widget.isAr
                  ? 'تسلسل الأسطوانات المحددة (${_selectedIndices.length} من أصل $totalRolls):'
                  : 'Selected rolls (${_selectedIndices.length} of $totalRolls):',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(totalRolls, (idx) {
                    final isSelected = _selectedIndices.contains(idx);
                    final val = widget.sequence[idx];
                    final displayVal = val == val.roundToDouble() ? val.toInt().toString() : val.toString();
                    final isLastAdded = idx == totalRolls - 1;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIndices.remove(idx);
                          } else {
                            _selectedIndices.add(idx);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accentAmber : AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentAmber : AppTheme.borderSubtle,
                          ),
                        ),
                        child: Text(
                          '#${idx + 1}: $displayVal${isLastAdded ? ' ★' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.surfaceDark : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Result Display Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentAmber.withValues(alpha: 0.15),
                    AppTheme.surfaceCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isAr ? 'عدد الأسطوانات المحددة:' : 'Selected Rolls:',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      Text(
                        '${_selectedIndices.length} ${widget.isAr ? 'أسطوانة/ثوب' : 'rolls'}',
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isAr ? 'مجموع أمتار/كمية الـ ${_selectedIndices.length} أسطوانات:' : 'Subtotal Meters/Qty:',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      Text(
                        '${subtotalQty.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${widget.unit}',
                        style: TextStyle(color: AppTheme.accentAmberLight, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  if (widget.price > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isAr ? 'إجمالي السعر لهذا العدد فقط:' : 'Subtotal Price:',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        Text(
                          '${subtotalPrice.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} د.ل',
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isAr ? 'النسبة من إجمالي القماش:' : 'Ratio of total:',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Close Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: AppTheme.surfaceDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  widget.isAr ? 'تم / إغلاق المعاينة' : 'Done / Close Preview',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentAmber : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.accentAmber : AppTheme.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? AppTheme.surfaceDark : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
