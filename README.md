# Stash

A beautiful personal savings tracker built with Flutter.

## Features

- **Goal tracking** — Create multiple savings goals with custom icons, colors, and target amounts
- **Transaction history** — Log deposits and withdrawals with category tags and search/filter
- **Insights** — Cumulative savings charts, per-period breakdowns, goal progress bars, and spending by category
- **Daily reminders** — Customizable notification title and body to keep you on track
- **Savings streaks** — Auto-tracked consecutive deposit streaks
- **Achievement badges** — Unlock 8 badges as you hit milestones
- **Import/Export** — Back up and restore your data as JSON
- **In-app updates** — Checks GitHub Releases for new versions and downloads directly

## Download

Go to [Releases](https://github.com/Minu181/Stash/releases) and download the APK for your device:

| File | Architecture |
|------|-------------|
| `app-armeabi-v7a-release.apk` | 32-bit ARM (most devices) |
| `app-arm64-v8a-release.apk` | 64-bit ARM (modern devices) |
| `app-x86_64-release.apk` | x86_64 (emulators, Chromebooks) |

## Build from source

```bash
# Clone the repo
git clone https://github.com/Minu181/Stash.git
cd Stash

# Install dependencies
flutter pub get

# Build split APKs
flutter build apk --split-per-abi
```

Built APKs will be in `build/app/outputs/flutter-apk/`.

## Tech stack

- Flutter + Dart
- Riverpod (state management)
- Drift (SQLite database)
- fl_chart (charts)
- flutter_local_notifications
- go_router

## License

MIT
