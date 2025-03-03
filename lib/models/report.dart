import 'package:better_bus_core/core.dart';

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
}