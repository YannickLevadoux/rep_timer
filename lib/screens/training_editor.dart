import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/exercise_group.dart';
import '../models/training.dart';
import '../services/training_storage.dart';
import '../screens/group_editor.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/exercise_group_card.dart';
import '../utils/snack.dart';

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
  // la liste jusqu'à un groupe précis après l'ajout d'un exercice/pause
  // (le groupe est alors garanti déjà construit, puisque l'utilisateur
  // vient d'y cliquer). Insuffisant pour un groupe tout juste créé : voir
  // _groupsScrollController ci-dessous.
  final Map<String, GlobalKey> _groupKeys = {};

  GlobalKey _keyForGroup(String groupId) =>
      _groupKeys.putIfAbsent(groupId, () => GlobalKey());

  // Contrôleur de la liste des groupes. Un nouveau groupe est toujours
  // ajouté en dernière position : dans une longue liste, son widget n'est
  // pas forcément déjà construit (ReorderableListView.builder virtualise
  // le contenu hors écran), donc cibler sa GlobalKey échouerait
  // silencieusement. On scrolle plutôt directement jusqu'à la fin de la
  // liste, ce qui force sa construction au passage.
  final ScrollController _groupsScrollController = ScrollController();

  void _scrollGroupsListToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_groupsScrollController.hasClients) return;
      _groupsScrollController.animateTo(
        _groupsScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
    _groupsScrollController.dispose();
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
      showSnack(context, "Merci de donner un nom à la séance");
      return;
    }

    if (groups.isEmpty) {
      showSnack(context, "Ajoute au moins un groupe d'exercices");
      return;
    }

    setState(() => _saving = true);

    final training = Training(
      id:
          widget.training?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      groups: groups,
      createdAt: widget.training?.createdAt ?? DateTime.now(),
    );

    await _storage.addOrUpdateTraining(training);

    if (!mounted) return;

    setState(() => _saving = false);

    showSnack(context, "Séance enregistrée");

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

    final choice = await showUnsavedChangesDialog(context);

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

    final deleted = await confirmAndDelete(
      context,
      title: "Supprimer la séance ?",
      content: 'Cette action est irréversible. Supprimer "${training.name}" ?',
      onDelete: () => _storage.deleteTraining(training.id),
    );

    if (!deleted || !mounted) return;

    // On retourne à l'accueil (true = recharger la liste des séances).
    Navigator.pop(context, true);
  }

  Future<void> _addGroup() async {
    FocusScope.of(context).unfocus();

    final group = await Navigator.push<ExerciseGroup>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupEditor(
          group: ExerciseGroup(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: "",
            items: [],
          ),
          isNewGroup: true,
        ),
      ),
    );

    if (group == null || !mounted) return;

    setState(() => groups.add(group));
    _scrollGroupsListToEnd();
  }

  Future<void> _editGroup(int index) async {
    FocusScope.of(context).unfocus();

    final group = await Navigator.push<ExerciseGroup>(
      context,
      MaterialPageRoute(builder: (_) => GroupEditor(group: groups[index])),
    );

    if (group == null || !mounted) return;

    setState(() {
      groups[index] = group;
    });
  }

  Future<void> _deleteGroup(int index) async {
    final group = groups[index];
    final confirmed = await showConfirmDialog(
      context,
      title: "Supprimer ce groupe ?",
      content: 'Supprimer "${group.name}" de la séance ?',
      confirmLabel: "Supprimer",
    );

    if (!confirmed || !mounted) return;

    setState(() {
      groups.removeAt(index);
      _groupKeys.remove(group.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
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

              const SizedBox(height: 10),

              Expanded(
                child: ReorderableListView.builder(
                  scrollController: _groupsScrollController,
                  buildDefaultDragHandles: false,
                  itemCount: groups.length,

                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
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

                      onDelete: () => _deleteGroup(index),
                      onEdit: () => _editGroup(index),
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
      ),
    );
  }
}
