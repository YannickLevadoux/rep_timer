enum GroupEditorMode {
  add,
  edit,
  quick;

  String get title => switch (this) {
    GroupEditorMode.add => 'Ajout de groupe',
    GroupEditorMode.edit => 'Édition du groupe',
    GroupEditorMode.quick => 'Session rapide',
  };

  String get actionLabel => switch (this) {
    GroupEditorMode.add => 'Ajouter à la séance',
    GroupEditorMode.edit => 'Enregistrer',
    GroupEditorMode.quick => 'Commencer',
  };

  bool get isQuick => this == GroupEditorMode.quick;

  bool get requiresInitialTypeSelection => this == GroupEditorMode.add;
}
