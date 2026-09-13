import '../models/session_step.dart';

/// Signature stable du plan, utilisée pour refuser un checkpoint devenu
/// incompatible après une modification de la séance enregistrée.
String sessionPlanSignature(List<SessionStep> steps) {
  var hash = 0x811c9dc5;
  for (final step in steps) {
    final values = [
      step.group.id,
      step.group.type.name,
      step.item.type.name,
      step.item.name,
      step.item.duration?.inSeconds,
      step.item.repetitions,
      step.item.isFreeDuration,
      step.tabataRoundIndex,
      step.tabataRoundTotal,
      step.tabataCycleIndex,
      step.tabataCycleTotal,
    ];
    for (final value in values) {
      for (final unit in '$value'.codeUnits) {
        hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
      }
      hash = ((hash ^ 0xff) * 0x01000193) & 0xffffffff;
    }
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
