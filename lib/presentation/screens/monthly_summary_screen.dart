import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../presentation/providers/dairy_provider.dart';
import '../../features/expense/expense_provider.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        elevation: 0,
      ),
      body: Consumer2<DairyProvider, ExpenseProvider>(
        builder: (context, dairy, expense, child) {
          if (dairy.isLoading || expense.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pricePerLiter = dairy.pricePerLiter;

          // Process records to gather unique months
          final Set<String> uniqueMonths = {};
          for (var record in dairy.allRecords) {
            uniqueMonths.add(DateFormat('yyyy-MM').format(record.date));
          }
          for (var record in expense.allEntries) {
            uniqueMonths.add(DateFormat('yyyy-MM').format(record.date));
          }

          // Sort months descending (latest first)
          final sortedMonths = uniqueMonths.toList()..sort((a, b) => b.compareTo(a));

          // Calculate "Last Month"
          final now = DateTime.now();
          final lastMonthDate = DateTime(now.year, now.month - 1, 1);

          double lastMonthMilk = dairy.getMonthlyTotal(lastMonthDate);
          double lastMonthExpense = expense.getMonthlyTotal(lastMonthDate);
          double lastMonthIncome = dairy.getMonthlyIncome(lastMonthDate);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Last Month Summary at Top (Enhanced)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90D9), Color(0xFF3F51B5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3F51B5).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Last Month — ${DateFormat('MMMM yyyy').format(lastMonthDate)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Milk
                    _buildSummaryRow(
                      Icons.water_drop,
                      'Total Milk',
                      '${lastMonthMilk.toStringAsFixed(3)} L',
                      Colors.white,
                    ),
                    const SizedBox(height: 12),
                    // Income
                    _buildSummaryRow(
                      Icons.trending_up,
                      'Total Income',
                      '₹${lastMonthIncome.toStringAsFixed(0)}',
                      const Color(0xFF81C784),
                    ),
                    const SizedBox(height: 12),
                    // Expense
                    _buildSummaryRow(
                      Icons.trending_down,
                      'Total Expense',
                      '₹${lastMonthExpense.toStringAsFixed(0)}',
                      const Color(0xFFEF9A9A),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'All Months',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (sortedMonths.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No data available yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                )
              else
                ...sortedMonths.map((monthKey) {
                  final parts = monthKey.split('-');
                  final year = int.parse(parts[0]);
                  final month = int.parse(parts[1]);
                  final date = DateTime(year, month);
                  
                  final milk = dairy.getMonthlyTotal(date);
                  final exp = expense.getMonthlyTotal(date);
                  final inc = milk * pricePerLiter;
                  final profitLoss = inc - exp;
                  
                  final monthName = DateFormat('MMMM yyyy').format(date);
                  
                  // Collect missing dates
                  int daysInMonth = DateTime(year, month + 1, 0).day;
                  int limit = (year == now.year && month == now.month) ? now.day : daysInMonth;
                  final List<DateTime> missingDates = [];
                  for (int d = 1; d <= limit; d++) {
                    bool found = dairy.allRecords.any((r) => r.date.year == year && r.date.month == month && r.date.day == d);
                    if (!found) missingDates.add(DateTime(year, month, d));
                  }

                  // Use per-record income (accurate per-month pricing)
                  final incomeAccurate = dairy.getMonthlyIncome(date);

                  return _buildEnhancedMonthCard(
                    monthName: monthName,
                    milk: milk,
                    income: incomeAccurate,
                    expense: exp,
                    profitLoss: incomeAccurate - exp,
                    missingDates: missingDates,
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedMonthCard({
    required String monthName,
    required double milk,
    required double income,
    required double expense,
    required double profitLoss,
    required List<DateTime> missingDates,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDark ? 0.05 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F51B5).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    monthName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3F51B5),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: profitLoss >= 0 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${profitLoss >= 0 ? '+' : ''}₹${profitLoss.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: profitLoss >= 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            if (missingDates.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Missing Milk Entry Days (${missingDates.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      missingDates.map((d) => DateFormat('dd').format(d)).join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            
            // Milk row
            _buildDetailRow(
              icon: Icons.water_drop,
              iconColor: Colors.blue,
              label: 'Total Milk Produced',
              value: '${milk.toStringAsFixed(3)} L',
              valueColor: Colors.blue[700]!,
            ),
            const SizedBox(height: 10),
            
            // Income row
            _buildDetailRow(
              icon: Icons.arrow_upward,
              iconColor: Colors.green,
              label: 'Total Income',
              value: '₹${income.toStringAsFixed(0)}',
              valueColor: Colors.green[700]!,
            ),
            const SizedBox(height: 10),
            
            // Expense row
            _buildDetailRow(
              icon: Icons.arrow_downward,
              iconColor: Colors.red,
              label: 'Total Expense',
              value: '₹${expense.toStringAsFixed(0)}',
              valueColor: Colors.red[700]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color valueColor,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
