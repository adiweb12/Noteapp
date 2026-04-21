# NoteCraft 📝

A **production-ready Flutter Notepad App** with rich text editing, drawing canvas, image support, dark mode, and more — built with Clean Architecture and Riverpod.

---

## ✨ Features

| Feature | Details |
|---|---|
| **Rich Text Editor** | Bold, italic, underline, strikethrough, headings (H1-H3), bullet/numbered lists, checkboxes, text color |
| **Drawing Canvas** | Touch drawing with undo/redo, multiple pen colors, eraser, adjustable stroke width, dark/light canvas |
| **Image Support** | Pick from gallery or camera, multiple images per note, tap to remove |
| **Auto-Save** | Debounced auto-save every 800ms while editing |
| **Search** | Real-time full-text search across titles and content |
| **Pin & Archive** | Pin important notes, archive old ones |
| **Tags** | Add/remove tags per note |
| **Dark Mode** | Full dark/light/system theme support (Material 3) |
| **Note Colors** | 8 beautiful tint colors per note |
| **Export** | Export single note as `.txt`, export all notes as `.json` |
| **Import** | Import notes from a `.json` backup file |
| **Share** | Share note text or file via any app |
| **Grid / List View** | Toggle between masonry grid and list view |

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point, Riverpod setup
├── models/
│   ├── note_model.dart          # NoteModel + Hive adapter
│   ├── note_model.g.dart        # Generated Hive adapter
│   └── drawing_model.dart       # DrawingStroke + DrawingData models
├── services/
│   ├── hive_service.dart        # Hive initialization
│   ├── notes_repository.dart    # All CRUD, search, export/import
│   └── image_service.dart       # Image picker + local storage
├── viewmodels/
│   ├── providers.dart           # All Riverpod providers
│   └── drawing_viewmodel.dart   # Drawing state (ChangeNotifier)
├── screens/
│   ├── home_screen.dart         # Notes list (grid/list, search, FAB)
│   ├── note_editor_screen.dart  # Full editor with Quill + toolbar
│   ├── drawing_screen.dart      # Full-screen drawing canvas
│   ├── archive_screen.dart      # Archived notes
│   └── settings_screen.dart     # Theme, export/import, stats
├── widgets/
│   ├── note_card.dart           # Note card (grid + list variants)
│   ├── drawing_canvas.dart      # CustomPainter canvas + toolbar
│   ├── color_picker.dart        # Note color picker strip
│   ├── search_bar_widget.dart   # Animated search field
│   └── empty_state.dart         # Empty state with animation
├── theme/
│   └── app_theme.dart           # Light/dark Material 3 themes
└── utils/
    └── app_constants.dart       # Constants, DateFormatter, extensions
```

---

## 🚀 Setup & Installation

### Prerequisites

- Flutter SDK **3.5.0+** ([install guide](https://docs.flutter.dev/get-started/install))
- Dart SDK **3.5.0+**
- Android Studio / VS Code with Flutter extension
- Android device or emulator (API 21+)

### Steps

```bash
# 1. Clone / unzip the project
cd notecraft

# 2. Install dependencies
flutter pub get

# 3. Run on connected device or emulator
flutter run

# 4. Build APK for release
flutter build apk --release
```

### ⚠️ First-time Setup Notes

The Hive adapter (`note_model.g.dart`) is **already pre-generated** in this project — you do **not** need to run `build_runner`. But if you modify `note_model.dart`, regenerate with:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.5.1 | State management |
| `hive` + `hive_flutter` | ^2.2.3 / ^1.1.0 | Local database |
| `flutter_quill` | ^10.8.5 | Rich text editor |
| `flutter_staggered_grid_view` | ^0.7.0 | Masonry grid layout |
| `flutter_animate` | ^4.5.0 | UI animations |
| `image_picker` | ^1.1.2 | Gallery & camera |
| `path_provider` | ^2.1.4 | App directories |
| `path` | ^1.9.0 | Path manipulation |
| `share_plus` | ^10.0.2 | Share files & text |
| `file_picker` | ^8.1.2 | Pick JSON files for import |
| `uuid` | ^4.4.2 | Unique note IDs |
| `intl` | ^0.19.0 | Date formatting |
| `shared_preferences` | ^2.3.2 | Theme + view mode persistence |
| `google_fonts` | ^6.2.1 | Inter font family |

---

## 🏗 Architecture

```
┌──────────────────────────────────────────┐
│              UI Layer                     │
│   screens/ + widgets/                     │
│   ConsumerWidget (Riverpod)               │
└──────────────┬───────────────────────────┘
               │ watches / reads
┌──────────────▼───────────────────────────┐
│           ViewModel Layer                 │
│   providers.dart (StateNotifier)          │
│   drawing_viewmodel.dart (ChangeNotifier) │
└──────────────┬───────────────────────────┘
               │ calls
┌──────────────▼───────────────────────────┐
│            Data Layer                     │
│   notes_repository.dart                   │
│   hive_service.dart                       │
│   image_service.dart                      │
└──────────────┬───────────────────────────┘
               │ reads/writes
┌──────────────▼───────────────────────────┐
│           Storage Layer                   │
│   Hive (notes) + File system (images)     │
└──────────────────────────────────────────┘
```

---

## 🎨 Customization

- **Add more colors**: Edit `noteColorsLight` / `noteColorsDark` in `app_theme.dart`
- **Change seed color**: Modify `_seedColor` in `app_theme.dart`  
- **Change auto-save delay**: Modify `autoSaveDebounce` in `app_constants.dart`

---

## 📱 Screenshots

> Build and run on your device to see the app in action!

---

## 🔧 Troubleshooting

**Camera permission denied**: Make sure to grant camera permissions in device settings.

**Images not showing**: Images are stored in the app's documents directory. Clearing app data will remove them.

**Import fails**: Make sure the JSON file was exported from NoteCraft (or matches the `NoteModel` schema).
