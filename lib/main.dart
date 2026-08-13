import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_event.dart';
import 'package:the_shelf/blocs/auth/auth_state.dart';
import 'package:the_shelf/blocs/collection/collection_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_event.dart';
import 'package:the_shelf/blocs/document_import/document_import_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/screens/auth_screen.dart';
import 'package:the_shelf/screens/home_screen.dart';
import 'package:the_shelf/screens/splash_screen.dart';
import 'package:the_shelf/services/shelf_classifier_service.dart';
import 'package:the_shelf/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization if configured
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
          create: (context) => AuthBloc()..add(const AuthCheckSession()),
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
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return _SystemBrightnessObserver(
            child: MaterialApp(
              title: 'The Shelf',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.getThemeData(themeState.resolvedPalette),
              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  // Polished startup navigation gate
                  if (authState is Authenticated) {
                    return const HomeScreen();
                  }
                  if (authState is Unauthenticated) {
                    return const AuthScreen();
                  }
                  // Show clean splash screen during session check (never flickers AuthScreen)
                  return const SplashScreen();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Observes system brightness changes and feeds them into ThemeCubit
/// for "System" mode auto-switching.
class _SystemBrightnessObserver extends StatefulWidget {
  final Widget child;
  const _SystemBrightnessObserver({required this.child});

  @override
  State<_SystemBrightnessObserver> createState() =>
      _SystemBrightnessObserverState();
}

class _SystemBrightnessObserverState extends State<_SystemBrightnessObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Feed initial platform brightness
    _updateBrightness();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _updateBrightness();
  }

  void _updateBrightness() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    context.read<ThemeCubit>().updatePlatformBrightness(brightness);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
