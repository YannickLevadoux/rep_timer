import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String _copyright = '© 2026 Yannick Levadoux';
const String _appIconAsset = 'assets/icon/app_icon.png';

Future<void> showRepTimerAboutDialog(BuildContext context) async {
  final packageInfo = await PackageInfo.fromPlatform();
  if (!context.mounted) return;
  showAboutDialog(
    context: context,
    applicationName: packageInfo.appName,
    applicationVersion: '${packageInfo.version} (${packageInfo.buildNumber})',
    applicationIcon: SizedBox(
      width: 48,
      height: 48,
      child: Image.asset(_appIconAsset),
    ),
    applicationLegalese: _copyright,
  );
}
