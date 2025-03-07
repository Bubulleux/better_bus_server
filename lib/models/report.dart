import 'dart:convert';
import 'dart:ffi';

import 'package:better_bus_core/core.dart';
import 'package:postgres/postgres.dart';

class ServerReport extends Report {
  DateTime creationDate = DateTime.now();

  // TODO: Make it better
  bool get keep => updates.containsValue(true);

  ServerReport(super.station, super.id, DateTime firstUpdate) {
    updates[firstUpdate] = true;
  }
  ServerReport.empty(super.station, super.id);

  void update(bool sillThere) {
    updates[DateTime.now()] = sillThere;
  }

  @override
  int get hashCode => station.hashCode;

  Map<String, dynamic> toJson() => {
    "id": id,
    "station": station.id,
    "updates": updates.map((key, value) => MapEntry(key.millisecondsSinceEpoch.toString(), value)),
  };

  void addUpdate(DateTime time, bool stillThere) {
    updates[time] = stillThere;
  }

  factory ServerReport.fromDbRaw(Map<String, dynamic> row, Map<int, Station> stations)  {
    Station station = stations[row["station_id"]]!;
    final id = row["report_id"];
    final report =  ServerReport.empty(station, id);
    report.loadUpdate(row);
    return report;
  }

  void loadUpdate(Map<String, dynamic> row) {
    final timeEpoch = double.parse(row["time_epoch"] as String).toInt();
    final time = DateTime.fromMillisecondsSinceEpoch(timeEpoch * 1000);
    final stillThere = row["still_there"];

    updates[time] = stillThere;
  }
}