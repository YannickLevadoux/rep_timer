import 'package:flutter/material.dart';

/// Pilote le fondu partagé entre la séance et sa vue de progression.
class SessionBlinkController {
  SessionBlinkController({
    required TickerProvider vsync,
    required bool enabled,
    required bool initiallyPaused,
  }) : animationController = enabled
           ? AnimationController(
               vsync: vsync,
               duration: const Duration(milliseconds: 900),
             )
           : null {
    if (!enabled) return;
    if (initiallyPaused) {
      animationController!.value = 1;
    } else {
      animationController!.repeat(reverse: true);
    }
  }

  final AnimationController? animationController;

  Animation<double> get opacity => animationController == null
      ? const AlwaysStoppedAnimation(1)
      : Tween<double>(begin: 1, end: 0.35).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: Curves.easeInOut,
          ),
        );

  void synchronize({required bool paused, required bool finished}) {
    final controller = animationController;
    if (controller == null) return;
    if (finished || paused) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat(reverse: true);
    }
  }

  void dispose() => animationController?.dispose();
}
