# Secure Notes Pro

Secure Notes Pro is a premium offline-first Flutter notes app built for the ADF academic submission. It uses Provider for reactive state management, Hive for local note storage, and SharedPreferences for PIN/security settings.

## Features

- Create, edit, delete, search, sort, and favorite notes
- Premium glassmorphism/neumorphism UI with pastel gradients
- Dynamic greeting, stats dashboard, categories, and recent activity
- Mood-based note colors with animated gradient cards
- Swipe right to favorite, swipe left to delete
- Long-press multi-select delete
- Individual note lock with PIN and hidden locked content
- Optional app-level startup lock
- OTP-style PIN screen with shake animation
- Light theme and deep premium dark mode
- Expanding FAB menu for Add Note, Voice Note, and Quick Note
- Local JSON backup and restore

## Tech Stack

| Layer | Technology |
| --- | --- |
| Framework | Flutter |
| Language | Dart |
| State Management | Provider |
| Local Database | Hive |
| Settings Storage | SharedPreferences |
| Architecture | Modular feature-based structure |

## Project Structure

```text
lib/
  main.dart
  models/
    note_model.dart
  services/
    hive_service.dart
    pin_service.dart
  providers/
    note_provider.dart
  screens/
    home_screen.dart
    add_edit_note_screen.dart
    lock_screen.dart
    splash_lock_screen.dart
  widgets/
    note_card.dart
    search_bar.dart
  utils/
    theme.dart
```

## Run Locally

```bash
git clone https://github.com/Kanani-Shubham/ADF_ALA_3.git
cd ADF_ALA_3
flutter pub get
flutter run
```

## Build

```bash
flutter build apk --release
flutter build web
```

## Screenshots

Add screenshots after running the app:

- `screenshots/home_screen.png`
- `screenshots/add_note.png`
- `screenshots/pin_screen.png`
- `screenshots/settings_screen.png`

## Author

Shubham Kanani

Enrollment No.: 20230905090053
