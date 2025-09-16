import 'package:flutter/material.dart';
import '../services/openai_chart_service.dart';

class OpenAIInterpretationWidget extends StatefulWidget {
  final Map<String, dynamic> chartData;

  const OpenAIInterpretationWidget({
    Key? key, // Change from super.key to Key? key
    required this.chartData,
  }) : super(key: key); // Add explicit super constructor

  @override
  State<OpenAIInterpretationWidget> createState() => _OpenAIInterpretationWidgetState();
}

class _OpenAIInterpretationWidgetState extends State<OpenAIInterpretationWidget> {
  final OpenAIChartService _openAIService = OpenAIChartService();
  final TextEditingController _promptController = TextEditingController();
  
  String? _chartInterpretation;
  bool _isLoadingInterpretation = false;
  String? _chartPrompt;
  bool _showPromptEditor = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _askOpenAIInterpretation() async {
    setState(() {
      _isLoadingInterpretation = true;
      _chartInterpretation = null;
    });

    try {
      // Build and store the prompt
      final prompt = _openAIService.buildChartPrompt(widget.chartData);
      setState(() {
        _chartPrompt = prompt;
        _promptController.text = prompt;
      });

      final answer = await _openAIService.interpretChart(widget.chartData);
      
      if (mounted) {
        setState(() {
          _chartInterpretation = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chartInterpretation = 'Erreur lors de l\'analyse: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInterpretation = false;
        });
      }
    }
  }

  Future<void> _sendCustomPrompt() async {
    if (_promptController.text.isEmpty) return;
    
    setState(() {
      _isLoadingInterpretation = true;
      _chartInterpretation = null;
      _chartPrompt = _promptController.text;
    });

    try {
      final answer = await _openAIService.sendMessage(_promptController.text);
      
      if (mounted) {
        setState(() {
          _chartInterpretation = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chartInterpretation = 'Erreur lors de l\'analyse: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInterpretation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        
        // Main buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoadingInterpretation ? null : _askOpenAIInterpretation,
              icon: _isLoadingInterpretation 
                  ? const SizedBox(
                      width: 16, 
                      height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Icon(Icons.psychology),
              label: const Text('Analyse OpenAI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showPromptEditor = !_showPromptEditor;
                });
              },
              icon: Icon(_showPromptEditor ? Icons.keyboard_arrow_up : Icons.edit),
              label: Text(_showPromptEditor ? 'Masquer' : 'Modifier prompt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),

        // Prompt editor section
        if (_showPromptEditor) ...[
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Éditeur de Prompt OpenAI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _promptController,
                  maxLines: 15,
                  decoration: const InputDecoration(
                    hintText: 'Écrivez votre question ou modifiez le prompt...',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoadingInterpretation ? null : _sendCustomPrompt,
                      icon: _isLoadingInterpretation 
                          ? const SizedBox(
                              width: 16, 
                              height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            )
                          : const Icon(Icons.send),
                      label: const Text('Envoyer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        _promptController.clear();
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Effacer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Display prompt used
        if (_chartPrompt != null) ...[
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.code, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      '📤 Prompt envoyé à OpenAI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    _chartPrompt!,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Display interpretation
        if (_chartInterpretation != null) ...[
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      '📥 Réponse d\'OpenAI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  _chartInterpretation!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}