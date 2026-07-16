import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Écran final affiché une fois la séance terminée (normalement ou de
/// façon anticipée). Purement informatif : durée totale et retour à
/// l'accueil.
class SessionFinishedView extends StatelessWidget {
  final String trainingName;
  final Duration totalDuration;
  final VoidCallback onBackHome;

  const SessionFinishedView({
    super.key,
    required this.trainingName,
    required this.totalDuration,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trainingName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                "Séance terminée !",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text("Durée totale : ${formatDuration(totalDuration)}"),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onBackHome,
                child: const Text("Retour à l'accueil"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
