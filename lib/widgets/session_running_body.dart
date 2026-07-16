import 'package:flutter/material.dart';

import '../models/session_step.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import '../utils/formatters.dart';
import 'section_divider.dart';
import 'session_comment_section.dart';

/// Corps principal de l'écran d'exécution d'une séance : exercice en
/// cours (icône + nom clignotants), chronomètre/compte à rebours,
/// commentaire, et actions (précédent/suivant, valider, pause).
///
/// Widget purement d'affichage : toute la logique (progression, calcul
/// des durées, pause...) reste dans `SessionController` et l'écran
/// parent, qui fournit ici l'état courant et les callbacks d'action.
class SessionRunningBody extends StatelessWidget {
  final SessionStep step;
  final SessionStep? nextStep;
  final int currentIndex;
  final int totalSteps;
  final Duration globalElapsed;
  final Duration stepElapsed;
  final bool paused;
  final Animation<double> blinkOpacity;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onComplete;
  final VoidCallback onTogglePause;
  final VoidCallback onEditComment;

  const SessionRunningBody({
    super.key,
    required this.step,
    required this.nextStep,
    required this.currentIndex,
    required this.totalSteps,
    required this.globalElapsed,
    required this.stepElapsed,
    required this.paused,
    required this.blinkOpacity,
    required this.onPrevious,
    required this.onNext,
    required this.onComplete,
    required this.onTogglePause,
    required this.onEditComment,
  });

  @override
  Widget build(BuildContext context) {
    final item = step.item;
    final isDurationBased = item.duration != null;
    final isFreeDuration = item.isFreeDuration;
    final remaining = isDurationBased
        ? (item.duration! - stepElapsed)
        : Duration.zero;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                tooltip: "Exercice précédent",
                onPressed: currentIndex > 0 ? onPrevious : null,
              ),
              const SizedBox(width: 8),
              Text(
                formatDuration(globalElapsed),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next),
                tooltip: "Exercice suivant",
                onPressed: currentIndex < totalSteps - 1 ? onNext : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentIndex / totalSteps,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text("Exercice ${currentIndex + 1} / $totalSteps"),

          // ---- Section "Prochain" ----
          const SectionDivider(label: "Prochain"),

          Text(
            nextStep == null
                ? "Fin de la session"
                : nextStep!.item.type == ItemType.rest
                ? "Pause"
                : nextStep!.item.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          // ---- Section "En cours" ----
          const SectionDivider(label: "En cours"),

          Text(
            "${step.group.name} — Répétition ${step.roundIndex} / ${step.totalRounds}",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Zone principale : exercice en cours (icône + nom clignotent
          // pendant que la séance tourne, se figent immédiatement en
          // pause). Le commentaire, s'il existe, clignote avec eux.
          FadeTransition(
            opacity: blinkOpacity,
            child: Column(
              children: [
                Icon(
                  item.type == ItemType.exercise
                      ? iconForExercise(item.iconName)
                      : Icons.timer,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          SessionCommentSection(
            item: item,
            blinkOpacity: blinkOpacity,
            onEditComment: onEditComment,
          ),

          const SizedBox(height: 24),

          if (isFreeDuration)
            // Durée libre : chronomètre qui monte, indépendant du
            // chronomètre global, démarré automatiquement avec l'étape.
            // Même présentation que le compte à rebours du mode Temps
            // pour rester cohérent visuellement.
            Text(
              formatDuration(stepElapsed),
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            )
          else if (isDurationBased)
            // Compte à rebours très visible : élément le plus proéminent
            // de l'écran.
            Text(
              formatDuration(remaining),
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            )
          else ...[
            Text(
              "× ${item.repetitions ?? 0}",
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: paused ? null : onComplete,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Text(
                  "Répétitions effectuées",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],

          if (isFreeDuration) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: paused ? null : onComplete,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Text(
                  "Exercice effectué",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTogglePause,
              icon: Icon(paused ? Icons.play_arrow : Icons.pause),
              label: Text(paused ? "Reprendre" : "Pause"),
            ),
          ),
        ],
      ),
    );
  }
}
