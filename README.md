<div align="center">

# 🔐 Secure Notes Pro

### *Your thoughts, beautifully protected.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Hive](https://img.shields.io/badge/Hive-Local%20DB-FF7043?style=for-the-badge)](https://pub.dev/packages/hive)
[![Provider](https://img.shields.io/badge/Provider-State%20Mgmt-7B1FA2?style=for-the-badge)](https://pub.dev/packages/provider)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**A premium, offline-first note-taking app built with Flutter — featuring PIN security, mood-based note styling, favorites, dark mode, and JSON backup.**

</div>

---

## 📖 Overview

**Secure Notes Pro** is a fully offline, privacy-first note-taking application developed with Flutter. It goes beyond basic CRUD — users can categorize notes by mood color, lock sensitive entries behind a PIN, search and filter by category, back up their data as JSON, and switch between a polished light and deep-glow dark theme.

Built as part of the **Android Development Framework (ADF)** academic module, this app demonstrates real-world patterns: clean architecture, reactive state management with Provider, local persistence with Hive, and a carefully crafted UI that feels at home on both Android and iOS.

---

## ✨ Features

### 🔹 Core Features
- **Full CRUD** — create, view, edit, and delete notes with a clean, focused interface
- **Search & filter** — instantly search by title/content; filter notes by category tag
- **Favorites system** — heart any note to pin it to a dedicated Favorites view
- **Grid layout** — two-column masonry-style cards with mood-based pastel backgrounds

### 🔐 Security Features
- **App lock (PIN)** — optional startup PIN enforced via a splash lock screen
- **Note-level locking** — individual notes can be locked; content is hidden until unlocked
- **PIN management** — 4-digit secure PIN stored via SharedPreferences; set/change from Settings

### 🎨 UI / UX Features
- **Dual themes** — clean pastel light mode + premium deep-glow dark mode
- **Mood colors** — 6 pastel color options per note (blue, pink, mint, peach, lavender, sky)
- **Smooth navigation** — page transitions, back gestures, and a persistent bottom nav bar
- **Contextual greeting** — home screen greets the user by name with time-aware messaging

### ⚡ Advanced Features
- **Dark mode toggle** — persisted across sessions via SharedPreferences
- **Category tags** — Personal, Work, Ideas, Study, Dreams, Plans — with custom display labels
- **Export backup** — serialize all notes to a JSON file for external storage
- **Restore backup** — import a previously exported JSON file to restore notes
- **Stats dashboard** — live counters for total notes, favorites, and locked notes

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart) |
| **State Management** | Provider |
| **Local Database** | Hive (NoSQL, Flutter-native) |
| **Persistent Settings** | SharedPreferences |
| **Architecture** | Feature-based modular clean architecture |
| **Platform Target** | Android, iOS, Web (Chrome) |

---

## 📱 App Screenshots

<div align="center">

### 🏠 Home Screen
<img src="https://github.com/Kanani-Shubham/ADF_ALA_3/blob/main/home_screen.png" width="270" alt="Home Screen"/>

*Personalized greeting, live stats, recent activity, and note cards with mood colors*

---

### ✏️ Add / Edit Note
<img src="https://github.com/Kanani-Shubham/ADF_ALA_3/blob/main/add_note.png" width="270" alt="Add Note Screen"/>

*Title + body editor, category picker, and 6 mood color swatches*

---

### 🔒 PIN Lock Screen
<img src="https://github.com/Kanani-Shubham/ADF_ALA_3/blob/main/pin_screen.png" width="270" alt="PIN Lock Screen"/>

*4-dot secure PIN entry for unlocking individual notes or the entire app*

---

### ❤️ Favorites Screen
<img src="https://github.com/Kanani-Shubham/ADF_ALA_3/blob/main/favorites_screen.png" width="270" alt="Favorites Screen"/>

*All favorited notes in one place, with search and category filter*

---

### ⚙️ Control Center (Settings)
<img src="https://github.com/Kanani-Shubham/ADF_ALA_3/blob/main/settings_screen.png" width="270" alt="Settings Screen"/>

*App lock toggle, premium dark mode switch, export & restore backup*

</div>

---

## 🧩 Project Structure

```
lib/
├── models/
│   └── note_model.dart          # Hive data model for a Note
│
├── providers/
│   └── note_provider.dart       # ChangeNotifier — all business logic
│
├── screens/
│   ├── splash_lock_screen.dart  # Startup PIN gate
│   ├── home_screen.dart         # Notes grid + search + stats
│   ├── add_edit_note_screen.dart # Create / edit a note
│   └── lock_screen.dart         # Per-note PIN unlock screen
│
├── services/
│   ├── hive_service.dart        # Hive init + CRUD helpers
│   └── pin_service.dart         # PIN read / write via SharedPreferences
│
├── utils/
│   └── theme.dart               # Light + dark AppTheme definitions
│
└── main.dart                    # App entry point + ChangeNotifierProvider
```

---

## ⚙️ Installation

**Prerequisites:** Flutter SDK ≥ 3.0, Dart ≥ 3.0, Android Studio or VS Code

```bash
# 1. Clone the repository
git clone https://github.com/shubhamkanani/secure-notes-pro.git
cd secure-notes-pro

# 2. Install dependencies
flutter pub get

# 3. Run on a device / emulator
flutter run

# 4. (Optional) Build release APK
flutter build apk --release
```

> **Note:** The app uses Hive for local storage. No internet connection or backend setup is required.

---

## 🎯 Learning Outcomes

This project was developed as part of the **Android Development Framework (ADF)** academic module. Key concepts applied and learned:

- **Flutter widget lifecycle** — understanding `StatelessWidget` vs `StatefulWidget` and when to use each
- **Provider pattern** — reactive state management using `ChangeNotifier`, `Consumer`, and `context.read/watch`
- **Hive NoSQL** — defining TypeAdapters, initializing boxes, and performing async CRUD without a remote server
- **SharedPreferences** — persisting lightweight settings (theme, PIN, app lock toggle) across app restarts
- **Clean architecture** — separating models, providers, screens, services, and utilities into dedicated layers
- **Security patterns** — PIN-gated startup with a splash lock screen and per-note locking logic
- **Theme management** — defining and switching between light and dark `ThemeData` at runtime
- **JSON serialization** — exporting and importing structured data for backup and restore

---

## 🔮 Future Improvements

- **Biometric authentication** — fingerprint / Face ID as an alternative to PIN unlock
- **Cloud sync** — optional Firebase Firestore sync to back up notes across devices
- **Rich text editor** — bold, italic, bullet lists, and inline images inside notes
- **Reminder / alarm** — attach a date-time reminder to any note with local notifications
- **Note sharing** — share a note as plain text or PDF via the native share sheet

---

## 👨‍💻 Author

**Shubham Kanani**
Enrollment No. — 20230905090053

> Built with 💙 using Flutter

---

<div align="center">

*If you found this project useful, consider starring ⭐ the repository.*

</div>
