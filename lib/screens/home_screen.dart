import 'package:flutter/material.dart';

import '../models/training.dart';
import '../services/session_checkpoint_storage.dart';
import '../services/training_storage.dart';
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

  List<Training> _trainings = [];
  bool _loading = true;

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
    final checkpoint = await checkpointStorage.loadCheckpoint();
    if (checkpoint == null) return;

    // Un checkpoint de plus de 24h est considéré comme abandonné : on
    // l'efface silencieusement plutôt que de proposer une reprise qui
    // n'aurait plus de sens pour l'utilisateur.
    final age = DateTime.now().difference(checkpoint.savedAt);
    if (age > const Duration(hours: 24)) {
      await checkpointStorage.clearCheckpoint();
      return;
    }

    final trainings = await _storage.loadTrainings();
    Training? training;
    for (final t in trainings) {
      if (t.id == checkpoint.trainingId) {
        training = t;
        break;
      }
    }

    // La séance référencée n'existe plus (supprimée entre-temps) :
    // checkpoint devenu invalide, on l'efface.
    if (training == null) {
      await checkpointStorage.clearCheckpoint();
      return;
    }

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
    final trainings = await _storage.loadTrainings();

    if (!mounted) return;

    setState(() {
      _trainings = trainings;
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
          : _trainings.isEmpty
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
                        subtitle: Text("${training.groups.length} groupe(s)"),
                        onTap: () => _toggleExpanded(training.id),
                      ),
                      if (_expandedTrainingId == training.id)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _startTraining(training),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text("Commencer"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _openEditor(training: training),
                                  icon: const Icon(Icons.edit),
                                  label: const Text("Éditer"),
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
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
