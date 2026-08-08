# The Shelf (`The-Shelf`)

A personal digital library application built with Flutter and Dart, designed to organize, search, and manage digital documents across 17 auto-categorized shelves using on-device machine learning and local SQLite persistence.

---

## Key Features

- **Local SQLite Persistence**: Full document persistence using `sqflite` (`DocumentRepository` layer) with indexed queries across document titles and category shelves.
- **Global Multi-Shelf Search**: Full-text and category matching with in-search shelf filter chips, instant query responses, and location context display.
- **Extensible Theme System**: Multi-palette theme engine supporting Terracotta (Warm Cream) and Teal (Fresh Mint) palettes with instant live application and `shared_preferences` storage.
- **Native Gesture Navigation**: Smooth horizontal `PageView` tab switching (`All Items` -> `Books` -> `PDFs`) supporting real-time finger swipes and tap triggers without page reload flashing.
- **Pure Dart On-Device Machine Learning**: Zero-dependency TF-IDF vectorization and Softmax classification engine evaluating document metadata in under 0.1ms natively in Dart.
- **Automated Shelf Organization**: Automatic classification of imported PDF and EPUB documents into 17 target shelves with populated-first shelf ordering.

---

## Technical Architecture

```text
lib/
├── blocs/
│   ├── document_import/     # Document picker & text extraction BLoC
│   ├── shelf/               # Shelf items state management BLoC
│   └── theme/               # Active theme palette Cubit with SharedPreferences
├── models/
│   ├── mock_shelf_items.dart # Development mock data
│   └── shelf_state.dart      # Shelf item data models
├── screens/
│   ├── home_screen.dart     # PageView shelf list navigation
│   ├── search_screen.dart   # Title & category search interface
│   ├── settings_screen.dart # Theme selection & app preferences
│   └── shelf_detail_screen.dart # Shelf content detail view
├── services/
│   ├── document_repository.dart    # SQLite persistence layer via sqflite
│   ├── document_import_service.dart # File picking & PDF text extraction
│   └── shelf_classifier_service.dart # Pure Dart TF-IDF classification engine
├── theme/
│   ├── app_color_palette.dart # Palette definitions (Terracotta, Teal)
│   └── app_theme.dart        # Dynamic ThemeData generation
└── widgets/                  # Reusable UI components (ShelfCard, BookRow, AppHeader)
```

---

## Database Schema (`documents` Table)

```sql
CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  shelf TEXT NOT NULL,
  file_path TEXT NOT NULL,
  added_at TEXT NOT NULL
);

CREATE INDEX idx_documents_shelf ON documents(shelf);
CREATE INDEX idx_documents_title ON documents(title);
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

4. **Launch on macOS Desktop**:
   ```bash
   flutter run -d macos
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
