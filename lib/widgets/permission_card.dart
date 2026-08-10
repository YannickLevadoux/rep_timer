import 'package:flutter/material.dart';

class PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String statusLabel;
  final bool statusLoading;
  final Widget? action;

  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.statusLoading,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '$title, $statusLabel',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(description),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (statusLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              if (action != null) ...[
                const SizedBox(height: 16),
                Semantics(button: true, child: action!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
