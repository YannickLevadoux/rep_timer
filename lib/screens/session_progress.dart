import 'dart:async';

import 'package:flutter/material.dart';

import '../models/session_step.dart';
import '../widgets/session_progress_step_tile.dart';

/// Vue détaillée de la progression d'une séance en cours : exercices
/// terminés (coche verte) vs en attente. Poussé par-dessus l'écran de
/// séance, qui continue de tourner en arrière-plan.
class SessionProgressScreen extends StatefulWidget {
  final List<SessionStep> steps;
  final List<bool> completed; // référence partagée avec l'écran de séance
  final int Function() currentIndexProvider;

  // Même AnimationController que l'écran d'exécution : garantit un
  // clignotement synchronisé, et se fige/reprend automatiquement avec
  // la pause (gérée côté écran de séance).
  final AnimationController blinkController;

  // Demande à l'écran de séance de changer d'exercice courant. La
  // navigation manuelle ne modifie jamais le statut "terminé".
  final void Function(int index) onSelectStep;

  const SessionProgressScreen({
    super.key,
    required this.steps,
    required this.completed,
    required this.currentIndexProvider,
    required this.blinkController,
    required this.onSelectStep,
  });

  @override
  State<SessionProgressScreen> createState() => _SessionProgressScreenState();
}

class _SessionProgressScreenState extends State<SessionProgressScreen> {
  Timer? _refreshTimer;
  late final List<GlobalKey> _itemKeys;

  @override
  void initState() {
    super.initState();

    _itemKeys = List.generate(widget.steps.length, (_) => GlobalKey());

    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Positionne automatiquement la liste sur l'exercice en cours à
    // l'ouverture de l'écran.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scrollToCurrent() {
    final currentIndex = widget.currentIndexProvider();
    if (currentIndex < 0 || currentIndex >= _itemKeys.length) return;

    final itemContext = _itemKeys[currentIndex].currentContext;
    if (itemContext == null) return;

    Scrollable.ensureVisible(
      itemContext,
      alignment: 0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _confirmAndSelect(int index) async {
    if (index == widget.currentIndexProvider()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Changer d'exercice ?"),
          content: const Text(
            "La progression actuelle de la séance sera modifiée. Continuer ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Continuer"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    widget.onSelectStep(index);

    if (!mounted) return;
    // Retour à l'écran d'exécution sur le nouvel exercice choisi.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.currentIndexProvider();
    final doneCount = widget.completed.where((c) => c).length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Progression ($doneCount/${widget.steps.length})"),
      ),
      body: ListView.builder(
        itemCount: widget.steps.length,
        itemBuilder: (context, index) {
          final step = widget.steps[index];
          final done = widget.completed[index];
          final isCurrent = index == currentIndex;

          return SessionProgressStepTile(
            key: _itemKeys[index],
            step: step,
            done: done,
            isCurrent: isCurrent,
            blinkController: widget.blinkController,
            onSelect: () => _confirmAndSelect(index),
          );
        },
      ),
    );
  }
}
