import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';
import 'package:pdf_maker/helper/pdf_download.dart';
import 'package:pdf_maker/model/customer.dart';
import 'package:pdf_maker/model/invoice.dart';
import 'package:pdf_maker/model/supplier.dart';
import 'package:pdf_maker/utils.dart';

class DownloadMyPdf {
  static Future<void> CreatePdf(Invoice invoice) async {
    final pdf = Document();

       pdf.addPage(pw.MultiPage(
        build: (context) => [
              buildHeader(invoice),
              SizedBox(height: 3 * PdfPageFormat.cm),
                buildTitle(invoice),
              buildInvoice(invoice),
              Divider(),
              buildTotal(invoice),
            ],
        footer: (context) => buildFooter(invoice)));

    // final page = pw.MultiPage(
    //   build: (context) => [
    //     buildHeader(invoice),
    //     pw.SizedBox(height: 3 * PdfPageFormat.cm),
    //     buildTitle(invoice),
    //     buildInvoice(invoice),
    //     pw.Divider(),
    //     buildTotal(invoice),
    //   ],
    // );

    await pdfDownload.openFile(name: "MyInvoice", pdf: pdf); 
    
  }

  static Widget buildHeader(Invoice invoice) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 1 * PdfPageFormat.cm),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        buildSupplierAddress(invoice.supplier),
        Container(
            height: 50,
            width: 50,
            child: BarcodeWidget(
                data: invoice.info.number, barcode: Barcode.qrCode())),
      ]),
      SizedBox(height: 1 * PdfPageFormat.cm),
      Row(
          // crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildCustomerAddress(invoice.customer),
            buildInvoiceInfo(invoice.info)
          ])
    ]);
  }

  static Widget buildSupplierAddress(Supplier supplier) {
    return Column(children: [
      Text(supplier.name, style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 1 * PdfPageFormat.mm),
      Text(supplier.address)
    ]);
  }

  static Widget buildCustomerAddress(Customer customer) {
    return Column(children: [Text(customer.name), Text(customer.address)]);
  }

  static buildInvoiceInfo(InvoiceInfo info) {
    // final paymentTerms = '${info.dueDate.difference(info.date).inDays} days';
    final PaymentTerms = '${(info.dueDate.difference(info.date).inDays)} days';
    final titles = <String>[
      'Invoice Number:',
      'Invoice Date:',
      'Payment Terms:',
      'Due Date:'
    ];
    final data = <String>[
      info.number,
      Utils.formatDate(info.date),
      PaymentTerms,
      Utils.formatDate(info.dueDate)
    ];

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(titles.length, (index) {
          final title = titles[index];
          final value = data[index];
          return buildText(title: title, value: value, width: 200);
        }));
  }

  static buildText(
      {required String title,
      required String value,
      double width = double.infinity,
      TextStyle? textStyle,
      bool flag = false}) {
    final style = textStyle ?? TextStyle(fontWeight: FontWeight.bold);

    return Container(
        width: width,
        child: Row(
          children: [
            Expanded(child: Text(title, style: style)),
            Text(value, style: flag ? style : null),
          ],
        ));
  }

  static Widget buildTitle(Invoice invoice) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('First Pdf',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      SizedBox(height: 0.8 * PdfPageFormat.cm),
      Text(invoice.info.description),
      SizedBox(height: .8 * PdfPageFormat.cm)
    ]);
  }

  static Widget buildInvoice(Invoice invoice) {
    final headers = [
      'Description',
      'Date',
      'Quantity',
      'Unit Price',
      'VAT',
      'Total'
    ];

    final data = invoice.item.map((item) {
      final total = item.unitPrice * item.quantity * (1 + item.vat);

      return [
        item.description,
        Utils.formatDate(item.date),
        '${item.quantity}',
        '\$ ${item.unitPrice}',
        '${item.vat} %',
        '\$ ${total.toStringAsFixed(2)}',
      ];
    }).toList();

    return TableHelper.fromTextArray(
      data: data,
      border: null,
      headers: headers,
      headerStyle: TextStyle(fontWeight: FontWeight.bold),
      headerDecoration: const BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: Alignment.centerLeft,
        1: Alignment.centerRight,
        2: Alignment.centerRight,
        3: Alignment.centerRight,
        4: Alignment.centerRight,
        5: Alignment.centerRight,
      },
    );
  }

  static Widget buildTotal(Invoice invoice) {
    final netTotal = invoice.item
        .map((item) => item.unitPrice * item.quantity)
        .reduce((value, element) => value + element);
    final vatPercent = invoice.item.first.vat;
    final vat = netTotal + vatPercent;
    final total = netTotal + vat;

    return Container(
        alignment: Alignment.centerRight,
        child: Row(children: [
          Spacer(flex: 6),
          Expanded(
              flex: 4,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildText(
                        title: 'Net Total',
                        value: Utils.formatPrice(netTotal),
                        flag: true),
                    buildText(
                        title: 'Vat ${vatPercent * 100} %',
                        value: Utils.formatPrice(vat),
                        flag: false),
                    Divider(),
                    buildText(
                      title: 'Total amount due',
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      value: Utils.formatPrice(total),
                      flag: true,
                    ),
                    SizedBox(height: 2 * PdfPageFormat.mm),
                    Container(height: 1, color: PdfColors.grey400),
                    SizedBox(height: 0.5 * PdfPageFormat.mm),
                    Container(height: 1, color: PdfColors.grey400),
                  ]))
        ]));
  }

  static Widget buildFooter(Invoice invoice) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Divider(),
      SizedBox(height: 2 * PdfPageFormat.mm),
      buildSimpleText(title: 'Address', value: invoice.supplier.address),
      SizedBox(height: 1 * PdfPageFormat.mm),
      buildSimpleText(title: 'Paypal', value: invoice.supplier.paymentInfo)
    ]);
  }

  static buildSimpleText({
    required String title,
    required String value,
  }) {
    final style = TextStyle(fontWeight: FontWeight.bold);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: style),
        SizedBox(width: 2 * PdfPageFormat.mm),
        Text(value),
      ],
    );
  }
}
