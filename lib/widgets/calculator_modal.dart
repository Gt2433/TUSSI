import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Function to show the calculator modal sheet or dialog from anywhere in the app
Future<double?> showCalculatorModal(
  BuildContext context, {
  double? initialValue,
  ValueChanged<double>? onSelectValue,
}) async {
  return await showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CalculatorModalWidget(
      initialValue: initialValue,
      onSelectValue: onSelectValue,
    ),
  );
}

class _CalculatorModalWidget extends StatefulWidget {
  final double? initialValue;
  final ValueChanged<double>? onSelectValue;

  const _CalculatorModalWidget({
    this.initialValue,
    this.onSelectValue,
  });

  @override
  State<_CalculatorModalWidget> createState() => _CalculatorModalWidgetState();
}

class _HistoryItem {
  final String expression;
  final String result;
  _HistoryItem(this.expression, this.result);
}

class _CalculatorModalWidgetState extends State<_CalculatorModalWidget> {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _waitingForSecondOperand = false;
  bool _showHistory = false;
  final List<_HistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue! > 0) {
      _display = _formatNum(widget.initialValue!);
    }
  }

  String _formatNum(double num) {
    if (num.isNaN || num.isInfinite) return 'خطأ';
    if (num == num.roundToDouble()) {
      return num.toInt().toString();
    }
    // Trim trailing zeros up to 4 decimals
    String str = num.toStringAsFixed(4);
    while (str.contains('.') && (str.endsWith('0') || str.endsWith('.'))) {
      str = str.substring(0, str.length - 1);
    }
    return str;
  }

  void _onDigitPress(String digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_waitingForSecondOperand) {
        _display = digit == '00' ? '0' : digit;
        _waitingForSecondOperand = false;
      } else {
        if (_display == '0') {
          if (digit == '00') return;
          _display = digit;
        } else {
          if (_display.length < 15) {
            _display += digit;
          }
        }
      }
    });
  }

  void _onDecimalPress() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_waitingForSecondOperand) {
        _display = '0.';
        _waitingForSecondOperand = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onToggleSign() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_display == '0' || _display == 'خطأ') return;
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    });
  }

  void _onPercentPress() {
    HapticFeedback.selectionClick();
    final val = double.tryParse(_display);
    if (val != null) {
      setState(() {
        _display = _formatNum(val / 100);
      });
    }
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_waitingForSecondOperand || _display == 'خطأ') {
        _display = '0';
        _waitingForSecondOperand = false;
        return;
      }
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
        if (_display == '-' || _display.isEmpty) _display = '0';
      } else {
        _display = '0';
      }
    });
  }

  void _onClear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _display = '0';
    });
  }

  void _onAllClear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _waitingForSecondOperand = false;
    });
  }

  void _onOperatorPress(String op) {
    HapticFeedback.selectionClick();
    final currentVal = double.tryParse(_display);
    if (currentVal == null) return;

    setState(() {
      if (_firstOperand == null) {
        _firstOperand = currentVal;
      } else if (_operator != null && !_waitingForSecondOperand) {
        final res = _calculate(_firstOperand!, currentVal, _operator!);
        _display = _formatNum(res);
        _firstOperand = res;
      }

      _operator = op;
      _expression = '${_formatNum(_firstOperand!)} $op';
      _waitingForSecondOperand = true;
    });
  }

  double _calculate(double op1, double op2, String op) {
    switch (op) {
      case '+':
        return op1 + op2;
      case '-':
        return op1 - op2;
      case '×':
        return op1 * op2;
      case '÷':
        return op2 != 0 ? op1 / op2 : double.nan;
      default:
        return op2;
    }
  }

  void _onEqualPress() {
    HapticFeedback.mediumImpact();
    if (_firstOperand == null || _operator == null) return;

    final secondOperand = double.tryParse(_display) ?? 0;
    final res = _calculate(_firstOperand!, secondOperand, _operator!);
    final resStr = _formatNum(res);
    final exprStr = '${_formatNum(_firstOperand!)} $_operator ${_formatNum(secondOperand)}';

    setState(() {
      _history.insert(0, _HistoryItem(exprStr, resStr));
      _expression = '$exprStr =';
      _display = resStr;
      _firstOperand = res.isNaN ? null : res;
      _operator = null;
      _waitingForSecondOperand = true;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _display));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ النتيجة ($_display) بنجاح'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.accentAmberDark,
      ),
    );
  }

  void _selectResult() {
    final val = double.tryParse(_display);
    if (val != null && !val.isNaN) {
      if (widget.onSelectValue != null) {
        widget.onSelectValue!(val);
      }
      Navigator.of(context).pop(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator bar
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),

              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calculate_rounded,
                          color: AppTheme.accentAmber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'آلة حاسبة ذكية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                        icon: Icon(
                          _showHistory ? Icons.calculate_outlined : Icons.history_rounded,
                          color: _showHistory ? AppTheme.accentAmber : AppTheme.textMuted,
                          size: 22,
                        ),
                        tooltip: 'السجل',
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppTheme.textMuted,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_showHistory) ...[
                // History View
                Container(
                  height: 240,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: _history.isEmpty
                      ? Center(
                          child: Text(
                            'لا يوجد سجل حسابات بعد',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _history.length,
                          separatorBuilder: (_, __) => Divider(color: AppTheme.borderSubtle, height: 12),
                          itemBuilder: (context, index) {
                            final item = _history[index];
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _display = item.result;
                                  _showHistory = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.expression,
                                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                    ),
                                    Text(
                                      '= ${item.result}',
                                      style: TextStyle(
                                        color: AppTheme.accentAmber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ] else ...[
                // Calculator Screen (Display)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Expression line
                      SizedBox(
                        height: 24,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Text(
                            _expression,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Main Display Output
                      Row(
                        children: [
                          IconButton(
                            onPressed: _copyToClipboard,
                            icon: Icon(
                              Icons.copy_rounded,
                              color: AppTheme.textMuted,
                              size: 18,
                            ),
                            tooltip: 'نسخ',
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              child: SelectableText(
                                _display,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Keypad Grid
              Column(
                children: [
                  Row(
                    children: [
                      _buildCalcBtn('AC', flex: 1, isAction: true, color: AppTheme.error, onTap: _onAllClear),
                      _buildCalcBtn('C', flex: 1, isAction: true, onTap: _onClear),
                      _buildCalcBtn('⌫', flex: 1, isAction: true, icon: Icons.backspace_outlined, onTap: _onBackspace),
                      _buildCalcBtn('÷', flex: 1, isOperator: true, onTap: () => _onOperatorPress('÷')),
                    ],
                  ),
                  Row(
                    children: [
                      _buildCalcBtn('7', flex: 1, onTap: () => _onDigitPress('7')),
                      _buildCalcBtn('8', flex: 1, onTap: () => _onDigitPress('8')),
                      _buildCalcBtn('9', flex: 1, onTap: () => _onDigitPress('9')),
                      _buildCalcBtn('×', flex: 1, isOperator: true, onTap: () => _onOperatorPress('×')),
                    ],
                  ),
                  Row(
                    children: [
                      _buildCalcBtn('4', flex: 1, onTap: () => _onDigitPress('4')),
                      _buildCalcBtn('5', flex: 1, onTap: () => _onDigitPress('5')),
                      _buildCalcBtn('6', flex: 1, onTap: () => _onDigitPress('6')),
                      _buildCalcBtn('-', flex: 1, isOperator: true, onTap: () => _onOperatorPress('-')),
                    ],
                  ),
                  Row(
                    children: [
                      _buildCalcBtn('1', flex: 1, onTap: () => _onDigitPress('1')),
                      _buildCalcBtn('2', flex: 1, onTap: () => _onDigitPress('2')),
                      _buildCalcBtn('3', flex: 1, onTap: () => _onDigitPress('3')),
                      _buildCalcBtn('+', flex: 1, isOperator: true, onTap: () => _onOperatorPress('+')),
                    ],
                  ),
                  Row(
                    children: [
                      _buildCalcBtn('±', flex: 1, isAction: true, onTap: _onToggleSign),
                      _buildCalcBtn('0', flex: 1, onTap: () => _onDigitPress('0')),
                      _buildCalcBtn('.', flex: 1, onTap: _onDecimalPress),
                      _buildCalcBtn('=', flex: 1, isPrimary: true, onTap: _onEqualPress),
                    ],
                  ),
                ],
              ),

              // Use value button (if returning to input)
              if (widget.onSelectValue != null || widget.initialValue != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _selectResult,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentAmber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'إدراج النتيجة في الحقل',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalcBtn(
    String text, {
    required int flex,
    required VoidCallback onTap,
    bool isOperator = false,
    bool isAction = false,
    bool isPrimary = false,
    IconData? icon,
    Color? color,
  }) {
    Color bg = AppTheme.surfaceCard;
    Color fg = AppTheme.textPrimary;

    if (isOperator) {
      bg = AppTheme.accentAmber.withValues(alpha: 0.15);
      fg = AppTheme.accentAmber;
    } else if (isAction) {
      bg = AppTheme.surfaceElevated;
      fg = color ?? AppTheme.textSecondary;
    } else if (isPrimary) {
      bg = AppTheme.accentAmber;
      fg = Colors.black;
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: AppTheme.accentAmber.withValues(alpha: 0.2),
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOperator || isPrimary
                      ? AppTheme.accentAmber.withValues(alpha: 0.3)
                      : AppTheme.borderSubtle,
                  width: 1,
                ),
              ),
              child: icon != null
                  ? Icon(icon, color: fg, size: 22)
                  : Text(
                      text,
                      style: TextStyle(
                        fontSize: isOperator || isAction ? 22 : 20,
                        fontWeight: isPrimary || isOperator ? FontWeight.bold : FontWeight.w600,
                        color: fg,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
