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

The following is a repository-wide invariant for every issue:

* Every tracked Dart file under `lib/` must contain at most 199 physical lines.
* This limit applies even when the issue does not mention file size.
* Before committing and pushing, run the same file-size check as the
  `Report large files in lib` CI step.
* If a change would make a file reach 200 lines, extract coherent
  responsibilities into dedicated files before committing.
* Do not satisfy the limit by compressing formatting, creating artificial
  wrappers, using `part` files, or reducing readability.

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

Run focused tests during development. Unless the issue defines a different
validation scope, before handing off a pull request, run:

1. the tracked Dart file-size check from
   `.github/workflows/flutter-validate.yml`;
2. `flutter pub get`;
3. `dart format --output=none --set-exit-if-changed .`;
4. `flutter analyze --no-fatal-infos`;
5. `flutter test --coverage`;
6. `flutter build apk --debug`.

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
* When a GitHub issue specifies a development branch, work on that exact
  branch. The specified branch authorizes commits for that issue. If the issue
  does not specify a branch, do not create a commit.
* After completing the issue and its required validation, commit the scoped
  changes and push the specified branch to the remote repository.
* Let `.github/workflows/issue-lifecycle.yml` create or recover the pull
  request, then verify that an open pull request targeting `main` exists and
  references the issue. Do not create a duplicate pull request manually.
* After that verification, the Product Owner is responsible for following the
  GitHub Actions checks and merging the pull request.
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
