# 🔗 LinkVault — Smart Content Saver

A professional Flutter (Android) app to save, manage, and search links shared from any app — YouTube, Instagram, LinkedIn, Facebook, and more.

---

## ✨ Features

| Feature | Description |
|---|---|
| **Share Intent** | Receive links via Android share from any app |
| **Auto-Detect Category** | Automatically identifies YouTube, Instagram, LinkedIn, etc. |
| **Full CRUD** | Add, view, edit, delete saved links |
| **SQLite Storage** | Local persistent storage via `sqflite` |
| **Search** | Full-text search across title, URL, description, tags |
| **Tabs/Filter** | Filter by category using tab bar |
| **Favorites** | Star/bookmark important links |
| **Tags** | Add custom hashtags to links |
| **Sort** | Sort by newest, oldest, title, or category |
| **Open Links** | Tap any card to open in browser |
| **Copy URL** | Long-press → copy URL to clipboard |

---

## 📁 Project Structure

```
linkvault/
├── lib/
│   ├── main.dart                   # Entry point + share handler
│   ├── models/
│   │   └── link_model.dart         # LinkModel + auto-detection
│   ├── database/
│   │   └── db_helper.dart          # SQLite CRUD + search
│   ├── screens/
│   │   ├── home_screen.dart        # Main screen (list + search + tabs)
│   │   └── add_edit_screen.dart    # Add/Edit form screen
│   └── widgets/
│       ├── app_theme.dart          # Theme, colors, fonts
│       └── link_card.dart          # Individual link card widget
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml     # Share intent filters
│       └── kotlin/…/MainActivity.kt
└── pubspec.yaml                    # Dependencies
```

---

## 🚀 Setup & Run

### 1. Prerequisites
- Flutter 3.10+ installed
- Android Studio / VS Code with Flutter plugin
- Android device or emulator (API 21+)

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run the app
```bash
flutter run
```

### 4. Build release APK
```bash
flutter build apk --release
```
APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📦 Dependencies

```yaml
sqflite: ^2.3.0          # SQLite database
path: ^1.8.3             # Path utilities
share_handler: ^0.0.23   # Android share intent
url_launcher: ^6.2.4     # Open links in browser
intl: ^0.19.0            # Date formatting
flutter_slidable: ^3.1.0 # Swipe-to-action cards
shimmer: ^3.0.0          # Loading placeholders
```

---

## 🗄️ Database Schema

```sql
CREATE TABLE saved_links (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  title       TEXT NOT NULL,
  url         TEXT NOT NULL,
  description TEXT DEFAULT '',
  category    TEXT DEFAULT 'Other',
  date        TEXT NOT NULL,
  is_favorite INTEGER DEFAULT 0,
  tags        TEXT DEFAULT ''
);
```

---

## 📱 How Share Intent Works

1. User opens YouTube/Instagram/any app
2. Taps "Share" → selects **LinkVault**
3. App launches and opens Add Link screen pre-filled with the URL
4. Category is auto-detected from the URL
5. User adds title/description/tags and saves

### Supported categories (auto-detected):
- ▶️ YouTube (`youtube.com`, `youtu.be`)
- 📸 Instagram (`instagram.com`)
- 💼 LinkedIn (`linkedin.com`)
- 👥 Facebook (`facebook.com`, `fb.com`)
- 🐦 Twitter/X (`twitter.com`, `x.com`)
- 🔴 Reddit (`reddit.com`)
- 💻 GitHub (`github.com`)
- 📝 Medium (`medium.com`)
- 🎵 TikTok (`tiktok.com`)
- 📌 Pinterest (`pinterest.com`)
- 🎧 Spotify (`spotify.com`)
- 🛒 Shopping (`amazon.com`)
- 🔗 Other

---

## 🎨 Design

- **Theme**: Light with green (#4CAF50) primary
- **Cards**: Rounded with category color stripe
- **Typography**: Nunito (bold, readable)
- **Colors**: Soft greens, white cards, subtle shadows
- **Empty States**: Illustrated empty screens

---

## 🔧 Customization

### Add a new category:
1. Add to `LinkModel.detectCategory()` method
2. Add emoji in `LinkModel.categoryEmoji()`
3. Add color in `AppTheme.categoryColor()`
4. Add to the `_tabs` list in `HomeScreen`

### Change database path / name:
Edit `DBHelper._initDB()` → change `'linkvault.db'`

---

## 📝 Notes

- All data is stored **locally** — no internet, no Firebase required
- Share handler requires **Android API 21+**
- The app uses `launchMode="singleTop"` to handle multiple shares gracefully
