import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../presentation/providers/dairy_provider.dart';
import '../../features/expense/expense_provider.dart';
import '../../data/models/milk_entry.dart';
import '../../data/models/expense_entry.dart';
import '../../features/reports/report_generator.dart';
import '../../features/data_management/data_management_service.dart';

class ReportsScreen extends StatefulWidget {
  final DateTime? initialMonth;
  const ReportsScreen({super.key, this.initialMonth});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filtering state
  late String _activeFilter; // 'Day', 'Week', 'This Month', 'Year', 'Custom'
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialMonth != null) {
      _activeFilter = 'Custom';
      final year = widget.initialMonth!.year;
      final month = widget.initialMonth!.month;
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0, 23, 59, 59);
      _customRange = DateTimeRange(start: start, end: end);
    } else {
      _activeFilter = 'This Month';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTimeRange _getDateRangeForFilter() {
    final now = DateTime.now();
    switch (_activeFilter) {
      case 'Day':
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case 'Week':
        // Start of week (Monday)
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startDay = DateTime(start.year, start.month, start.day);
        final end = startDay.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return DateTimeRange(start: startDay, end: end);
      case 'This Month':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case 'Last Month':
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case 'Year':
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case 'Custom':
        if (_customRange != null) return _customRange!;
        // Fallback to last 30 days
        return DateTimeRange(
          start: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 30)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      default:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
    }
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _activeFilter = 'Custom';
        _customRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dairyP = Provider.of<DairyProvider>(context);
    final expenseP = Provider.of<ExpenseProvider>(context);

    // Calculate current filtered dates
    final range = _getDateRangeForFilter();

    // Filtered data lists
    final filteredMilk = dairyP.allRecords
        .where(
          (r) =>
              r.date.isAfter(
                range.start.subtract(const Duration(seconds: 1)),
              ) &&
              r.date.isBefore(range.end.add(const Duration(seconds: 1))),
        )
        .toList();

    final filteredExpenses = expenseP.allEntries
        .where(
          (e) =>
              e.date.isAfter(
                range.start.subtract(const Duration(seconds: 1)),
              ) &&
              e.date.isBefore(range.end.add(const Duration(seconds: 1))),
        )
        .toList();

    // KPI Summary calculations
    final totalMilk = filteredMilk.fold(0.0, (sum, r) => sum + r.totalYield);
    final totalIncome = filteredMilk.fold(0.0, (sum, r) {
      final price = r.pricePerLiter > 0
          ? r.pricePerLiter
          : dairyP.pricePerLiter;
      return sum + r.totalYield * price;
    });
    final totalExpense = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final netProfit = totalIncome - totalExpense;

    // comparisons (Current Month vs Previous Month)
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    final prevMonthEnd = DateTime(now.year, now.month, 0);

    final prevMonthIncome = dairyP.allRecords
        .where(
          (r) =>
              r.date.isAfter(
                prevMonthStart.subtract(const Duration(seconds: 1)),
              ) &&
              r.date.isBefore(prevMonthEnd.add(const Duration(seconds: 1))),
        )
        .fold(0.0, (sum, r) {
          final price = r.pricePerLiter > 0
              ? r.pricePerLiter
              : dairyP.pricePerLiter;
          return sum + r.totalYield * price;
        });
    final thisMonthIncome = dairyP.allRecords
        .where(
          (r) => r.date.isAfter(
            thisMonthStart.subtract(const Duration(seconds: 1)),
          ),
        )
        .fold(0.0, (sum, r) {
          final price = r.pricePerLiter > 0
              ? r.pricePerLiter
              : dairyP.pricePerLiter;
          return sum + r.totalYield * price;
        });

    final prevMonthExpense = expenseP.allEntries
        .where(
          (e) =>
              e.date.isAfter(
                prevMonthStart.subtract(const Duration(seconds: 1)),
              ) &&
              e.date.isBefore(prevMonthEnd.add(const Duration(seconds: 1))),
        )
        .fold(0.0, (sum, e) => sum + e.amount);
    final thisMonthExpense = expenseP.allEntries
        .where(
          (e) => e.date.isAfter(
            thisMonthStart.subtract(const Duration(seconds: 1)),
          ),
        )
        .fold(0.0, (sum, e) => sum + e.amount);

    final prevMonthProfit = prevMonthIncome - prevMonthExpense;
    final thisMonthProfit = thisMonthIncome - thisMonthExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdf(
              context,
              filteredMilk,
              filteredExpenses,
              dairyP.pricePerLiter,
              range,
            ),
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.swap_vertical_circle_outlined),
            onPressed: () => _showImportExportDialog(context, dairyP, expenseP),
            tooltip: 'Import/Export CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── FILTER SELECTOR BAR (Dropdown Menu) ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 20,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Period:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  initialValue: _activeFilter,
                  onSelected: (value) {
                    if (value == 'Custom') {
                      _selectCustomRange();
                    } else {
                      setState(() {
                        _activeFilter = value;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _activeFilter == 'Custom' && _customRange != null
                              ? '${DateFormat('dd/MM/yy').format(_customRange!.start)} - ${DateFormat('dd/MM/yy').format(_customRange!.end)}'
                              : _activeFilter,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: theme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Day', child: Text('Day')),
                    const PopupMenuItem(value: 'Week', child: Text('Week')),
                    const PopupMenuItem(
                      value: 'This Month',
                      child: Text('This Month'),
                    ),
                    const PopupMenuItem(
                      value: 'Last Month',
                      child: Text('Last Month'),
                    ),
                    const PopupMenuItem(value: 'Year', child: Text('Year')),
                    const PopupMenuItem(
                      value: 'Custom',
                      child: Text('Custom Range'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── KPI METRIC CARDS GRID ───
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildKPICard(
                        title: 'Total Milk',
                        value: '${totalMilk.toStringAsFixed(1)} L',
                        icon: Icons.water_drop,
                        iconColor: Colors.blue,
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKPICard(
                        title: 'Total Income',
                        value: '₹${totalIncome.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee,
                        iconColor: Colors.green,
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKPICard(
                        title: 'Expenses',
                        value: '₹${totalExpense.toStringAsFixed(0)}',
                        icon: Icons.money_off_rounded,
                        iconColor: Colors.redAccent,
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKPICard(
                        title: 'Net Profit',
                        value: '₹${netProfit.toStringAsFixed(0)}',
                        icon: Icons.trending_up,
                        iconColor: Colors.indigo,
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar to Switch Graph Sections
          TabBar(
            controller: _tabController,
            indicatorColor: theme.primaryColor,
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Production'),
              Tab(text: 'Expenses'),
              Tab(text: 'Financials'),
            ],
          ),

          // Graphs Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductionTab(filteredMilk, theme, isDark),
                _buildExpensesTab(filteredExpenses, theme, isDark),
                _buildFinancialTab(
                  filteredMilk,
                  filteredExpenses,
                  theme,
                  isDark,
                  dairyP.pricePerLiter,
                  thisMonthProfit,
                  prevMonthProfit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterName) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(filterName),
        selected: _activeFilter == filterName,
        onSelected: (val) {
          if (val) {
            setState(() {
              _activeFilter = filterName;
            });
          }
        },
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D1B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ─── PRODUCTION TAB SCREEN ───
  Widget _buildProductionTab(
    List<MilkEntry> records,
    ThemeData theme,
    bool isDark,
  ) {
    if (records.isEmpty) {
      return const Center(
        child: Text('No production data logged for this range.'),
      );
    }

    // Sort by Date ASC
    final sorted = List<MilkEntry>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Prepare spots for line chart
    final List<FlSpot> spots = [];
    final Map<int, String> dayLabel = {};

    for (int i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      spots.add(FlSpot(i.toDouble(), r.totalYield));
      dayLabel[i] = DateFormat('dd/MM').format(r.date);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Milk Yield Trend', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.only(right: 16, top: 12),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        // Show labels occasionally to avoid clutter
                        int interval = (sorted.length / 5).ceil();
                        if (interval == 0) interval = 1;
                        if (idx % interval == 0 && dayLabel.containsKey(idx)) {
                          return Text(
                            dayLabel[idx]!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Daily Log List', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final r = sorted[sorted.length - 1 - index]; // show latest first
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.water_drop, color: Colors.blue),
                ),
                title: Text(DateFormat('dd MMMM yyyy').format(r.date)),
                subtitle: Text(
                  'Morning: ${r.morningMilk}L — Evening: ${r.eveningMilk}L',
                ),
                trailing: Text(
                  '${r.totalYield.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── EXPENSES TAB SCREEN ───
  Widget _buildExpensesTab(
    List<ExpenseEntry> expenses,
    ThemeData theme,
    bool isDark,
  ) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text('No expense data logged for this range.'),
      );
    }

    // Category breakdown
    final Map<ExpenseCategory, double> totals = {};
    for (var e in expenses) {
      totals.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
    }

    final double totalAmount = totals.values.fold(0.0, (sum, v) => sum + v);

    // Prepare pie segments
    final List<PieChartSectionData> sections = [];
    final List<Widget> legends = [];

    final colors = {
      ExpenseCategory.feed: Colors.green,
      ExpenseCategory.medical: Colors.redAccent,
      ExpenseCategory.rice: Colors.orange,
      ExpenseCategory.others: Colors.grey,
    };

    final labels = {
      ExpenseCategory.feed: 'Feed',
      ExpenseCategory.medical: 'Medical',
      ExpenseCategory.rice: 'Rice',
      ExpenseCategory.others: 'Other',
    };

    totals.forEach((category, amount) {
      final percentage = (amount / totalAmount) * 100;
      sections.add(
        PieChartSectionData(
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          color: colors[category],
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

      legends.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                color: colors[category],
                margin: const EdgeInsets.only(right: 8),
              ),
              Text('${labels[category]}: '),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense Category Breakdown',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: legends,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Recent Expense Logs', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final e = expenses[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  child: Icon(Icons.money_off, color: Colors.red.shade700),
                ),
                title: Text(labels[e.category]!),
                subtitle: Text(DateFormat('dd MMMM yyyy').format(e.date)),
                trailing: Text(
                  '-₹${e.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── FINANCIAL TAB SCREEN ───
  Widget _buildFinancialTab(
    List<MilkEntry> milk,
    List<ExpenseEntry> expenses,
    ThemeData theme,
    bool isDark,
    double fallbackPrice,
    double thisMonthProfit,
    double prevMonthProfit,
  ) {
    // Group monthly income and expense to build comparison chart
    // Let's group for the last 6 months
    final now = DateTime.now();
    final List<String> monthLabels = [];
    final List<double> monthlyIncomes = [];
    final List<double> monthlyExpenses = [];

    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthName = DateFormat('MMM').format(targetDate);
      monthLabels.add(monthName);

      // Income calculation
      double income = 0;
      final mRecords = milk.where(
        (r) =>
            r.date.year == targetDate.year && r.date.month == targetDate.month,
      );
      for (var r in mRecords) {
        final price = r.pricePerLiter > 0 ? r.pricePerLiter : fallbackPrice;
        income += r.totalYield * price;
      }
      monthlyIncomes.add(income);

      // Expense calculation
      final eRecords = expenses.where(
        (e) =>
            e.date.year == targetDate.year && e.date.month == targetDate.month,
      );
      double exp = eRecords.fold(0.0, (sum, e) => sum + e.amount);
      monthlyExpenses.add(exp);
    }

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < 6; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthlyIncomes[i],
              color: Colors.green,
              width: 8,
            ),
            BarChartRodData(
              toY: monthlyExpenses[i],
              color: Colors.redAccent,
              width: 8,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income vs Expenses (Last 6 Months)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.only(right: 16),
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx >= 0 && idx < 6) {
                          return Text(
                            monthLabels[idx],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Month-over-Month Profit Comparison',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1D1B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                _buildProfitComparisonRow(
                  'This Month Profit',
                  thisMonthProfit,
                  theme,
                ),
                const Divider(height: 24),
                _buildProfitComparisonRow(
                  'Previous Month Profit',
                  prevMonthProfit,
                  theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitComparisonRow(
    String label,
    double value,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: value >= 0 ? theme.primaryColor : Colors.red,
          ),
        ),
      ],
    );
  }

  // ─── PDF REPORT GENERATION ───
  void _generatePdf(
    BuildContext context,
    List<MilkEntry> milk,
    List<ExpenseEntry> expenses,
    double price,
    DateTimeRange range,
  ) async {
    final label =
        "${DateFormat('dd/MM/yyyy').format(range.start)} - ${DateFormat('dd/MM/yyyy').format(range.end)}";
    await ReportGenerator().generateAndPrint(
      milkRecords: milk,
      expenseRecords: expenses,
      pricePerLiter: price,
      periodLabel: label,
      isDownload: true,
      startDate: range.start,
      endDate: range.end,
    );
  }

  // ─── CSV IMPORT/EXPORT DIALOG ───
  void _showImportExportDialog(
    BuildContext context,
    DairyProvider dp,
    ExpenseProvider ep,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.swap_vertical_circle_outlined, color: Colors.green),
              SizedBox(width: 12),
              Text('Import / Export Data'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section: Milk (Income) Data
                _buildDialogHeader(theme, 'Milk (Income) Data'),
                _buildDialogActionTile(
                  context: ctx,
                  icon: Icons.upload_file_rounded,
                  label: 'Export Milk to CSV',
                  color: Colors.blue,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final all = await dp.getRecordsForRange(
                      DateTime(2000),
                      DateTime(2050),
                    );
                    await DataManagementService().exportMilkData(all);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Milk Records Exported successfully!"),
                      ),
                    );
                  },
                ),
                _buildDialogActionTile(
                  context: ctx,
                  icon: Icons.download_for_offline_rounded,
                  label: 'Import Milk from CSV',
                  color: Colors.blue,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final entries = await DataManagementService()
                        .pickAndParseMilk();
                    if (entries.isEmpty) return;

                    int count = 0;
                    for (var e in entries) {
                      await dp.addOrUpdateRecord(
                        e.date,
                        e.morningMilk,
                        e.eveningMilk,
                        e.notes,
                      );
                      count++;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Imported $count Milk Records!")),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Section: Expense Data
                _buildDialogHeader(theme, 'Expense Data'),
                _buildDialogActionTile(
                  context: ctx,
                  icon: Icons.upload_file_rounded,
                  label: 'Export Expenses to CSV',
                  color: Colors.redAccent,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final all = await ep.getRecordsForRange(
                      DateTime(2000),
                      DateTime(2050),
                    );
                    await DataManagementService().exportExpenseData(all);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Expenses Exported successfully!"),
                      ),
                    );
                  },
                ),
                _buildDialogActionTile(
                  context: ctx,
                  icon: Icons.download_for_offline_rounded,
                  label: 'Import Expenses from CSV',
                  color: Colors.redAccent,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final entries = await DataManagementService()
                        .pickAndParseExpenses();
                    if (entries.isEmpty) return;

                    int count = 0;
                    for (var e in entries) {
                      await ep.addExpense(
                        e.date,
                        e.category,
                        e.amount,
                        e.notes,
                      );
                      count++;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Imported $count Expense Records!"),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildDialogActionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
