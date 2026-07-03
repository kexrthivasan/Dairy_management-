import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/models/milk_entry.dart';
import '../../data/models/expense_entry.dart';

class ReportGenerator {
  Future<void> generateAndPrint({
    required List<MilkEntry> milkRecords,
    required List<ExpenseEntry> expenseRecords,
    required double pricePerLiter,
    required String periodLabel,
    bool isDownload = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = await _buildPdfDocument(
      milkRecords,
      expenseRecords,
      pricePerLiter,
      periodLabel,
      startDate: startDate,
      endDate: endDate,
    );

    final name =
        'Report_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.pdf';

    if (isDownload) {
      await Printing.sharePdf(bytes: await pdf.save(), filename: name);
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: name.replaceAll('.pdf', ''), // layoutPdf adds extension usually
      );
    }
  }

  Future<pw.Document> _buildPdfDocument(
    List<MilkEntry> milkRecords,
    List<ExpenseEntry> expenseRecords,
    double pricePerLiter,
    String periodLabel, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    // Fill in missing dates if range is provided
    List<MilkEntry> filledMilkRecords = [];
    if (startDate != null && endDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      final Map<String, MilkEntry> existingMap = {
        for (var r in milkRecords) DateFormat('yyyy-MM-dd').format(r.date): r,
      };

      var current = start;
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        final key = DateFormat('yyyy-MM-dd').format(current);
        if (existingMap.containsKey(key)) {
          filledMilkRecords.add(existingMap[key]!);
        } else {
          filledMilkRecords.add(
            MilkEntry(
              date: current,
              morningMilk: 0.0,
              eveningMilk: 0.0,
              pricePerLiter: 0.0,
              notes: '',
              createdAt: current,
            ),
          );
        }
        current = current.add(const Duration(days: 1));
      }
    } else {
      filledMilkRecords = List.from(milkRecords);
    }

    filledMilkRecords.sort((a, b) => a.date.compareTo(b.date));
    expenseRecords.sort((a, b) => a.date.compareTo(b.date));

    // Overall Totals
    double totalMilk = 0, totalIncome = 0;
    for (var r in filledMilkRecords) {
      totalMilk += r.totalYield;
      final actualPrice = r.pricePerLiter > 0 ? r.pricePerLiter : pricePerLiter;
      totalIncome += r.totalYield * actualPrice;
    }
    double totalExpense = expenseRecords.fold(0, (sum, e) => sum + e.amount);
    double netProfit = totalIncome - totalExpense;

    // Grouping by Month (Format: yyyy-MM)
    final Set<String> allMonths = {};
    final Map<String, List<MilkEntry>> milkByMonth = {};
    final Map<String, List<ExpenseEntry>> expenseByMonth = {};

    for (var r in filledMilkRecords) {
      final key = DateFormat('yyyy-MM').format(r.date);
      allMonths.add(key);
      milkByMonth.putIfAbsent(key, () => []).add(r);
    }
    for (var e in expenseRecords) {
      final key = DateFormat('yyyy-MM').format(e.date);
      allMonths.add(key);
      expenseByMonth.putIfAbsent(key, () => []).add(e);
    }

    final sortedMonths = allMonths.toList()..sort();

    bool isFirstPage = true;

