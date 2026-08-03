import 'package:flutter/material.dart';

/// Retour visuel commun aux écrans lisant un stockage local JSON.
class StorageReadWarningBanner extends StatelessWidget {
  const StorageReadWarningBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.all(12),
      child: Text(message),
    );
  }
}

class StorageReadErrorView extends StatelessWidget {
  const StorageReadErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text("Réessayer")),
          ],
        ),
      ),
    );
  }
}
