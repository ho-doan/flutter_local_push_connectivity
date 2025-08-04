import 'package:flutter/material.dart';

class SettingsStyle extends StatelessWidget {
  const SettingsStyle({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true, // inline display mode
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

extension SettingsStyleExtension on Widget {
  Widget settingsStyle(String title) {
    return SettingsStyle(title: title, child: this);
  }
}
