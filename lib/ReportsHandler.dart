import 'package:better_bus_core/core.dart';

import 'models/report.dart';

class ReportsHandler {
  GTFSProvider provider;
  Map<int, Report> reports = {};
  Map<int, Station> stationsMap = {};

  ReportsHandler(this.provider);

  Future<bool> init() async {
    final success = await provider.init();

    if (!success) return Future.value(false);
    stationsMap.addEntries(
        (await provider.getStations()).map((e) => MapEntry(e.id, e)));
    return true;
  }

  Future<bool> sendReport(int stationId) async {
    if (!stationsMap.containsKey(stationId)) return false;

    return _addReport(Report(stationsMap[stationId]!));
  }

  Future<bool> _addReport(Report report) async {
    reports[report.id] = report;
    return Future.value(true);
  }

  Future<bool> reportUpdate(int reportId, bool stillThere) {
    if (!reports.containsKey(reportId)) return Future.value(false);
    final report = reports[reportId];
    report!.update(stillThere);
    return Future.value(true);
  }

  Future<List<Report>> getReports() async {
    return Future.value(reports.values.toList());
  }

  int countReports() {
    return reports.length;
  }
}
