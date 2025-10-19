import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yapper/features/auth/presentation/pages/spalsh_screen.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/profile/presentation/bloc/theme/theme_bloc.dart';
import 'features/profile/presentation/bloc/theme/theme_state.dart';
import 'injection_container.dart' as di;
import 'core/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // ignore: avoid_print
    print('Could not load .env file: $e');
  }

  // Initialize Supabase first so storage/auth clients are ready for DI or app use.
  try {
    await initializeSupabase();
  } catch (e) {
    // Don't crash the app here; surface the error in logs for the developer to fix.
    // In production you may want to rethrow or show an error screen.
    // ignore: avoid_print
    print('Supabase initialization error: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Ignore duplicate initialization errors
    if (!e.toString().contains('duplicate-app')) rethrow;
  }

  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<ThemeBloc>()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'Yappers',
            theme: themeState.themeData,
            home: SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
