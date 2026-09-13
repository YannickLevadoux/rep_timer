import '../models/session_step.dart';

String formatTabataStepLabel(SessionStep step) {
  final cycle = step.tabataCycleIndex ?? step.roundIndex;
  final cycleTotal = step.tabataCycleTotal ?? step.totalRounds;
  if (step.tabataRoundIndex == null || step.tabataRoundTotal == null) {
    return 'Cycle $cycle/$cycleTotal';
  }
  if (step.tabataRoundTotal == 1) return 'Cycle $cycle/$cycleTotal';
  return 'Tour ${step.tabataRoundIndex}/${step.tabataRoundTotal} · '
      'Cycle $cycle/$cycleTotal';
}
