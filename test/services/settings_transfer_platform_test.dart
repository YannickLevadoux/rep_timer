import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/settings_transfer_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pickerChannel = MethodChannel(
    'miguelruivo.flutter.plugins.filepicker',
    StandardMethodCodec(),
  );
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pickerChannel, null);
    messenger.setMockMethodCallHandler(shareChannel, null);
  });

  test('sélectionne un JSON et conserve son chemin nullable', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pickerChannel, (call) async {
      expect(call.method, 'custom');
      expect(call.arguments, containsPair('allowedExtensions', ['json']));
      return [
        {
          'path': '/tmp/reptimer.json',
          'name': 'reptimer.json',
          'size': 12,
          'bytes': null,
        },
      ];
    });

    final selection = await SettingsTransferPlatform.pickBackup();

    expect(selection, isNotNull);
    expect(selection!.path, '/tmp/reptimer.json');
  });

  test('retourne null lorsque le sélecteur est annulé', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pickerChannel, (_) async => null);

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
