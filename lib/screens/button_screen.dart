import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_maker/helper/pdf_downloader.dart';
import 'package:pdf_maker/helper/pdf_generator.dart';
import 'package:pdf_maker/helper/test_file.dart';
import 'package:pdf_maker/model/customer.dart';
import 'package:pdf_maker/model/invoice.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../model/supplier.dart'; // For Android printing

class ButtonScreen extends StatelessWidget {
  const ButtonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate PDF Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _generateAndPrintPdf();
              },
              child: const Text("Generate PDF"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final date = DateTime.now();
                final dueDate = date.add(const Duration(days: 7));

                final invoice = Invoice(
                  supplier: const Supplier(
                    name: 'Sarah Field',
                    address: 'Sarah Street 9, Beijing, China',
                    paymentInfo: 'https://paypal.me/sarahfieldzz',
                  ),
                  customer: const Customer(
                    name: 'Apple Inc.',
                    address: 'Apple Street, Cupertino, CA 95014',
                  ),
                  info: InvoiceInfo(
                    date: date,
                    dueDate: dueDate,
                    description: 'My description...',
                    number: '${DateTime.now().year}-9999',
                  ),
                  item: [
                    InvoiceItem(
                      description: 'Coffee',
                      date: DateTime.now(),
                      quantity: 3,
                      vat: 0.19,
                      unitPrice: 5.99,
                    ),
                    InvoiceItem(
                      description: 'Water',
                      date: DateTime.now(),
                      quantity: 8,
                      vat: 0.19,
                      unitPrice: 0.99,
                    ),
                    InvoiceItem(
                      description: 'Orange',
                      date: DateTime.now(),
                      quantity: 3,
                      vat: 0.19,
                      unitPrice: 2.99,
                    ),
                    InvoiceItem(
                      description: 'Apple',
                      date: DateTime.now(),
                      quantity: 8,
                      vat: 0.19,
                      unitPrice: 3.99,
                    ),
                    InvoiceItem(
                      description: 'Mango',
                      date: DateTime.now(),
                      quantity: 1,
                      vat: 0.19,
                      unitPrice: 1.59,
                    ),
                    InvoiceItem(
                      description: 'Blue Berries',
                      date: DateTime.now(),
                      quantity: 5,
                      vat: 0.19,
                      unitPrice: 0.99,
                    ),
                    InvoiceItem(
                      description: 'Lemon',
                      date: DateTime.now(),
                      quantity: 4,
                      vat: 0.19,
                      unitPrice: 1.29,
                    ),
                  ],
                );

                // final pdfFile = await PdfGenerator.create_pdf(invoice);
                await DownloadMyPdf.CreatePdf(invoice);
                // pdfDownloader.openFile(pdfFile);
              },
              child: const Text("Download Bill PDF"),
            )
          ],
        ),
        // child: ElevatedButton(
        //   onPressed: () async {
        //     await _generateAndPrintPdf();
        //   },
        //   child: const Text("Generate PDF"),
        // ),
      ),
    );
  }

  Future<void> _generateAndPrintPdf() async {
    final pdfDoc = await createPdf();
    final bytes = await pdfDoc.save();

    if (kIsWeb) {
      // For web, create an anchor element and trigger a download
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'barcode_grid.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else if (Platform.isAndroid) {
      // For Android, print the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'barcode_grid.pdf',
      );
    } else {
      // Use share_plus for iOS (consider AirPrint compatibility)
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/barcode_grid.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: "My Pdf");
    }
  }

  Future<pw.Document> createPdf() async {
    final doc = pw.Document();
    final page1 = pw.Page(
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.GridView(
        crossAxisCount: 6,
        childAspectRatio: 0.5,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        children: List.generate(
          12,
          (index) => pw.BarcodeWidget(
            barcode: pw.Barcode.code128(),
            data: 'code1234567890 $index',
          ),
        ),
      ),
    );

    final page2 = pw.Page(
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.GridView(
          crossAxisCount: 7,
          childAspectRatio: 0.5,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          children: List.generate(
            90,
            (index) => pw.BarcodeWidget(
                barcode: pw.Barcode.dataMatrix(),
                data: 'abcd1234efgh5678 $index',
                drawText: true),
          )),
    );

    doc.addPage(page1);
    doc.addPage(page2);
    return doc;
  }
}

Future<void> _generateAndDownloadBillPdf() async {
  final pdfDoc = await createBillPdf();
  final bytes = await pdfDoc.save();

  if (kIsWeb) {
    // For web, create an anchor element and trigger a download
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'bill.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  } else if (Platform.isAndroid || Platform.isIOS) {
    // For mobile, save and share the PDF
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/bill.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: "My Bill");
  }
}

Future<pw.Document> createBillPdf() async {
  final doc = pw.Document();
  final page = pw.Page(
    margin: const pw.EdgeInsets.all(20), // Set margins here
    build: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Bill',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),
        pw.Text('Item 1: \$10.00'),
        pw.Text('Item 2: \$15.00'),
        pw.Text('Item 3: \$20.00'),
        pw.Divider(),
        pw.Text('Total: \$45.00',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );

  doc.addPage(page);
  return doc;
}

Future<Directory> getTemporaryDirectory() async {
  return Directory.systemTemp;
}
