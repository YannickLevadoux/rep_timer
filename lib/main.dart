import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/training.dart';
import 'screens/training_editor.dart';
import 'screens/training_history.dart';
import 'screens/training_session.dart';
import 'screens/training_summary.dart';
import 'services/session_checkpoint_storage.dart';
import 'services/training_storage.dart';

Future<void> main() async {
  // Verrouille l'orientation en portrait pour toute l'application : le
  // paysage n'est jamais autorisé, y compris pendant l'exécution d'une
  // séance. WidgetsFlutterBinding doit être initialisé avant tout appel
  // à un canal de plateforme comme SystemChrome.
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Par défaut on suit le thème du système (clair/sombre),
  // mais l'utilisateur peut le forcer via le bouton dans l'AppBar.
  ThemeMode _themeMode = ThemeMode.system;

  void _cycleThemeMode() {
    setState(() {
      _themeMode = switch (_themeMode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.deepPurple;

    return MaterialApp(
      title: 'Mes entraînements',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),

      home: HomePage(
        themeMode: _themeMode,
        onToggleTheme: _cycleThemeMode,
      ),
    );
  }
}

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
      _expandedTrainingId =
          _expandedTrainingId == trainingId ? null : trainingId;
    });
  }

  IconData get _themeIcon => switch (widget.themeMode) {
        ThemeMode.system => Icons.brightness_auto,
        ThemeMode.light => Icons.light_mode,
        ThemeMode.dark => Icons.dark_mode,
      };

  String get _themeLabel => switch (widget.themeMode) {
        ThemeMode.system => "Système",
        ThemeMode.light => "Clair",
        ThemeMode.dark => "Sombre",
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes entraînements"),
        actions: [
          IconButton(
            icon: Icon(_themeIcon),
            tooltip: "Thème : $_themeLabel (appuyer pour changer)",
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trainings.isEmpty
              ? const Center(
                  child: Text("Aucune séance enregistrée"),
                )
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
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () =>
                                          _startTraining(training),
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
                builder: (context) => const TrainingHistoryScreen(),
              ),
            );
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: "Accueil",
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: "Historique",
          ),
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