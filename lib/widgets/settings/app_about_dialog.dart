import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../models/build_metadata.dart';

const String _copyright = '© 2026 Yannick Levadoux';
const String _appIconAsset = 'assets/icon/app_icon.png';

Future<void> showRepTimerAboutDialog(BuildContext context) async {
  final packageInfo = await PackageInfo.fromPlatform();
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (context) => RepTimerAboutDialog(
      packageInfo: packageInfo,
      buildMetadata: BuildMetadata.fromEnvironment(),
    ),
  );
}

class RepTimerAboutDialog extends StatelessWidget {
  const RepTimerAboutDialog({
    super.key,
    required this.packageInfo,
    required this.buildMetadata,
  });

  final PackageInfo packageInfo;
  final BuildMetadata buildMetadata;

  @override
  Widget build(BuildContext context) {
    return AboutDialog(
      applicationName: packageInfo.appName,
      applicationVersion: '${packageInfo.version} (${packageInfo.buildNumber})',
      applicationIcon: SizedBox(
        width: 48,
        height: 48,
        child: Image.asset(_appIconAsset),
      ),
      applicationLegalese: _copyright,
      children: buildMetadata.isDevelopment
          ? [
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Chip(label: Text('DEV')),
                  Text(buildMetadata.displayText!),
                ],
              ),
            ]
          : null,
    );
  }
}
