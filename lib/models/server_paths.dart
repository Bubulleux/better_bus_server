import 'dart:io';

import 'package:better_bus_core/core.dart';

class ServerPaths extends GTFSPaths {
  ServerPaths({Directory? root}) : super.broken(){
    root ??= Directory.current;
    // Nerver add / before gtfs
    // It'll produce error without tilling you
    super.gtfsFilePath = "${root.path}gtfs/gtfs.zip";
    super.extractDir = "${root.path}gtfs/extract/";
  }
}