    if (sortedMonths.isEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(periodLabel, pricePerLiter),
              pw.SizedBox(height: 20),
              pw.Text("No data available for the selected period."),
            ];
          },
        ),
      );
      return pdf;
    }

    for (final monthKey in sortedMonths) {
      final monthMilkRecords = milkByMonth[monthKey] ?? [];
      final monthExpenseRecords = expenseByMonth[monthKey] ?? [];

      double mMilk = 0, mIncome = 0;
      for (var r in monthMilkRecords) {
        mMilk += r.totalYield;
        final actualPrice = r.pricePerLiter > 0
            ? r.pricePerLiter
            : pricePerLiter;
        mIncome += r.totalYield * actualPrice;
      }
      double mExpense = monthExpenseRecords.fold(0, (sum, e) => sum + e.amount);
      double mProfit = mIncome - mExpense;

      // Get human readable month name
      final monthDate = DateFormat('yyyy-MM').parse(monthKey);
      final monthLabel = DateFormat('MMMM yyyy').format(monthDate);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            final widgets = <pw.Widget>[];

            // Add Header only on the first page or change it to be per month.
            if (isFirstPage) {
              widgets.add(_buildHeader(periodLabel, pricePerLiter));
              widgets.add(pw.SizedBox(height: 10));
              widgets.add(
                pw.Text(
                  "Overall Summary",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
              widgets.add(pw.SizedBox(height: 10));
              widgets.add(
                _buildSummaryTable(
                  totalMilk,
                  totalIncome,
                  totalExpense,
                  netProfit,
                ),
              );
              widgets.add(pw.SizedBox(height: 30));
              isFirstPage = false;
            }

            // Month Title
            widgets.add(
              pw.Center(
                child: pw.Text(
                  "Month: $monthLabel",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
            // Monthly Summary Table
            widgets.add(_buildSummaryTable(mMilk, mIncome, mExpense, mProfit));
            widgets.add(pw.SizedBox(height: 20));

            widgets.add(
              pw.Text(
                "Daily Details - $monthLabel",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
            widgets.add(_buildMilkTable(monthMilkRecords, pricePerLiter));
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(_buildExpenseTable(monthExpenseRecords));
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(_buildFooter());

            return widgets;
          },
        ),
      );
    }
    return pdf;
  }

  pw.Widget _buildHeader(String period, double defaultPrice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            "Home Dairy Milk Report",
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Period: $period", style: const pw.TextStyle(fontSize: 14)),
            pw.Text(
              "Default Price: Rs. $defaultPrice / L",
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.green),
      ],
    );
  }

  pw.Widget _buildSummaryTable(
    double milk,
    double income,
    double expense,
    double profit,
  ) {
    return pw.Table.fromTextArray(
      headers: [
        'Total Milk (L)',
        'Total Income',
        'Total Expense',
        'Net Profit',
      ],
      data: [
        [
          milk.toStringAsFixed(1),
          'Rs. ${income.toStringAsFixed(1)}',
          'Rs. ${expense.toStringAsFixed(1)}',
          'Rs. ${profit.toStringAsFixed(1)}',
        ],
      ],
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
      cellAlignment: pw.Alignment.center,
      cellStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
    );
  }

  pw.Widget _buildMilkTable(List<MilkEntry> records, double defaultPrice) {
    if (records.isEmpty) return pw.Text("No milk records for this month.");

    // Calculate totals
    double sumMilk = 0;
    double sumMorning = 0;
    double sumEvening = 0;
    double sumAmount = 0;

    for (var r in records) {
      sumMilk += r.totalYield;
      sumMorning += r.morningMilk;
      sumEvening += r.eveningMilk;
      final actualPrice = r.pricePerLiter > 0 ? r.pricePerLiter : defaultPrice;
      sumAmount += r.totalYield * actualPrice;
    }

    final data = records.map((r) {
      final actualPrice = r.pricePerLiter > 0 ? r.pricePerLiter : defaultPrice;
      final amount = r.totalYield * actualPrice;
      return [
        DateFormat('dd-MMM-yyyy').format(r.date),
        r.morningMilk.toStringAsFixed(3),
        r.eveningMilk.toStringAsFixed(3),
        r.totalYield.toStringAsFixed(3),
        amount.toStringAsFixed(1),
      ];
    }).toList();

    // Add Total Row
    data.add([
      'TOTAL',
      sumMorning.toStringAsFixed(3),
      sumEvening.toStringAsFixed(3),
      sumMilk.toStringAsFixed(3),
      sumAmount.toStringAsFixed(1),
    ]);

    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
      cellAlignment: pw.Alignment.centerRight,
      headers: ['Date', 'Morn(L)', 'Eve(L)', 'Tot(L)', 'Amt'],
      data: data,
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Date
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5), // Amount
      },
    );
  }

  pw.Widget _buildExpenseTable(List<ExpenseEntry> records) {
    if (records.isEmpty) return pw.Container(); // Or empty text

    // Calculate total
    double sumExpense = records.fold(0, (sum, e) => sum + e.amount);

    final data = records.map((e) {
      return [
        DateFormat('dd-MMM-yyyy').format(e.date),
        e.category.name.toUpperCase(),
        e.notes ?? '',
        e.amount.toStringAsFixed(1),
      ];
    }).toList();

    // Add Total Row
    data.add(['TOTAL', '', '', sumExpense.toStringAsFixed(1)]);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Expense Transactions",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.red700),
          cellAlignment: pw.Alignment.centerLeft,
          headers: ['Date', 'Category', 'Notes', 'Amount'],
          data: data,
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          // Right align the Amount column (index 3)
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "Generated on ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Text(
              "Designed and developed by Dairy Manager",
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
