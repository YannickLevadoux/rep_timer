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
  final Future<bool> Function(int index)? onBeforeSelectStep;

  const SessionProgressScreen({
    super.key,
    required this.steps,
    required this.completed,
    required this.currentIndexProvider,
    required this.blinkController,
    required this.onSelectStep,
    this.onBeforeSelectStep,
  });

  @override
  State<SessionProgressScreen> createState() => _SessionProgressScreenState();
}

class _SessionProgressScreenState extends State<SessionProgressScreen> {
  static const _currentStepAlignment = 0.3;

  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  late final int _initialCurrentIndex;

  @override
  void initState() {
    super.initState();

    _initialCurrentIndex = widget.currentIndexProvider();

    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Positionne automatiquement la liste sur l'exercice en cours à
    // l'ouverture de l'écran.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToInitialCurrent(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInitialCurrent() {
    if (_initialCurrentIndex < 0 ||
        _initialCurrentIndex >= widget.steps.length ||
        !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final itemExtent =
        (position.maxScrollExtent + position.viewportDimension) /
        widget.steps.length;
    final targetOffset =
        _initialCurrentIndex * itemExtent -
        position.viewportDimension * _currentStepAlignment;

    unawaited(
      _scrollController.animateTo(
        targetOffset
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  SessionProgressStepTile _buildStepTile(
    int index, {
    required bool isCurrent,
    required bool done,
    VoidCallback? onSelect,
  }) => SessionProgressStepTile(
    step: widget.steps[index],
    done: done,
    isCurrent: isCurrent,
    blinkController: widget.blinkController,
    onSelect: onSelect ?? () => _confirmAndSelect(index),
  );

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

    final beforeSelect = widget.onBeforeSelectStep;
    if (beforeSelect != null && !await beforeSelect(index)) return;

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
        controller: _scrollController,
        prototypeItem: widget.steps.isEmpty
            ? null
            : _buildStepTile(
                _initialCurrentIndex >= 0 &&
                        _initialCurrentIndex < widget.steps.length
                    ? _initialCurrentIndex
                    : 0,
                done: false,
                isCurrent: false,
                onSelect: () {},
              ),
        itemCount: widget.steps.length,
        itemBuilder: (context, index) {
          return _buildStepTile(
            index,
            done: widget.completed[index],
            isCurrent: index == currentIndex,
          );
        },
      ),
    );
  }
}
