import 'dart:convert';
import 'dart:ffi';

import 'package:better_bus_core/core.dart';
import 'package:postgres/postgres.dart';

class ServerReport extends Report {
  DateTime creationDate = DateTime.now();

  ServerReport(station) : super(station, station.hashCode){
    updates[DateTime.now()] = true;
  }

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

  factory ServerReport.fromDbRaw(Map<String, dynamic> row, Map<int, Station> stations)  {
    Station station = stations[row["stationId"]]!;
    final report =  ServerReport(station);
    report.updates.clear();
    report.addUpdate(row);
    return report;
  }

  void addUpdate(Map<String, dynamic> row) {
    UndecodedBytes bytes = row["updatetime"];
    bytes.typeOid;

    int timestamp = bytes.bytes.buffer.asInt64List().first;
    print(timestamp);
    print(DateTime.fromMicrosecondsSinceEpoch(timestamp));

    print(Time.fromMicroseconds(bytes.typeOid));
    updates[row["updatetime"]!] = row["stillThere"];
  }
}