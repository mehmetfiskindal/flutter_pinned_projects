import 'dart:convert';
import 'package:http/http.dart' as http;

/// Represents a GitHub repository with essential information
class Repository {
  final String name;
  final String description;
  final int stars;
  final String language;
  final String avatarUrl;
  final String url;

  Repository({
    required this.name,
    required this.description,
    required this.stars,
    required this.language,
    required this.avatarUrl,
    required this.url,
  });

  /// Creates a Repository from GraphQL API response
  factory Repository.fromGraphQLJson(Map<String, dynamic> json) {
    final node = json['node'] ?? {};
    final owner = node['owner'] ?? {};

    return Repository(
      name: node['name'] ?? 'Unknown',
      description: node['description'] ?? 'No description',
      stars: node['stargazers']?['totalCount'] ?? 0,
      language: node['primaryLanguage']?['name'] ?? 'Unknown',
      avatarUrl: owner['avatarUrl'] ?? '',
      url: node['url'] ?? '',
    );
  }
}

/// Service to interact with GitHub API and fetch pinned repositories
class GithubService {
  final http.Client client;

  /// Optional GitHub personal access token for authenticated requests
  final String? accessToken;

  GithubService({
    http.Client? client,
    this.accessToken,
  }) : client = client ?? http.Client();

  /// Fetches pinned repositories for a GitHub username using GraphQL API
  Future<List<Repository>> fetchPinnedRepositories(String username) async {
    final url = Uri.parse('https://api.github.com/graphql');

    // GraphQL query to get pinned repositories
    final query = '''
    {
      user(login: "$username") {
        pinnedItems(first: 6, types: REPOSITORY) {
          edges {
            node {
              ... on Repository {
                name
                description
                url
                stargazers {
                  totalCount
                }
                primaryLanguage {
                  name
                }
                owner {
                  avatarUrl
                }
              }
            }
          }
        }
      }
    }
    ''';

    // Prepare headers - add token if available
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await client.post(
      url,
      headers: headers,
      body: json.encode({'query': query}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // Check for errors in the GraphQL response
      if (responseData['errors'] != null) {
        throw Exception(responseData['errors'][0]['message']);
      }

      final data = responseData['data'];
      final user = (data is Map<String, dynamic>) ? data['user'] : null;
      if (user == null) {
        throw Exception('GitHub user not found');
      }

      final pinnedItems =
          (user is Map<String, dynamic>) ? user['pinnedItems'] : null;
      final edges =
          (pinnedItems is Map<String, dynamic>) ? pinnedItems['edges'] : null;
      final edgeList = (edges is List) ? edges : const [];
      return edgeList.map((edge) => Repository.fromGraphQLJson(edge)).toList();
    } else {
      throw Exception(
          'GitHub API request failed with status: ${response.statusCode}');
    }
  }
}
