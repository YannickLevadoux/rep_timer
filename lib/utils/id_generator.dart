/// Génère des identifiants uniques à partir de l'horodatage courant,
/// couplé à un compteur : évite toute collision même si plusieurs
/// identifiants sont générés dans la même microseconde (ex : duplication
/// d'une séance à plusieurs groupes). Même principe que le générateur
/// interne déjà utilisé par TrainingExportService pour l'import.
class IdGenerator {
  int _counter = 0;

  String next() => '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
}
