# Copilot Instructions for `postal_deposit` (Flutter Project)

## Project Overview
- **Type:** Cross-platform Flutter app (mobile, desktop, web)
- **Main entry:** `lib/main.dart`
- **Platform targets:** Android, iOS, Linux, macOS, Windows, Web
- **Build system:** Uses Flutter's standard build tools; platform-specific folders (`android/`, `ios/`, etc.)

## Architecture & Structure
- **App logic:** Centralized in `lib/` (main Dart code)
- **Platform code:** Native integrations in `android/`, `ios/`, `macos/`, `linux/`, `windows/`
- **Web assets:** In `web/` (HTML, icons, manifest)
- **Tests:** In `test/` (Dart unit/widget tests)

## Developer Workflows
- **Build:**
  - Run `flutter build <platform>` (e.g., `flutter build apk`, `flutter build ios`, `flutter build web`)
- **Run/Debug:**
  - Use `flutter run` for local development
- **Test:**
  - Run `flutter test` to execute all tests in `test/`
- **Platform-specific:**
  - Android: Gradle files in `android/` (`build.gradle.kts`, `gradle-wrapper.properties`)
  - iOS/macOS: Xcode workspace in `ios/Runner.xcworkspace`, `macos/Runner.xcworkspace`

## Patterns & Conventions
- **Dart code:** Follows standard Flutter conventions; main entry is `main()` in `lib/main.dart`
- **Assets:** Place images and icons in platform-specific asset folders (e.g., `ios/Runner/Assets.xcassets/`, `web/icons/`)
- **Configuration:**
  - `pubspec.yaml` for dependencies and assets
  - `analysis_options.yaml` for linting rules
- **No custom AI agent rules found in codebase.**

## Integration Points
- **External dependencies:** Managed via `pubspec.yaml` (Dart/Flutter packages)
- **Native code:** Platform folders contain native code/configuration for each OS
- **No custom service boundaries or advanced data flows detected.**

## Examples
- **Main app:** See `lib/main.dart` for app entry and widget tree
- **Test example:** See `test/widget_test.dart` for sample widget test
- **Asset usage:** See `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` for asset customization

---

**If any section is unclear or missing important project-specific details, please provide feedback or point to files with custom logic, workflows, or conventions.**
