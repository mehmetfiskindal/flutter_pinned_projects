import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'github_service.dart';
import 'card_style.dart';

/// A widget that displays a user's pinned GitHub repositories
class PinnedProjectsWidget extends StatelessWidget {
  /// GitHub username to fetch pinned repositories for
  final String username;

  /// Optional GitHub service instance for dependency injection
  final GithubService githubService;

  /// Optional GitHub personal access token for authenticated requests
  final String? accessToken;

  /// Optional number of repositories to display (defaults to 6)
  final int maxRepos;

  /// Optional custom loading widget
  final Widget? loadingWidget;

  /// Optional custom error widget builder
  final Widget Function(String error)? errorWidgetBuilder;

  /// Optional custom empty state widget
  final Widget? emptyWidget;

  /// Optional card style
  final CardStyle cardStyle;

  /// Optional seed color to derive a Material 3 `ColorScheme`.
  ///
  /// If not provided, the widget uses `Theme.of(context).colorScheme`.
  final Color? seedColor;

  /// Optional brightness override used with `seedColor`.
  ///
  /// If not provided, the widget uses `Theme.of(context).brightness`.
  final Brightness? brightness;

  /// Optional explicit `ColorScheme` override.
  ///
  /// If provided, it takes precedence over `seedColor`.
  final ColorScheme? colorScheme;

  /// Creates a widget to display pinned GitHub repositories
  PinnedProjectsWidget({
    super.key,
    required this.username,
    GithubService? githubService,
    this.accessToken,
    this.maxRepos = 6,
    this.loadingWidget,
    this.errorWidgetBuilder,
    this.emptyWidget,
    this.cardStyle = CardStyle.modern,
    this.seedColor,
    this.brightness,
    this.colorScheme,
  }) : githubService = githubService ?? GithubService(accessToken: accessToken);

  void _showLaunchError(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// Opens the URL in the browser (web + mobile friendly).
  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        _showLaunchError(context, 'Invalid URL');
        return;
      }

      final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!ok) {
        if (!context.mounted) return;
        _showLaunchError(context, 'Could not open the link');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showLaunchError(context, 'Could not open the link');
      debugPrint('launchUrl failed: $e');
    }
  }

  Widget _repoAvatar({required Repository repo, required int index}) {
    final placeholder = Image.asset(
      'assets/placeholder.png',
      package: 'flutter_pinned_projects',
      fit: BoxFit.cover,
    );

    final url = repo.avatarUrl.trim();
    final image = url.isEmpty
        ? placeholder
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => placeholder,
          );

    return ClipOval(
      child: SizedBox(
        key: Key('repo_avatar_$index'),
        width: 32,
        height: 32,
        child: image,
      ),
    );
  }

  bool _isDesktopLike(TargetPlatform platform) {
    return kIsWeb ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;
  }

  ThemeData _resolveTheme(BuildContext context) {
    final base = Theme.of(context);

    final resolvedScheme = colorScheme ??
        (seedColor != null
            ? ColorScheme.fromSeed(
                seedColor: seedColor!,
                brightness: brightness ?? base.brightness,
              )
            : null);

    if (resolvedScheme == null) return base;
    return base.copyWith(colorScheme: resolvedScheme);
  }

  @override
  Widget build(BuildContext context) {
    final themed = _resolveTheme(context);
    final isDesktop = _isDesktopLike(themed.platform);

    return FutureBuilder<List<Repository>>(
      future: githubService.fetchPinnedRepositories(username),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return errorWidgetBuilder?.call(snapshot.error.toString()) ??
              Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: themed.colorScheme.error),
                ),
              );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return emptyWidget ??
              const Center(child: Text('No pinned repositories found.'));
        } else {
          final repos = snapshot.data!.take(maxRepos).toList();

          Widget content;
          // Choose card style based on the selected option
          if (cardStyle == CardStyle.minimal) {
            content = _buildMinimalList(repos, context, themed);
          } else if (cardStyle == CardStyle.grid) {
            content = _buildGridView(repos, context, themed);
          } else {
            content = _buildModernList(repos, context, themed);
          }

          // Desktop/web affordances: always-visible scrollbar + selectable text.
          content = Scrollbar(
            thumbVisibility: isDesktop,
            child: content,
          );
          content = SelectionArea(child: content);

          return Theme(data: themed, child: content);
        }
      },
    );
  }

  Widget _buildModernList(
    List<Repository> repos,
    BuildContext context,
    ThemeData themed,
  ) {
    final scheme = themed.colorScheme;

    return ListView.builder(
      itemCount: repos.length,
      itemBuilder: (context, index) {
        final repo = repos[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: InkWell(
            onTap: () => _launchUrl(context, repo.url),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _repoAvatar(repo: repo, index: index),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          repo.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    repo.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: scheme.tertiary),
                      const SizedBox(width: 4),
                      Text('${repo.stars}'),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          repo.language,
                          style: TextStyle(
                            color: scheme.onSecondaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalList(
    List<Repository> repos,
    BuildContext context,
    ThemeData themed,
  ) {
    return ListView.builder(
      itemCount: repos.length,
      itemBuilder: (context, index) {
        final repo = repos[index];
        return ListTile(
          title: Text(repo.name),
          subtitle: Text(repo.description),
          trailing: Text('${repo.stars} stars'),
          onTap: () => _launchUrl(context, repo.url),
        );
      },
    );
  }

  Widget _buildGridView(
    List<Repository> repos,
    BuildContext context,
    ThemeData themed,
  ) {
    final scheme = themed.colorScheme;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
      ),
      itemCount: repos.length,
      itemBuilder: (context, index) {
        final repo = repos[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () => _launchUrl(context, repo.url),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _repoAvatar(repo: repo, index: index),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          repo.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(repo.description,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: scheme.tertiary),
                      const SizedBox(width: 4),
                      Text('${repo.stars}'),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(repo.language,
                            style:
                                TextStyle(color: scheme.onSecondaryContainer)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
