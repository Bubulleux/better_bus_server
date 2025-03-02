import 'package:core/core.dart';
class Report {
  final Station station;
  late final DateTime time;

  Report(this.station) {
    time = DateTime.now();
  }


}