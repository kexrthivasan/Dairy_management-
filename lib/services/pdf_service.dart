import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/milk_entry.dart';
import 'package:intl/intl.dart';

class PdfService {
  Future<void> generateAndPrint(List<MilkEntry> records) async {
    final pdf = pw.Document();

    // Calculate totals
    double totalMorning = 0;
    double totalEvening = 0;
    double grandTotal = 0;

    for (var r in records) {
      totalMorning += r.morningMilk;
      totalEvening += r.eveningMilk;
      grandTotal += r.totalYield;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Home Dairy Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(DateFormat('MMM dd, yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: [
                'Date',
                'Morning (L)',
                'Evening (L)',
                'Total (L)',
                'Notes',
              ],
              data: [
                ...records.map(
                  (r) => [
                    DateFormat('yyyy-MM-dd').format(r.date),
                    r.morningMilk.toStringAsFixed(1),
                    r.eveningMilk.toStringAsFixed(1),
                    r.totalYield.toStringAsFixed(1),
                    r.notes,
                  ],
                ),
                // Summary Row
                [
                  'TOTALS',
                  totalMorning.toStringAsFixed(1),
                  totalEvening.toStringAsFixed(1),
                  grandTotal.toStringAsFixed(1),
                  '',
                ],
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
