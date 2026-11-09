import 'package:offmoney/application/backup/backup_codec.dart';
import 'package:offmoney/application/backup/backup_snapshot.dart';
import 'package:offmoney/application/clock.dart';
import 'package:offmoney/application/month_repository.dart';

final class ExportBackup {
  const ExportBackup(this._repository, this._clock);

  final MonthRepository _repository;
  final Clock _clock;

  String fileName() => 'offmoney-backup-${todayFrom(_clock).iso}.json';

  Future<String> call() async =>
      BackupCodec.encode(await _repository.snapshot(), exportedAt: _clock());
}

final class ImportBackup {
  const ImportBackup(this._repository, this._clock);

  final MonthRepository _repository;
  final Clock _clock;

  BackupReading read(String text) =>
      BackupCodec.decode(text, today: todayFrom(_clock));

  Future<void> apply(BackupSnapshot snapshot) =>
      _repository.replaceAll(snapshot);
}
