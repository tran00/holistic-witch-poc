import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_client.dart';
import 'widgets/chat_bubble.dart';
import 'form_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter OpenAI Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/chat': (context) => const ChatPage(),
        '/form': (context) => const FormPage(),
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
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('Menu', style: TextStyle(fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat with OpenAI'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/chat');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Form Page'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/form');
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Select a page from the menu.'),
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
  late final OpenAIClient _openAI;

  @override
  void initState() {
    super.initState();
    _openAI = OpenAIClient(dotenv.env['OPENAI_API_KEY'] ?? '');
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
        begin: isUser ? const Offset(1, 0) : const Offset(-1, 0), // slide from right or left
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
      appBar: AppBar(title: const Text('OpenAI Chat')),
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
