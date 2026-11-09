import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/presentation/backup/backup_files.dart';

const int megabyte = 1024 * 1024;

final class FakePickedFile extends PlatformFile {
  FakePickedFile(this.content, {int? length, this.readFailure})
    : _length = length ?? utf8.encode(content).length;

  final String content;
  final int? _length;
  final Exception? readFailure;

  @override
  String get name => 'offmoney-backup.json';

  @override
  Uri get uri => Uri.file('/cache/file_picker/offmoney-backup.json');

  @override
  int? lengthSync() => _length;

  @override
  Future<int?> length() async => _length;

  @override
  Future<Uint8List> readAsBytes() async {
    if (readFailure case final failure?) throw failure;
    return utf8.encode(content);
  }

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(utf8.encode(content));

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class FakeFilePicker extends FilePickerPlatform {
  FakeFilePicker(this.picked);

  final List<PlatformFile> picked;
  int clears = 0;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => picked;

  @override
  Future<void> clearTemporaryFiles() async {
    clears++;
  }
}

FakeFilePicker usePicker(List<PlatformFile> picked) {
  final original = FilePickerPlatform.instance;
  addTearDown(() => FilePickerPlatform.instance = original);
  final picker = FakeFilePicker(picked);
  FilePickerPlatform.instance = picker;
  return picker;
}

void main() {
  const files = PickerBackupFiles();

  group('open clears the copy the picker keeps in its cache', () {
    test('after reading the file', () async {
      final picker = usePicker([FakePickedFile('{"format": "offmoney"}')]);

      expect(await files.open(), '{"format": "offmoney"}');
      expect(picker.clears, 1);
    });

    test('when the file is too large', () async {
      final picker = usePicker([FakePickedFile('', length: 21 * megabyte)]);

      await expectLater(files.open(), throwsFormatException);
      expect(picker.clears, 1);
    });

    test('when the file cannot be read', () async {
      final picker = usePicker([
        FakePickedFile('', readFailure: const FileSystemException('denied')),
      ]);

      await expectLater(files.open(), throwsA(isA<FileSystemException>()));
      expect(picker.clears, 1);
    });
  });

  test('open returns nothing when the choice is canceled', () async {
    usePicker([]);

    expect(await files.open(), isNull);
  });
}
