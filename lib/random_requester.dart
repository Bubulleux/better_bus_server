import 'dart:math';

import 'package:better_bus_core/core.dart';

class RandomRequester {
  final int reportCount;
  final int updateCount;

  final Duration duration;
  final Duration updateDelay;
  final BusNetwork provider;
  final RadarClient client;

  RandomRequester({
    required this.reportCount,
    this.updateCount = 0,
    this.duration = const Duration(seconds: 10),
    this.updateDelay = const Duration(milliseconds: 500),
    required this.provider,
    required this.client,
  });

  Future start() async {
    final futures = <Future>[];
    final stations = await provider.getStations();

    for (var i = 0; i < max(reportCount, updateCount); i++) {
      Duration wait = duration * Random.secure().nextDouble();
      final station = stations[Random.secure().nextInt(stations.length)];

      final create = i < reportCount
          ? Future.delayed(wait).then((_) async {
              print("Start sent on ${station.name}");
              final report = await client.sendReport(station);
              print("Report sent ${report?.id}");
            })
          : Future.value();

      final update = i < updateCount
          ? Future.delayed(wait + updateDelay).then((_) async {
              final reports = await client.getReports();
              Report report = reports[Random.secure().nextInt(reports.length)];
              await client.updateReport(report, Random.secure().nextDouble() > 0.5);
              print("Report update ${report.id}");
            })
          : Future.value();

      futures.addAll([create, update]);
    }

    await Future.wait(futures);

    print("All reports sent");

    final report = await client.getReports();
    print("Fetch report count: ${report.length}");
  }
}
