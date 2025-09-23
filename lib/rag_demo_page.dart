import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/rag_service.dart';
import 'widgets/app_drawer.dart';

class RagDemoPage extends StatefulWidget {
  const RagDemoPage({super.key});

  @override
  State<RagDemoPage> createState() => _RagDemoPageState();
}

class _RagDemoPageState extends State<RagDemoPage> {
  // --- Action methods for buttons ---
  Future<void> _testConfiguration() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _configTest = null;
    });
    try {
      final results = await _ragService.testConfiguration();
      setState(() {
        _configTest = results;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Test de configuration échoué: $e';
        _configTest = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _debugPinecone() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _answer = null;
      _sources = null;
    });
    try {
      final testQuery = _questionController.text.trim().isNotEmpty
          ? _questionController.text.trim()
          : 'tarot';
      final result = await _ragService.debugPineconeSearch(testQuery);
      if (result['success'] == true) {
        final totalMatches = result['total_matches'] as int;
        setState(() {
          _answer = '🔬 DEBUG PINECONE RESULTS:\n\n• Total matches found: $totalMatches';
        });
      } else {
        setState(() {
          _error = 'Erreur lors du debug Pinecone: ${result['error'] ?? 'inconnue'}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du debug Pinecone: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _askQuestion() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _answer = null;
      _sources = null;
      _systemPromptSent = null;
    });
    try {
      final question = _questionController.text.trim();
      if (question.isEmpty) {
        setState(() {
          _error = 'Veuillez entrer une question.';
        });
        return;
      }
      final result = await _ragService.askQuestion(question);
      setState(() {
        _answer = result['answer'] as String?;
        _sources = (result['sources'] as List?)?.cast<Map<String, dynamic>>();
        _systemPromptSent = result['systemPrompt'] as String?;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la requête: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo RAG - Questions Astrologiques'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🤖 Système RAG Activé',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pinecone: ${dotenv.env['PINECONE_INDEX_NAME'] ?? 'Non configuré'}',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                      Text(
                        'Supabase: ${dotenv.env['SUPABASE_URL']?.isNotEmpty == true ? 'Connecté' : 'Non configuré'}',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                      Text(
                        'Modèle: ${dotenv.env['OPENAI_EMBEDDING_MODEL'] ?? 'text-embedding-3-small'}',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Posez votre question astrologique',
                  hintText: 'Ex: Que signifie avoir Mars en Bélier?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.help_outline),
                ),
                maxLines: 3,
                // onSubmitted: (_) => _askQuestion(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testConfiguration,
                icon: const Icon(Icons.settings_suggest),
                label: const Text('Tester la configuration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _debugPinecone,
                icon: const Icon(Icons.bug_report),
                label: const Text('🔬 Debug Pinecone'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _askQuestion,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Recherche en cours...' : 'Poser la question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              if (_configTest != null) ...[
                Text(
                  'Test de Configuration',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _configTest!['openai_available'] ? Icons.check_circle : Icons.error,
                              color: _configTest!['openai_available'] ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text('OpenAI Embeddings'),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              _configTest!['pinecone_available'] ? Icons.check_circle : Icons.error,
                              color: _configTest!['pinecone_available'] ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text('Pinecone Vector DB'),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              _configTest!['supabase_available'] ? Icons.check_circle : Icons.error,
                              color: _configTest!['supabase_available'] ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text('Supabase Database'),
                          ],
                        ),
                        if ((_configTest!['errors'] as List).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Erreurs détectées:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          ...((_configTest!['errors'] as List).map((error) => Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Text(
                              '• $error',
                              style: TextStyle(color: Colors.red[600], fontSize: 12),
                            ),
                          ))),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (_error != null)
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ),
              if (_systemPromptSent != null && _answer != null) ...[
                const Text('Prompt système envoyé à OpenAI :', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: SelectableText(
                    _systemPromptSent!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    minLines: 3,
                    maxLines: 16,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_answer != null) ...[
                Text(
                  'Réponse IA',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _answer!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (_sources != null && _sources!.isNotEmpty) ...[
                Text(
                  'Sources utilisées (${_sources!.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...(_sources!.map((source) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.article, color: Colors.orange[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Score: ${(source['score'] as double?)?.toStringAsFixed(3) ?? '?'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                            const Spacer(),
                            if (source['content']?['title'] != null)
                              Expanded(
                                child: Text(
                                  source['content']['title'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          source['content']?['chunk_text'] ??
                          source['content']?['content'] ??
                          source['content']?['text'] ??
                          'Contenu non disponible',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ))),
              ],
            ],
          ),
        ),
      ),
    );
  }
  final TextEditingController _questionController = TextEditingController();
  final RagService _ragService = RagService();
  
  String? _answer;
  List<Map<String, dynamic>>? _sources;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _configTest;
  String? _systemPromptSent;

  }