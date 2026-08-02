import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/document_import/document_import_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/screens/home_screen.dart';
import 'package:the_shelf/services/shelf_classifier_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Kick off asynchronous asset loading for on-device classifier
  ShelfClassifierService.instance.ensureInitialized();

  runApp(const TheShelfApp());
}

class TheShelfApp extends StatelessWidget {
  const TheShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DocumentImportBloc>(
          create: (context) => DocumentImportBloc(),
        ),
        BlocProvider<ShelfBloc>(
          create: (context) => ShelfBloc()..add(const LoadShelfItemsEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'The Shelf',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2C4C3B), // Warm deep forest green
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(centerTitle: false),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2C4C3B),
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(centerTitle: false),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
