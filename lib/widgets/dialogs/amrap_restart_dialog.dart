import 'package:flutter/material.dart';

Future<bool> showAmrapRestartDialog(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Recommencer l'AMRAP ?"),
        content: const Text(
          'Les tours enregistrés pour cette tentative seront supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recommencer'),
          ),
        ],
      ),
    ) ??
    false;
