import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../presentation/providers/dairy_provider.dart';
import '../../features/expense/expense_provider.dart';
import '../../data/models/milk_entry.dart';
import '../../data/models/expense_entry.dart';
import '../../features/reports/report_generator.dart';
import '../widgets/milk_entry_card.dart';
import 'add_record_screen.dart';
import '../../features/data_management/data_management_service.dart';

class FullReportScreen extends StatefulWidget {
  const FullReportScreen({super.key});

  @override
  State<FullReportScreen> createState() => _FullReportScreenState();
}

class _FullReportScreenState extends State<FullReportScreen> {
  late TextEditingController _priceController;
  String _currentFilter = 'Last Month';

  @override
  void initState() {
    super.initState();
    final dairyP = Provider.of<DairyProvider>(context, listen: false);
    _priceController = TextEditingController(
      text: dairyP.pricePerLiter.toStringAsFixed(0),
    );

    // Update provider when text changes
    _priceController.addListener(() {
      final val = double.tryParse(_priceController.text);
      if (val != null) {
        dairyP.setPricePerLiter(val);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter('Last Month');
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
    });

    final dairyP = Provider.of<DairyProvider>(context, listen: false);
    final expenseP = Provider.of<ExpenseProvider>(context, listen: false);
    final now = DateTime.now();

    if (filter == 'Last Month') {
      // Last Month = previous calendar month
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
      dairyP.filterByDateRange(lastMonth, lastDayOfLastMonth);
      expenseP.filterByDateRange(lastMonth, lastDayOfLastMonth);
    } else if (filter == 'This Week') {
      dairyP.filterByWeek(now);
      expenseP.filterByWeek(now);
    } else if (filter == 'This Month') {
      dairyP.filterByMonth(now);
      expenseP.filterByMonth(now);
    } else if (filter == 'Today') {
      dairyP.filterBySingleDate(now);
      expenseP.filterBySingleDate(now);
    }
  }

  void _applyCustomFilter(DateTime start, DateTime end) {
    setState(() {
      _currentFilter = "Custom";
    });
    final dairyP = Provider.of<DairyProvider>(context, listen: false);
    final expenseP = Provider.of<ExpenseProvider>(context, listen: false);

    dairyP.filterByDateRange(start, end);
    expenseP.filterByDateRange(start, end);
  }

  void _handleRadioChange(String? value) async {
    if (value == 'Custom Range') {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now,
        initialDateRange: DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        ),
      );
      if (picked != null) {
        _applyCustomFilter(picked.start, picked.end);
        setState(() => _currentFilter = 'Custom Range');
      }
    } else if (value != null) {
      _applyFilter(value);
    }
  }

  Widget _buildRadioOption(String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: title,
          groupValue: _currentFilter,
          onChanged: _handleRadioChange,
        ),
        GestureDetector(
          onTap: () => _handleRadioChange(title),
          child: Text(title),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consume both providers
    final dairyP = Provider.of<DairyProvider>(context);
    final expenseP = Provider.of<ExpenseProvider>(context);

    // Merge and Sort
    final List<dynamic> allItems = [];
    allItems.addAll(dairyP.records); // MilkEntry
    allItems.addAll(expenseP.entries); // ExpenseEntry

    // safe sort
    allItems.sort((a, b) {
      DateTime da = (a is MilkEntry) ? a.date : (a as ExpenseEntry).date;
      DateTime db = (b is MilkEntry) ? b.date : (b as ExpenseEntry).date;
      return db.compareTo(da); // Descending
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdf(context, dairyP, expenseP),
            tooltip: 'Generate PDF',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, dairyP, expenseP),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_milk',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Export Milk (CSV)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_expense',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Export Expenses (CSV)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import_milk',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Import Milk (CSV)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import_expense',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Import Expenses (CSV)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      // FAB removed per requirement - PDF generation available via AppBar icon
      body: Column(
        children: [
          // 1. Controls (Filter & Price)
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Radio Buttons
                const Text('Report Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Wrap(
                  spacing: 4.0,
                  runSpacing: -8.0,
                  children: [
                    _buildRadioOption('Today'),
                    _buildRadioOption('This Week'),
                    _buildRadioOption('This Month'),
                    _buildRadioOption('Last Month'),
                    _buildRadioOption('Custom Range'),
                  ],
                ),
                const SizedBox(height: 12),
                // Price Input
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cost / Liter (Modified Manually)',
                    border: OutlineInputBorder(),
                    prefixText: 'Rs. ',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. List
          Expanded(
            child: allItems.isEmpty
                ? const Center(child: Text("No records found for this period."))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: allItems.length,
                    itemBuilder: (context, index) {
                      final item = allItems[index];
                      if (item is MilkEntry) {
                        return MilkEntryCard(
                          record: item,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddRecordScreen(recordToEdit: item),
                            ),
                          ),
                          onDelete: () =>
                              _confirmDeleteMilk(context, dairyP, item),
                        );
                      } else if (item is ExpenseEntry) {
                        return _ExpenseCard(
                          entry: item,
                          onTap: () => _showEditExpenseDialog(
                            context,
                            expenseP,
                            item,
                          ), // Edit Expense
                          onDelete: () =>
                              _confirmDeleteExpense(context, expenseP, item),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(
    String value,
    DairyProvider dp,
    ExpenseProvider ep,
  ) async {
    final dms = DataManagementService();
    try {
      if (value == 'export_milk') {
        // Export ALL records, not just filtered.
        // We probably want backup of everything.
        // But dp exposes `records` (filtered).
        // Let's ask dp for filtered, or all?
        // Usually Export is ALL.
        // Accessing hidden `_allRecords`?
        // We added `getRecordsForRange`. We can use huge range.
        final all = await dp.getRecordsForRange(DateTime(2000), DateTime(2050));
        await dms.exportMilkData(all);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Milk Records Exported!")));
      } else if (value == 'export_expense') {
        final all = await ep.getRecordsForRange(DateTime(2000), DateTime(2050));
        await dms.exportExpenseData(all);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Expenses Exported!")));
      } else if (value == 'import_milk') {
        final entries = await dms.pickAndParseMilk();
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
      } else if (value == 'import_expense') {
        final entries = await dms.pickAndParseExpenses();
        if (entries.isEmpty) return;

        int count = 0;
        // Check for duplicates roughly?
        // Current logic: Add.
        for (var e in entries) {
          await ep.addExpense(e.date, e.category, e.amount, e.notes);
          count++;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Imported $count Expense Records!")),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _confirmDeleteMilk(
    BuildContext context,
    DairyProvider p,
    MilkEntry item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Milk Record?'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              p.deleteRecord(item.date);
              Navigator.pop(ctx);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpense(
    BuildContext context,
    ExpenseProvider p,
    ExpenseEntry item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              p.deleteExpense(item);
              Navigator.pop(ctx);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditExpenseDialog(
    BuildContext context,
    ExpenseProvider p,
    ExpenseEntry item,
  ) {
    final amountCtrl = TextEditingController(text: item.amount.toString());
    final notesCtrl = TextEditingController(text: item.notes);
    ExpenseCategory selectedCat = item.category;
    DateTime selectedDate = item.date;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Expense"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount (Rs)",
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ExpenseCategory>(
                      value: selectedCat,
                      items: ExpenseCategory.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedCat = v!),
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(
                        "Date: ${DateFormat('dd MMM').format(selectedDate)}",
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setState(() => selectedDate = d);
                      },
                    ),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: "Notes"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text);
                    if (amt == null) return;
                    // Calling new update method
                    p.updateExpense(
                      item,
                      selectedDate,
                      selectedCat,
                      amt,
                      notesCtrl.text,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("UPDATE"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generatePdf(
    BuildContext context,
    DairyProvider dp,
    ExpenseProvider ep,
  ) async {
    // Show Dialog to select filter for PDF
    await showDialog(
      context: context,
      builder: (context) {
        String filterType = "LastMonth"; // Default
        DateTime? customStart;
        DateTime? customEnd;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Generate PDF Report"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Period:"),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: filterType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: "LastMonth",
                        child: Text("Last Month"),
                      ),
                      DropdownMenuItem(value: "Week", child: Text("This Week")),
                      DropdownMenuItem(
                        value: "Month",
                        child: Text("This Month"),
                      ),
                      DropdownMenuItem(
                        value: "Custom",
                        child: Text("Custom Date Range"),
                      ),
                    ],
                    onChanged: (val) async {
                      if (val == "Custom") {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: now,
                        );
                        if (picked != null) {
                          setState(() {
                            filterType = val!;
                            customStart = picked.start;
                            customEnd = picked.end;
                          });
                        }
                      } else {
                        setState(() {
                          filterType = val!;
                          customStart = null;
                          customEnd = null;
                        });
                      }
                    },
                  ),
                  if (filterType == "Custom" && customStart != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Selected: ${DateFormat('dd/MM/yyyy').format(customStart!)} - ${DateFormat('dd/MM/yyyy').format(customEnd!)}",
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("DOWNLOAD"),
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog

                    // Calculate date range based on selection
                    DateTime start, end;
                    final now = DateTime.now();

                    switch (filterType) {
                      case "Week":
                        start = now.subtract(Duration(days: now.weekday - 1));
                        end = start.add(const Duration(days: 6));
                        break;
                      case "Month":
                        start = DateTime(now.year, now.month, 1);
                        end = DateTime(now.year, now.month + 1, 0);
                        break;
                      case "Custom":
                        if (customStart != null && customEnd != null) {
                          start = customStart!;
                          end = customEnd!;
                        } else {
                          // Fallback
                          start = now.subtract(const Duration(days: 30));
                          end = now;
                        }
                        break;
                      case "LastMonth":
                      default:
                        start = DateTime(now.year, now.month - 1, 1);
                        end = DateTime(now.year, now.month, 0);
                        break;
                    }

                    // Get records specifically for this range (without affecting UI)
                    // Since providers store one list, we must filter a COPY or rely on repository.
                    // IMPORTANT: Providers currently modify state. If we use existing provider methods, UI changes.
                    // Solution: Use repository directly OR accept that UI changes (User requested "Separate filter").
                    // Usually correct UX: If I download a report for "Last Month", show me that view or just gen PDF.
                    // The user asked for "separate filter for the pdf download".
                    // We can fetch data manually using the same logic as providers but locally.
                    // BUT, Providers cache all records in `_allRecords`. We can access `_allRecords` if we expose a getter or helper.
                    // DairyProvider exposes `records` (filtered). It does NOT expose `allRecords`.
                    // Let's modify Provider to allow getting filtered list WITHOUT changing state?
                    // Or easier: temporarily filter, gen PDF, then restore? No, that flickers UI.

                    // Hack/Simpler approach: The providers ALREADY HAVE all data in memory (loaded on init).
                    // We can just ask them "Give me records effectively filtering this list".
                    // But the public API only exposes `records` (filtered).
                    // For now, I'll filter the current UI's `records` IF the user selects "Current View"?
                    // No, user wants separate filter.

                    // Real solution: Add `getRecordsForRange(start, end)` to providers that returns a List, not void.
                    final milkList = await dp.getRecordsForRange(start, end);
                    final expenseList = await ep.getRecordsForRange(start, end);

                    final price =
                        double.tryParse(_priceController.text) ?? 30.0;

                    await ReportGenerator().generateAndPrint(
                      milkRecords: milkList,
                      expenseRecords: expenseList,
                      pricePerLiter: price,
                      // Use explicit date range for all report types to be clear
                      periodLabel:
                          "${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}",
                      isDownload: true,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}



class _ExpenseCard extends StatelessWidget {
  final ExpenseEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (entry.category) {
      case ExpenseCategory.feed:
        icon = Icons.grass;
        break;
      case ExpenseCategory.medical:
        icon = Icons.medical_services;
        break;
      case ExpenseCategory.rice:
        icon = Icons.rice_bowl;
        break;
      case ExpenseCategory.others:
        icon = Icons.category;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade50,
          child: Icon(icon, color: Colors.red),
        ),
        title: Text(
          entry.category.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${DateFormat('MMM dd').format(entry.date)} - ${entry.notes ?? ''}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                "- Rs.${entry.amount.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
