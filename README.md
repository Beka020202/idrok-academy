# Idrok Academy — Flutter phone app (Android + iPhone)

Idrok Academy (formerly Kodla), rewritten in **Dart / Flutter**: one codebase, a native app on both phones.
The Python server stays for accounts, the leaderboard and the teacher panel.

```
kodla/
├── app/                  Flutter app (Dart)
│   ├── lib/
│   │   ├── config.dart   ← server addresses (edit after deploying)
│   │   ├── content/      courses and lessons: HTML, CSS, JS, Python, AI + warm-up test
│   │   │                 (each lesson is a question *generator* — every attempt is different)
│   │   ├── progress.dart game rules (XP, leagues, quests, streak)
│   │   ├── focus.dart    Android "Do Not Disturb" during tests
│   │   ├── i18n.dart     Uzbek / Russian texts
│   │   ├── state.dart    app state, saving, server calls
│   │   ├── widgets.dart  shared UI pieces
│   │   └── screens/      intro, login, profile setup, home, courses, lesson/test, AI helper,
│   │                     practice, ranking, shop, teacher, profile
│   ├── assets/           fonts, icon, intro video, shop renders, shop list
│   ├── test/             automatic tests
│   └── tool/             setup_platforms.py, shop_render/ (3D renders of shop prizes)
├── server/
│   ├── server.py         accounts, photos, leagues, leaderboards, shop orders, teacher panel
│   ├── runner.py         runs students' Python code in a locked-down process
│   ├── progress.py       same game rules as the app
│   └── content/          lessons.json and shop.json (shared lists)
├── render.yaml           Render setup for both services
└── .github/workflows/build.yml   GitHub builds the APK for you
```

## How it works for students
- **Intro video** plays on launch, then the app opens.
- **Registration:** name, school, where they live and their own photo (no avatars).
- **Warm-up:** 8 short questions after registration. It quietly places the student in the
  Beginner, Advanced or Master league. Students are not told it is a placement test.
- **Leagues:** students move up automatically when they are fast and accurate and earn much more XP
  than others in their league in a week. Weekly and monthly leaderboards rank XP *earned* in the period,
  so spending XP never lowers anyone's place.
- **One currency — XP.** Lessons of similar length give the same XP in every league
  (20 XP per lesson, 30 XP per AI project).
- **Test protection:** every attempt gets new generated questions; leaving the app cancels the test
  at once and the retry is harder; each question has a timer (harder = more time, beginners get extra time).
  Android asks for Do Not Disturb access and silences notifications during a test.
  iPhone shows a short Guided Access guide.
- **XP shop:** real prizes with the Idrok logo (pen → laptop). Orders appear in the teacher panel,
  where the teacher marks them delivered or cancels them (XP is refunded).
- **AI helper:** after a mistake, explains it in simple words for 5 XP.
- **AI course:** beginners learn what AI is, smart prompting and spotting AI mistakes and fakes;
  Advanced and Master build a chatbot, a digit recogniser and a quiz generator.


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
Write the lesson builder in `app/lib/content/<course>.dart`, add it to `kCourses` in
`app/lib/content/catalog.dart`, and add the same `id`, `xp` and `leagues` to `server/content/lessons.json`.
`flutter test` checks that both lists match and that every generated question is valid.

## Shop prizes
Prices and names live in `server/content/shop.json` (copy it to `app/assets/content/shop.json`).
Pictures are `app/assets/shop/<id>.png`; `app/tool/shop_render/` re-creates them.

## Before Google Play / App Store
- Google Play: create an upload key and release signing (the GitHub APK is fine for direct installs).
  Since users are school students, Play's rules for apps used by children apply.
- iPhone: needs a Mac or a cloud Mac build plus an Apple Developer account ($99/year).
