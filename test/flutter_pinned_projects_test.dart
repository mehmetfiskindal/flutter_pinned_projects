// filepath: /Users/mehmetfiskindal/flutter_pinned_projects/test/flutter_pinned_projects_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_pinned_projects/github_service.dart';
import 'package:flutter_pinned_projects/flutter_pinned_projects.dart';
import 'package:flutter_pinned_projects/card_style.dart';
import 'flutter_pinned_projects_test.mocks.dart';

@GenerateMocks([GithubService])
void main() {
  group('PinnedProjectsWidget', () {
    late MockGithubService mockGithubService;

    setUp(() {
      mockGithubService = MockGithubService();
    });

    testWidgets('limits the number of repositories displayed based on maxRepos',
        (WidgetTester tester) async {
      final mockRepos = List.generate(
        10,
        (index) => Repository(
          name: 'Repo $index',
          description: 'Description $index',
          stars: index * 10,
          language: 'Dart',
          url: 'https://github.com/repo$index',
          avatarUrl: '',
        ),
      );

      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) async => Future.value(mockRepos));

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PinnedProjectsWidget(
              username: 'developersailor',
              githubService: mockGithubService,
              maxRepos: 3, // Limit to 3 repos
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Default style is modern, which uses Card
      expect(find.byType(Card), findsNWidgets(3));
      expect(find.text('Repo 0'), findsOneWidget);
      expect(find.text('Repo 1'), findsOneWidget);
      expect(find.text('Repo 2'), findsOneWidget);
      expect(find.text('Repo 3'), findsNothing); // Should not find the 4th repo
    });

    testWidgets('displays repositories using minimal style',
        (WidgetTester tester) async {
      final mockRepos = [
        Repository(
          name: 'Minimal Repo 1',
          description: 'Minimal Desc 1',
          stars: 10,
          language: 'Dart',
          url: 'https://github.com/minimal1',
          avatarUrl: '',
        ),
      ];

      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) async => Future.value(mockRepos));

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PinnedProjectsWidget(
              username: 'developersailor',
              githubService: mockGithubService,
              cardStyle: CardStyle.minimal, // Use minimal style
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Minimal Repo 1'), findsOneWidget);
      expect(find.text('Minimal Desc 1'), findsOneWidget);
      // Should not use Card in minimal style
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('shows avatar in modern style', (WidgetTester tester) async {
      final mockRepos = [
        Repository(
          name: 'Repo 1',
          description: 'Description 1',
          stars: 100,
          language: 'Dart',
          url: 'https://github.com/repo1',
          avatarUrl: '', // Use placeholder path in tests
        ),
      ];

      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) async => Future.value(mockRepos));

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PinnedProjectsWidget(
              username: 'developersailor',
              githubService: mockGithubService,
              cardStyle: CardStyle.modern,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('repo_avatar_0')), findsOneWidget);
    });

    testWidgets('shows avatar in grid style', (WidgetTester tester) async {
      final mockRepos = [
        Repository(
          name: 'Grid Repo 1',
          description: 'Grid Desc 1',
          stars: 20,
          language: 'Flutter',
          url: 'https://github.com/grid1',
          avatarUrl: '',
        ),
        Repository(
          name: 'Grid Repo 2',
          description: 'Grid Desc 2',
          stars: 30,
          language: 'Dart',
          url: 'https://github.com/grid2',
          avatarUrl: '',
        ),
      ];

      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) async => Future.value(mockRepos));

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PinnedProjectsWidget(
              username: 'developersailor',
              githubService: mockGithubService,
              cardStyle: CardStyle.grid,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('repo_avatar_0')), findsOneWidget);
      expect(find.byKey(const Key('repo_avatar_1')), findsOneWidget);
    });

    testWidgets('displays repositories using grid style',
        (WidgetTester tester) async {
      final mockRepos = [
        Repository(
          name: 'Grid Repo 1',
          description: 'Grid Desc 1',
          stars: 20,
          language: 'Flutter',
          url: 'https://github.com/grid1',
          avatarUrl: '',
        ),
        Repository(
          name: 'Grid Repo 2',
          description: 'Grid Desc 2',
          stars: 30,
          language: 'Dart',
          url: 'https://github.com/grid2',
          avatarUrl: '',
        ),
      ];

      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) async => Future.value(mockRepos));

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PinnedProjectsWidget(
              username: 'developersailor',
              githubService: mockGithubService,
              cardStyle: CardStyle.grid, // Use grid style
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2)); // Grid items are Cards
      expect(find.text('Grid Repo 1'), findsOneWidget);
      expect(find.text('Grid Repo 2'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing); // Should not use ListTile
    });

    testWidgets('displays custom loading widget', (WidgetTester tester) async {
      // Don't complete the future to keep the widget in loading state.
      // Avoid Future.delayed which leaves pending timers in newer test bindings.
      final completer = Completer<List<Repository>>();
      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) => completer.future);

      const customLoadingWidget = Center(child: Text('Custom Loading...'));

      await tester.pumpWidget(
        MaterialApp(
          home: PinnedProjectsWidget(
            username: 'developersailor',
            githubService: mockGithubService,
            loadingWidget: customLoadingWidget,
          ),
        ),
      );

      // Don't pumpAndSettle, check initial loading state
      expect(find.text('Custom Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays custom error widget', (WidgetTester tester) async {
      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) async => throw Exception('Fetch Error'));

      Widget customErrorBuilder(String error) =>
          Center(child: Text('Custom Error: $error'));

      await tester.pumpWidget(
        MaterialApp(
          home: PinnedProjectsWidget(
            username: 'developersailor',
            githubService: mockGithubService,
            errorWidgetBuilder: customErrorBuilder,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Custom Error: Exception: Fetch Error'),
        findsOneWidget,
      );
      expect(find.text('Error: Exception: Fetch Error'), findsNothing);
    });

    testWidgets('displays custom empty widget', (WidgetTester tester) async {
      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) async => []);

      const customEmptyWidget = Center(child: Text('Nothing here!'));

      await tester.pumpWidget(
        MaterialApp(
          home: PinnedProjectsWidget(
            username: 'developersailor',
            githubService: mockGithubService,
            emptyWidget: customEmptyWidget,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nothing here!'), findsOneWidget);
      expect(find.text('No pinned repositories found.'), findsNothing);
    });

    testWidgets('displays loading indicator while fetching data',
        (WidgetTester tester) async {
      final completer = Completer<List<Repository>>();
      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        MaterialApp(
          home: PinnedProjectsWidget(
            username: 'developersailor',
            githubService: mockGithubService,
          ),
        ),
      );

      // Without pumpAndSettle to stay in loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when fetch fails',
        (WidgetTester tester) async {
      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) async => throw Exception('Failed to fetch'));

      await tester.pumpWidget(
        MaterialApp(
          home: PinnedProjectsWidget(
            username: 'developersailor',
            githubService: mockGithubService,
          ),
        ),
      );

      await tester.pumpAndSettle(); // Wait for FutureBuilder to rebuild

      expect(find.text('Error: Exception: Failed to fetch'), findsOneWidget);
    });

    testWidgets('displays no data message when no repositories are found',
        (WidgetTester tester) async {
      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: PinnedProjectsWidget(
            username: 'developersailor',
            githubService: mockGithubService,
          ),
        ),
      );

      await tester.pumpAndSettle(); // Wait for FutureBuilder to rebuild

      expect(find.text('No pinned repositories found.'), findsOneWidget);
    });

    testWidgets('displays a list of repositories when data is available',
        (WidgetTester tester) async {
      final mockRepos = [
        Repository(
          name: 'Repo 1',
          description: 'Description 1',
          stars: 100,
          language: 'Dart',
          url: 'https://github.com/repo1',
          avatarUrl: '',
        ),
        Repository(
          name: 'Repo 2',
          description: 'Description 2',
          stars: 200,
          language: 'Flutter',
          url: 'https://github.com/repo2',
          avatarUrl: '',
        ),
      ];

      when(mockGithubService.fetchPinnedRepositories(any))
          .thenAnswer((_) async => Future.value(mockRepos));

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PinnedProjectsWidget(
              username: 'developersailor',
              githubService: mockGithubService,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Wait for FutureBuilder to rebuild

      // Default style is modern, which uses Card, not ListTile
      expect(find.byType(Card), findsNWidgets(2));
      expect(find.text('Repo 1'), findsOneWidget);
      expect(find.text('Repo 2'), findsOneWidget);
      expect(find.text('Description 1'), findsOneWidget);
      expect(find.text('Description 2'), findsOneWidget);
    });
  });
}
