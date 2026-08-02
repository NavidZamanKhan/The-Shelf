# The Shelf Mobile Application (`The-Shelf`)

Cross-platform Flutter client for **The Shelf**, a personal library and document management application that organizes books, articles, and digital files into auto-categorized shelves using on-device machine learning.

---

## Technical Overview

The application features a lightweight, zero-dependency on-device text classification engine implemented entirely in Pure Dart:

- **Pure Dart Inference Engine**: Executes sublinear TF-IDF vectorization, L2 normalization, linear transformation ($z = W \cdot v + b$), and Softmax probability computation natively in Dart without ONNX Runtime, TFLite, or native C++ FFI binaries.
- **Sub-Millisecond Latency**: Evaluates text predictions in less than 0.1 milliseconds per document directly on the client thread.
- **Multilingual Support**: Supports full Unicode text tokenization for English and Bengali document metadata.
- **Thread-Safe Model Lifecycle**: Implements memoized asynchronous asset loading (`ShelfClassifierService.instance.ensureInitialized()`) to prevent race conditions during startup or document import.
- **Document Text Extraction**: Integrates `read_pdf_text` for extracting plain text content from imported PDF documents across iOS and Android.
- **Interactive Classifier Verification**: Includes a built-in interactive debugger screen (`ClassifierDebugScreen`) for real-time model verification against pre-set sample inputs and custom text prompts.

---

## Repository Structure

```text
the_shelf/
├── assets/
│   └── models/
│       └── tfidf_model.json           # Model parameters (vocabulary, IDF, coef, intercept)
├── lib/
│   ├── main.dart                      # Application root and service initialization
│   ├── screens/
│   │   ├── home_screen.dart           # Tab navigation, floating action button, import modal
│   │   └── classifier_debug_screen.dart # Interactive model verification UI
│   └── services/
│       └── shelf_classifier_service.dart # Pure Dart TF-IDF + Logistic Regression engine
├── test/
│   ├── widget_test.dart               # Widget smoke tests
│   └── classifier_service_test.dart   # Automated classifier integration tests
└── pubspec.yaml                       # Flutter package dependencies and asset declarations
```

---

## Setup and Development

### Prerequisites

- Flutter SDK version `^3.12.2` or later
- Dart SDK included with Flutter
- Xcode (for iOS Simulator / iOS build)
- Android Studio / Android SDK (for Android build)

### 1. Dependency Resolution

Retrieve all pub packages specified in `pubspec.yaml`:

```bash
flutter pub get
```

### 2. Static Code Analysis

Run static analysis to verify code quality and rule compliance:

```bash
flutter analyze
```

### 3. Automated Test Suite

Execute unit, widget, and classifier service integration tests:

```bash
flutter test
```

### 4. Running the Application

Launch the application on your target platform:

#### macOS Desktop Target (Fastest Launch)
```bash
flutter run -d macos
```

#### iOS Simulator Target
```bash
flutter emulators --launch apple_ios_simulator
flutter run -d iphone
```

#### Android Emulator Target
```bash
flutter emulators --launch Pixel_9_Pro_XL
flutter run -d android
```

---

## Architecture & Service Layer API

### Service Usage Example

```dart
import 'package:the_shelf/services/shelf_classifier_service.dart';

// 1. Ensure model parameters are loaded from rootBundle asset
await ShelfClassifierService.instance.ensureInitialized();

// 2. Perform synchronous classification on text
final ClassificationResult result = ShelfClassifierService.instance.classify(
  'A dark wizard threatens the magical kingdom with ancient dark spells'
);

print('Predicted Shelf: ${result.label}');
print('Confidence: ${(result.confidence * 100).toStringAsFixed(2)}%');
print('Latency: ${result.latencyMs} ms');
```

---

## Target Shelf Categories (17 Shelves)

1. Fantasy
2. Historical Fiction
3. Mystery
4. Romance
5. Science Fiction
6. Horror
7. Thriller
8. Young Adult
9. Graphic Novels & Comics
10. Anime & Manga
11. Children's
12. Poetry
13. History
14. Biography & Memoir
15. Philosophy
16. Self-Help & Personal Development
17. Miscellaneous
