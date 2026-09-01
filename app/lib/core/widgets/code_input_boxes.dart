import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';

/// Row of single-character boxes used for confirmation codes (registration,
/// account linking).
class CodeInputBoxes extends StatefulWidget {
  const CodeInputBoxes({
    super.key,
    this.length = 4,
    this.onCompleted,
    this.boxSize = 60,
    this.radius = 20,
    this.gap = 10,
    this.alwaysActiveBorder = false,
  });

  final int length;
  final ValueChanged<String>? onCompleted;
  final double boxSize;
  final double radius;
  final double gap;

  /// When true, every box shows the filled (blue) border from the start
  /// instead of only once it has a character in it.
  final bool alwaysActiveBorder;

  @override
  State<CodeInputBoxes> createState() => _CodeInputBoxesState();
}

class _CodeInputBoxesState extends State<CodeInputBoxes> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        final filled = _controllers[index].text.isNotEmpty;
        final active = filled || widget.alwaysActiveBorder;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
          child: SizedBox(
            width: widget.boxSize,
            height: widget.boxSize,
            child: TextField(
              controller: _controllers[index],
              focusNode: _nodes[index],
              textAlign: TextAlign.center,
              maxLength: 1,
              autocorrect: false,
              enableSuggestions: false,
              enableInteractiveSelection: false,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: BorderSide(
                    color: active ? AppColors.primary : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: BorderSide(
                    color: active ? AppColors.primary : AppColors.border,
                  ),
                ),
                // Without an explicit focusedBorder, Flutter falls back to
                // the ambient InputDecorationTheme (a pill-shaped border
                // elsewhere in the app), which made a focused box balloon
                // into an oval instead of staying a rounded square.
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (value) => _onChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}
