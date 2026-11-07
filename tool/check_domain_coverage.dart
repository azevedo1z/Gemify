import 'dart:io';

const _domain = 'lib/domain/';

void main(List<String> arguments) {
  final report = File(
    arguments.isEmpty ? 'coverage/lcov.info' : arguments.first,
  );
  final reported = <String>{};
  String? current;
  var total = 0;
  var covered = 0;
  for (final line in report.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = _domainPath(line.substring(3));
      if (current != null) reported.add(current);
    } else if (current != null && line.startsWith('DA:')) {
      total++;
      if (int.parse(line.substring(3).split(',')[1]) > 0) covered++;
    }
  }
  final domainFiles = {
    for (final file in Directory(_domain).listSync(recursive: true))
      if (file is File && file.path.endsWith('.dart')) ?_domainPath(file.path),
  };
  final untested = domainFiles.difference(reported);
  stdout.writeln('lib/domain line coverage: $covered/$total');
  for (final path in untested) {
    stdout.writeln('Not loaded by any test: $path');
  }
  if (total == 0 || covered < total || untested.isNotEmpty) exitCode = 1;
}

String? _domainPath(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final start = normalized.indexOf(_domain);
  return start < 0 ? null : normalized.substring(start);
}
