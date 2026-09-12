import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/settings_transfer_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  final originalFilePickerPlatform = FilePickerPlatform.instance;

  tearDown(() {
    FilePickerPlatform.instance = originalFilePickerPlatform;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(shareChannel, null);
  });

  test('sélectionne un JSON et conserve son chemin nullable', () async {
    final platform = _FakeFilePickerPlatform(
      file: _FakePlatformFile(
        name: 'reptimer.json',
        path: '/tmp/reptimer.json',
      ),
    );
    FilePickerPlatform.instance = platform;

    final selection = await SettingsTransferPlatform.pickBackup();

    expect(selection, isNotNull);
    expect(selection!.path, '/tmp/reptimer.json');
    expect(platform.type, FileType.custom);
    expect(platform.allowedExtensions, ['json']);
  });

  test('retourne null lorsque le sélecteur est annulé', () async {
    FilePickerPlatform.instance = _FakeFilePickerPlatform(file: null);

    expect(await SettingsTransferPlatform.pickBackup(), isNull);
  });

  test('lit le contenu du fichier sélectionné', () async {
    final directory = await Directory.systemTemp.createTemp(
      'rep_timer_transfer_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/backup.json');
    await file.writeAsString('{"version":3}');

    expect(
      await SettingsTransferPlatform.readBackup(file.path),
      '{"version":3}',
    );
  });

  test('convertit les trois résultats du partage plateforme', () async {
    final directory = await Directory.systemTemp.createTemp('rep_timer_share_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/backup.json');
    await file.writeAsString('{}');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    for (final entry in <String, TransferShareResult>{
      'com.example.share': TransferShareResult.success,
      '': TransferShareResult.dismissed,
      'dev.fluttercommunity.plus/share/unavailable':
          TransferShareResult.unavailable,
    }.entries) {
      messenger.setMockMethodCallHandler(shareChannel, (call) async {
        expect(call.method, 'share');
        expect(
          call.arguments,
          containsPair('subject', 'Export des séances RepTimer'),
        );
        return entry.key;
      });

      expect(
        await SettingsTransferPlatform.shareBackup(file.path),
        entry.value,
      );
    }
  });
}

final class _FakeFilePickerPlatform extends FilePickerPlatform {
  _FakeFilePickerPlatform({required this.file});

  final PlatformFile? file;
  FileType? type;
  List<String>? allowedExtensions;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus status)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    this.type = type;
    this.allowedExtensions = allowedExtensions;
    return file;
  }
}

base class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile({required this.name, required String path})
    : uri = Uri.file(path);

  @override
  final String name;

  @override
  final Uri uri;

  @override
  Never get xFile => throw UnsupportedError('Non utilisé par ce test.');

  @override
  int? lengthSync() => null;

  @override
  Future<int> length() async => 0;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List(0);

  @override
  Stream<Uint8List> readAsByteStream() => const Stream.empty();
}
