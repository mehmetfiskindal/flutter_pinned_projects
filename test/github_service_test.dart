import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:convert';
import 'package:flutter_pinned_projects/github_service.dart';
import 'github_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('GithubService', () {
    late MockClient mockClient;
    late GithubService githubService;

    setUp(() {
      mockClient = MockClient();
      githubService = GithubService(client: mockClient);
    });

    test(
      'fetchPinnedRepositories returns a list of repositories on GraphQL success',
      () async {
        final username = 'testuser';
        final mockGraphQLResponse = jsonEncode({
          'data': {
            'user': {
              'pinnedItems': {
                'edges': [
                  {
                    'node': {
                      'name': 'Repo1',
                      'description': 'Description 1',
                      'url': 'https://github.com/testuser/repo1',
                      'stargazers': {'totalCount': 10},
                      'primaryLanguage': {'name': 'Dart'},
                      'owner': {'avatarUrl': 'https://avatar.url/user'}
                    }
                  },
                  {
                    'node': {
                      'name': 'Repo2',
                      'description': null, // Test null description
                      'url': 'https://github.com/testuser/repo2',
                      'stargazers': {'totalCount': 5},
                      'primaryLanguage': null, // Test null language
                      'owner': {'avatarUrl': 'https://avatar.url/user'}
                    }
                  }
                ]
              }
            }
          }
        });

        when(mockClient.post(
          Uri.parse('https://api.github.com/graphql'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(mockGraphQLResponse, 200));

        final repositories =
            await githubService.fetchPinnedRepositories(username);

        expect(repositories, isA<List<Repository>>());
        expect(repositories.length, 2);

        expect(repositories[0].name, 'Repo1');
        expect(repositories[0].description, 'Description 1');
        expect(repositories[0].stars, 10);
        expect(repositories[0].language, 'Dart');
        expect(repositories[0].avatarUrl, 'https://avatar.url/user');
        expect(repositories[0].url, 'https://github.com/testuser/repo1');

        expect(repositories[1].name, 'Repo2');
        expect(repositories[1].description, 'No description'); // Default value
        expect(repositories[1].stars, 5);
        expect(repositories[1].language, 'Unknown'); // Default value
        expect(repositories[1].avatarUrl, 'https://avatar.url/user');
        expect(repositories[1].url, 'https://github.com/testuser/repo2');

        // Verify the request body contains the correct query
        final verificationResult = verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        ));
        final capturedBody = jsonDecode(verificationResult.captured.single);
        expect(capturedBody['query'], contains('user(login: "$username")'));
        expect(capturedBody['query'], contains('pinnedItems(first: 6'));
      },
    );

    test('fetchPinnedRepositories throws an exception on HTTP failure',
        () async {
      final username = 'testuser';

      when(mockClient.post(
        Uri.parse('https://api.github.com/graphql'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () async => await githubService.fetchPinnedRepositories(username),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('GitHub API request failed with status: 404'),
        )),
      );
    });

    test('fetchPinnedRepositories throws an exception on GraphQL error',
        () async {
      final username = 'testuser';
      final mockErrorResponse = jsonEncode({
        'errors': [
          {
            'message':
                'Could not resolve to a User with the login of \'$username\'.'
          }
        ]
      });

      when(mockClient.post(
        Uri.parse('https://api.github.com/graphql'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(mockErrorResponse, 200));

      expect(
        () async => await githubService.fetchPinnedRepositories(username),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Could not resolve to a User'),
        )),
      );
    });

    test(
        'fetchPinnedRepositories includes Authorization header when token is provided',
        () async {
      final username = 'testuser';
      final token = 'test_token';
      githubService = GithubService(client: mockClient, accessToken: token);
      final mockGraphQLResponse = jsonEncode({
        // Provide a minimal valid response
        'data': {
          'user': {
            'pinnedItems': {'edges': []}
          }
        }
      });

      when(mockClient.post(
        Uri.parse('https://api.github.com/graphql'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(mockGraphQLResponse, 200));

      await githubService.fetchPinnedRepositories(username);

      final verificationResult = verify(mockClient.post(
        any,
        headers: captureAnyNamed('headers'),
        body: anyNamed('body'),
      ));

      final capturedHeaders =
          verificationResult.captured.single as Map<String, String>;
      expect(capturedHeaders['Content-Type'], 'application/json');
      expect(capturedHeaders['Authorization'], 'Bearer $token');
    });

    test(
        'fetchPinnedRepositories excludes Authorization header when token is null',
        () async {
      final username = 'testuser';
      // githubService is already initialized without a token in setUp
      final mockGraphQLResponse = jsonEncode({
        // Provide a minimal valid response
        'data': {
          'user': {
            'pinnedItems': {'edges': []}
          }
        }
      });

      when(mockClient.post(
        Uri.parse('https://api.github.com/graphql'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(mockGraphQLResponse, 200));

      await githubService.fetchPinnedRepositories(username);

      final verificationResult = verify(mockClient.post(
        any,
        headers: captureAnyNamed('headers'),
        body: anyNamed('body'),
      ));

      final capturedHeaders =
          verificationResult.captured.single as Map<String, String>;
      expect(capturedHeaders['Content-Type'], 'application/json');
      expect(capturedHeaders.containsKey('Authorization'), isFalse);
    });

    test('Repository.fromGraphQLJson handles missing fields gracefully', () {
      final json = {
        'node': {
          'name': 'Test Repo',
          // Missing description
          'stargazers': null, // Missing stargazers
          'primaryLanguage': {'name': 'Dart'},
          'owner': {}, // Missing avatarUrl
          'url': 'https://github.com/test/test-repo'
        }
      };

      final repo = Repository.fromGraphQLJson(json);

      expect(repo.name, 'Test Repo');
      expect(repo.description, 'No description'); // Default value
      expect(repo.stars, 0); // Default value
      expect(repo.language, 'Dart');
      expect(repo.avatarUrl, ''); // Default value
      expect(repo.url, 'https://github.com/test/test-repo');
    });

    test('Repository.fromGraphQLJson handles completely empty node', () {
      final json = {
        'node': {} // Empty node
      };

      final repo = Repository.fromGraphQLJson(json);

      expect(repo.name, 'Unknown');
      expect(repo.description, 'No description');
      expect(repo.stars, 0);
      expect(repo.language, 'Unknown');
      expect(repo.avatarUrl, '');
      expect(repo.url, '');
    });

    test('Repository.fromGraphQLJson handles null node', () {
      final json = {
        'node': null // Null node
      };

      final repo = Repository.fromGraphQLJson(json);

      expect(repo.name, 'Unknown');
      expect(repo.description, 'No description');
      expect(repo.stars, 0);
      expect(repo.language, 'Unknown');
      expect(repo.avatarUrl, '');
      expect(repo.url, '');
    });

    test('Repository.fromGraphQLJson handles missing fields in node', () {
      final json = {
        'node': {
          'name': 'Test Repo',
          // Missing description
          'stargazers': null, // Missing stargazers
          'primaryLanguage': null, // Missing primaryLanguage
          'owner': {}, // Missing avatarUrl
          'url': null // Missing url
        }
      };

      final repo = Repository.fromGraphQLJson(json);

      expect(repo.name, 'Test Repo');
      expect(repo.description, 'No description'); // Default value
      expect(repo.stars, 0); // Default value
      expect(repo.language, 'Unknown'); // Default value
      expect(repo.avatarUrl, ''); // Default value
      expect(repo.url, ''); // Default value
    });
  });
}
