# AGENTS.md

## What This Repo Is
- Flutter package `flutter_pinned_projects` with an `example/` app.
- Main public widget: `PinnedProjectsWidget` in `lib/flutter_pinned_projects.dart`.
- Data fetcher: `GithubService.fetchPinnedRepositories()` in `lib/github_service.dart` (GitHub **GraphQL** `POST https://api.github.com/graphql`).

## Fast Verification (Repo Root)
- Get deps: `flutter pub get` (Flutter tooling also resolves `./example`).
- Static analysis: `flutter analyze`.
- Tests: `flutter test`.

## Codegen (Mockito Mocks)
- Generated files live in `test/*.mocks.dart` and say “Do not manually edit”.
- If you change `@GenerateMocks(...)` annotations or mock types, regenerate with:
  `dart run build_runner build --delete-conflicting-outputs`

## Non-Obvious Behavior / Gotchas
- `GithubService` always queries `pinnedItems(first: 6, ...)` in GraphQL; `PinnedProjectsWidget.maxRepos` only limits the UI via `take(maxRepos)`.
- GitHub’s GraphQL API typically requires authentication; `GithubService` adds `Authorization: Bearer <token>` only when `accessToken` is provided.
- `PinnedProjectsWidget` contains `assert(() { print(...) })` debug logging; it runs in debug/tests only, but it still affects test output.
- `example/lib/main.dart` includes an `accessToken` placeholder; don’t hardcode or commit real tokens.
- Package asset `assets/placeholder.png` is declared in the root `pubspec.yaml`.

## Structure Pointers
- Library code: `lib/` (`flutter_pinned_projects.dart`, `github_service.dart`, `card_style.dart`).
- Example app entrypoint: `example/lib/main.dart`.
- Widget/unit tests: `test/`.
