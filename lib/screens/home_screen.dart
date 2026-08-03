import 'package:flutter/material.dart';

import '../models/session_checkpoint.dart';
import '../models/training.dart';
import '../services/json_prefs_storage.dart';
import '../services/session_checkpoint_storage.dart';
import '../services/training_storage.dart';
import '../utils/id_generator.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/duplicate_training_dialog.dart';
import 'quick_tabata_screen.dart';
import 'settings_screen.dart';
import 'training_editor.dart';
import 'training_history.dart';
import 'training_session.dart';
import 'training_summary.dart';

class HomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const HomePage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TrainingStorage _storage = TrainingStorage();
  final IdGenerator _idGenerator = IdGenerator();

  List<Training> _trainings = [];
  bool _loading = true;
  bool _storageWarning = false;
  bool _storageFailure = false;
  bool _checkpointWarning = false;

  // Une seule séance développée à la fois (null = aucune).
  String? _expandedTrainingId;

  @override
  void initState() {
    super.initState();
    _loadTrainings();
    // Vérifie, après le premier affichage, si une séance était en cours
    // au moment où le processus a été tué par le système ; si oui, on
    // reprend directement dessus (voir _resumePendingSessionIfAny).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resumePendingSessionIfAny(),
    );
  }

  Future<void> _resumePendingSessionIfAny() async {
    final checkpointStorage = SessionCheckpointStorage();
    final checkpointResult = await checkpointStorage.loadCheckpoint();
    final SessionCheckpoint? checkpoint;
    switch (checkpointResult) {
      case StorageNoData<SessionCheckpoint>():
        return;
      case StorageReadSuccess<SessionCheckpoint>(:final data):
        checkpoint = data;
      case StorageReadPartial<SessionCheckpoint>():
      case StorageReadFailure<SessionCheckpoint>():
        if (mounted) setState(() => _checkpointWarning = true);
        return;
    }

    // Un checkpoint de plus de 24h est considéré comme abandonné : on
    // l'efface silencieusement plutôt que de proposer une reprise qui
    // n'aurait plus de sens pour l'utilisateur.
    final age = DateTime.now().difference(checkpoint.savedAt);
    if (age > const Duration(hours: 24)) {
      await checkpointStorage.clearCheckpoint();
      return;
    }

    final trainingsResult = await _storage.loadTrainings();
    final List<Training> trainings;
    final canConcludeTrainingIsMissing = switch (trainingsResult) {
      StorageNoData<List<Training>>() => true,
      StorageReadSuccess<List<Training>>() => true,
      StorageReadPartial<List<Training>>() => false,
      StorageReadFailure<List<Training>>() => false,
    };
    switch (trainingsResult) {
      case StorageNoData<List<Training>>():
        trainings = <Training>[];
      case StorageReadSuccess<List<Training>>(:final data):
        trainings = data;
      case StorageReadPartial<List<Training>>(:final data):
        trainings = data;
        if (mounted) setState(() => _storageWarning = true);
      case StorageReadFailure<List<Training>>():
        return;
    }
    Training? training;
    for (final t in trainings) {
      if (t.id == checkpoint.trainingId) {
        training = t;
        break;
      }
    }

    // La séance référencée n'existe plus (supprimée entre-temps) :
    // checkpoint devenu invalide, on l'efface.
    if (training == null && canConcludeTrainingIsMissing) {
      await checkpointStorage.clearCheckpoint();
      return;
    }

    if (training == null) return;

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSessionScreen(
          training: training!,
          initialCheckpoint: checkpoint,
        ),
      ),
    );

    // Au retour (séance terminée ou abandonnée), la liste peut avoir
    // changé (historique, suppression...).
    if (mounted) _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    final result = await _storage.loadTrainings();

    if (!mounted) return;

    setState(() {
      switch (result) {
        case StorageNoData<List<Training>>():
          _trainings = <Training>[];
          _storageWarning = false;
          _storageFailure = false;
        case StorageReadSuccess<List<Training>>(:final data):
          _trainings = data;
          _storageWarning = false;
          _storageFailure = false;
        case StorageReadPartial<List<Training>>(:final data):
          _trainings = data;
          _storageWarning = true;
          _storageFailure = false;
        case StorageReadFailure<List<Training>>():
          _trainings = <Training>[];
          _storageWarning = false;
          _storageFailure = true;
      }
      _loading = false;
    });
  }

  Future<void> _openEditor({Training? training}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingEditor(training: training),
      ),
    );

    // On ne recharge que si l'utilisateur a effectivement enregistré,
    // pour éviter un rechargement inutile en cas d'annulation.
    if (saved == true) {
      _loadTrainings();
    }
  }

  void _startTraining(Training training) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSummaryScreen(training: training),
      ),
    );
  }

  // Duplication d'une séance : demande le nouveau nom (prérempli "<nom>
  // - Copie"), puis construit une copie totalement indépendante (voir
  // Training.duplicate/ExerciseGroup.copyWith) avant de l'enregistrer via
  // le mécanisme de sauvegarde existant. La séance d'origine n'est jamais
  // modifiée. Reste sur l'écran d'accueil (aucune navigation n'a lieu ici
  // en dehors du dialogue), la liste est simplement rechargée.
  Future<void> _duplicateTraining(Training training) async {
    final name = await showDuplicateTrainingDialog(
      context,
      originalName: training.name,
    );

    if (name == null || !mounted) return;

    final duplicate = training.duplicate(name: name, newId: _idGenerator.next);
    try {
      await _storage.addOrUpdateTraining(duplicate);
    } on StorageMutationBlockedException {
      if (!mounted) return;
      setState(() => _storageWarning = true);
      showSnack(
        context,
        "Duplication impossible : certaines séances n'ont pas pu être lues.",
      );
      return;
    }

    if (!mounted) return;
    _loadTrainings();
  }

  void _toggleExpanded(String trainingId) {
    setState(() {
      // Un second clic sur la séance déjà développée la referme ;
      // sinon on referme la précédente et on développe la nouvelle.
      _expandedTrainingId = _expandedTrainingId == trainingId
          ? null
          : trainingId;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          themeMode: widget.themeMode,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );

    // On recharge systématiquement au retour : Paramètres peut avoir
    // modifié les séances stockées (import), sans qu'il soit nécessaire
    // de faire remonter un signal explicite pour un rechargement aussi
    // peu coûteux (simple lecture locale).
    if (mounted) _loadTrainings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes entraînements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Paramètres",
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _storageFailure
          ? _StorageError(onRetry: _loadTrainings)
          : Column(
              children: [
                if (_storageWarning || _checkpointWarning)
                  const _StorageWarning(),
                Expanded(
                  child: _trainings.isEmpty
                      ? const Center(child: Text("Aucune séance enregistrée"))
                      : ListView.builder(
                          itemCount: _trainings.length,
                          itemBuilder: (context, index) {
                            final training = _trainings[index];

                            return Card(
                              key: ValueKey(training.id),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(training.name),
                                    subtitle: Text(
                                      "${training.groups.length} groupe(s)",
                                    ),
                                    onTap: () => _toggleExpanded(training.id),
                                  ),
                                  if (_expandedTrainingId == training.id)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        12,
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.copy),
                                            tooltip: "Dupliquer la séance",
                                            onPressed: _storageWarning
                                                ? null
                                                : () => _duplicateTraining(
                                                    training,
                                                  ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _storageWarning
                                                  ? null
                                                  : () => _openEditor(
                                                      training: training,
                                                    ),
                                              icon: const Icon(Icons.edit),
                                              label: const Text("Éditer"),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: FilledButton.icon(
                                              onPressed: _checkpointWarning
                                                  ? null
                                                  : () => _startTraining(
                                                      training,
                                                    ),
                                              icon: const Icon(
                                                Icons.play_arrow,
                                              ),
                                              label: const Text("Commencer"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QuickTabataScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TrainingHistoryScreen(),
              ),
            );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Accueil"),
          NavigationDestination(icon: Icon(Icons.bolt), label: "Quick Tabata"),
          NavigationDestination(icon: Icon(Icons.history), label: "Historique"),
        ],
      ),
      // Ajout d'un bouton flottant pour créer une nouvelle séance
      floatingActionButton: FloatingActionButton(
        onPressed: _storageWarning || _storageFailure
            ? null
            : () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StorageWarning extends StatelessWidget {
  const _StorageWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.all(12),
      child: const Text(
        "Certaines données n'ont pas pu être lues. Les actions pouvant les "
        "remplacer sont désactivées pour protéger les données enregistrées.",
      ),
    );
  }
}

class _StorageError extends StatelessWidget {
  const _StorageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Les séances enregistrées n'ont pas pu être lues.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text("Réessayer")),
          ],
        ),
      ),
    );
  }
}
