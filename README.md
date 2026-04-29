# Secure Notes Pro

A production-style Flutter notes app for academic submission. It uses Provider for reactive state, Hive for offline note storage, and SharedPreferences for PIN settings.

## Features

- Create, edit, delete, search, sort, and favorite notes
- Grid UI with pastel cards, soft shadows, and responsive layout
- Lock individual notes with a PIN and hide locked content
- Optional app-level startup lock
- Categories, bottom navigation, dark mode, swipe delete, and multi-select delete
- Local JSON backup and restore through copy/paste

## Project Structure

```text
lib/
  main.dart
  models/note_model.dart
  services/hive_service.dart
  services/pin_service.dart
  providers/note_provider.dart
  screens/home_screen.dart
  screens/add_edit_note_screen.dart
  screens/lock_screen.dart
  screens/splash_lock_screen.dart
  widgets/note_card.dart
  widgets/search_bar.dart
  utils/theme.dart
```

## Run

```bash
flutter pub get
flutter run
```

## Screenshots

Add screenshots here after running the app:

- `screenshots/home.png`
- `screenshots/editor.png`
- `screenshots/lock.png`

## Notes

The note content is base64 encoded during JSON export as a simple demonstration of basic content encoding. For a real production security app, replace this with platform keystore-backed encryption.
