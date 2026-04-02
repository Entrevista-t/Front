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

# Lint / analyze (option 6 or manual)
docker run --rm -v "${PWD}:/app" -w /app ghcr.io/cirruslabs/flutter:3.27.1 bash -lc "flutter pub get && flutter analyze"
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
├── main.dart               # App entry, GoRouter config, ThemeData, theme toggle
├── models/
│   └── interview_models.dart   # All data classes (Question, InterviewResult, etc.)
├── screens/                # One file per screen (11 screens)
│   ├── landing_screen.dart         # Hero + floating review cards + footer (FAQ, Privacy, GitHub links)
│   ├── login_screen.dart           # Glassmorphism login & register card (?mode=register)
│   ├── home_screen.dart            # Dashboard with categories + session history
│   ├── category_selection_screen.dart
│   ├── interview_screen.dart       # Camera + timer + question flow + onboarding dialog + camera toggle
│   ├── results_screen.dart         # AI-generated scores, charts, metrics
│   ├── report_sent_screen.dart     # Confirmation after PDF report is sent
│   ├── profile_screen.dart
│   ├── edit_profile_screen.dart
│   ├── faq_screen.dart             # FAQ page with accordion (8 items in Catalan)
│   └── privacy_policy_screen.dart  # RGPD privacy policy (10 sections in Catalan)
├── services/
│   └── api_service.dart        # All HTTP calls, token management
├── theme/                      # Centralised design system
│   ├── app_colors.dart         # AppColors ThemeExtension (light + dark palettes, gradients)
│   ├── app_spacing.dart        # Spacing, radius, shadow, duration, curve tokens
│   ├── app_theme.dart          # ThemeData builder (light + dark), font constants
│   └── theme_notifier.dart     # Light/dark mode toggle (ChangeNotifier)
└── widgets/                    # Reusable components
    ├── dot_grid_background.dart    # Animated dot grid with optional glow orbs
    ├── floating_glass_card.dart    # Animated floating glassmorphism card
    ├── glass_container.dart        # Static glassmorphism container
    ├── faq_accordion.dart          # FAQ accordion section with animated expand/collapse
    ├── onboarding_dialog.dart      # 4-slide onboarding carousel dialog (interview tutorial)
    ├── app_card.dart               # Standard card wrapper
    ├── app_empty_state.dart        # Empty state placeholder
    ├── app_section_header.dart     # Section header with title + action
    ├── glow_icon.dart              # Icon with radial glow effect
    ├── score_badge.dart            # Colour-coded score badge
    └── session_tile.dart           # Interview session list tile
```

**No state management library** — all screens use `StatefulWidget` + `setState`. Auth token and user info are persisted via `SharedPreferences`.

**Navigation** uses GoRouter v14. Routes are defined in `main.dart`:
- `/landing` — landing page (initial route)
- `/login` — login/register (query param `?mode=register`)
- `/home` — main dashboard
- `/interview/:categoryId` — interview flow (query param `?name=`)
- `/results/:sessionId` — results view
- `/report-sent/:sessionId` — confirmation
- `/profile`, `/profile/edit` — user profile
- `/faq` — FAQ page
- `/privacy` — privacy policy

The router redirects unauthenticated users to `/login`. A dev bypass mode (`kDevBypassLogin = true`) skips auth for UI review.

**API** calls live exclusively in `ApiService`. Results polling is handled there (30 attempts × 2 s). Fallback/mock data (`Question.fallback()`, `InterviewResult.mock()`) is defined on the model classes for offline/error states.

---

## Theme & design conventions

**Light + dark theme** with a floating toggle bubble (bottom-right). Theme is managed by `ThemeNotifier` and `AppTheme.light()` / `AppTheme.dark()`.

### Design tokens (centralised in `lib/theme/`)

| Token | Purpose |
|---|---|
| `kAccent` (`#6366F1`) | Primary indigo accent |
| `kAccentTeal`, `kAccentAmber`, `kAccentRose`, `kAccentSky` | Secondary accent palette |
| `AppColors.light` / `AppColors.dark` | Full light/dark palettes (bg, glass, text, border, glow) |
| `kFontSerif` (`Gambetta`) | Headlines, display text |
| `kFontSans` (`Satoshi`) | Body text, labels, buttons |
| `kRadiusSm/Md/Lg/Xl/Glass/Pill/Full` | Border radius tokens |
| `kShadowSm/Md/Lg/Glass/Glow` | Box shadow presets |
| `kDurationFast/Normal/Slow/Entrance/Float` | Animation duration presets |

Access theme-aware colours via `context.colors.bgBase`, `context.colors.textPrimary`, etc. (extension method on `BuildContext`).

### Visual style
- **Glassmorphism** — `BackdropFilter` + semi-transparent backgrounds with subtle borders (`GlassContainer`, `FloatingGlassCard`)
- **DotGridBackground** — animated dot pattern used on landing, login, interview, FAQ, and privacy screens
- **Animations** — stagger-in entrance animations (hero, FAQ), floating cards, pulse effects (recording), animated expand/collapse (FAQ accordion), carousel (onboarding)
- **Responsive** — `LayoutBuilder` or `MediaQuery` for wide/narrow layouts where needed

---

## Code conventions

- **Files**: `snake_case.dart` — **Classes**: `PascalCase` — **Private members/methods**: `_prefixed`
- Screen class order: fields → `initState` → `dispose` → `build` → private helper methods
- Complex `build()` methods are broken into private `_buildXxx()` helpers
- Error messages shown to users must be in Catalan; throw `Exception('Catalan message')` from services
- Models define `fromJson()` factories and, where relevant, static `fallback()` / `mock()` methods for offline use
- `InterviewCategory.defaults()` returns a hardcoded list of Catalan job categories — extend this list when adding categories before the backend is ready
- Use existing design tokens from `app_colors.dart`, `app_spacing.dart`, and `app_theme.dart` — do not hardcode colours or dimensions
- Reusable widgets go in `lib/widgets/`, screen-specific widgets stay as private classes in the screen file