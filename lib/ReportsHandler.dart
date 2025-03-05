import 'package:better_bus_core/core.dart';
import 'package:server/models/custom_responses.dart';

import 'models/report.dart';

class ReportsHandler {
  GTFSProvider provider;
  Map<int, ServerReport> reports = {};
  Map<int, Station> stationsMap = {};

  ReportsHandler(this.provider);

  Future<bool> init() async {
    final success = await provider.init();

    if (!success) return Future.value(false);
    stationsMap.addEntries(
        (await provider.getStations()).map((e) => MapEntry(e.id, e)));
    return true;
  }

  Future<ServerReport?> sendReport(int stationId) async {
    if (!stationsMap.containsKey(stationId)) return null;

    final report = ServerReport(stationsMap[stationId]!);
     _addReport(report);
     return report;
  }

  Future<bool> _addReport(ServerReport report) async {
    reports[report.id] = report;
    return Future.value(true);
  }

  Future<ServerReport?> reportUpdate(int reportId, bool stillThere) {
    if (!reports.containsKey(reportId)) return Future.value(null);
    final report = reports[reportId];
    report!.update(stillThere);
    return Future.value(report);
  }

  Future<List<ServerReport>> getReports() async {
    return Future.value(reports.values.toList());
  }

  int countReports() {
    return reports.length;
  }
}
