import 'package:flutter/material.dart';
import 'widgets/app_drawer.dart';
import 'widgets/numerology_analysis_section.dart';
import 'models/numerology_analysis.dart';
import 'openai_client.dart';
import 'rag_service_singleton.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/numerology_service.dart';
import 'services/numerology_descriptions_service.dart';
import 'services/numerology_prompt_service.dart';

class NumerologiePage extends StatefulWidget {
  const NumerologiePage({super.key});

  @override
  State<NumerologiePage> createState() => _NumerologiePageState();
}

class _NumerologiePageState extends State<NumerologiePage> {

  final _formKey = GlobalKey<FormState>();
  final _birthDateController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _currentYearController = TextEditingController();

  // Numerology numbers
  int? nombreDeVie;
  int? nombreExpression;
  int? nombreIntime;
  int? nombreAnneePersonnelle;
  int? nombreAme;
  int? nombrePersonnalite;
  int? nombrePerception;
  List<int?> sphereNumbers = List.filled(9, null);

  // Analysis states using the model
  final Map<String, NumerologyAnalysis> analyses = {
    'chemin': NumerologyAnalysis(),
    'expression': NumerologyAnalysis(),
    'intime': NumerologyAnalysis(),
    'annee': NumerologyAnalysis(),
    'ame': NumerologyAnalysis(),
    'personnalite': NumerologyAnalysis(),
    'perception': NumerologyAnalysis(),
    'sphere1': NumerologyAnalysis(),
    'sphere2': NumerologyAnalysis(),
    'sphere3': NumerologyAnalysis(),
    'sphere4': NumerologyAnalysis(),
    'sphere5': NumerologyAnalysis(),
    'sphere6': NumerologyAnalysis(),
    'sphere7': NumerologyAnalysis(),
    'sphere8': NumerologyAnalysis(),
    'sphere9': NumerologyAnalysis(),
  };

  late final OpenAIClient _openAI;

  // RAG-specific state variables
  String? ragAnswer;
  String? ragContext;
  String? lastSystemPrompt;
  bool isRagLoading = false;

  @override
  void initState() {
    super.initState();
    _openAI = OpenAIClient(dotenv.env['OPENAI_API_KEY'] ?? '');
    _loadDescriptions();
    
    // Default data
    _birthDateController.text = '08051980';
    _firstNameController.text = 'Pamela ELEONORE MARGUERITE';
    _lastNameController.text = 'Lessel';
    _currentYearController.text = DateTime.now().year.toString();
  }

  Future<void> _loadDescriptions() async {
    await NumerologyDescriptionsService.loadDescriptions();
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentYearController.dispose();
    super.dispose();
  }

  void _calculateNumbers() {
    final birthDate = _birthDateController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final currentYear = _currentYearController.text.trim();

    if (!NumerologyService.validateInputs(birthDate, firstName, lastName, currentYear)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs correctement.')),
      );
      return;
    }

    final results = NumerologyService.calculateAllNumbers(birthDate, firstName, lastName, currentYear);

