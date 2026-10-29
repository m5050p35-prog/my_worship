import 'package:flutter/material.dart';
import '../models.dart';
import '../services/notification_service.dart';

class ExpensesBody extends StatefulWidget {
  final UserData user;
  final VoidCallback onChanged;

  const ExpensesBody({
    super.key,
    required this.user,
    required this.onChanged,
  });

  @override
  State<ExpensesBody> createState() => _ExpensesBodyState();
}

class _ExpensesBodyState extends State<ExpensesBody> {
  final _descCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'IQD'; // ═══ العملة الافتراضية ═══
  int _viewMode = 0; // 0 = this week, 1 = reports

  UserData get user => widget.user;

  DateTime get _weekStart => fridayOfWeek(DateTime.now());
  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  List<Expense> get _thisWeekExpenses {
    final start = _weekStart;
    final end = _weekEnd.add(const Duration(days: 1));
    final list = user.expenses.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
          d.isBefore(end);
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double get _thisWeekTotalIQD => _thisWeekExpenses
      .where((e) => e.currency == 'IQD')
      .fold(0.0, (s, e) => s + e.amount);

  double get _thisWeekTotalUSD => _thisWeekExpenses
      .where((e) => e.currency == 'USD')
      .fold(0.0, (s, e) => s + e.amount);

  bool get _reminderEnabled =>
      (user.reminders['expenses']?.enabled) ?? false;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.user.expensesViewMode;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  Helpers
  // ═══════════════════════════════════════════════════════════════
  static const _monthsAr = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  String _fmtDate(DateTime d) => '${d.day} ${_monthsAr[d.month - 1]} ${d.year}';

  String _fmtAmount(double amount, String currency) {
    if (currency == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    }
    return '${amount.toStringAsFixed(0)} د.ع';
  }

  double? _parseAmount(String s) {
    final normalized = s
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll('٫', '.')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(normalized);
  }

  // ═══════════════════════════════════════════════════════════════
  //  Actions
  // ═══════════════════════════════════════════════════════════════
  void _addExpense() {
    final desc = _descCtrl.text.trim();
    final amt = _parseAmount(_amtCtrl.text);
    if (desc.isEmpty) {
      _snack('أدخل وصف المصروف');
      return;
    }
    if (amt == null || amt <= 0) {
      _snack('أدخل مبلغاً صحيحاً');
      return;
    }
    setState(() {
      user.expenses.add(Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: desc,
        amount: amt,
        date: _selectedDate,
        currency: _selectedCurrency,
      ));
      _descCtrl.clear();
      _amtCtrl.clear();
      _selectedDate = DateTime.now();
    });
    widget.onChanged();
    FocusScope.of(context).unfocus();
    _snack('✅ تمت الإضافة');
  }

