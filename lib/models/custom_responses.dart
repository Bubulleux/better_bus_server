import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'report.dart';

class CustomResponses extends Response {
  CustomResponses(super.statusCode);

  CustomResponses.json(Iterable body)
      : assert(body is Map || body is List),
        super.ok(
          jsonEncode(body),
          headers: {"content-type": "application/json"},
        );

  CustomResponses.reports(List<ServerReport> reports)
    : this.json(reports.map((e) => e.toJson()).toList());
}
