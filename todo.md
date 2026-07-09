# Todo List - Bedrock Abbottabad Cleanup & Commenting

This todo list outlines the future cleanup, extensive inline commenting, and verification steps planned for the Bedrock Abbottabad weather and hazard crowdsourcing application.

## Phase 1: Code Formatting & Lint Verification
- [x] Run `dart format .` to format all Dart files.
- [x] Run `flutter analyze` to ensure there are no compilation warnings or errors.

## Phase 2: In-Depth Line-by-Line Commenting
- [ ] Comment Presentation Layer (Screens & HUD Components):
  - [ ] `lib/presentation/screens/home_screen.dart`
  - [ ] `lib/presentation/screens/admin_panel_screen.dart`
  - [ ] `lib/presentation/screens/login_screen.dart`
  - [ ] `lib/presentation/screens/splash_screen.dart`
  - [ ] `lib/presentation/screens/weather_screen.dart`
- [ ] Comment Data & Domain Layers (Models, Repositories, Data Sources):
  - [ ] `lib/data/repositories/hazard_repository.dart`
  - [ ] `lib/core/providers/user_profile_provider.dart`
  - [ ] `lib/core/providers/broadcast_provider.dart`
  - [ ] `lib/data/datasources/remote/admin_datasource.dart`
- [ ] Comment Global Entrypoint:
  - [ ] `lib/main.dart`

### Key Design Decision Documentation Required:
1. **Clean Architecture separation**: Explain why DTOs and Domain Models are decoupled.
2. **Provider State Management**: Explain the notification flow (`notifyListeners()`).
3. **Robust Fallbacks**: Document the offline recovery and fallback patterns.
4. **Fitts's Law Touch Targets**: Document sizing of interactive controls (minimum 44 logical pixels).

## Phase 3: Git Initialization & Remote Setup
- [x] Run `git init` in repository root.
- [x] Create a comprehensive `.gitignore` matching standard Flutter configuration.
- [x] Add the remote: `git remote add origin https://github.com/moazm01/bedrock-weather-app`.

## Phase 4: Stage, Commit, and Push
- [x] Stage files with `git add .`.
- [x] Create commit: `git commit -m "feat: Cleaned up code, resolved Firebase fallbacks, added todo checklist"`.
- [x] Push to remote: `git push -u origin main`.
