# Idrok Academy — Flutter phone app (Android + iPhone)

Idrok Academy (formerly Kodla), rewritten in **Dart / Flutter**: one codebase, a native app on both phones.
The Python server stays for accounts, the leaderboard and the teacher panel.

```
kodla/
├── app/                  Flutter app (Dart)
│   ├── lib/
│   │   ├── config.dart   ← server addresses (edit after deploying)
│   │   ├── lessons.dart  courses, lessons, answer checks
│   │   ├── progress.dart game rules (XP, gems, quests, streak)
│   │   ├── i18n.dart     Uzbek / Russian texts
│   │   ├── state.dart    app state, saving, server calls
│   │   ├── widgets.dart  shared UI pieces
│   │   └── screens/      login, home, courses, lesson, practice, ranking, teacher, profile
│   ├── assets/fonts/     bundled fonts (work offline)
│   ├── test/             automatic tests
│   └── tool/setup_platforms.py
├── server/
│   ├── server.py         accounts, leaderboard, teacher panel
│   ├── runner.py         runs students' Python code in a locked-down process
│   ├── lessons.py, progress.py
├── render.yaml           Render setup for both services
└── .github/workflows/build.yml   GitHub builds the APK for you
```

## Design system
Everything visual lives in two files, so screens never repeat styles:
- `app/lib/theme.dart`: light and dark palettes (orange, yellow, black, white and neutrals), type scale, spacing grid (`S`), corner radii (`R`), shadows and glow (`Shadows`), motion timings (`Motion`, which respects the phone's "Reduce motion" setting).
- `app/lib/widgets.dart`: reusable components such as `AppButton` (primary / success / dark / secondary / ghost / danger, with pressed, focus, disabled and loading states), `AppCard` (solid / inset / glass / tinted), `Glass`, `FloatingNavBar`, `AppTextField`, `Segmented`, `AppProgress`, `AppRing`, `CodeEditor`, `Console`, `Skeleton`, `EmptyState`, `showAppSheet`, `AppToast` and `AppRoute`.

Appearance follows the phone (System) by default. Users can switch to Light or Dark in Profile → Settings.

## Why it's fast
- Lessons, quizzes, game rules and fonts are **inside the app**: screens open instantly and work without internet.
- The internet is used only to save progress, load the leaderboard and run Python exercises.
- Flutter draws at 60 fps on cheap Android phones.

## 1. Put the server online (Render)
1. Upload this folder to a GitHub repository.
2. Render → **New → Blueprint** → choose the repository. It creates two services from `render.yaml`:
   - `kodla-api` (paid Starter plan, because it needs a disk for the database)
   - `kodla-runner` (free plan; it has no passwords or data, so the Python sandbox can't leak anything)
3. Enter `TEACHER_PASSWORD` (at least 12 characters) when Render asks.
4. Copy the two addresses Render gives you (e.g. `https://kodla-api-xxxx.onrender.com`) into
   `app/lib/config.dart` → `kDefaultServer` and `kRunnerServer`.

The free runner falls asleep after 15 minutes without use. The first Python run after that takes up to a minute (the app shows "Bajarilmoqda…"/"Выполняется…" while it waits).

## 2. Get the APK
**Easiest — GitHub builds it:** push the repository. Open **Actions** → the latest "Build Kodla app" run → **Artifacts** → `kodla-android`. Inside is `app-release.apk`. Send it to phones (e.g. via Telegram) and install it.
The same run also checks the code, runs the tests and checks that the iPhone version compiles. If a step is red, open it and send me the error text.

**On your own computer:**
```
# Install Flutter once: https://docs.flutter.dev/get-started/install
cd app
python tool/setup_platforms.py      # creates android/ and ios/ folders (once)
flutter run                         # runs on a phone connected by USB
flutter build apk --release         # APK → build/app/outputs/flutter-apk/
```

## Classroom mode (one Wi‑Fi, no internet needed)
```
cd server
python server.py --teacher-password YourPassword
```
In the app, tap **Server manzili / Адрес сервера** on the login screen and enter the address the server prints
(`http://192.168.x.x:8765`). Python exercises then run on this laptop too.

## Adding a lesson
Add it in **both** `app/lib/lessons.dart` and `server/lessons.py` with the same `id` and `xp`.
For a practice step, add its answer check to `kChecks` in `lessons.dart`.

## Before Google Play / App Store
- App icon: replace the default Flutter icon (e.g. with the `flutter_launcher_icons` package).
- Google Play: create an upload key and release signing (the GitHub APK is fine for direct installs).
  Since users are school students, Play's rules for apps used by children apply.
- iPhone: needs a Mac or a cloud Mac build plus an Apple Developer account ($99/year).
