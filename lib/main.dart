import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';
import 'firebase_options.dart';
import 'core/theme/bedrock_theme.dart';

// Services
import 'core/services/firebase_auth_service.dart';
import 'core/services/geolocator_location_service.dart';
import 'core/services/local_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/datasources/remote/firestore_user_datasource.dart';
import 'data/datasources/remote/firestore_hazard_datasource.dart';
import 'data/datasources/remote/open_meteo_datasource.dart';
import 'data/datasources/remote/usgs_earthquake_datasource.dart';
import 'data/datasources/remote/reliefweb_datasource.dart';

// Repositories
import 'data/repositories/user_repository.dart';
import 'data/repositories/hazard_repository.dart';
import 'data/repositories/weather_repository.dart';
import 'data/repositories/earthquake_repository.dart';
import 'data/repositories/reliefweb_repository.dart';

// Providers
import 'core/providers/auth_provider.dart';
import 'core/providers/user_profile_provider.dart';
import 'core/providers/hazard_feed_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/weather_provider.dart';
import 'core/providers/radar_provider.dart';
import 'core/providers/earthquake_provider.dart';
import 'core/providers/reliefweb_provider.dart';
import 'core/providers/broadcast_provider.dart';

// Import all screens for the Phase 2 Named Routes setup
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/permission_primer_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/signup_screen.dart';
import 'presentation/screens/forgot_password_screen.dart';
import 'presentation/screens/main_shell.dart';
import 'presentation/screens/hazard_report_screen.dart';
import 'presentation/screens/hazard_detail_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/flutter_widgets_lab_screen.dart';
import 'presentation/screens/admin_panel_screen.dart';

// The main entrypoint function of the Flutter application.
// Official Reference: https://docs.flutter.dev/cookbook/navigation/named-routes
void main() async {
  // WidgetsFlutterBinding.ensureInitialized() guarantees that the Flutter widget engine is fully
  // booted and binding handles are ready before we execute the runApp method.
  // Reference: https://api.flutter.dev/flutter/widgets/WidgetsFlutterBinding/ensureInitialized.html
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Pass all uncaught Flutter errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    // Initialize App Check for app attestation security
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
    // Configure Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint(
      'Firebase initialization failed: $e. Running in offline/mock standby mode.',
    );
  }

  final authService = FirebaseAuthService();
  final locationService = GeolocatorLocationService();
  final userDataSource = FirestoreUserDataSource();
  final userRepository = UserRepository(userDataSource);
  final hazardDataSource = FirestoreHazardDataSource();
  final hazardRepository = HazardRepository(hazardDataSource);
  final weatherDataSource = OpenMeteoWeatherDataSource();
  final weatherRepository = WeatherRepository(weatherDataSource);
  final earthquakeDataSource = UsgsEarthquakeDataSource();
  final earthquakeRepository = EarthquakeRepository(earthquakeDataSource);
  final reliefWebDataSource = ReliefWebDataSource();
  final reliefWebRepository = ReliefWebRepository(reliefWebDataSource);

  // start the app layout by running BedrockApp as our root widget.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(
          create: (_) => LocationProvider(locationService),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProfileProvider(userRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => HazardFeedProvider(hazardRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => WeatherProvider(weatherRepository),
        ),
        ChangeNotifierProvider(create: (_) => RadarProvider()),
        ChangeNotifierProvider(
          create: (_) => EarthquakeProvider(earthquakeRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ReliefWebProvider(reliefWebRepository),
        ),
        ChangeNotifierProvider(create: (_) => BroadcastProvider()),
      ],
      child: const BedrockApp(),
    ),
  );
}

// BedrockApp is a StatelessWidget (immutability) because the global configuration (theme, title)
// of the MaterialApp itself does not change dynamically during runtime.
// Reference: https://docs.flutter.dev/ui/widgets-intro
class BedrockApp extends StatelessWidget {
  const BedrockApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp acts as the wrapper to set up the Material Design visual system.
    // It configures themes, localizations, navigator routes, and the global widget overlay.
    // Reference: https://api.flutter.dev/flutter/material/MaterialApp-class.html
    return MaterialApp(
      title: 'Bedrock Abbottabad',
      // Disable the red "DEBUG" banner at the top right of the screen.
      debugShowCheckedModeBanner: false,

      // Theme settings: Lock the app strictly into the dark AMOLED theme.
      // Reference: https://docs.flutter.dev/cookbook/design/themes
      theme: BedrockTheme.darkTheme,
      darkTheme: BedrockTheme.darkTheme,
      themeMode: ThemeMode.dark, // Enforces darkTheme mode exclusively.
      // Phase 2 Named Routes routing configurations
      // Rather than manually instantiating MaterialPageRoute, named routes reference screens
      // by string identifiers.
      // Reference: https://docs.flutter.dev/cookbook/navigation/named-routes
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/permission': (context) => const PermissionPrimerScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/main': (context) => const MainShell(),
        '/hazard_report': (context) => const HazardReportScreen(),
        '/hazard_detail': (context) => const HazardDetailScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/widgets_lab': (context) => const FlutterWidgetsLabScreen(),
        '/admin_panel': (context) => const AdminPanelScreen(),
      },
    );
  }
}
