# The Shelf (`The-Shelf`)

A personal digital library application built with Flutter and Dart, designed to organize, search, and manage digital documents across 17 auto-categorized shelves using on-device machine learning, Cloud Firestore synchronization, and local SQLite persistence.

---

## Key Features

- **Firebase Authentication & Social Sign-In**: Traditional Email & Password authentication, Passwordless Magic Link sign-in, and official Google Sign-In with 4-color vector branding.
- **Cloud Firestore & Firebase Storage Sync**: Automatic profile synchronization under Cloud Firestore `/users/{uid}` and image uploads to Firebase Storage (`avatar.jpg` and `banner.jpg`) with offline `SharedPreferences` caching fallback.
- **Custom Profile & Reader Motto**: Interactive Cover Banner photo picker, Avatar profile picture picker, User Name customization, and styled Reading Motto / Book Quote section (`PhosphorIcons.quotes`).
- **Custom Collections (SQLite Many-to-Many)**: User-created collections (up to 20), color pickers, Phosphor icons, and SQLite join table (`collections` & `collection_documents`) ensuring full data preservation.
- **Multi-Criteria Library Sorting (Persistent)**: Funnel sort options for shelves—Alphabetical (A ➔ Z / Z ➔ A), Most Items First, Least Items First, and Populated First—automatically saved to `SharedPreferences`.
- **Pure Dart On-Device Machine Learning**: Zero-dependency TF-IDF vectorization and Softmax classification engine evaluating document metadata in under 0.1ms natively in Dart.
- **Local SQLite Persistence**: Full document persistence using `sqflite` (`DocumentRepository` layer) with indexed queries across document titles and category shelves.
- **Extensible Theme System**: Multi-palette theme engine supporting Terracotta (Warm Cream) and Teal (Fresh Mint) palettes with instant live application and `shared_preferences` storage.
- **Polished Zero-Flicker App Startup**: Seamless local session restore with dedicated `SplashScreen` and zero AuthScreen flickering on cold start.

---

## Technical Architecture

```text
lib/
├── blocs/
│   ├── auth/                # Firebase Auth & UserProfile sync BLoC
│   ├── collection/          # Custom collections & many-to-many join BLoC
│   ├── document_import/     # Document picker & text extraction BLoC
│   ├── shelf/               # Shelf items state management BLoC
│   └── theme/               # Active theme palette Cubit with SharedPreferences
├── models/
│   ├── collection_model.dart # Custom collection data model
│   ├── mock_shelf_items.dart # Development mock data
│   ├── shelf_state.dart      # Shelf item data models
│   ├── sort_option.dart      # Multi-criteria sorting enum
│   └── user_profile.dart     # Cloud Firestore UserProfile data model
├── screens/
│   ├── auth_screen.dart     # Firebase Sign-In, Sign-Up, & Magic Link UI
│   ├── collection_detail_screen.dart # Collection documents view
│   ├── home_screen.dart     # Main library & PageView shelf list navigation
│   ├── profile_screen.dart  # Reader profile, cover banner, & genre breakdown
│   ├── search_screen.dart   # Title & category search interface
│   ├── settings_screen.dart # Theme selection & app preferences
│   ├── shelf_detail_screen.dart # Shelf content detail view
│   └── splash_screen.dart   # Clean loading splash screen
├── services/
│   ├── auth_repository.dart        # Firebase Auth & Google Sign-In repository
│   ├── collection_repository.dart  # SQLite collections & join table layer
│   ├── document_import_service.dart # File picking & PDF text extraction
│   ├── document_repository.dart    # SQLite persistence layer via sqflite
│   ├── shelf_classifier_service.dart # Pure Dart TF-IDF classification engine
│   └── user_profile_repository.dart # Cloud Firestore & Firebase Storage repository
├── theme/
│   ├── app_color_palette.dart # Palette definitions (Terracotta, Teal)
│   └── app_theme.dart        # Dynamic ThemeData generation
└── widgets/                  # Reusable UI components (EditProfileModal, SortOptionsModal, CollectionCard, BookRow, AppHeader)
```

---

## Database Schema (SQLite & Cloud Firestore)

### SQLite Schema (`the_shelf_documents.db`)

```sql
CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  shelf TEXT NOT NULL,
  file_path TEXT NOT NULL,
  added_at TEXT NOT NULL,
  user_id TEXT DEFAULT 'guest_local'
);

CREATE TABLE collections (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  user_id TEXT DEFAULT 'guest_local'
);

CREATE TABLE collection_documents (
  collection_id TEXT NOT NULL,
  document_id TEXT NOT NULL,
  added_at TEXT NOT NULL,
  PRIMARY KEY (collection_id, document_id),
  FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
);

CREATE INDEX idx_documents_shelf ON documents(shelf);
CREATE INDEX idx_documents_title ON documents(title);
CREATE INDEX idx_documents_user ON documents(user_id);
```

### Cloud Firestore Schema (`users/{uid}`)

```json
{
  "uid": "USER_ID_STRING",
  "email": "user@example.com",
  "displayName": "User Name",
  "photoUrl": "https://firebasestorage.googleapis.com/.../avatar.jpg",
  "bannerUrl": "https://firebasestorage.googleapis.com/.../banner.jpg",
  "bio": "Reading motto / favorite quote...",
  "createdAt": "2026-08-11T00:00:00.000Z",
  "updatedAt": "2026-08-11T00:00:00.000Z"
}
```

---

## Development Setup

### Prerequisites

- Flutter SDK `^3.12.2` or later
- Dart SDK included with Flutter
- macOS, iOS, or Android development toolchain

### Installation & Commands

1. **Retrieve dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run static analysis**:
   ```bash
   flutter analyze
   ```

3. **Run test suite**:
   ```bash
   flutter test
   ```

4. **Launch application**:
   ```bash
   flutter run
   ```

---

## Supported Target Shelves (17 Categories)

1. Fantasy
2. Historical Fiction
3. Mystery
4. Romance
5. Science Fiction
6. Horror
7. Graphic Novels & Comics
8. Anime & Manga
9. Poetry
10. History
11. Biography & Memoir
12. Philosophy
13. Self-Help & Personal Development
14. School/Reference
15. Classics
16. Religion & Spirituality
17. Miscellaneous
