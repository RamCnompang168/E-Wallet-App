import 'package:flutter/material.dart';
import 'core/services/auth_state.dart';
import 'core/services/in_app_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthState.instance.init();
  runApp(const NovaPayApp());
}

class NovaPayApp extends StatefulWidget {
  const NovaPayApp({super.key});

  @override
  State<NovaPayApp> createState() => _NovaPayAppState();
}

class _NovaPayAppState extends State<NovaPayApp> {
  ThemeMode mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: InAppNotificationService.navigatorKey,
    debugShowCheckedModeBanner: false,
    title: 'NovaPay',
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: mode,
    home: SplashScreen(
      onThemeChanged: () => setState(
        () => mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      ),
    ),
  );
}
