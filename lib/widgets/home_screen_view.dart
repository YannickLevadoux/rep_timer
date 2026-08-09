import 'package:flutter/material.dart';

import '../controllers/home_state.dart';
import '../models/training.dart';
import 'home_training_list.dart';
import 'storage_read_feedback.dart';

/// Présentation de l'accueil, pilotée par l'état et les actions de HomePage.
class HomeScreenView extends StatelessWidget {
  const HomeScreenView({
    super.key,
    required this.trainings,
    required this.expandedTrainingId,
    required this.status,
    required this.actions,
    required this.onOpenSettings,
    required this.onRetry,
    required this.onToggleExpanded,
    required this.onDuplicate,
    required this.onEdit,
    required this.onStart,
    required this.onDestinationSelected,
    required this.onCreate,
  });

  final List<Training> trainings;
  final String? expandedTrainingId;
  final HomeLoadStatus status;
  final HomeActionAvailability actions;
  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;
  final ValueChanged<String> onToggleExpanded;
  final ValueChanged<Training> onDuplicate;
  final ValueChanged<Training> onEdit;
  final ValueChanged<Training> onStart;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes entraînements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Paramètres",
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: status == HomeLoadStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : status == HomeLoadStatus.failure
          ? StorageReadErrorView(
              message: "Les séances enregistrées n'ont pas pu être lues.",
              onRetry: onRetry,
            )
          : Column(
              children: [
                if (status == HomeLoadStatus.partial ||
                    !actions.sessionStartAllowed)
                  const StorageReadWarningBanner(
                    message:
                        "Certaines données n'ont pas pu être lues. Les actions "
                        "pouvant les remplacer sont désactivées pour protéger "
                        "les données enregistrées.",
                  ),
                Expanded(
                  child: HomeTrainingList(
                    trainings: trainings,
                    expandedTrainingId: expandedTrainingId,
                    mutationsBlocked: !actions.trainingMutationsAllowed,
                    startBlocked: !actions.sessionStartAllowed,
                    onToggleExpanded: onToggleExpanded,
                    onDuplicate: onDuplicate,
                    onEdit: onEdit,
                    onStart: onStart,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Accueil"),
          NavigationDestination(icon: Icon(Icons.bolt), label: "Quick Tabata"),
          NavigationDestination(icon: Icon(Icons.history), label: "Historique"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: actions.trainingMutationsAllowed ? onCreate : null,
        child: const Icon(Icons.add),
      ),
    );
  }
}
