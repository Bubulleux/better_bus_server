import 'package:better_bus_core/core.dart';
class Report {
  final Station station;
  late final DateTime time;
  late final int id;

  // key: updateTime, value: stillThere
  final Map<DateTime, bool> updates = {};

  Report(this.station) {
    time = DateTime.now();
    id = hashCode;
    updates[time] = true;
  }

  void update(bool sillThere) {
    updates[DateTime.now()] = sillThere;
  }

  @override
  int get hashCode => time.hashCode ^ station.hashCode;

  Map<String, dynamic> toJson() => {
    "id": id,
    "station": station.id,
    "updates": updates.map((key, value) => MapEntry(key.millisecondsSinceEpoch.toString(), value)),
  };
}