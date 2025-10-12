import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_aivia/core/config/theme_config.dart';
import 'package:project_aivia/core/config/supabase_config.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/presentation/providers/theme_provider.dart';
import 'package:project_aivia/presentation/screens/splash/splash_screen.dart';
import 'package:project_aivia/presentation/screens/auth/login_screen.dart';
import 'package:project_aivia/presentation/screens/auth/register_screen.dart';
import 'package:project_aivia/presentation/screens/patient/patient_home_screen.dart';
import 'package:project_aivia/presentation/screens/family/family_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables dari .env
  await dotenv.load(fileName: ".env");

  // Initialize Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode dari provider
    final themeMode = ref.watch(currentThemeModeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // Theme configuration dengan dark mode support
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: themeMode,

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/patient/home': (context) => const PatientHomeScreen(),
        '/family/home': (context) => const FamilyHomeScreen(),
      },
    );
  }
}
