import 'package:flutter/material.dart';

class SelectableReadMoreText extends StatefulWidget {
  final String text;
  final int trimLines;
  final TextStyle? style;
  final String trimCollapsedText;
  final String trimExpandedText;
  final Color colorClickableText;
  final double? linkFontSize;

  const SelectableReadMoreText({
    Key? key,
    required this.text,
    this.trimLines = 3,
    this.style,
    this.trimCollapsedText = '\n\nVoir plus',
    this.trimExpandedText = '\n\nVoir moins',
    this.colorClickableText = Colors.blue,
    this.linkFontSize,
  }) : super(key: key);

  @override
  State<SelectableReadMoreText> createState() => _SelectableReadMoreTextState();
}

class _SelectableReadMoreTextState extends State<SelectableReadMoreText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final lines = widget.text.split('\n');
    final shouldTrim = lines.length > widget.trimLines;
    
    if (!shouldTrim) {
      return SelectableText(
        widget.text,
        style: widget.style,
      );
    }

    String displayText;
    String actionText;
    
    if (_isExpanded) {
      displayText = widget.text;
      actionText = widget.trimExpandedText;
    } else {
      displayText = lines.take(widget.trimLines).join('\n');
      actionText = widget.trimCollapsedText;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          displayText,
          style: widget.style,
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(
            actionText,
            style: TextStyle(
              color: widget.colorClickableText,
              fontWeight: FontWeight.bold,
              fontSize: widget.linkFontSize,
            ),
          ),
        ),
      ],
    );
  }
}