import 'dart:convert';
import 'dart:io';

import 'package:server/ReportsHandler.dart';
import 'package:server/models/custom_responses.dart';
import 'package:server/models/report.dart';
import 'package:server/models/server_paths.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

import 'package:shelf_router/shelf_router.dart';
import 'package:better_bus_core/core.dart';
import '../lib/lib.dart';

final provider = GTFSProvider.vitalis(ServerPaths());
final reports = ReportsHandler(provider);

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/count', _countReports)
  ..get('/sendReport/<stationId>', _sendReport)
  ..get('/lines.txt', _getLines)
  ..get('/stations', _getStation)
  ..get('/reports', _getReports);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Future<Response> _getLines(Request req) async {
  Map<String, BusLine> lines = await provider.getAllLines();
  print(lines.length);
  return Response.ok(lines.values.map((e) => e.toString()).join("\n"));
}

Future<Response> _getStation(Request req) async {
  final stations = await provider.getStations();
  final json =
      Map.fromEntries(stations.map((e) => MapEntry(e.id.toString(), e.name)));

  return Response.ok(jsonEncode(json),
      headers: {"content-type": "application/json"});
}

Future<Response> _echoHandler(Request request) async {
  final message = request.params['message'];
  await Future.delayed(Duration(seconds: 1));
  return Response.ok('$message\n');
}

Response _countReports(Request request) {
  return Response.ok("Count report: ${reports.countReports()}");
}

Future<Response> _sendReport(Request request) async {
  final stationId = request.params["stationId"];
  if (stationId == null) {
    return Response.badRequest(body: "Missing stationId");
  }
  ServerReport? report = await reports.sendReport(int.parse(stationId));
  if (report == null) {
    return Response.badRequest(body: "Station does not existe");
  }
  return CustomResponses.json(report.toJson());
}

Future<bool> initProvider() async {
  final success = await reports.init();
  if (!success) {
    throw "Provider failed to init";
  }
  print("Provider init Success !!");
  return true;
}

Future<Response> _getReports(Request req) async {
  return CustomResponses.reports(await reports.getReports());
}

void main(List<String> args) async {
  await initProvider();
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
