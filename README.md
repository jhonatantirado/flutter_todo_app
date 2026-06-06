# Todo App

A lightweight task management app built with Flutter. Create, organise, and track your daily tasks across iOS, Android, web, and desktop from a single codebase.

---

## Overview

The Todo App lets you manage tasks with a simple, focused interface. Each task has four pieces of information: a **title**, a **description**, a **status**, and an optional **target date**. Statuses progress from **Pending** through **In Progress** to **Done**, giving you a clear picture of where everything stands at a glance.

### What you can do

- **Add tasks** — tap *New task* to open a form, fill in the title, an optional description, an initial status, and an optional target date.
- **Update tasks** — change a task's status inline via the dropdown on each card, or tap the edit icon to update any field including the target date.
- **Complete tasks** — tap the circle on the left of any card to toggle it between Pending and Done. Completed tasks are visually struck through and dimmed.
- **Delete tasks** — tap the trash icon to permanently remove a task.
- **Filter tasks** — use the chip bar at the top to show All tasks or narrow the view to Pending, In Progress, or Done.
- **Track deadlines** — tasks with a target date show a calendar icon and the date on the card. Tasks whose target date has passed and are not yet Done are highlighted in red with an "Overdue" badge.
- **Persist across sessions** — all tasks are saved locally using SQLite, so nothing is lost when you close the app.

---

## Technical Requirements

### All platforms
| Requirement | Version |
|---|---|
| Flutter SDK | ≥ 3.0.0 |
| Dart SDK | ≥ 3.0.0 |

Install Flutter by following the official guide: https://docs.flutter.dev/get-started/install

### Web (Chrome)
- Google Chrome browser
- No additional setup beyond the Flutter web SDK (included with Flutter)

### iOS
| Requirement | Notes |
|---|---|
| macOS | 13 (Ventura) or later |
| Xcode | Latest stable, installed from the Mac App Store |
| CocoaPods | `sudo gem install cocoapods` |
| Ruby | ≥ 3.0 (use `rbenv` if your system Ruby is older) |
| Apple Developer account | Free account for device testing; paid ($99/yr) for App Store distribution |

### Android
| Requirement | Notes |
|---|---|
| Android Studio | Latest stable, for the Android SDK and emulator |
| Android SDK | API level 21 (Android 5.0) or higher |
| Java | JDK 17, bundled with Android Studio |

### Desktop (macOS / Windows / Linux)
- The target platform's standard build toolchain (Xcode for macOS, Visual Studio Build Tools for Windows, `clang`/`cmake` for Linux)
- See https://docs.flutter.dev/get-started/install for platform-specific setup

---

## Running the App

### 1. Clone the repository

```bash
git clone https://github.com/your-username/todo_app.git
cd todo_app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Web — one-time setup

The web build uses a WASM build of SQLite. Copy the required worker files into the `web/` folder:

```bash
dart run sqflite_common_ffi_web:setup
```

### 4. Run the app

**Chrome:**
```bash
flutter run -d chrome
```

**iOS Simulator:**
```bash
open -a Simulator
flutter run -d iphone
```

**iOS device:**  
Open `ios/Runner.xcworkspace` in Xcode, select your team under *Signing & Capabilities*, trust the certificate on your device, then:
```bash
flutter run -d your-iphone-name
```

**Android emulator or device:**
```bash
flutter run -d android
```

**macOS desktop:**
```bash
flutter run -d macos
```

### 5. Build a release binary

| Platform | Command | Output |
|---|---|---|
| Web | `flutter build web` | `build/web/` |
| iOS | `flutter build ipa` | `build/ios/ipa/` |
| Android | `flutter build apk` | `build/app/outputs/apk/` |
| macOS | `flutter build macos` | `build/macos/Build/Products/Release/` |

### Verify your environment

At any point you can run the following to check that all dependencies are correctly installed:

```bash
flutter doctor
```

All items relevant to your target platform should show a green ✓.

---

## Architecture

The app follows a simple **layered architecture** with a clear separation between data, business logic, and UI.

```
lib/
├── main.dart                      # Entry point — platform setup and app root
├── models/
│   └── todo.dart                  # Todo entity and TodoStatus enum
├── data/
│   └── database_helper.dart       # SQLite data access layer (singleton)
├── screens/
│   └── todo_list_screen.dart      # Main screen — state management and layout
└── widgets/
    ├── todo_card.dart             # Single task card (stateless)
    └── todo_form_sheet.dart       # Add / edit bottom sheet (stateful)
```

### Layers

**Model (`models/`):**  
`Todo` is a plain Dart class with five fields: `id`, `title`, `description`, `status`, and `targetDate`. `toMap()` / `fromMap()` handle SQLite serialization, and `copyWith()` enables immutable-style updates. Because `targetDate` is optional (`DateTime?`), `copyWith()` uses a private `const _KeepDate` sentinel as the default so callers can explicitly pass `null` to clear the date without it being confused with "not provided". `TodoStatus` is an enum with an extension that maps each case to a display label and a stored string value.

**Data (`data/`):**  
`DatabaseHelper` is a singleton that owns the SQLite connection via the `sqflite` package. It exposes five methods — `insertTodo`, `getAllTodos`, `updateTodo`, `deleteTodo`, and `close` — and hides all SQL from the rest of the app. The database is created lazily on first access. Schema migrations are handled via the `onUpgrade` callback; upgrading from version 1 to 2 adds the `target_date` column to existing installations.

**Screens (`screens/`):**  
`TodoListScreen` is the single screen. It is a `StatefulWidget` that holds the in-memory list of todos, the active filter, and the loading flag. It is responsible for calling `DatabaseHelper` and updating state via `setState`. All mutations follow the same pattern: await the database operation, then update the in-memory list.

**Widgets (`widgets/`):**  
`TodoCard` and `TodoFormSheet` are pure presentational widgets. They receive data and callbacks as constructor arguments and never touch the database directly. This keeps them reusable and easy to test.

### Data flow

```
User action (tap / type)
        │
        ▼
   Widget callback
        │
        ▼
TodoListScreen mutation method
        │
        ├──► DatabaseHelper (persist to SQLite)
        │
        └──► setState() → build() → updated UI
```

### Persistence

SQLite is accessed via the `sqflite` package. Because sqflite requires different initialisation per platform, `main.dart` sets the appropriate `databaseFactory` before `runApp`:

| Platform | Implementation |
|---|---|
| Web | `sqflite_common_ffi_web` — SQLite compiled to WASM, stored in IndexedDB |
| Desktop | `sqflite_common_ffi` — SQLite via Dart FFI |
| iOS / Android | `sqflite` native plugin — no extra setup needed |

The database schema consists of a single `todos` table:

```sql
CREATE TABLE todos (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  title       TEXT    NOT NULL,
  description TEXT    NOT NULL DEFAULT '',
  status      TEXT    NOT NULL DEFAULT 'pending',
  target_date TEXT,
  created_at  TEXT    NOT NULL
);
```

`target_date` is stored as an ISO 8601 string (e.g. `2025-12-31T00:00:00.000`) or SQL NULL when no date has been set. The column was added in schema version 2 via a migration; existing rows receive NULL automatically.

### State management

State is managed locally in `TodoListScreen` using Flutter's built-in `setState`. This is intentional — the app has a single screen and a flat data model, so a more complex solution such as `provider` or `Riverpod` would add overhead without benefit. If the app grows to multiple screens that share the same task list, the natural next step would be to extract the list state and database calls into a `ChangeNotifier` and expose it via `provider`.