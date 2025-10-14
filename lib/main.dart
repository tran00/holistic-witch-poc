import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/openai_chart_service.dart';
import 'widgets/chat_bubble.dart';
import 'numerologie.dart';
import 'three_card_draw_page.dart';
import 'four_card_draw_page.dart';
import 'six_card_draw_page.dart';
import 'widgets/app_drawer.dart';
import 'natal_chart_page.dart';
import 'natal_chart_page_with_sweph.dart';
import 'daily_chart_page.dart'; // Add this import
import 'rag_demo_page.dart'; // Add RAG demo page

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Simple error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('💥 Flutter Error: ${details.exception}');
    print('💥 Context: ${details.context}');
  };
  
  // Load .env with simple try-catch
  try {
    print('🔄 Loading .env file...');
    await dotenv.load(fileName: ".env");
    print('✅ .env loaded - API Key found: ${dotenv.env['OPENAI_API_KEY']?.isNotEmpty == true ? "YES" : "NO"}');
  } catch (e) {
    print('❌ Error loading .env: $e');
    print('⚠️ App will continue without .env file');
    
    // Initialize dotenv with empty map to prevent null errors
    dotenv.testLoad(fileInput: '');
  }
  
  // Run app directly
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter OpenAI Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/chat': (context) => const ChatPage(),
        '/tirage3': (context) => const ThreeCardDrawPage(),
        '/tirage4': (context) => const FourCardDrawPage(),
        '/tirage6': (context) => const SixCardDrawPage(),
        '/numerologie': (context) => const NumerologiePage(),
        '/natal': (context) => const NatalChartPage(),
        '/natal-sweph': (context) => const NatalChartPageWithSweph(),
        '/daily-chart': (context) => const DailyChartPage(), // Add this route
        '/rag-demo': (context) => const RagDemoPage(), // Add RAG demo route
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      drawer: const AppDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tarologie Section
              const Text(
                'Tarologie',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.star),
                label: const Text('Les Trois Portes'),
                onPressed: () {
                  Navigator.pushNamed(context, '/tirage3');
                },
              ),
              
              const SizedBox(height: 32),
              
              // Astrologie Section
              const Text(
                'Astrologie',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.account_tree),
                label: const Text('Natal Chart (SwEph)'),
                onPressed: () {
                  Navigator.pushNamed(context, '/natal-sweph');
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.star),
                label: const Text('Daily Chart Comparison'),
                onPressed: () {
                  Navigator.pushNamed(context, '/daily-chart');
                },
              ),
              
              const SizedBox(height: 32),
              
              // Numérologie Section
              const Text(
                'Numérologie',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.calculate),
                label: const Text('Numerologie'),
                onPressed: () {
                  Navigator.pushNamed(context, '/numerologie');
                },
              ),
              
              const SizedBox(height: 32),
              
              // Connexion OpenAI Section
              const Text(
                'Connexion OpenAI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('Go to Chat'),
                onPressed: () {
                  Navigator.pushNamed(context, '/chat');
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.psychology),
                label: const Text('RAG Demo - Test AI'),
                onPressed: () {
                  Navigator.pushNamed(context, '/rag-demo');
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  late final OpenAIChartService _openAI;

  @override
  void initState() {
    super.initState();
    _openAI = OpenAIChartService();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Add user message
    _messages.add({'role': 'user', 'content': text});
    _listKey.currentState?.insertItem(_messages.length - 1);
    _controller.clear();
    setState(() => _isLoading = true);

    try {
      final reply = await _openAI.sendMessage(text);

      // Add assistant message
      _messages.add({'role': 'assistant', 'content': reply});
      _listKey.currentState?.insertItem(_messages.length - 1);
    } catch (e) {
      _messages.add({'role': 'assistant', 'content': 'Error: $e'});
      _listKey.currentState?.insertItem(_messages.length - 1);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
    final msg = _messages[index];
    final isUser = msg['role'] == 'user';

    return SlideTransition(
      position: Tween<Offset>(
        begin: isUser ? const Offset(1, 0) : const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: animation,
        child: ChatBubble(
          message: msg['content'] ?? '',
          isUser: isUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenAI Chat'),
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
      body: Column(
        children: [
          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _messages.length,
              itemBuilder: _buildItem,
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );  
  }
}
