---
name: screenshot
description: Take screenshots of the Flutter app for visual verification
user_invocable: true
---

# Flutter App Screenshot Skill

Take screenshots of FitApp pages for visual verification using golden tests.

## How It Works

Flutter CanvasKit renders via WebGL, making Chrome DevTools Protocol screenshots unreliable
(blank white images). Instead, this uses Flutter's **golden test** framework which captures
screenshots directly from the rendering pipeline — no browser needed.

Text appears as blocks in golden tests (test framework font rendering), but layout, colors,
icons, and structure are all accurately represented.

## Taking Screenshots

### Step 1: Clean up stale Chrome processes

Always run this first to avoid port conflicts from prior runs:

```bash
pkill -f "chrome.*flutter_tools" 2>/dev/null || true
```

### Step 2: Run the golden tests

```bash
flutter test test/screenshot_test.dart --update-goldens
```

### Step 3: View the screenshots

Read the captured PNGs with the Read tool:
- `test/screenshots/01_marketing_landing.png`
- `test/screenshots/02_login.png`
- `test/screenshots/03_faq.png`

## Adding New Screenshot Tests

Edit `test/screenshot_test.dart`. Each test should:

```dart
testWidgets('screen name screenshot', (tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(wrapInApp(const YourScreen()));
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('screenshots/your_screen.png'),
  );
});
```

## Limitations

- Golden tests don't load real fonts — text renders as rectangular blocks
- Authenticated screens (HomeScreen, Calendar, etc.) need Firebase mocking
- Network images won't load — use placeholder assertions instead

## Browser Cleanup

Chrome instances accumulate when Flutter test/run processes are interrupted:
- `flutter run` and `flutter drive` launch Chrome with temp user-data-dirs
- If killed improperly, Chrome stays open as an orphaned process
- Always run `pkill -f "chrome.*flutter_tools"` before new test runs
- Verify cleanup: `ps aux | grep "chrome.*flutter_tools" | grep -v grep`
