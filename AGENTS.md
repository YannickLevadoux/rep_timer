# AGENTS.md

## Project

RepTimer is an Android-focused Flutter/Dart application for creating and
running workout sessions.

Repository:
https://github.com/YannickLevadoux/rep_timer

## Product invariants

* The user interface is in French.
* The application remains portrait-only unless an issue explicitly changes it.
* User data is stored locally; there is no backend or user account.
* Preserve stored-data compatibility and the defensive storage protections.
* Reuse the existing session, progress, completion, checkpoint, and
  notification services instead of duplicating their logic in widgets.

## Architecture

* Keep models and validation contracts under `lib/models/` and
  `lib/validation/`.
* Keep state and user actions that do not require a widget context in
  controllers or services.
* Keep screens responsible for dependency composition, Flutter lifecycle,
  navigation, and coordination with dialogs when those concerns apply.
* Keep reusable and presentational UI in `lib/widgets/`.
* Reuse the existing storage abstractions and services for persistence.

## General rules

* Respect the existing architecture and coding style.
* Keep changes strictly within the scope of the requested issue.
* Do not introduce unrelated refactors or cleanup.
* Prefer simple and maintainable solutions over unnecessary abstractions.
* Reuse existing components, services, models, and utilities when appropriate.
* Preserve existing behavior unless the issue explicitly requests a behavior change.
* Do not add new dependencies unless they are necessary.
* Preserve unrelated user changes already present in the worktree.

## Flutter / Dart

* Follow standard Flutter and Dart conventions.
* Keep widgets focused on UI responsibilities.
* Move business logic out of widgets when appropriate.
* Prefer small, focused classes and files.
* When refactoring an existing large class, preserve its public behavior and
  interfaces unless the issue explicitly requires otherwise.
* Avoid duplicating logic already available elsewhere in the project.

## File size

When an issue explicitly requests reducing a file below a given size:

* Do not achieve the target by compressing formatting or reducing readability.
* Extract coherent responsibilities into dedicated classes or files.
* Do not create artificial wrappers solely to reduce line count.
* Do not use `part` files or compressed formatting to circumvent a line limit.
* The resulting architecture must remain understandable and maintainable.

## Scope

Before modifying code:

1. Read the complete GitHub issue.
2. Inspect the relevant existing implementation.
3. Identify dependencies and existing tests.
4. Implement only what is necessary to satisfy the issue.

If the issue depends on another issue or pull request, verify that the required
changes are present in the current branch. Do not assume that a dependency is
available solely because it is referenced by the issue. Report the blocker when
a required dependency is missing.

## Tests and validation

Run focused tests during development. Before handing off a pull request, run
the CI-equivalent checks unless the issue defines a different validation scope:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test --coverage
flutter build apk --debug
```

Fix regressions introduced by the changes.

Do not modify unrelated tests merely to make the test suite pass.

Do not report a check as successful when it could not be executed. Respect any
coverage threshold defined by the issue and do not introduce a coverage
regression.

## Tests for refactors

For refactoring issues:

* Existing behavior must remain unchanged.
* Existing tests must continue to pass.
* Add or update tests when extracted logic requires dedicated coverage.
* Do not weaken assertions or remove meaningful tests.

## Git

* Development branches follow `<type>/<issue>-<description>`, where `type` is
  `feature`, `bugfix`, `hotfix`, or `clean`.
* Do not create commits unless explicitly requested.
* When an issue requests delivery, push the associated branch and let
  `.github/workflows/issue-lifecycle.yml` create or recover the pull request.
  Do not create a duplicate pull request manually.
* Do not push directly to `main`, merge a pull request, create a tag, or publish
  a release unless explicitly authorized.
* Do not modify CI/CD workflows unless the issue concerns CI/CD.
* Do not modify generated files unless required by the task.

## Completion

A task is complete when:

* the requirements of the GitHub issue are implemented;
* existing behavior outside the issue scope is preserved;
* formatting is valid;
* static analysis passes;
* relevant tests pass;
* no unrelated modifications remain.
