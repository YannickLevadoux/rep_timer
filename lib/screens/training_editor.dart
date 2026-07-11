import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/exercise_group.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import '../services/training_storage.dart';
import '../utils/exercise_icons.dart';
import '../widgets/exercise_group_card.dart';
import '../widgets/exercise_icon_picker.dart';
import '../widgets/duration_minutes_seconds_picker.dart';

/// Mode de saisie d'un exercice dans les dialogues d'ajout/édition.
/// Purement local à l'UI : converti en (repetitions/duration/isFreeDuration)
/// sur TrainingItem au moment de la sauvegarde.
enum _ExerciseMode { repetitions, duration, freeDuration }

_ExerciseMode _modeOf(TrainingItem item) {
  if (item.isFreeDuration) return _ExerciseMode.freeDuration;
  if (item.duration != null) return _ExerciseMode.duration;
  return _ExerciseMode.repetitions;
}

class TrainingEditor extends StatefulWidget {
  // Si une séance est fournie, l'écran s'ouvre en mode édition (pré-rempli).
  // Sinon, il s'ouvre en mode création.
  final Training? training;

  const TrainingEditor({super.key, this.training});

  @override
  State<TrainingEditor> createState() => _TrainingEditorState();
}

class _TrainingEditorState extends State<TrainingEditor> {
  final TextEditingController _nameController = TextEditingController();

  final List<ExerciseGroup> groups = [];

  // Une GlobalKey stable par groupe (par id), pour pouvoir faire défiler
  // la liste jusqu'à un groupe précis après sa création (Scrollable.
  // ensureVisible a besoin d'un BuildContext identifiable).
  final Map<String, GlobalKey> _groupKeys = {};

  GlobalKey _keyForGroup(String groupId) =>
      _groupKeys.putIfAbsent(groupId, () => GlobalKey());

