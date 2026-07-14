import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import '../utils/formatters.dart';
import '../widgets/duration_minutes_seconds_picker.dart';
import 'training_session.dart';

/// Écran de préparation d'une séance "Quick Tabata" : permet de lancer
/// rapidement un cycle travail/pause répété, sans passer par la création
/// d'une séance classique. La séance générée n'est jamais persistée dans
/// le stockage local — elle n'existe que le temps de son exécution.
class QuickTabataScreen extends StatefulWidget {
  const QuickTabataScreen({super.key});

  @override
  State<QuickTabataScreen> createState() => _QuickTabataScreenState();
}

class _QuickTabataScreenState extends State<QuickTabataScreen> {
  static const String _defaultName = "Quick Tabata";

  final TextEditingController _nameController = TextEditingController(
    text: _defaultName,
  );
  final TextEditingController _repsController = TextEditingController(
    text: "1",
  );

  Duration _workDuration = const Duration(seconds: 20);
  Duration _pauseDuration = const Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    // Le temps total affiché dépend du nombre de répétitions saisi : il
    // faut se reconstruire à chaque frappe pour le tenir à jour en temps
    // réel (le nom n'a pas besoin d'un listener, il n'influence aucun
    // calcul affiché).
    _repsController.addListener(_onRepsChanged);
  }

  void _onRepsChanged() => setState(() {});

  @override
  void dispose() {
    _repsController.removeListener(_onRepsChanged);
    _nameController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  int get _repetitions {
    final parsed = int.tryParse(_repsController.text);
    return (parsed == null || parsed < 1) ? 1 : parsed;
  }

  // (work + pause) x répétitions, comme demandé.
  Duration get _totalDuration =>
      (_workDuration + _pauseDuration) * _repetitions;

  void _start() {
    // Valeur saisie, ou "Quick Tabata" si le champ a été vidé — couvre
    // aussi bien "jamais modifié" que "modifié puis effacé", sans jamais
    // bloquer l'utilisateur avec un message d'erreur pour un flux qui se
    // veut rapide.
    final name = _nameController.text.trim().isEmpty
        ? _defaultName
        : _nameController.text.trim();

    final group = ExerciseGroup(
      id: 'quick_group_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      rounds: _repetitions,
      items: [
        TrainingItem(
          type: ItemType.exercise,
          name: "Work",
          duration: _workDuration,
        ),
        TrainingItem(
          type: ItemType.rest,
          name: "Pause",
          duration: _pauseDuration,
        ),
      ],
    );

    // Séance générée entièrement en mémoire : jamais écrite dans
    // TrainingStorage, donc jamais visible dans la liste des séances.
    final quickTraining = Training(
      id: 'quick_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      groups: [group],
      createdAt: DateTime.now(),
    );

    // Lance directement le moteur d'exécution existant, exactement comme
    // pour une séance classique — aucune logique spécifique ajoutée.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSessionScreen(training: quickTraining),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quick Tabata")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Nom de la séance",
              ),
            ),

            const SizedBox(height: 28),

            Text(
              "Work",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Center(
              child: DurationMinutesSecondsPicker(
                value: _workDuration,
                onChanged: (d) => setState(() => _workDuration = d),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              "Pause",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Center(
              child: DurationMinutesSecondsPicker(
                value: _pauseDuration,
                onChanged: (d) => setState(() => _pauseDuration = d),
              ),
            ),

            const SizedBox(height: 28),

            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Nombre de répétitions",
              ),
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Temps total estimé"),
                    Text(
                      formatDuration(_totalDuration),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Commencer"),
            ),
          ],
        ),
      ),
    );
  }
}
