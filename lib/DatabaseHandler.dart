import 'package:better_bus_core/core.dart';
import 'package:postgres/postgres.dart';
import 'package:server/models/report.dart';

class DBHandler {
  final Endpoint endpoint;
  Connection? _conn;

  Connection get conn => _conn!;

  DBHandler(this.endpoint);

  DBHandler.localhost()
      : this(Endpoint(
          host: '192.168.188.242',
          port: 5432,
          database: 'better-bus',
          username: 'localuser',
          password: 'easypassword',
        ));

  Future<Connection?> connect() async {
    _conn = await Connection.open(endpoint);
    print("Data base connection success");
    return conn;
  }

  Future<bool> sendReport(Report report) async {
    await conn.execute(
        'INSERT INTO public.reports("reportId", "stationId")'
        r'VALUES ($1, $2);',
        parameters: [report.id, report.station.id]);

    return await updateReport(report, report.updates.entries.last);
  }

  Future<bool> updateReport(Report report, MapEntry<DateTime, bool> update) async {
    print(update.key);
    await conn.execute(
        'INSERT INTO public.report_updates("reportId", "stationId", "updatetime", "stillThere")'
        r'VALUES ($1, $2,$3, $4);',
        parameters: [report.id, report.station.id, update.key.toString(), update.value.toString().toUpperCase()]
    );
    return true;
  }
  
  Future<Map<int, ServerReport>> loadReports(Map<int, Station> stations) async {
    final result = await conn.execute(
        Sql('SELECT * FROM public.report_updates')
    );
    print(result.schema);
    Map<int, ServerReport> reports = {};
    for (var row in result) {
      final map = row.toColumnMap();
      final int id = map["reportId"]!;
      if (reports.containsKey(id)) {
        reports[id]!.addUpdate(map);
      } else {
        reports[id] = ServerReport.fromDbRaw(map, stations);
      }
    }
    return reports;
  }
}
