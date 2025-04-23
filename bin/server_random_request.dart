
import 'package:better_bus_core/core.dart';
import 'package:server/models/server_paths.dart';
import 'package:server/random_requester.dart';
import 'package:shelf/shelf.dart';
import 'server.dart' as server;

Future runRandomClient() async {
  final provider = GTFSProvider.vitalis(ServerPaths());
  await provider.init();
  print("Local provider init");
  final client = RadarClient.production(provider: provider);
  await client.init();
  final requester = RandomRequester(
    reportCount: 250,
    updateCount: 400,
    loop: true,
    getStatus: true,
    duration: Duration(seconds: 20),
    provider: provider,
    client: client,
  );

  await requester.start();
}

void main() async {
  // await server.asyncMain([]);

  print("Starting requester ---------------");
  runRandomClient();
}
