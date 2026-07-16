import 'package:flutter/material.dart';

/// Affiche un message bref via le [SnackBar] par défaut de l'écran
/// courant. Factorise le
/// `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` répété
/// dans plusieurs écrans (validation de formulaire, confirmation
/// d'enregistrement, erreurs d'import/export...).
void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
