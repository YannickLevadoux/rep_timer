import 'package:flutter/material.dart';

import '../models/group_type.dart';

/// Sélecteur du type de groupe, sous forme de liste déroulante. Isolé de
/// [GroupEditor] : l'ajout d'un nouveau [GroupType] à l'avenir n'impacte
/// que ce widget (la liste des items provient directement de
/// La liste reste limitée aux éditeurs déjà disponibles. Les types temporisés
/// sont activés par l'issue dédiée à l'éditeur partagé.
class TypeSelector extends StatelessWidget {
  static const editableTypes = [GroupType.free, GroupType.variableRepetitions];

  final GroupType value;
  final ValueChanged<GroupType> onChanged;

  const TypeSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<GroupType>(
      initialValue: value,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Type du groupe",
      ),
      items: editableTypes
          .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
          .toList(),
      onChanged: (type) => onChanged(type!),
    );
  }
}
