import 'package:flutter/material.dart';

/// Une seule roue numérique (0..max), toujours visible pour le défilement,
/// et qui ouvre un petit clavier de saisie directe quand on touche la
/// valeur actuellement centrée.
class NumberWheelField extends StatefulWidget {
  final int min;
  final int max;
  final int value;
  final String label;
  final ValueChanged<int> onChanged;

  const NumberWheelField({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  State<NumberWheelField> createState() => _NumberWheelFieldState();
}

class _NumberWheelFieldState extends State<NumberWheelField> {
  late final FixedExtentScrollController _controller;

  int get _clampedValue => widget.value.clamp(widget.min, widget.max);

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: _clampedValue - widget.min,
    );
  }

  @override
  void didUpdateWidget(covariant NumberWheelField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si la valeur est modifiée depuis l'extérieur (ex : saisie clavier
    // validée), on resynchronise la roue pour qu'elle reste cohérente
    // avec la valeur affichée.
    final targetIndex = _clampedValue - widget.min;
    if (_controller.hasClients && _controller.selectedItem != targetIndex) {
      _controller.animateToItem(
        targetIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openKeyboardEntry() async {
    final textController = TextEditingController(
      text: _clampedValue.toString(),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Saisir : ${widget.label}"),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, int.tryParse(textController.text));
              },
              child: const Text("Valider"),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    widget.onChanged(result.clamp(widget.min, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.max - widget.min + 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 120,
          width: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ListWheelScrollView.useDelegate(
                controller: _controller,
                itemExtent: 40,
                diameterRatio: 1.3,
                perspective: 0.003,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  widget.onChanged(widget.min + index);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: itemCount,
                  builder: (context, index) {
                    final n = widget.min + index;
                    final isSelected = n == _clampedValue;

                    return Center(
                      child: GestureDetector(
                        onTap: isSelected ? _openKeyboardEntry : null,
                        child: Text(
                          n.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: isSelected ? 24 : 18,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Simple repère visuel de la valeur centrale, ne capte aucun
              // événement (le tap est géré par le Text lui-même).
              IgnorePointer(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(widget.label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
