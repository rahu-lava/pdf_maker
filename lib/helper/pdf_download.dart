import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class pdfDownload {
  static Future<void> openFile(
      {required String name, required Document pdf}) async {
    final bytes = await pdf.save();

    if (kIsWeb) {
      // For web, create an anchor element and trigger a download
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '$name.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else if (Platform.isAndroid) {
      // For Android, print the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: '$name.pdf',
      );
    } else {
      // Use share_plus for iOS (consider AirPrint compatibility)
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$name.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: "My Pdf");
    }
  }
}