  void _scrollToGroup(String groupId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _groupKeys[groupId]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    });
  }

  final TrainingStorage _storage = TrainingStorage();

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.training;
    if (existing != null) {
      _nameController.text = existing.name;
      // Copie profonde (via toJson/fromJson, déjà présents sur les
      // modèles) : l'édition ne doit jamais modifier en place les objets
      // d'origine, seulement cette copie locale tant que l'utilisateur
      // n'a pas cliqué sur Enregistrer.
      groups.addAll(
        existing.groups.map((g) => ExerciseGroup.fromJson(g.toJson())),
      );
    }

    // Le titre de l'AppBar affiche le nom en direct : on doit se
    // reconstruire à chaque frappe.
    _nameController.addListener(_onNameChanged);

    // Référence de comparaison pour détecter toute modification non
    // enregistrée (ajout/suppression/renommage/réorganisation/réglages).
    _initialSnapshot = _currentSnapshot();
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  // Représentation canonique de l'état actuel de l'écran (nom + groupes,
  // dans l'ordre), utilisée pour détecter les modifications non
  // enregistrées. Réutilise directement les toJson() déjà présents sur
  // les modèles, sans dupliquer de logique de comparaison champ à champ.
  String _currentSnapshot() {
    return jsonEncode({
      'name': _nameController.text.trim(),
      'groups': groups.map((g) => g.toJson()).toList(),
    });
  }

  late final String _initialSnapshot;

  bool get _hasUnsavedChanges => _currentSnapshot() != _initialSnapshot;

  Future<void> _saveTraining() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merci de donner un nom à la séance")),
      );
      return;
    }

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ajoute au moins un groupe d'exercices")),
      );
      return;
    }

    setState(() => _saving = true);

    final training = Training(
      id: widget.training?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      groups: groups,
      createdAt: widget.training?.createdAt ?? DateTime.now(),
    );

    await _storage.addOrUpdateTraining(training);

    if (!mounted) return;

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Séance enregistrée")),
    );

    // On renvoie `true` pour que l'écran d'accueil sache qu'il doit
    // recharger la liste des séances sauvegardées.
    Navigator.pop(context, true);
  }

  // Gère le bouton Retour : sortie directe si rien n'a changé, sinon
  // propose Enregistrer / Abandonner les modifications / Annuler.
  Future<void> _handleBackPressed() async {
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modifications non enregistrées"),
          content: const Text(
            "Vous avez des modifications non enregistrées. Que souhaitez-vous faire ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text("Annuler"),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text("Abandonner les modifications"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text("Enregistrer"),
            ),
          ],
        );
      },
    );

    switch (choice) {
      case 'save':
        // Réutilise exactement le même enregistrement que le bouton
        // Enregistrer : il quitte l'écran une fois la sauvegarde faite
        // (et reste dessus si la validation échoue, ex. nom vide).
        await _saveTraining();
        break;
      case 'discard':
        // Aucune donnée d'origine n'a été touchée (édition sur une copie
        // locale) : il suffit de quitter sans rien enregistrer.
        if (mounted) Navigator.pop(context);
        break;
      case 'cancel':
      default:
        // Referme le dialogue, reste sur l'écran, rien n'est perdu.
        break;
    }
  }

  Future<void> _confirmDeleteTraining() async {
    FocusScope.of(context).unfocus();

    final training = widget.training;
    if (training == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Supprimer la séance ?"),
          content: Text(
            'Cette action est irréversible. Supprimer "${training.name}" ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _storage.deleteTraining(training.id);

    if (!mounted) return;

    // On retourne à l'accueil (true = recharger la liste des séances).
    Navigator.pop(context, true);
  }

  void _moveItemUp(ExerciseGroup group, int index) {
    if (index == 0) return;

    setState(() {
      final item = group.items.removeAt(index);
      group.items.insert(index - 1, item);
    });
  }

  void _moveItemDown(ExerciseGroup group, int index) {
    if (index >= group.items.length - 1) return;

    setState(() {
      final item = group.items.removeAt(index);
      group.items.insert(index + 1, item);
    });
  }

  // Réordonnancement par drag & drop des exercices/pauses dans un groupe
  void _reorderItems(ExerciseGroup group, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;

      final item = group.items.removeAt(oldIndex);
      group.items.insert(newIndex, item);
    });
  }

  void _deleteItem(ExerciseGroup group, int index) {
    setState(() {
      group.items.removeAt(index);
    });
  }

  // Modification d'un exercice ou d'une pause existant(e)
  Future<void> _editItem(ExerciseGroup group, int index) async {
    // Empêche Flutter de restaurer le focus (et donc le clavier) sur un
    // champ de l'écran sous-jacent (ex : le titre de la séance) quand ce
    // dialogue se refermera.
    FocusScope.of(context).unfocus();

    final item = group.items[index];

    if (item.type == ItemType.rest) {
      Duration selectedDuration = item.duration ?? defaultExerciseDuration;

      final result = await showDialog<Duration>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text("Modifier la pause"),
                content: SingleChildScrollView(
                  child: DurationMinutesSecondsPicker(
                    value: selectedDuration,
                    onChanged: (d) => setDialogState(() => selectedDuration = d),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Annuler"),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (selectedDuration.inSeconds <= 0) return;
                      Navigator.pop(context, selectedDuration);
                    },
                    child: const Text("Valider"),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result != null) {
        setState(() {
          item.duration = result;
        });
      }

      return;
    }

    // Exercice
    final nameController = TextEditingController(text: item.name);
    _ExerciseMode mode = _modeOf(item);
    final valueController = TextEditingController(
      text: item.repetitions?.toString() ?? '',
    );
    Duration selectedDuration = item.duration ?? defaultExerciseDuration;
    final commentController = TextEditingController(text: item.comment ?? '');
    String selectedIconName = item.iconName ?? defaultExerciseIconName;

    final result = await showDialog<TrainingItem>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Modifier l'exercice"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: () async {
                          final chosen = await showExerciseIconPicker(
                            context,
                            currentIconName: selectedIconName,
                          );
                          if (chosen != null) {
                            setDialogState(() => selectedIconName = chosen);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                          ),
                          child: Icon(
                            iconForExercise(selectedIconName),
                            size: 32,
                            color:
                                Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Toucher pour changer l'icône",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nom",
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButton<_ExerciseMode>(
                      value: mode,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: _ExerciseMode.repetitions,
                          child: Text("Répétitions"),
                        ),
                        DropdownMenuItem(
                          value: _ExerciseMode.duration,
                          child: Text("Temps"),
                        ),
                        DropdownMenuItem(
                          value: _ExerciseMode.freeDuration,
                          child: Text("Durée libre"),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          mode = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    if (mode == _ExerciseMode.duration)
                      DurationMinutesSecondsPicker(
                        value: selectedDuration,
                        onChanged: (d) =>
                            setDialogState(() => selectedDuration = d),
                      )
                    else if (mode == _ExerciseMode.repetitions)
                      TextField(
                        controller: valueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Nombre de répétitions",
                        ),
                      )
                    else
                      // Durée libre : ni durée ni répétitions à saisir, le
                      // temps sera mesuré pendant l'exécution de la séance.
                      Text(
                        "Aucun temps ni nombre de répétitions à définir : "
                        "un chronomètre démarrera pendant la séance et "
                        "vous déciderez vous-même de la fin de l'exercice.",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      minLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Commentaire (optionnel)",
                        hintText: "Poids, intensité...",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),
                FilledButton(
                  onPressed: () {
                    final comment = commentController.text.trim();

                    Navigator.pop(
                      context,
                      TrainingItem(
                        type: ItemType.exercise,
                        name: nameController.text,
                        repetitions: mode == _ExerciseMode.repetitions
                            ? int.tryParse(valueController.text)
                            : null,
                        duration: mode == _ExerciseMode.duration
                            ? selectedDuration
                            : null,
                        isFreeDuration: mode == _ExerciseMode.freeDuration,
                        comment: comment.isEmpty ? null : comment,
                        iconName: selectedIconName,
                      ),
                    );
                  },
                  child: const Text("Valider"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        item.name = result.name;
        item.repetitions = result.repetitions;
        item.duration = result.duration;
        item.comment = result.comment;
        item.iconName = result.iconName;
      });
    }
  }

  // Méthode pour ajouter un nouvel exercice
  Future<void> _addExercise(ExerciseGroup group) async {
  FocusScope.of(context).unfocus();

  // Préremplit uniquement une valeur par défaut, modifiable librement par
  // l'utilisateur ; n'affecte pas les exercices déjà créés.
  final nameController = TextEditingController(text: group.name);
  final valueController = TextEditingController();
  final commentController = TextEditingController();
  String selectedIconName = defaultExerciseIconName;
  Duration selectedDuration = defaultExerciseDuration;

  //ItemType mode = ItemType.exercise;
  _ExerciseMode mode = _ExerciseMode.repetitions;

  final result = await showDialog<TrainingItem>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Nouvel exercice"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: () async {
                        final chosen = await showExerciseIconPicker(
                          context,
                          currentIconName: selectedIconName,
                        );
                        if (chosen != null) {
                          setDialogState(() => selectedIconName = chosen);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child: Icon(
                          iconForExercise(selectedIconName),
                          size: 32,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Toucher pour changer l'icône",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Nom",
                    ),
                  ),

                  const SizedBox(height: 16),

                  DropdownButton<_ExerciseMode>(
                    value: mode,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: _ExerciseMode.repetitions,
                        child: Text("Répétitions"),
                      ),
                      DropdownMenuItem(
                        value: _ExerciseMode.duration,
                        child: Text("Temps"),
                      ),
                      DropdownMenuItem(
                        value: _ExerciseMode.freeDuration,
                        child: Text("Durée libre"),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        mode = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  if (mode == _ExerciseMode.duration)
                    DurationMinutesSecondsPicker(
                      value: selectedDuration,
                      onChanged: (d) =>
                          setDialogState(() => selectedDuration = d),
                    )
                  else if (mode == _ExerciseMode.repetitions)
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Nombre de répétitions",
                      ),
                    )
                  else
                    // Durée libre : ni durée ni répétitions à saisir, le
                    // temps sera mesuré pendant l'exécution de la séance.
                    Text(
                      "Aucun temps ni nombre de répétitions à définir : "
                      "un chronomètre démarrera pendant la séance et "
                      "vous déciderez vous-même de la fin de l'exercice.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Commentaire (optionnel)",
                      hintText: "Poids, intensité...",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              FilledButton(
                onPressed: () {
                  final comment = commentController.text.trim();

                  Navigator.pop(
                    context,
                    TrainingItem(
                      type: ItemType.exercise,
                      name: nameController.text,
                      repetitions: mode == _ExerciseMode.repetitions
                          ? int.tryParse(valueController.text)
                          : null,
                      duration: mode == _ExerciseMode.duration
                          ? selectedDuration
                          : null,
                      isFreeDuration: mode == _ExerciseMode.freeDuration,
                      comment: comment.isEmpty ? null : comment,
                      iconName: selectedIconName,
                    ),
                  );
                },
                child: const Text("Ajouter"),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != null) {
    setState(() {
      group.items.add(result);
    });
    _scrollToGroup(group.id);
  }
}

  Future<void> _addGroup() async {
  FocusScope.of(context).unfocus();

  final controller = TextEditingController();
  final roundsController = TextEditingController(text: "1");

  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Nouveau groupe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Ex : Échauffement",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: roundsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Nombre de répétitions du groupe",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                "name": controller.text,
                "rounds": roundsController.text,
              });
            },
            child: const Text("Ajouter"),
          ),
        ],
      );
    },
  );

  if (result != null && result["name"]!.trim().isNotEmpty) {
    final rounds = int.tryParse(result["rounds"] ?? "1") ?? 1;
    final newGroupId = DateTime.now().microsecondsSinceEpoch.toString();

    setState(() {
      groups.add(
        ExerciseGroup(
          id: newGroupId,
          name: result["name"]!.trim(),
          rounds: rounds < 1 ? 1 : rounds,
          items: [],
        ),
      );
    });

    // Le focus reste sur le champ Titre uniquement si l'utilisateur y
    // retape explicitement ; ici on l'amène plutôt vers le groupe créé.
    _scrollToGroup(newGroupId);
  }
}

  void _updateRounds(ExerciseGroup group, int rounds) {
    if (rounds < 1) return;

    setState(() {
      group.rounds = rounds;
    });
  }

  Future<void> _renameGroup(ExerciseGroup group) async {
    FocusScope.of(context).unfocus();

    final controller = TextEditingController(text: group.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Renommer le groupe"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Ex : Échauffement"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("Valider"),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final trimmed = result.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      group.name = trimmed;
    });
  }

