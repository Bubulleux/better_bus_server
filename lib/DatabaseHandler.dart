import 'dart:async';
import 'dart:io';

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
    if (_conn?.isOpen ?? false) return conn;
    _conn = await Connection.open(endpoint);
    print("Data base connection success");
    return conn;
  }

  Future<Connection> forceConnect() async {
    if (_conn?.isOpen ?? false) return Future.value(_conn);
    try {
      _conn = await Connection.open(endpoint,
          settings: ConnectionSettings(connectTimeout: Duration(seconds: 5)));
    } catch (e) {
      _conn = null;
    }
    if (_conn?.isOpen ?? false) {
      return Future.value(_conn);
    }
    print("Data base connection failed it will restart in 5s");
    await Future.delayed(Duration(seconds: 5));
    return forceConnect();
  }

  Future<int> createReport(Station station) async {
    await forceConnect();
    final result = await conn.execute(
        'INSERT INTO public.reports("station_id")'
        r'VALUES ($1) RETURNING id',
        parameters: [station.id.toString()]);
    int id = result.first.first as int;
    print("Report generated with id $id");
    return id;
  }

  Future<DateTime?> updateReport(int reportId, bool stillThere) async {
    await forceConnect();
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
    await forceConnect();
    final startDate = startFrom != null
        ? DateTime.now().subtract(startFrom)
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

  Future<Set<int>> removeOld(Duration limit) async {
    await forceConnect();

    final result = await conn.execute(
      'UPDATE public.reports AS r SET alive = false '
          'FROM ( '
          '  SELECT report_id, MAX(time) as time '
          '  FROM public.report_updates '
          '  WHERE still_there '
          '  GROUP BY report_id '
          ' ) AS u '
          r'WHERE r.id = u.report_id AND r.alive AND (EXTRACT (EPOCH FROM (NOW() - u.time))) > $1 '
          'RETURNING r.id ',
      parameters: [limit.inSeconds],
    );

    return result.map((e) => e.first as int).toSet();
  }

  String formatDate(DateTime date) {
    return date.toUtc().toIso8601String();
  }
}
