import 'dart:io';

import 'package:better_bus_core/core.dart';
import 'package:postgres/postgres.dart';
import 'package:server/models/report.dart';

class DBHandler {
  final Endpoint endpoint;
  Connection? _conn;

  Connection get conn => _conn!;

  DBHandler(this.endpoint) {
    print("DB CREATE ${endpoint.username} ${endpoint.password} ${endpoint.host}");
  }

  DBHandler.localhost()
      : this(Endpoint(
          host: '192.168.188.242',
          port: 5432,
          database: 'better-bus',
          username: 'localuser',
          password: 'password',
        ));

  DBHandler.env()
      : this(Endpoint(
          host: Platform.environment["DB_HOST"] ?? 'localhost',
          port: int.tryParse(Platform.environment["DB_PORT"] ?? "") ?? 5432,
          database: Platform.environment["DB_NAME"] ?? 'better-bus',
          username: Platform.environment["DB_USER"] ?? 'bbuser',
          password: Platform.environment["DB_PASSWORD"]!,
        ));

  Future<Connection?> connect() async {
    _conn = await Connection.open(endpoint);
    print("Data base connection success");
    return conn;
  }

  Future<int> createReport(Station station) async {
    final result = await conn.execute(
        'INSERT INTO public.reports("station_id")'
        r'VALUES ($1) RETURNING id',
        parameters: [station.id.toString()]);
    int id = result.first.first as int;
    print("Report generated with id $id");
    return id;
  }

  Future<DateTime?> updateReport(int reportId, bool stillThere) async {
    final result = await conn.execute(
        'INSERT INTO public.report_updates(report_id, "still_there", "time")'
        r'VALUES ($1, $2, NOW())'
        'RETURNING EXTRACT (EPOCH FROM time) * 1000;',
        parameters: [reportId, stillThere.toString()]);
    final timeEpoch = double.parse(result.first.first as String).toInt();
    return DateTime.fromMillisecondsSinceEpoch(timeEpoch);
  }

  Future<Map<int, ServerReport>> loadReports(Map<int, Station> stations,
      {Duration? startFrom = const Duration(hours: 1)}) async {
    final startDate = startFrom != null
        ? DateTime.now().subtract(startFrom!)
        : DateTime.fromMillisecondsSinceEpoch(0);
    final result = await conn.execute(
      'SELECT report_id, station_id, still_there, '
      r'EXTRACT (EPOCH FROM time) AS time_epoch '
      'FROM public.report_updates '
      'LEFT JOIN public.reports '
      'ON report_updates.report_id = public.reports.id '
      'WHERE alive = true '
      r"AND EXTRACT (EPOCH FROM time) > $1 "
      r'ORDER BY time; ',
      parameters: [startDate.millisecondsSinceEpoch / 1000],
    );

    print(result.schema);
    Map<int, ServerReport> reports = {};
    for (var row in result) {
      final map = row.toColumnMap();
      final int id = map["report_id"]!;
      if (reports.containsKey(id)) {
        reports[id]!.loadUpdate(map);
      } else {
        reports[id] = ServerReport.fromDbRaw(map, stations);
      }
    }
    print("Loaded ${reports.length} reports");
    print("${result.length} Updated found");
    return reports;
  }

  String formatDate(DateTime date) {
    return date.toUtc().toIso8601String();
  }
}
