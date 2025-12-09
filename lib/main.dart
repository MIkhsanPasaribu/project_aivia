import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// 🆕 Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'package:project_aivia/core/config/theme_config.dart';
import 'package:project_aivia/core/config/supabase_config.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/presentation/providers/theme_provider.dart';
import 'package:project_aivia/presentation/screens/splash/splash_screen.dart';
import 'package:project_aivia/presentation/screens/auth/login_screen.dart';
import 'package:project_aivia/presentation/screens/auth/register_screen.dart';
import 'package:project_aivia/presentation/screens/patient/patient_home_screen.dart';
import 'package:project_aivia/presentation/screens/family/family_home_screen.dart';
// 🆕 FCM Service import
import 'package:project_aivia/data/services/fcm_service.dart';
// 🆕 Notification Service import
import 'package:project_aivia/data/services/notification_service.dart';
// 🆕 Face Recognition Service import
import 'package:project_aivia/data/services/face_recognition_service.dart';

/// 🎯 Global Navigator Key untuk FCM notification tap handling
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🆕 Initialize Firebase FIRST (before Supabase)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🆕 Register background message handler (MUST be before any other Firebase code)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 🆕 Initialize Local Notifications
  await NotificationService.initialize();
  debugPrint('✅ Main: Notification service initialized');

  // 🆕 Initialize Face Recognition Service (load TFLite model)
  final faceRecognitionService = FaceRecognitionService();
  await faceRecognitionService.initialize();
  debugPrint('✅ Main: Face recognition service initialized');

  // Load environment variables dari .env
  await dotenv.load(fileName: ".env");

  // Initialize Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // 🆕 Initialize FCM Service (after Supabase for auth)
  // Note: Full initialization akan dipanggil setelah user login
  // Karena butuh user_id untuk save token ke database
  debugPrint('✅ Main: All services initialized');

  // 🆕 Set navigator key untuk FCM notification tap handling
  FCMService.setNavigatorKey(navigatorKey);

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
      navigatorKey: navigatorKey, // 🆕 Navigator key untuk FCM tap handling
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
