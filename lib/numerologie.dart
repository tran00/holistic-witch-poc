import 'package:flutter/material.dart';
import 'widgets/app_drawer.dart';
import 'openai_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  late final OpenAIClient _openAI;

  @override
  void initState() {
    super.initState();
    _openAI = OpenAIClient(dotenv.env['OPENAI_API_KEY'] ?? '');
    
    // Add default data
    _birthDateController.text = '08051980';
    _firstNameController.text = 'Pamela ELEONORE MARGUERITE';
    _lastNameController.text = 'Lessel';
    
    // Set current year
    _currentYearController.text = DateTime.now().year.toString();
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentYearController.dispose(); // New
    super.dispose();
  }

  int _calculateLifePathNumber(String birthDate) {
    // Format attendu: JJMMAAAA (ex: 25081990)
    if (birthDate.length != 8) return 0;
    final digits = birthDate.split('').map(int.parse).toList();
    int sum = digits.reduce((a, b) => a + b);
    while (sum > 9 && sum != 11 && sum != 22 && sum != 33) {
      sum = sum.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return sum;
  }

  int _letterValue(String letter) {
    // A=1, B=2, ..., I=9, J=1, ..., R=9, S=1, ..., Z=8
    final l = letter.toUpperCase();
    if (RegExp(r'[A-Z]').hasMatch(l)) {
      return ((l.codeUnitAt(0) - 65) % 9) + 1;
    }
    return 0;
  }

  int _calculateExpressionNumber(String firstName, String lastName) {
    final all = (firstName + lastName).replaceAll(RegExp(r'[^A-Za-z]'), '');
    int sum = all.split('').map(_letterValue).reduce((a, b) => a + b);
    while (sum > 9 && sum != 11 && sum != 22 && sum != 33) {
      sum = sum.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return sum;
  }

  int _calculateIntimeNumber(String firstName, String lastName) {
    // Only vowels
    final all = (firstName + lastName).replaceAll(RegExp(r'[^AEIOUYaeiouy]'), '');
    if (all.isEmpty) return 0;
    int sum = all.split('').map(_letterValue).reduce((a, b) => a + b);
    while (sum > 9 && sum != 11 && sum != 22 && sum != 33) {
      sum = sum.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return sum;
  }

  int _calculateAnneePersonnelle(String birthDate, int currentYear) {
    // Calculate the personal year number
    final birthYear = int.parse(birthDate.substring(4, 8));
    int anneePersonnelle = (birthYear % 100) + currentYear;
    while (anneePersonnelle > 9 && anneePersonnelle != 11 && anneePersonnelle != 22 && anneePersonnelle != 33) {
      anneePersonnelle = anneePersonnelle.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return anneePersonnelle;
  }

  int _calculatePersonalYear(String birthDate, String currentYear) {
    if (birthDate.length != 8 || currentYear.length != 4) return 0;
    final day = int.parse(birthDate.substring(0, 2));
    final month = int.parse(birthDate.substring(2, 4));
    final year = int.parse(currentYear);
    int sum = day + month + year;
    while (sum > 9 && sum != 11 && sum != 22 && sum != 33) {
      sum = sum.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return sum;
  }

  void _calculateNumbers() {
    final birthDate = _birthDateController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final currentYear = _currentYearController.text.trim();

    // Validation
    if (birthDate.length != 8 || firstName.isEmpty || lastName.isEmpty || currentYear.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs correctement.')),
      );
      return;
    }

    setState(() {
      nombreDeVie = _calculateLifePathNumber(birthDate);
      nombreExpression = _calculateExpressionNumber(firstName, lastName);
      nombreIntime = _calculateIntimeNumber(firstName, lastName);
      nombreAnneePersonnelle = _calculatePersonalYear(birthDate, currentYear); // New
      cheminPrompt = null;
      cheminAnswer = null;
      expressionPrompt = null;
      expressionAnswer = null;
      intimePrompt = null;
      intimeAnswer = null;
      anneePrompt = null; // New
      anneeAnswer = null; // New
    });
  }

  Future<void> _askCheminOpenAI() async {
    if (nombreDeVie == null) return;
    final prompt =
        "En tant qu'expert en numérologie, analyse le chemin de vie numéro $nombreDeVie pour une personne née le ${_birthDateController.text}. Donne une interprétation détaillée.";
    setState(() {
      isLoadingChemin = true;
      cheminPrompt = prompt;
      cheminAnswer = null;
    });
    try {
      final answer = await _openAI.sendMessage(prompt);
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
    final prompt =
        "En tant qu'expert en numérologie, analyse le nombre d'expression $nombreExpression pour une personne nommée ${_firstNameController.text} ${_lastNameController.text}. Donne une interprétation détaillée.";
    setState(() {
      isLoadingExpression = true;
      expressionPrompt = prompt;
      expressionAnswer = null;
    });
    try {
      final answer = await _openAI.sendMessage(prompt);
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
    final prompt =
        "En tant qu'expert en numérologie, analyse le nombre intime $nombreIntime pour une personne nommée ${_firstNameController.text} ${_lastNameController.text}. Donne une interprétation détaillée.";
    setState(() {
      isLoadingIntime = true;
      intimePrompt = prompt;
      intimeAnswer = null;
    });
    try {
      final answer = await _openAI.sendMessage(prompt);
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
    final prompt =
        "En tant qu'expert en numérologie, analyse l'année personnelle numéro $nombreAnneePersonnelle pour une personne née le ${_birthDateController.text}. Donne une interprétation détaillée.";
    setState(() {
      isLoadingAnnee = true;
      anneePrompt = prompt;
      anneeAnswer = null;
    });
    try {
      final answer = await _openAI.sendMessage(prompt);
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
                  SelectableText('Nombre chemin de vie : $nombreDeVie', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SelectableText('Nombre d\'expression : $nombreExpression', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SelectableText('Nombre intime : $nombreIntime', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SelectableText('Nombre année personnelle : $nombreAnneePersonnelle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // New
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoadingChemin ? null : _askCheminOpenAI,
                    child: const Text('demander à openAI votre chemin de vie'),
                  ),
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
                ],
              ),
          ],
        ),
      ),
    );
  }
}