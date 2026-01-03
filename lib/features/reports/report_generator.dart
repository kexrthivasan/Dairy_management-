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
  }) async {
    final pdf = await _buildPdfDocument(
      milkRecords,
      expenseRecords,
      pricePerLiter,
      periodLabel,
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
    String periodLabel,
  ) async {
    final pdf = pw.Document();

    milkRecords.sort((a, b) => a.date.compareTo(b.date));

    double totalMilk = 0;
    for (var r in milkRecords) {
      totalMilk += r.totalYield;
    }
    double totalIncome = totalMilk * pricePerLiter;
    double totalExpense = expenseRecords.fold(0, (sum, e) => sum + e.amount);
    double netProfit = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(periodLabel, pricePerLiter),
            pw.SizedBox(height: 20),
            _buildSummaryTable(totalMilk, totalIncome, totalExpense, netProfit),
            pw.SizedBox(height: 20),
            pw.Text(
              "Daily Details",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
            pw.SizedBox(height: 10),
            _buildMilkTable(milkRecords, pricePerLiter),
            pw.SizedBox(height: 20),
            _buildExpenseTable(expenseRecords),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );
    return pdf;
  }

  pw.Widget _buildHeader(String period, double price) {
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
              "Price: Rs. $price / L",
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
          income.toStringAsFixed(1),
          expense.toStringAsFixed(1),
          profit.toStringAsFixed(1),
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

  pw.Widget _buildMilkTable(List<MilkEntry> records, double price) {
    if (records.isEmpty) return pw.Text("No milk records for this period.");

    // Calculate totals
    double sumMilk = 0;
    for (var r in records) {
      sumMilk += r.totalYield;
    }
    double sumAmount = sumMilk * price;

    final data = records.map((r) {
      final amount = r.totalYield * price;
      return [
        DateFormat('dd-MMM-yyyy').format(r.date),
        r.morningMilk.toStringAsFixed(1),
        r.eveningMilk.toStringAsFixed(1),
        r.totalYield.toStringAsFixed(1),
        amount.toStringAsFixed(1),
      ];
    }).toList();

    // Add Total Row
    data.add([
      'TOTAL',
      '',
      '',
      sumMilk.toStringAsFixed(1),
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
              "Designed and developed by Keerthivasan",
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
