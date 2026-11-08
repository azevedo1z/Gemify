import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final String script = File('tool/release_notes.sh').absolute.path;
final String bash = Platform.isWindows
    ? r'C:\Program Files\Git\bin\bash.exe'
    : 'bash';
final Object skipWithoutBash = Platform.isWindows && !File(bash).existsSync()
    ? 'Needs Git Bash'
    : false;

Future<String> releaseNotes(List<String> subjects) async {
  final repository = await Directory.systemTemp.createTemp('release_notes');
  addTearDown(() => repository.delete(recursive: true));
  Future<void> git(List<String> arguments) async {
    final result = await Process.run(
      'git',
      arguments,
      workingDirectory: repository.path,
    );
    if (result.exitCode != 0) fail('git $arguments: ${result.stderr}');
  }

  await git(['init', '--quiet']);
  for (final subject in subjects) {
    await git([
      '-c',
      'user.name=Test',
      '-c',
      'user.email=test@example.com',
      'commit',
      '--quiet',
      '--allow-empty',
      '--message',
      subject,
    ]);
  }
  await git(['tag', 'v0.1.0']);
  final result = await Process.run(bash, [
    script,
    'v0.1.0',
  ], workingDirectory: repository.path);
  if (result.exitCode != 0) fail('release_notes.sh: ${result.stderr}');
  return result.stdout as String;
}

void main() {
  test('a "!" before the colon marks a breaking change', () async {
    final notes = await releaseNotes([
      'feat!: drop the version 1 backup',
      'fix(backup)!: reject unknown fields',
    ]);

    expect(notes, contains('- **Breaking:** drop the version 1 backup'));
    expect(notes, contains('- **Breaking:** reject unknown fields'));
  }, skip: skipWithoutBash);

  test('a "!" after the colon is part of the description', () async {
    final notes = await releaseNotes(['fix: !important flag ignored']);

    expect(notes, '## Fixes\n\n- !important flag ignored\n\n');
  }, skip: skipWithoutBash);

  test('reverts are listed under other changes', () async {
    final notes = await releaseNotes(['revert: feat: add the savings box']);

    expect(notes, '## Other changes\n\n- feat: add the savings box\n\n');
  }, skip: skipWithoutBash);
}
