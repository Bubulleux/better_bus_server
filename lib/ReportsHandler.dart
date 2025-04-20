import 'package:better_bus_core/core.dart';
import 'package:server/DatabaseHandler.dart';
import 'package:server/analytic.dart';

import 'models/report.dart';

class ReportsHandler {
  GTFSProvider provider;
  Map<int, ServerReport> reports = {};
  Map<int, Station> stationsMap = {};
  Set<int> notSavedReport = {};
  ApiAnalytic analytic = ApiAnalytic();
  final DBHandler? db;


  ReportsHandler(this.provider, this.db);

  Future<bool> init() async {
    analytic.startHook();
    var success = await provider.init();
    success &= db == null || await db?.connect() != null;
    if (db == null) print("WARNING: No Database provider !!");

    if (!success) return Future.value(false);
    stationsMap.addEntries(
        (await provider.getStations()).map((e) => MapEntry(e.id, e)));

    reports = await db!.loadReports(stationsMap);
    final cleaned = cleanReport(null);
    print("${cleaned.length} Report cleaned");
    return true;
  }

  Future<ServerReport?> sendReport(int stationId) async {
    if (!stationsMap.containsKey(stationId)) return null;
    final station = stationsMap[stationId]!;
    final existingReport = reports.values.where(
        (e) => e.station == station
    ).firstOrNull;

    if (existingReport != null) {
      print("Creating abord it will update");
      return reportUpdate(existingReport.id, true);
    }

    final report = await _createReport(station);
    return report;
  }

  Future<ServerReport?> _createReport(Station station) async {
    int? id = await db?.createReport(station);
    if (id == null) {
      id ??= reports.length.hashCode ^ DateTime.now().hashCode;
      print("Database not found, report created but not saved with id $id");
      notSavedReport.add(id);
    }
    DateTime time = (await db!.updateReport(id, true))!;
    reports[id] = ServerReport(station, id, time);
    return reports[id];
  }

  Future<ServerReport?> reportUpdate(int reportId, bool stillThere) async {
    if (!reports.containsKey(reportId)) return Future.value(null);

    final report = reports[reportId];
    if (report == null) return Future.value(null);

    final time = await db?.updateReport(reportId, stillThere);
    if (time == null) return Future.value(null);

    report.addUpdate(time, stillThere);

    return Future.value(report);
  }

  Future<List<ServerReport>> getReports() async {
    await dropOld(Duration(hours: 1));
    return Future.value(reports.values.toList());
  }

  Future<Set<int>> dropOld(Duration limit) async {
    Set<int> old = await db!.removeOld(limit);
    reports.removeWhere((k,_) => old.contains(k));
    return old;
  }

  List<ServerReport> cleanReport(DateTime? limit) {
    final removeId =
        reports.entries.where((e) => !e.value.keep).map((e) => e.key).toSet();
    final removed = removeId.map((e) => reports[e]!).toList();
    reports.removeWhere((k, _) => removeId.contains(k));
    return removed;
  }

  int countReports() {
    return reports.length;
  }

  ApiStatus getStatus() {
    analytic.gotStatus();
    return ApiStatus(true, version: "1.1.0");
  }
}
