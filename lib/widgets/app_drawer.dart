import 'package:flutter/material.dart';

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
            leading: const Icon(Icons.list),
            title: const Text('Numerologie'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/numerologie');
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Tirage 3 cartes conseil'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/tirage3');
            },
          ),
        ],
      ),
    );
  }
}