    setState(() {
      nombreDeVie = results['lifePathNumber'];
      nombreExpression = results['expressionNumber'];
      nombreIntime = results['intimeNumber'];
      nombreAnneePersonnelle = results['personalYearNumber'];
      nombreAme = results['soulNumber'];
      nombrePersonnalite = results['personalityNumber'];
      nombrePerception = results['perceptionNumber'];
      
      for (int i = 0; i < 9; i++) {
        sphereNumbers[i] = results['sphere${i + 1}'];
      }
      
      // Reset all analyses
      analyses.forEach((key, analysis) => analysis.reset());
    });
  }

  Future<void> _performAnalysis(String key, int number, String basePrompt, String numberType) async {
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      number,
      basePrompt,
      numberType
    );
    
    setState(() {
      analyses[key]!.isLoading = true;
      analyses[key]!.prompt = enhancedPrompt;
      analyses[key]!.answer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          analyses[key]!.answer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          analyses[key]!.answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          analyses[key]!.isLoading = false;
        });
      }
    }
  }

  String _createPersonalPrompt(String analysis, String name) {
    return "En tant qu'expert en numérologie, $analysis pour $name. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
  }

  /// Create a numerology prompt using the prompt service
  String _createNumerologyRagPrompt(int number, String analysisType, String name, String birthDate) {
    return NumerologyPromptService.buildNumerologyRagPrompt(
      number: number,
      numberType: NumerologyPromptService.getNumerologyTypeName(analysisType),
      name: name,
      birthDate: birthDate,
    );
  }

  // ===========================================================================================================
  /// RAG-based numerology analysis function (follows three-card page pattern)
  Future<void> _askRag(int number, String analysisType, String name, String birthDate) async {
    if (!mounted) return;
    
    final name = "${_firstNameController.text} ${_lastNameController.text}";
    final birthDate = _birthDateController.text;
    
    setState(() {
      isRagLoading = true;
      ragAnswer = null;
      ragContext = null;
      lastSystemPrompt = null;
      
      // IMPORTANT: Also update the specific analysis state
      analyses[analysisType]!.isLoading = true;
      analyses[analysisType]!.answer = null;
    });
    
    try {
      // Use template for vector search prompt (simpler, focused on retrieval)
      final vectorSearchPrompt = NumerologyPromptService.buildNumerologyVectorSearchPrompt(
        number: number,
        numberType: analysisType,
      );
      
      // Use template for final OpenAI response prompt (includes tone instructions)
      final finalSystemPrompt = NumerologyPromptService.buildNumerologyRagPrompt(
        number: number,
        numberType: NumerologyPromptService.getNumerologyTypeName(analysisType),
        name: name,
        birthDate: birthDate,
      );
      
      // Enrich the vector search query
      // final question = customQuestion ?? "Analyse numérologique demandée pour $name.";
      // final enrichedQuery = "$vectorSearchPrompt\n\n$question";
      
      // Debug: print the query and prompt
      // print('NUMEROLOGY RAG QUERY DEBUG: question = "$vectorSearchPrompt"');
      print('NUMEROLOGY RAG SYSTEM PROMPT DEBUG: prompt = "$finalSystemPrompt"');

      // Use the same pattern as three-card page: askQuestion with systemPrompt and contextFilter
      final result = await ragService.askQuestion(
        vectorSearchPrompt,
        systemPrompt: finalSystemPrompt,
        contextFilter: 'numerologie',
      );
      
      if (mounted) {
        setState(() {
          ragAnswer = result['answer'] as String?;
          ragContext = result['context_used'] as String?;
          lastSystemPrompt = finalSystemPrompt;
          
          // IMPORTANT: Also update the specific analysis state
          analyses[analysisType]!.answer = result['answer'] as String?;
          analyses[analysisType]!.prompt = finalSystemPrompt;
        });
      }
    } catch (e) {
      print('Error in numerology RAG: $e');
      if (mounted) {
        setState(() {
          ragAnswer = 'Erreur lors de l\'analyse: $e';
          
          // IMPORTANT: Also update the specific analysis state
          analyses[analysisType]!.answer = 'Erreur lors de l\'analyse: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isRagLoading = false;
          
          // IMPORTANT: Also update the specific analysis state
          analyses[analysisType]!.isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = "${_firstNameController.text} ${_lastNameController.text}";
    
    return Scaffold(
      appBar: AppBar(
        title: const SelectableText('Numerologie'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form section
            _buildForm(),
            
            const SizedBox(height: 32),
            
            // Results section
            if (_hasResults()) ...[
              _buildResults(),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Analysis sections
              ..._buildAnalysisSections(name),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _birthDateController,
            decoration: const InputDecoration(
              labelText: 'Date de naissance (JJMMAAAA)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            maxLength: 8,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Prénom',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _currentYearController,
            decoration: const InputDecoration(
              labelText: 'Année actuelle (AAAA)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _calculateNumbers,
            child: const Text('Calculer'),
          ),
        ],
      ),
    );
  }

  bool _hasResults() {
    return nombreDeVie != null && nombreExpression != null && 
           nombreIntime != null && nombreAnneePersonnelle != null;
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic numbers
        SelectableText('Nombre chemin de vie : $nombreDeVie', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        // SelectableText('Nombre intime : $nombreIntime', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SelectableText('Nombre année personnelle : $nombreAnneePersonnelle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        // SelectableText('Numéro de perception : ${nombrePerception ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        
        const SizedBox(height: 16),
        
        // Additional numbers
        SelectableText('Numéro de l\'âme : ${nombreAme ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SelectableText('Numéro de la personnalité : ${nombrePersonnalite ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SelectableText('Nombre d\'expression : $nombreExpression', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        
        // Spheres
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const SelectableText('Sphères :', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
        const SizedBox(height: 8),
        
        ..._buildSphereNumbers(),
      ],
    );
  }

  List<Widget> _buildSphereNumbers() {
    final sphereNames = [
      'Identité', 'Sentiment', 'Communication', 'Travail', 'Analytique',
      'Famille', 'Spiritualité', 'Talents', 'Empathie'
    ];
    
    return List.generate(9, (index) => 
      SelectableText('Sphère ${index + 1} (${sphereNames[index]}) : ${sphereNumbers[index] ?? 0}', 
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
    );
  }

  // --- Sphere OpenAI and RAG analysis helpers ---
  Future<void> _performSphereOpenAI(String key, String prompt) async {
    setState(() {
      analyses[key]!.isLoading = true;
      analyses[key]!.prompt = prompt;
      analyses[key]!.answer = null;
      analyses[key]!.promptType = 'openai';
    });
    try {
      final answer = await _openAI.sendMessage(prompt);
      if (mounted) {
        setState(() {
          analyses[key]!.answer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          analyses[key]!.answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          analyses[key]!.isLoading = false;
        });
      }
    }
  }

  Future<void> _performSphereRag(String key, String prompt) async {
    setState(() {
      analyses[key]!.isLoading = true;
      analyses[key]!.prompt = prompt;
      analyses[key]!.answer = null;
      analyses[key]!.promptType = 'rag';
    });
    try {
      final result = await ragService.askQuestion(prompt, contextFilter: 'numerologie');
      if (mounted) {
        setState(() {
          analyses[key]!.answer = result['answer'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          analyses[key]!.answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          analyses[key]!.isLoading = false;
        });
      }
    }
  }

  List<Widget> _buildAnalysisSections(String name) {
    final sections = [
      // Basic analyses
      NumerologyAnalysisSection(
        buttonText: 'Le Chemin de Vie',
        isLoading: analyses['chemin']!.isLoading,
        onPressed: nombreDeVie != null ? () => _askRag(nombreDeVie!, 'chemin', name, _birthDateController.text) : null,
        prompt: analyses['chemin']!.prompt,
        answer: analyses['chemin']!.answer,
      ),
      
      NumerologyAnalysisSection(
        buttonText: 'nombre d\'expression',
        isLoading: analyses['expression']!.isLoading,
        onPressed: nombreExpression != null ? () => _askRag(nombreExpression!, 'expression', name, _birthDateController.text) : null,
        prompt: analyses['expression']!.prompt,
        answer: analyses['expression']!.answer,
      ),
      
      // NumerologyAnalysisSection(
      //   buttonText: 'nombre intime',
      //   isLoading: analyses['intime']!.isLoading,
      //   onPressed: nombreIntime != null ? () => _performAnalysis(
      //     'intime', nombreIntime!, 
      //     _createPersonalPrompt("analyse le nombre intime $nombreIntime", name),
      //     "nombre intime"
      //   ) : null,
      //   prompt: analyses['intime']!.prompt,
      //   answer: analyses['intime']!.answer,
      // ),
      
      NumerologyAnalysisSection(
        buttonText: 'année personnelle',
        isLoading: analyses['annee']!.isLoading,
        onPressed: nombreAnneePersonnelle != null ? () => _performAnalysis(
          'annee', nombreAnneePersonnelle!, 
          _createPersonalPrompt("analyse l'année personnelle numéro $nombreAnneePersonnelle", "$name, né(e) le ${_birthDateController.text}"),
          "année personnelle"
        ) : null,
        prompt: analyses['annee']!.prompt,
        answer: analyses['annee']!.answer,
      ),
    ];

    // Add sphere sections
    final sphereNames = ['Identité', 'Sentiment', 'Communication', 'Travail', 'Analytique', 'Famille', 'Spiritualité', 'Talents', 'Empathie'];

    // Move the helper methods above this loop
    // ...existing code...
    for (int i = 0; i < 9; i++) {
      final sphereKey = 'sphere${i + 1}';
      final sphereAnalysis = "La sphère de ${sphereNames[i].toLowerCase()} se construit avec l'énergie du ${i + 1} que je construis en mode énergie du ${sphereNumbers[i]} Il y a donc le ${i + 1} et le ${sphereNumbers[i]} à prendre en considération pour l'interprétation de chaque sphère.";
      final promptOpenAI = _createPersonalPrompt(sphereAnalysis, name);
      final promptRag = _createPersonalPrompt("La sphère de ${sphereNames[i].toLowerCase()} se construit avec l'énergie du ${i + 1} que je construis en mode énergie du ${sphereNumbers[i]}", name); // no number signification for RAG
      sections.addAll([
        NumerologyAnalysisSection(
          buttonText: 'Sphère ${i + 1} : ${sphereNames[i]} (OpenAI)',
          isLoading: analyses[sphereKey]!.isLoading && analyses[sphereKey]!.promptType == 'openai',
          onPressed: sphereNumbers[i] != null ? () => _performSphereOpenAI(sphereKey, promptOpenAI) : null,
          prompt: analyses[sphereKey]!.promptType == 'openai' ? analyses[sphereKey]!.prompt : null,
          answer: analyses[sphereKey]!.promptType == 'openai' ? analyses[sphereKey]!.answer : null,
        ),
        NumerologyAnalysisSection(
          buttonText: 'Sphère ${i + 1} : ${sphereNames[i]} (RAG)',
          isLoading: analyses[sphereKey]!.isLoading && analyses[sphereKey]!.promptType == 'rag',
          onPressed: sphereNumbers[i] != null ? () => _performSphereRag(sphereKey, promptRag) : null,
          prompt: analyses[sphereKey]!.promptType == 'rag' ? analyses[sphereKey]!.prompt : null,
          answer: analyses[sphereKey]!.promptType == 'rag' ? analyses[sphereKey]!.answer : null,
        ),
      ]);
    }

    // Add remaining analyses
    sections.addAll([
      NumerologyAnalysisSection(
        buttonText: 'Numéro de l\'âme',
        isLoading: analyses['ame']!.isLoading,
        onPressed: nombreAme != null ? () => _performAnalysis(
          'ame', nombreAme!, 
          _createPersonalPrompt("analyse le numéro de l'âme $nombreAme. Le numéro de l'âme représente comment vous soutenez votre âme", name),
          "numéro de l'âme"
        ) : null,
        prompt: analyses['ame']!.prompt,
        answer: analyses['ame']!.answer,
      ),
      
      NumerologyAnalysisSection(
        buttonText: 'Numéro de la personnalité',
        isLoading: analyses['personnalite']!.isLoading,
        onPressed: nombrePersonnalite != null ? () => _performAnalysis(
          'personnalite', nombrePersonnalite!, 
          _createPersonalPrompt("analyse le numéro de la personnalité $nombrePersonnalite. Ce numéro représente comment les autres vous perçoivent", name),
          "numéro de la personnalité"
        ) : null,
        prompt: analyses['personnalite']!.prompt,
        answer: analyses['personnalite']!.answer,
      ),
    ]);

    return sections;
  }
}