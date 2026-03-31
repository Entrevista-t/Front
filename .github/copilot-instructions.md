# Copilot Instructions — Entrevista't (Flutter Frontend)

## Project overview

Flutter web app (also targeting mobile) for interview practice. Users pick a job category, answer timed questions on camera, and receive AI-evaluated feedback with scores and a PDF report. Backend is FastAPI + PostgreSQL (separate repo). **All UI text must be in Catalan. Code, comments, and docs in English.**

---

## Commands

### Development (Docker)
```powershell
# Interactive launcher — covers all common tasks
./start.ps1

# Start dev server with hot reload (option 1)
docker-compose -f docker-compose-dev.yml up -d --build
# App runs at http://localhost:8080

# Run tests (option 5)
docker run --rm -v "${PWD}:/app" -w /app ghcr.io/cirruslabs/flutter:3.27.1 bash -lc "flutter pub get && flutter test"
```

### Local Flutter (no Docker)
```bash
flutter pub get
flutter run -d web-server --web-port 8080 --dart-define=API_URL=http://localhost:5000
flutter test                          # full suite
flutter test test/widget_test.dart    # single test file
flutter analyze                       # lint
flutter build apk --release --dart-define=API_URL=<url>
```

### Environment
Requires a `.env` file (copy from `.env.example`):
```
API_URL=http://localhost:5000
```

---

## Architecture

```
lib/
├── main.dart           # App entry, GoRouter config, ThemeData
├── models/
│   └── interview_models.dart   # All data classes (5 models)
├── screens/            # One file per screen (8 screens)
│   ├── landing_screen.dart
│   ├── login_screen.dart       # Handles both login & register (?mode=register)
│   ├── home_screen.dart
│   ├── interview_screen.dart   # Camera + timer + question flow
│   ├── results_screen.dart
│   ├── report_sent_screen.dart
│   ├── profile_screen.dart
│   └── edit_profile_screen.dart
└── services/
    └── api_service.dart        # All HTTP calls, token management
```

**No state management library** — all screens use `StatefulWidget` + `setState`. Auth token and user info are persisted via `SharedPreferences`.

**Navigation** uses GoRouter v14. Routes are defined in `main.dart`. The router redirects unauthenticated users to `/login`. Path params are used for IDs: `/interview/:categoryId`, `/results/:sessionId`.

**API** calls live exclusively in `ApiService`. Results polling is handled there (30 attempts × 2 s). Fallback/mock data (`Question.fallback()`, `InterviewResult.mock()`) is defined on the model classes for offline/error states.

---

## Theme & design conventions

Dark-only theme with these constants (defined per-file at the top):

| Purpose | Color |
|---|---|
| Background | `#0F1117` |
| Card/Surface | `#1A1E2E` |
| Primary accent | `#00D4A1` (teal) |
| Secondary accent | `#E91E8C` (pink, results screen) |
| Text primary | `#E8EAF0` |
| Text muted | `#7B8099` |

Color constants are declared as `static const Color _name = Color(0xFF...)` at the top of each file. There is no shared theme file — if adding a new screen, replicate this pattern.

Layouts use `LayoutBuilder` to differentiate web (wide) from mobile (narrow). Helper methods like `_buildWebLayout()` / `_buildMobileLayout()` keep `build()` clean.

---

## Code conventions

- **Files**: `snake_case.dart` — **Classes**: `PascalCase` — **Private members/methods**: `_prefixed`
- Screen class order: fields → `initState` → `dispose` → `build` → private helper methods
- Complex `build()` methods are broken into private `_buildXxx()` helpers
- Error messages shown to users must be in Catalan; throw `Exception('Catalan message')` from services
- Models define `fromJson()` factories and, where relevant, static `fallback()` / `mock()` methods for offline use
- `InterviewCategory.defaults()` returns a hardcoded list of Catalan job categories — extend this list when adding categories before the backend is ready