// Add rest

  Future<void> _addRest(ExerciseGroup group) async {
  FocusScope.of(context).unfocus();

  Duration selectedDuration = defaultExerciseDuration;

  final result = await showDialog<TrainingItem>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Nouvelle pause"),
            content: SingleChildScrollView(
              child: DurationMinutesSecondsPicker(
                value: selectedDuration,
                onChanged: (d) => setDialogState(() => selectedDuration = d),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              FilledButton(
                onPressed: () {
                  if (selectedDuration.inSeconds <= 0) return;

                  Navigator.pop(
                    context,
                    TrainingItem(
                      type: ItemType.rest,
                      name: "Pause",
                      duration: selectedDuration,
                    ),
                  );
                },
                child: const Text("Ajouter"),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != null) {
    setState(() {
      group.items.add(result);
    });
    _scrollToGroup(group.id);
  }
}

// Next

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: Scaffold(
        appBar: AppBar(
        centerTitle: true,
        title: Text(
          _nameController.text.trim().isEmpty
              ? "Nouvelle séance"
              : _nameController.text.trim(),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.training != null)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Supprimer la séance",
              onPressed: _confirmDeleteTraining,
            )
          else
            // Garde le titre visuellement centré même sans bouton de
            // suppression (séance pas encore créée), en compensant la
            // largeur du bouton retour à gauche.
            const SizedBox(width: 48),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Nom de la séance",
                hintText: "Ex : Full Body",
              ),
            ),

            const SizedBox(height: 16),

            // Fin TextField 

            const SizedBox(height: 10),

            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: groups.length,

                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;

                    final item = groups.removeAt(oldIndex);
                    groups.insert(newIndex, item);
                  });
                },

                itemBuilder: (context, index) {
                  final group = groups[index];

                  return ExerciseGroupCard(
                    key: _keyForGroup(group.id),

                    group: group,
                    index: index,

                    onExpanded: (expanded) {
                      setState(() {
                        group.expanded = expanded;
                      });
                    },

                    onDelete: () {
                      setState(() {
                        groups.removeAt(index);
                      });
                      _groupKeys.remove(group.id);
                    },

                    onRename: () => _renameGroup(group),

                    onRoundsChanged: (rounds) =>
                        _updateRounds(group, rounds),

                    onAddExercise: () => _addExercise(group),
                    onAddRest: () => _addRest(group),

                    onReorderItems: (oldIndex, newIndex) =>
                        _reorderItems(group, oldIndex, newIndex),
                    onMoveItemUp: (itemIndex) =>
                        _moveItemUp(group, itemIndex),
                    onMoveItemDown: (itemIndex) =>
                        _moveItemDown(group, itemIndex),
                    onEditItem: (itemIndex) => _editItem(group, itemIndex),
                    onDeleteItem: (itemIndex) =>
                        _deleteItem(group, itemIndex),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addGroup,
                icon: const Icon(Icons.add),
                label: const Text("Ajouter un groupe"),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _saveTraining,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Enregistrer"),
              ),
            ),
          ],
        ),
      ),
      // End of body
      ),
    );
  }
}