  Future<void> _deleteExpense(Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المصروف'),
        content: Text('حذف "${e.description}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => user.expenses.remove(e));
    widget.onChanged();
  }

  Future<void> _pickDate() async {
    final r = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'اختر التاريخ',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (r != null) setState(() => _selectedDate = r);
  }

  Future<void> _toggleReminder(bool v) async {
    setState(() {
      if (v) {
        user.reminders['expenses'] = ReminderConfig(
          enabled: true,
          hour: 21,
          minute: 0,
          freq: ReminderFrequency.daily,
        );
      } else {
        user.reminders.remove('expenses');
      }
    });
    await NotificationService.scheduleExpenseDaily(v);
    widget.onChanged();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ═══════════════════════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('هذا الأسبوع'),
                icon: Icon(Icons.receipt_long),
              ),
              ButtonSegment(
                value: 1,
                label: Text('التقارير'),
                icon: Icon(Icons.bar_chart),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (s) {
              setState(() => _viewMode = s.first);
              widget.user.expensesViewMode = _viewMode;
              widget.onChanged();
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _viewMode == 0 ? _buildCurrentWeek() : _buildReports(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  هذا الأسبوع
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCurrentWeek() {
    final primary = Theme.of(context).colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIllustrationBanner(),
        const SizedBox(height: 16),

        // ═══ ملخص الأسبوع ═══
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_month, color: primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'هذا الأسبوع (الجمعة → الخميس)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmtDate(_weekStart)} — ${_fmtDate(_weekEnd)}',
                      style: TextStyle(
                          color: Colors.grey[700], fontSize: 11),
                    ),
                  ],
                ),
              ),
              // ═══ الإجماليات (دولار + دينار) ═══
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_thisWeekTotalIQD > 0)
                    Text(
                      _fmtAmount(_thisWeekTotalIQD, 'IQD'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  if (_thisWeekTotalUSD > 0)
                    Text(
                      _fmtAmount(_thisWeekTotalUSD, 'USD'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  if (_thisWeekTotalIQD == 0 && _thisWeekTotalUSD == 0)
                    const Text('0', style: TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ═══ تذكير يومي ═══
        Card(
          margin: EdgeInsets.zero,
          color: _reminderEnabled
              ? Colors.green.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.06),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: const Text(
              'تذكير يومي - 9 مساءً',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'سجّل مصاريفك اليومية قبل النوم',
              style: TextStyle(fontSize: 11),
            ),
            secondary: Icon(
              _reminderEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: _reminderEnabled ? Colors.green : Colors.grey,
            ),
            value: _reminderEnabled,
            onChanged: _toggleReminder,
          ),
        ),
        const SizedBox(height: 16),

        _buildAddForm(primary),
        const SizedBox(height: 20),

        // ═══ قائمة مصاريف الأسبوع ═══
        Row(
          children: [
            const Text(
              'مصاريف هذا الأسبوع',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_thisWeekExpenses.length}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_thisWeekExpenses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.receipt_long,
                    size: 60, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'لم تسجل أي مصروف هذا الأسبوع بعد',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          ..._thisWeekExpenses.map(_expenseTile),
        const SizedBox(height: 80),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  البانر التمهيدي
  // ═══════════════════════════════════════════════════════════════
  Widget _buildIllustrationBanner() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E7C66), Color(0xFF2DBF9F)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E7C66).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'أضف مصروفك اليومي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'اكتب الوصف والمبلغ، اختر التاريخ\nواضغط حفظ — يتتبع التطبيق أسبوعك تلقائياً',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  نموذج الإضافة
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAddForm(Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إضافة مصروف',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'الوصف',
              hintText: 'مثال: وجبة غداء',
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // ═══ المبلغ + العملة ═══
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amtCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    hintText: '0',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency, // ✅ تم التصحيح هنا
                  decoration: const InputDecoration(
                    labelText: 'العملة',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'IQD', child: Text('د.ع', textAlign: TextAlign.center)),
                    DropdownMenuItem(
                        value: 'USD', child: Text('\$', textAlign: TextAlign.center)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCurrency = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 20,
                      color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fmtDate(_selectedDate),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addExpense,
              icon: const Icon(Icons.save),
              label: const Text('حفظ'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  عنصر مصروف
  // ═══════════════════════════════════════════════════════════════
  Widget _expenseTile(Expense e) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.receipt,
              size: 20, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          e.description,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          _fmtDate(e.date),
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fmtAmount(e.amount, e.currency),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.red),
              tooltip: 'حذف',
              onPressed: () => _deleteExpense(e),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  التقارير
  // ═══════════════════════════════════════════════════════════════
  Widget _buildReports() {
    final grouped = _groupByWeek();
    if (grouped.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'لا توجد بيانات بعد.\nأضف أول مصروف لعرض التقرير.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    double grandIQD = 0;
    double grandUSD = 0;
    for (var g in grouped) {
      grandIQD += g.totalIQD;
      grandUSD += g.totalUSD;
    }
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primary.withValues(alpha: 0.7)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.assessment, color: Colors.white, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي ${grouped.length} أسبوع',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (grandIQD > 0)
                      Text(
                        _fmtAmount(grandIQD, 'IQD'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (grandUSD > 0)
                      Text(
                        _fmtAmount(grandUSD, 'USD'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...grouped.map(_weekReportCard),
        const SizedBox(height: 40),
      ],
    );
  }

  List<_WeekGroup> _groupByWeek() {
    final map = <DateTime, List<Expense>>{};
    for (final e in user.expenses) {
      final ws = fridayOfWeek(e.date);
      map.putIfAbsent(ws, () => []).add(e);
    }
    final list = map.entries
        .map((entry) => _WeekGroup(
              start: entry.key,
              end: entry.key.add(const Duration(days: 6)),
              expenses: entry.value
                ..sort((a, b) => b.date.compareTo(a.date)),
            ))
        .toList();
    list.sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  Widget _weekReportCard(_WeekGroup w) {
    final isCurrent = w.start == _weekStart;
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent
              ? primary.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.15),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: isCurrent ? 0.15 : 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.calendar_month,
              size: 20, color: primary),
        ),
        title: Text(
          isCurrent ? 'هذا الأسبوع' : 'أسبوع سابق',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_fmtDate(w.start)} — ${_fmtDate(w.end)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${w.expenses.length} مصروف • ',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  if (w.totalIQD > 0)
                    Text(
                      _fmtAmount(w.totalIQD, 'IQD'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  if (w.totalIQD > 0 && w.totalUSD > 0)
                    const Text(' • '),
                  if (w.totalUSD > 0)
                    Text(
                      _fmtAmount(w.totalUSD, 'USD'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        children: w.expenses.map((e) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.circle, size: 8),
            title: Text(e.description, style: const TextStyle(fontSize: 13)),
            subtitle: Text(
              _fmtDate(e.date),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            trailing: Text(
              _fmtAmount(e.amount, e.currency),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: primary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WeekGroup {
  final DateTime start;
  final DateTime end;
  final List<Expense> expenses;

  _WeekGroup({
    required this.start,
    required this.end,
    required this.expenses,
  });

  double get totalIQD => expenses
      .where((e) => e.currency == 'IQD')
      .fold(0.0, (s, e) => s + e.amount);

  double get totalUSD => expenses
      .where((e) => e.currency == 'USD')
      .fold(0.0, (s, e) => s + e.amount);
}
