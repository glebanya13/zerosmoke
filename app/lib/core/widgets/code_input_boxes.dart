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
  });

  final int length;
  final ValueChanged<String>? onCompleted;
  final double boxSize;
  final double radius;
  final double gap;

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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: BorderSide(
                    color: filled ? AppColors.primary : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(widget.radius),
                  borderSide: BorderSide(
                    color: filled ? AppColors.primary : AppColors.border,
                  ),
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
