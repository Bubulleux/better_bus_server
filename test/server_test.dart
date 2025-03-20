import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:better_bus_core/core.dart';

void main() {
  final port = '8080';
  final host = 'http://localhost:$port';
  late Process p;

  setUp(() async {
    p = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {'PORT': port},
    );
    // Wait for server to start and print to stdout.
    await p.stdout.first;
  });

  tearDown(() => p.kill());

  test('Root', () async {
    final response = await get(Uri.parse('$host/'));
    expect(response.statusCode, 200);
    expect(response.body, 'Hello, World!\n');
  });

  test('Echo', () async {
    final response = await get(Uri.parse('$host/echo/hello'));
    expect(response.statusCode, 200);
    expect(response.body, 'hello\n');
  });

  test('404', () async {
    final response = await get(Uri.parse('$host/foobar'));
    expect(response.statusCode, 404);
  });

  test('radar', () async {
    // TODO : Maybe use a better provider
    final provider = ApiProvider.vitalis();
    final radar = RadarClient(apiUrl: Uri.parse(host), provider: provider);
    // TODO: Vitalis Only
    final nd = (await provider.getStations()).firstWhere((e) => e.name.startsWith("Notre"));

    var reports = await radar.getReports();
    expect(reports, isEmpty);

     var report = await radar.sendReport(nd);
     expect(report, isNotNull);
     reports = await radar.getReports();
     expect(reports, isNotEmpty);

     report = await radar.updateReport(reports.first, true);
     expect(report, isNotNull);

    report = await radar.updateReport(reports.first, false);
    expect(report, isNotNull);
    expect(report!.updates.length, greaterThan(1));
  });
}







