# Flutter Pinned Projects

Flutter Pinned Projects is a Flutter package that displays a user's pinned GitHub repositories inside your Flutter app.

## Features

- Fetch pinned repositories via GitHub GraphQL API.
- Ready-to-use `PinnedProjectsWidget`.
- Multiple card styles: `modern`, `minimal`, `grid`.
- Owner avatar support (modern + grid).

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter_pinned_projects: ^0.0.4
```

Then, run:

```bash
flutter pub get
```

## Usage

Import the package:

```dart
import 'package:flutter_pinned_projects/flutter_pinned_projects.dart';
```

Use the `PinnedProjectsWidget` to display pinned projects:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_pinned_projects/flutter_pinned_projects.dart';
import 'package:flutter_pinned_projects/card_style.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Pinned Projects')),
        body: PinnedProjectsWidget(
          username: 'octocat',
          // Optional: required for higher rate limits and private orgs.
          // accessToken: '<YOUR_GITHUB_TOKEN>',
          maxRepos: 6,
          cardStyle: CardStyle.modern,
          // Optional: make the widget match your app theme (or override).
          // seedColor: Colors.deepPurple,
          // brightness: Brightness.light,
        ),
      ),
    );
  }
}
```

## Notes

- GitHub GraphQL generally requires authentication. Pass `accessToken` for reliable results.
- The widget opens repo links using `url_launcher`.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## Author

Developed by Mehmet Fiskindal.
