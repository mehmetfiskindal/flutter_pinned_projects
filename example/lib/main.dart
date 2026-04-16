import 'package:flutter/material.dart';
import 'package:flutter_pinned_projects/card_style.dart';
import 'package:flutter_pinned_projects/flutter_pinned_projects.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Pinned Projects Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const githubToken = String.fromEnvironment('GITHUB_TOKEN');

    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Pinned Projects Example')),
      body: PinnedProjectsWidget(
        username: "octocat",
        // Run with: flutter run --dart-define=GITHUB_TOKEN=YOUR_TOKEN
        accessToken: githubToken.isEmpty ? null : githubToken,
        maxRepos: 6,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        errorWidgetBuilder: (error) => Center(child: Text('Error: $error')),
        emptyWidget: const Center(child: Text('No pinned repositories found.')),
        cardStyle: CardStyle.modern,
        // Optional: derive widget-specific scheme from a seed.
        // seedColor: Colors.teal,
      ),
    );
  }
}
