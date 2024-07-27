import 'package:intl/intl.dart';

class Utils{
  static formatDate(DateTime date)=> DateFormat.yMd().format(date);
  static formatPrice(double price)=> '\$ ${price.toStringAsFixed(2)}';
}