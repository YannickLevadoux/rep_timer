import 'dart:async';

import 'package:flutter/material.dart';

import '../models/session_step.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';

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

  String _stepDetail(SessionStep step) {
    final item = step.item;
    if (item.type == ItemType.rest) {
      return "${item.duration?.inSeconds ?? 0} s";
    }
    if (item.isFreeDuration) {
      return "Durée libre";
    }
    return item.duration != null
        ? "${item.duration!.inSeconds} s"
        : "× ${item.repetitions ?? 0}";
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

          final leadingIcon = Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done
                ? Colors.green
                : isCurrent
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          );

          final titleText = Row(
            children: [
              Icon(
                step.item.type == ItemType.exercise
                    ? iconForExercise(step.item.iconName)
                    : Icons.timer,
                size: 18,
                color: isCurrent
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.item.name,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ),
            ],
          );

          return ListTile(
            key: _itemKeys[index],
            // L'exercice en cours clignote (icône + nom), avec le même
            // contrôleur que l'écran d'exécution : se fige en pause,
            // reprend avec la séance.
            leading: isCurrent
                ? FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0.35).animate(
                      CurvedAnimation(
                        parent: widget.blinkController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: leadingIcon,
                  )
                : leadingIcon,
            title: isCurrent
                ? FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0.35).animate(
                      CurvedAnimation(
                        parent: widget.blinkController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: titleText,
                  )
                : titleText,
            subtitle: Text(
              "${step.group.name} · répétition ${step.roundIndex}/${step.totalRounds} · "
              "${_stepDetail(step)}",
            ),
            trailing: isCurrent
                ? null
                : IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: "Lancer cet exercice",
                    onPressed: () => _confirmAndSelect(index),
                  ),
            onTap: () => _confirmAndSelect(index),
          );
        },
      ),
    );
  }
}
