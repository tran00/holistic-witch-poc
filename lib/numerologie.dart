import 'package:flutter/material.dart';
import 'widgets/app_drawer.dart';
import 'openai_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/numerology_service.dart';
import 'services/numerology_descriptions_service.dart';

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
  final _currentYearController = TextEditingController(); // New

  int? nombreDeVie;
  int? nombreExpression;
  int? nombreIntime;
  int? nombreAnneePersonnelle; // New

  // Add these new variables
  int? nombreAme;
  int? nombrePersonnalite;
  int? nombrePerception;

  // Add these new variables for Sphère 1
  int? nombreSphere1;
  String? sphere1Prompt;
  String? sphere1Answer;
  bool isLoadingSphere1 = false;

  // Add these new variables for Sphère 2
  int? nombreSphere2;
  String? sphere2Prompt;
  String? sphere2Answer;
  bool isLoadingSphere2 = false;

  // Add these new variables for Sphère 3
  int? nombreSphere3;
  String? sphere3Prompt;
  String? sphere3Answer;
  bool isLoadingSphere3 = false;

  // Add these new variables for Sphères 4-9
  int? nombreSphere4;
  String? sphere4Prompt;
  String? sphere4Answer;
  bool isLoadingSphere4 = false;

  int? nombreSphere5;
  String? sphere5Prompt;
  String? sphere5Answer;
  bool isLoadingSphere5 = false;

  int? nombreSphere6;
  String? sphere6Prompt;
  String? sphere6Answer;
  bool isLoadingSphere6 = false;

  int? nombreSphere7;
  String? sphere7Prompt;
  String? sphere7Answer;
  bool isLoadingSphere7 = false;

  int? nombreSphere8;
  String? sphere8Prompt;
  String? sphere8Answer;
  bool isLoadingSphere8 = false;

  int? nombreSphere9;
  String? sphere9Prompt;
  String? sphere9Answer;
  bool isLoadingSphere9 = false;

  String? cheminPrompt;
  String? cheminAnswer;
  String? expressionPrompt;
  String? expressionAnswer;
  String? intimePrompt;
  String? intimeAnswer;
  String? anneePrompt; // New
  String? anneeAnswer; // New

  bool isLoadingChemin = false;
  bool isLoadingExpression = false;
  bool isLoadingIntime = false;
  bool isLoadingAnnee = false; // New

  // Add these variables for the new calculations
  String? amePrompt;
  String? ameAnswer;
  bool isLoadingAme = false;

  String? personnalitePrompt;
  String? personnaliteAnswer;
  bool isLoadingPersonnalite = false;

  String? perceptionPrompt;
  String? perceptionAnswer;
  bool isLoadingPerception = false;

  late final OpenAIClient _openAI;

  @override
  void initState() {
    super.initState();
    _openAI = OpenAIClient(dotenv.env['OPENAI_API_KEY'] ?? '');
    
    // Load numerology descriptions
    _loadDescriptions();
    
    // Add default data
    _birthDateController.text = '08051980';
    _firstNameController.text = 'Pamela ELEONORE MARGUERITE';
    _lastNameController.text = 'Lessel';
    
    // Set current year
    _currentYearController.text = DateTime.now().year.toString();
  }

  // Add this method
  Future<void> _loadDescriptions() async {
    await NumerologyDescriptionsService.loadDescriptions();
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentYearController.dispose(); // New
    super.dispose();
  }

  void _calculateNumbers() {
    final birthDate = _birthDateController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final currentYear = _currentYearController.text.trim();

    // Validation using service
    if (!NumerologyService.validateInputs(birthDate, firstName, lastName, currentYear)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs correctement.')),
      );
      return;
    }

    // Calculate all numbers using service
    final results = NumerologyService.calculateAllNumbers(birthDate, firstName, lastName, currentYear);

    setState(() {
      nombreDeVie = results['lifePathNumber'];
      nombreExpression = results['expressionNumber'];
      nombreIntime = results['intimeNumber'];
      nombreAnneePersonnelle = results['personalYearNumber'];
      nombreAme = results['soulNumber']; // Add this
      nombrePersonnalite = results['personalityNumber']; // Add this
      nombrePerception = results['perceptionNumber']; // Add this
      nombreSphere1 = results['sphere1'];
      nombreSphere2 = results['sphere2'];
      nombreSphere3 = results['sphere3'];
      nombreSphere4 = results['sphere4'];
      nombreSphere5 = results['sphere5'];
      nombreSphere6 = results['sphere6'];
      nombreSphere7 = results['sphere7'];
      nombreSphere8 = results['sphere8'];
      nombreSphere9 = results['sphere9'];
      
      // Reset all prompts and answers
      _resetAllPromptsAndAnswers();
    });
  }

  void _resetAllPromptsAndAnswers() {
    cheminPrompt = null;
    cheminAnswer = null;
    expressionPrompt = null;
    expressionAnswer = null;
    intimePrompt = null;
    intimeAnswer = null;
    anneePrompt = null;
    anneeAnswer = null;
    sphere1Prompt = null;
    sphere1Answer = null;
    sphere2Prompt = null;
    sphere2Answer = null;
    sphere3Prompt = null;
    sphere3Answer = null;
    sphere4Prompt = null;
    sphere4Answer = null;
    sphere5Prompt = null;
    sphere5Answer = null;
    sphere6Prompt = null;
    sphere6Answer = null;
    sphere7Prompt = null;
    sphere7Answer = null;
    sphere8Prompt = null;
    sphere8Answer = null;
    sphere9Prompt = null;
    sphere9Answer = null;
    amePrompt = null;
    ameAnswer = null;
    personnalitePrompt = null;
    personnaliteAnswer = null;
    perceptionPrompt = null;
    perceptionAnswer = null;
  }

  Future<void> _askCheminOpenAI() async {
    if (nombreDeVie == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse le chemin de vie numéro $nombreDeVie pour ${_firstNameController.text} ${_lastNameController.text}, né(e) le ${_birthDateController.text}. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreDeVie!,
      basePrompt,
      "chemin de vie"
    );
    
    setState(() {
      isLoadingChemin = true;
      cheminPrompt = enhancedPrompt;
      cheminAnswer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          cheminAnswer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          cheminAnswer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingChemin = false;
        });
      }
    }
  }

  Future<void> _askExpressionOpenAI() async {
    if (nombreExpression == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse le nombre d'expression $nombreExpression pour ${_firstNameController.text} ${_lastNameController.text}. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreExpression!,
      basePrompt,
      "nombre d'expression"
    );
    
    setState(() {
      isLoadingExpression = true;
      expressionPrompt = enhancedPrompt;
      expressionAnswer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          expressionAnswer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          expressionAnswer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingExpression = false;
        });
      }
    }
  }

  Future<void> _askIntimeOpenAI() async {
    if (nombreIntime == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse le nombre intime $nombreIntime pour ${_firstNameController.text} ${_lastNameController.text}. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreIntime!,
      basePrompt,
      "nombre intime"
    );
    
    setState(() {
      isLoadingIntime = true;
      intimePrompt = enhancedPrompt;
      intimeAnswer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          intimeAnswer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          intimeAnswer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingIntime = false;
        });
      }
    }
  }

  Future<void> _askAnneeOpenAI() async {
    if (nombreAnneePersonnelle == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse l'année personnelle numéro $nombreAnneePersonnelle pour ${_firstNameController.text} ${_lastNameController.text}, né(e) le ${_birthDateController.text}. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreAnneePersonnelle!,
      basePrompt,
      "année personnelle"
    );
    
    setState(() {
      isLoadingAnnee = true;
      anneePrompt = enhancedPrompt;
      anneeAnswer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          anneeAnswer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          anneeAnswer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingAnnee = false;
        });
      }
    }
  }

  // Add this new method for Sphère 1
  Future<void> _askSphere1OpenAI() async {
    if (nombreSphere1 == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse la sphère 1 (identité) numéro $nombreSphere1 pour une personne nommée ${_firstNameController.text} ${_lastNameController.text}. La sphère 1 représente l'identité profonde et est calculée en comptant les lettres A, J, S dans le nom complet. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreSphere1!,
      basePrompt,
      "sphère 1 (identité)"
    );
    
    setState(() {
      isLoadingSphere1 = true;
      sphere1Prompt = enhancedPrompt;
      sphere1Answer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          sphere1Answer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          sphere1Answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSphere1 = false;
        });
      }
    }
  }

  // Add this new method for Sphère 2
  Future<void> _askSphere2OpenAI() async {
    if (nombreSphere2 == null) return;

    final basePrompt = "En tant qu'expert en numérologie, analyse la sphère 2 (sentiment, couple, relations aux autres) numéro $nombreSphere2 pour une personne nommée ${_firstNameController.text} ${_lastNameController.text}. La sphère 2 représente les sentiments, le couple et les relations aux autres. Elle est calculée en comptant les lettres B, K, T dans le nom complet, chaque lettre ayant une valeur de 2. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";

    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreSphere2!,
      basePrompt,
      "sphère 2 (sentiment)"
    );
    
    setState(() {
      isLoadingSphere2 = true;
      sphere2Prompt = enhancedPrompt;
      sphere2Answer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          sphere2Answer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          sphere2Answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSphere2 = false;
        });
      }
    }
  }

  // Add this new method for Sphère 3
  Future<void> _askSphere3OpenAI() async {
    if (nombreSphere3 == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse la sphère 3 (communication, créativité, ami(e)s, relations sociales) numéro $nombreSphere3 pour une personne nommée ${_firstNameController.text} ${_lastNameController.text}. La sphère 3 représente la communication, la créativité, les amitiés et les relations sociales. Elle est calculée en comptant les lettres C, L, U dans le nom complet, chaque lettre ayant une valeur de 3. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreSphere3!,
      basePrompt,
      "sphère 3 (communication)"
    );
    
    setState(() {
      isLoadingSphere3 = true;
      sphere3Prompt = enhancedPrompt;
      sphere3Answer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          sphere3Answer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          sphere3Answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSphere3 = false;
        });
      }
    }
  }

  // Add this new method for Sphère 4
  Future<void> _askSphere4OpenAI() async {
    if (nombreSphere4 == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse la sphère 4 (travail quotidien pro/école famille d'origine) numéro $nombreSphere4 pour une personne nommée ${_firstNameController.text} ${_lastNameController.text}. La sphère 4 représente le travail quotidien, professionnel/école et la famille d'origine. Elle est calculée en comptant les lettres D, M, V dans le nom complet, chaque lettre ayant une valeur de 4.  Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreSphere4!,
      basePrompt,
      "sphère 4 (travail)"
    );
    
    setState(() {
      isLoadingSphere4 = true;
      sphere4Prompt = enhancedPrompt;
      sphere4Answer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          sphere4Answer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          sphere4Answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSphere4 = false;
        });
      }
    }
  }

  // Add this new method for Sphère 5
  Future<void> _askSphere5OpenAI() async {
    if (nombreSphere5 == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse la sphère 5 (analytique) numéro $nombreSphere5 pour une personne nommée ${_firstNameController.text} ${_lastNameController.text}. La sphère 5 représente l'aspect analytique de la personnalité. Elle est calculée en comptant les lettres E, N, W dans le nom complet, chaque lettre ayant une valeur de 5. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreSphere5!,
      basePrompt,
      "sphère 5 (analytique)"
    );
    
    setState(() {
      isLoadingSphere5 = true;
      sphere5Prompt = enhancedPrompt;
      sphere5Answer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          sphere5Answer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          sphere5Answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSphere5 = false;
        });
      }
    }
  }

  // Add this new method for Sphère 6
  Future<void> _askSphere6OpenAI() async {
    if (nombreSphere6 == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse la sphère 6 (la famille que j'ai construite/que je construis) numéro $nombreSphere6 pour une personne nommée ${_firstNameController.text} ${_lastNameController.text}. La sphère 6 représente la famille que la personne a construite ou qu'elle construit. Elle est calculée en comptant les lettres F, O, X dans le nom complet, chaque lettre ayant une valeur de 6. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreSphere6!,
      basePrompt,
      "sphère 6 (famille)"
    );
    
    setState(() {
      isLoadingSphere6 = true;
      sphere6Prompt = enhancedPrompt;
      sphere6Answer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          sphere6Answer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          sphere6Answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSphere6 = false;
        });
      }
    }
  }

  // Add this new method for Sphère 7
  Future<void> _askSphere7OpenAI() async {
    if (nombreSphere7 == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse la sphère 7 (connaissances spirituelles et intellectuelles) numéro $nombreSphere7 pour une personne nommée ${_firstNameController.text} ${_lastNameController.text}. La sphère 7 représente les connaissances spirituelles et intellectuelles. Elle est calculée en comptant les lettres G, P, Y dans le nom complet, chaque lettre ayant une valeur de 7. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreSphere7!,
      basePrompt,
      "sphère 7 (spiritualité)"
    );
    
    setState(() {
      isLoadingSphere7 = true;
      sphere7Prompt = enhancedPrompt;
      sphere7Answer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          sphere7Answer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          sphere7Answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSphere7 = false;
        });
      }
    }
  }

  // Add this new method for Sphère 8
  Future<void> _askSphere8OpenAI() async {
    if (nombreSphere8 == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse la sphère 8 (talents argent) numéro $nombreSphere8 pour une personne nommée ${_firstNameController.text} ${_lastNameController.text}. La sphère 8 représente les talents et l'argent. Elle est calculée en comptant les lettres H, Q, Z dans le nom complet, chaque lettre ayant une valeur de 8. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreSphere8!,
      basePrompt,
      "sphère 8 (talents)"
    );
    
    setState(() {
      isLoadingSphere8 = true;
      sphere8Prompt = enhancedPrompt;
      sphere8Answer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          sphere8Answer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          sphere8Answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSphere8 = false;
        });
      }
    }
  }

  // Add this new method for Sphère 9
  Future<void> _askSphere9OpenAI() async {
    if (nombreSphere9 == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse la sphère 9 (l'empathie les autres) numéro $nombreSphere9 pour une personne nommée ${_firstNameController.text} ${_lastNameController.text}. La sphère 9 représente l'empathie et les relations avec les autres. Elle est calculée en comptant les lettres I, R dans le nom complet, chaque lettre ayant une valeur de 9. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreSphere9!,
      basePrompt,
      "sphère 9 (empathie)"
    );
    
    setState(() {
      isLoadingSphere9 = true;
      sphere9Prompt = enhancedPrompt;
      sphere9Answer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          sphere9Answer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          sphere9Answer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSphere9 = false;
        });
      }
    }
  }

  Future<void> _askAmeOpenAI() async {
    if (nombreAme == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse le numéro de l'âme $nombreAme pour ${_firstNameController.text} ${_lastNameController.text}. Le numéro de l'âme représente comment vous soutenez votre âme et est calculé à partir de toutes les voyelles. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombreAme!,
      basePrompt,
      "numéro de l'âme"
    );
    
    setState(() {
      isLoadingAme = true;
      amePrompt = enhancedPrompt;
      ameAnswer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          ameAnswer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          ameAnswer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingAme = false;
        });
      }
    }
  }

  Future<void> _askPersonnaliteOpenAI() async {
    if (nombrePersonnalite == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse le numéro de la personnalité $nombrePersonnalite pour ${_firstNameController.text} ${_lastNameController.text}. Le numéro de la personnalité est calculé à partir de toutes les consonnes et représente comment les autres vous perçoivent. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombrePersonnalite!,
      basePrompt,
      "numéro de la personnalité"
    );
    
    setState(() {
      isLoadingPersonnalite = true;
      personnalitePrompt = enhancedPrompt;
      personnaliteAnswer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          personnaliteAnswer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          personnaliteAnswer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingPersonnalite = false;
        });
      }
    }
  }

  Future<void> _askPerceptionOpenAI() async {
    if (nombrePerception == null) return;
    
    final basePrompt = "En tant qu'expert en numérologie, analyse le numéro de perception $nombrePerception pour ${_firstNameController.text} ${_lastNameController.text}. Le numéro de perception représente comment vous percevez le monde. Tu t'adresses à l'utilisateur de manière directe et personnelle. Donne une interprétation détaillée en utilisant \"vous\" ou \"tu\".";
    
    final enhancedPrompt = NumerologyDescriptionsService.getEnhancedPrompt(
      nombrePerception!,
      basePrompt,
      "numéro de perception"
    );
    
    setState(() {
      isLoadingPerception = true;
      perceptionPrompt = enhancedPrompt;
      perceptionAnswer = null;
    });
    
    try {
      final answer = await _openAI.sendMessage(enhancedPrompt);
      if (mounted) {
        setState(() {
          perceptionAnswer = answer;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          perceptionAnswer = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingPerception = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SelectableText('Numerologie'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
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
                    //readOnly: true, // Add this to make it non-editable
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _calculateNumbers,
                    child: const Text('Calculer'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (nombreDeVie != null && nombreExpression != null && nombreIntime != null && nombreAnneePersonnelle != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic numerology numbers
                  SelectableText('Nombre chemin de vie : $nombreDeVie', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SelectableText('Nombre intime : $nombreIntime', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SelectableText('Nombre année personnelle : $nombreAnneePersonnelle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SelectableText('Numéro de perception : ${nombrePerception ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 16),
                  
                  // Add the new numbers
                  SelectableText('Numéro de l\'âme : ${nombreAme ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SelectableText('Numéro de la personnalité : ${nombrePersonnalite ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SelectableText('Nombre d\'expression : $nombreExpression', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  
                  // Add sphere numbers section
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const SelectableText('Sphères :', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                  const SizedBox(height: 8),
                  
                  // Display all sphere numbers
                  SelectableText('Sphère 1 (Identité) : ${nombreSphere1 ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  SelectableText('Sphère 2 (Sentiment) : ${nombreSphere2 ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  SelectableText('Sphère 3 (Communication) : ${nombreSphere3 ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  SelectableText('Sphère 4 (Travail) : ${nombreSphere4 ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  SelectableText('Sphère 5 (Analytique) : ${nombreSphere5 ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  SelectableText('Sphère 6 (Famille) : ${nombreSphere6 ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  SelectableText('Sphère 7 (Spiritualité) : ${nombreSphere7 ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  SelectableText('Sphère 8 (Talents) : ${nombreSphere8 ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  SelectableText('Sphère 9 (Empathie) : ${nombreSphere9 ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Buttons section starts here
                  ElevatedButton(
                    onPressed: isLoadingChemin ? null : _askCheminOpenAI,
                    child: const Text('demander à openAI votre chemin de vie'),
                  ),
                  
                  // ... rest of your existing buttons and content
                  if (cheminPrompt != null) ...[
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
                        cheminPrompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingChemin)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (cheminAnswer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(cheminAnswer!),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingExpression ? null : _askExpressionOpenAI,
                    child: const Text('nombre d\'expression'),
                  ),
                  if (expressionPrompt != null) ...[
                    const SizedBox(height: 32),
                    SelectableText('Prompt :', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        expressionPrompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingExpression)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (expressionAnswer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(expressionAnswer!),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingIntime ? null : _askIntimeOpenAI,
                    child: const Text('nombre intime'),
                  ),
                  if (intimePrompt != null) ...[
                    const SizedBox(height: 32),
                    SelectableText('Prompt :', style: const TextStyle(fontWeight: FontWeight.bold)),     
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
                        intimePrompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingIntime)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (intimeAnswer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(intimeAnswer!),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingAnnee ? null : _askAnneeOpenAI,
                    child: const Text('année personnelle'),
                  ),
                  if (anneePrompt != null) ...[
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
                        anneePrompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingAnnee)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (anneeAnswer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(anneeAnswer!),
                    ),
                  // Add this new section for Sphère 1
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingSphere1 ? null : _askSphere1OpenAI,
                    child: const Text('Sphère 1'),
                  ),
                  if (sphere1Prompt != null) ...[
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
                        sphere1Prompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingSphere1)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (sphere1Answer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(sphere1Answer!),
                    ),

                  // Sphère 2 section
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingSphere2 ? null : _askSphere2OpenAI,
                    child: const Text('Sphère 2 : Sentiment'),
                  ),
                  if (sphere2Prompt != null) ...[
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
                        sphere2Prompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingSphere2)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (sphere2Answer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(sphere2Answer!),
                    ),

                  // Sphère 3 section
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingSphere3 ? null : _askSphere3OpenAI,
                    child: const Text('Sphère 3 : Communication'),
                  ),
                  if (sphere3Prompt != null) ...[
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
                        sphere3Prompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingSphere3)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (sphere3Answer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(sphere3Answer!),
                    ),

                  // Sphère 4 section
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingSphere4 ? null : _askSphere4OpenAI,
                    child: const Text('Sphère 4 : Travail'),
                  ),
                  if (sphere4Prompt != null) ...[
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
                        sphere4Prompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingSphere4)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (sphere4Answer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(sphere4Answer!),
                    ),

                  // Sphère 5 section
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingSphere5 ? null : _askSphere5OpenAI,
                    child: const Text('Sphère 5 : Analytique'),
                  ),
                  if (sphere5Prompt != null) ...[
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
                        sphere5Prompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingSphere5)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (sphere5Answer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(sphere5Answer!),
                    ),

                  // Sphère 6 section
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingSphere6 ? null : _askSphere6OpenAI,
                    child: const Text('Sphère 6 : Famille'),
                  ),
                  if (sphere6Prompt != null) ...[
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
                        sphere6Prompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingSphere6)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (sphere6Answer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(sphere6Answer!),
                    ),

                  // Sphère 7 section
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingSphere7 ? null : _askSphere7OpenAI,
                    child: const Text('Sphère 7 : Spiritualité'),
                  ),
                  if (sphere7Prompt != null) ...[
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
                        sphere7Prompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingSphere7)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (sphere7Answer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(sphere7Answer!),
                    ),

                  // Sphère 8 section
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingSphere8 ? null : _askSphere8OpenAI,
                    child: const Text('Sphère 8 : Talents'),
                  ),
                  if (sphere8Prompt != null) ...[
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
                        sphere8Prompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingSphere8)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (sphere8Answer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(sphere8Answer!),
                    ),

                  // Sphère 9 section
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoadingSphere9 ? null : _askSphere9OpenAI,
                    child: const Text('Sphère 9 : Empathie'),
                  ),
                  if (sphere9Prompt != null) ...[
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
                        sphere9Prompt!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLoadingSphere9)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (sphere9Answer != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: SelectableText(sphere9Answer!),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoadingAme ? null : _askAmeOpenAI,
              child: const Text('Numéro de l\'âme'),
            ),
            if (amePrompt != null) ...[
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
                  amePrompt!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (isLoadingAme)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            if (ameAnswer != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SelectableText(ameAnswer!),
              ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoadingPersonnalite ? null : _askPersonnaliteOpenAI,
              child: const Text('Numéro de la personnalité'),
            ),
            if (personnalitePrompt != null) ...[
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
                  personnalitePrompt!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (isLoadingPersonnalite)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            if (personnaliteAnswer != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SelectableText(personnaliteAnswer!),
              ),
          ],
        ),
      ),
    );
  }
}