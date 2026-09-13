import 'dart:async';

import 'package:flutter/material.dart';

import '../models/session_step.dart';
import '../widgets/session_progress_list.dart';

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
  late final SessionProgressListLayout _listLayout;

  @override
  void initState() {
    super.initState();

    _initialCurrentIndex = widget.currentIndexProvider();
    _listLayout = SessionProgressListLayout(widget.steps);

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
    final currentStepOffset = _listLayout.stepOffset(
      context,
      _initialCurrentIndex,
    );
    final targetOffset =
        currentStepOffset - position.viewportDimension * _currentStepAlignment;

    unawaited(_animateToInitialCurrent(targetOffset));
  }

  Future<void> _animateToInitialCurrent(double targetOffset) async {
    var position = _scrollController.position;
    await _scrollController.animateTo(
      targetOffset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    if (!mounted || !_scrollController.hasClients) return;

    // Une liste à hauteurs variées affine son étendue maximale à mesure que
    // de nouveaux éléments sont rendus. Une courte correction garantit donc
    // la limite exacte en fin de très longue séance.
    position = _scrollController.position;
    final correctedOffset = targetOffset
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((correctedOffset - position.pixels).abs() < 0.5) return;

    await _scrollController.animateTo(
      correctedOffset,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
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
      body: SessionProgressList(
        layout: _listLayout,
        steps: widget.steps,
        completed: widget.completed,
        currentIndex: currentIndex,
        blinkController: widget.blinkController,
        scrollController: _scrollController,
        onSelectStep: _confirmAndSelect,
      ),
    );
  }
}
