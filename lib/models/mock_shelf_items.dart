import 'package:the_shelf/blocs/shelf/shelf_state.dart';

/// Mock data flag set to false so only real user files in SQLite database remain.
const bool showMockDataInDev = false;

/// Empty list for production / clean library state.
final List<ShelfItem> devMockShelfItems = [];
