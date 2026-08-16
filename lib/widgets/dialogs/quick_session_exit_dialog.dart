import 'package:flutter/material.dart';

import 'confirm_dialog.dart';

Future<bool> showQuickSessionExitDialog(BuildContext context) =>
    showConfirmDialog(
      context,
      title: 'Quitter la Session rapide ?',
      content:
          'Cette session a été modifiée, mais elle n’a pas été lancée. '
          'Voulez-vous vraiment quitter ?',
      confirmLabel: 'Retour à l’accueil',
      cancelLabel: 'Rester',
    );
