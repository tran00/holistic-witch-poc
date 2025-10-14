import 'package:flutter/material.dart';
import '../natal_chart_page_with_sweph.dart';  // Add this import
import '../rag_demo_page.dart';  // Add RAG demo import

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            dense: true,
            title: const Text(
              'Accueil',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          
          const Divider(),
          
          // Tarologie Section
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text(
              'Tarologie',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            dense: true,
            title: const Text(
              'Les Trois Portes',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/tirage3');
            },
          ),
          
          const Divider(),
          
          // Astrologie Section
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text(
              'Astrologie',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.stars),
            dense: true,
            title: const Text(
              'Natal Chart (SwEph)',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NatalChartPageWithSweph(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.compare),
            dense: true,
            title: const Text(
              'Daily Chart Comparison',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/daily-chart');
            },
          ),
          
          const Divider(),
          
          // Numérologie Section
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text(
              'Numérologie',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.list),
            title: const Text(
              'Numerologie',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/numerologie');
            },
          ),
          
          const Divider(),
          
          // Connexion OpenAI Section
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
            child: Text(
              'Connexion OpenAI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.chat),
            title: const Text(
              'Go to Chat',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/chat');
            },
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.psychology),
            title: const Text(
              'RAG Demo - Test AI',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RagDemoPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}