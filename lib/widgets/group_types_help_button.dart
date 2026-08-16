import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'contextual_help_button.dart';

typedef GroupTypesHelpLoader = Future<String> Function();

class GroupTypesHelpButton extends StatelessWidget {
  const GroupTypesHelpButton({super.key, this.loadContent});

  final GroupTypesHelpLoader? loadContent;

  @override
  Widget build(BuildContext context) => ContextualHelpButton(
    title: 'Types de groupe',
    tooltip: 'Aide sur les types de groupe',
    icon: const Icon(Icons.help_outline),
    content: _GroupTypesHelpContent(
      loadContent:
          loadContent ??
          () => rootBundle.loadString('assets/help/group_types.md'),
    ),
  );
}

class _GroupTypesHelpContent extends StatefulWidget {
  const _GroupTypesHelpContent({required this.loadContent});

  final GroupTypesHelpLoader loadContent;

  @override
  State<_GroupTypesHelpContent> createState() => _GroupTypesHelpContentState();
}

class _GroupTypesHelpContentState extends State<_GroupTypesHelpContent> {
  late final Future<String> _content = widget.loadContent();

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _content,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text(
          "L'aide sur les types de groupe est momentanément indisponible.",
          key: Key('group-types-help-error'),
        );
      }
      final data = snapshot.data;
      if (data == null) {
        return const Center(
          child: CircularProgressIndicator(
            key: Key('group-types-help-loading'),
          ),
        );
      }
      return MarkdownBody(
        key: const Key('group-types-help-content'),
        data: data,
        selectable: true,
      );
    },
  );
}
