import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person, color: Colors.white),
            title: Text("Profile", style: TextStyle(color: Colors.white)),
            subtitle: Text("User Name", style: TextStyle(color: Colors.grey)),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title: const Text("About", style: TextStyle(color: Colors.white)),
            subtitle: const Text("CashNote v1.0", style: TextStyle(color: Colors.grey)),
            onTap: () {
               showAboutDialog(context: context, applicationName: "CashNote", applicationVersion: "1.0");
            },
          ),
        ],
      ),
    );
  }
}