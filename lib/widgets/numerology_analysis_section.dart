// lib/widgets/numerology_analysis_section.dart

import 'package:flutter/material.dart';

class NumerologyAnalysisSection extends StatelessWidget {
  final String buttonText;
  final bool isLoading;
  final VoidCallback? onPressed;
  final String? prompt;
  final String? answer;

  const NumerologyAnalysisSection({
    super.key,
    required this.buttonText,
    required this.isLoading,
    required this.onPressed,
    this.prompt,
    this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: Text(buttonText),
        ),
        if (prompt != null) ...[
          const SizedBox(height: 32),
          const SelectableText('Prompt :', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              prompt!,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        if (answer != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SelectableText(answer!),
          ),
      ],
    );
  }
}