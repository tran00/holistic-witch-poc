import 'package:flutter/material.dart';
import '../natal_chart_page_with_sweph.dart';  // Add this import

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Text('Menu', style: TextStyle(fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Accueil'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat with OpenAI'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/chat');
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Tirage 3 cartes conseil'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/tirage3');
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.auto_awesome),
          //   title: const Text('Tirage 4 cartes prédictif'),
          //   onTap: () {
          //     Navigator.pushReplacementNamed(context, '/tirage4');
          //   },
          // ),
          // ListTile(
          //   leading: const Icon(Icons.account_tree),
          //   title: const Text('Tirage 6 cartes pyramide'),
          //   onTap: () {
          //     Navigator.pushReplacementNamed(context, '/tirage6');
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.stars),
            title: const Text('Natal Chart (SwEph)'),
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
            leading: const Icon(Icons.list),
            title: const Text('Numerologie'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/numerologie');
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Thème natal'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/natal');
            },
          ),
        ],
      ),
    );
  }
}