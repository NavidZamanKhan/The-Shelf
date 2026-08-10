import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_event.dart';
import 'package:the_shelf/blocs/collection/collection_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_event.dart';
import 'package:the_shelf/blocs/document_import/document_import_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/screens/home_screen.dart';
import 'package:the_shelf/services/shelf_classifier_service.dart';
import 'package:the_shelf/theme/app_color_palette.dart';
import 'package:the_shelf/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase may not be configured on all platforms yet (e.g. macOS).
  // Wrap in try-catch so the app still launches; auth features will be
  // unavailable until platform-specific config files are added.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ Firebase init skipped: $e');
  }
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
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(const AuthStarted()),
        ),
        BlocProvider<DocumentImportBloc>(
          create: (context) => DocumentImportBloc(),
        ),
        BlocProvider<ShelfBloc>(
          create: (context) => ShelfBloc()..add(const LoadShelfItemsEvent()),
        ),
        BlocProvider<CollectionBloc>(
          create: (context) => CollectionBloc()..add(const LoadCollections()),
        ),
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit()..loadTheme(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, AppColorPalette>(
        builder: (context, activePalette) {
          return MaterialApp(
            title: 'The Shelf',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getThemeData(activePalette),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
