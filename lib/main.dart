import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/app_settings_storage.dart';
import 'services/session_notification_service.dart';

Future<void> main() async {
  // Verrouille l'orientation en portrait pour toute l'application : le
  // paysage n'est jamais autorisé, y compris pendant l'exécution d'une
  // séance. WidgetsFlutterBinding doit être initialisé avant tout appel
  // à un canal de plateforme comme SystemChrome.
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Requis par flutter_foreground_task pour que l'isolate principal
  // puisse recevoir les messages envoyés par le Foreground Service (voir
  // SessionNotificationService) — à appeler avant runApp, même si aucune
  // séance n'a encore démarré.
  SessionNotificationService.initCommunicationPort();

  // Le thème est résolu avant la première frame Flutter : l'écran de
  // démarrage natif reste visible pendant cette lecture très courte et aucun
  // thème intermédiaire incorrect n'est affiché.
  final settingsStorage = AppSettingsStorage();
  final initialThemeMode = await settingsStorage.loadThemeMode();

  runApp(
    MyApp(initialThemeMode: initialThemeMode, settingsStorage: settingsStorage),
  );
}

/// Racine de l'application : ne porte que la configuration globale
/// (thème, orientation) et le point d'entrée de navigation (HomePage).
/// Le reste (paramètres, écrans) vit dans ses propres fichiers sous
/// screens/, pour garder ce fichier minimal à mesure que l'app grandit.
class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.initialThemeMode = AppSettingsStorage.defaultThemeMode,
    this.settingsStorage,
  });

  final ThemeMode initialThemeMode;
  final AppSettingsStorage? settingsStorage;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Par défaut on suit le thème du système (clair/sombre), mais
  // l'utilisateur peut le forcer via l'écran Paramètres. Cet état reste
  // ici (à la racine) car MaterialApp.themeMode ne peut être piloté que
  // depuis le widget qui le construit ; il est transmis en cascade aux
  // écrans qui en ont besoin (HomePage -> SettingsScreen).
  late ThemeMode _themeMode;
  late final AppSettingsStorage _settingsStorage;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _settingsStorage = widget.settingsStorage ?? AppSettingsStorage();
  }

  Future<ThemeMode> _cycleThemeMode() async {
    final newMode = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };

    // Applique seulement une valeur confirmée par le stockage. En cas
    // d'échec, l'exception est traitée par Paramètres et l'état ne change pas.
    await _settingsStorage.saveThemeMode(newMode);
    if (mounted) setState(() => _themeMode = newMode);
    return newMode;
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.deepPurple;

    return MaterialApp(
      title: 'Mes entraînements',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
      ),

      home: HomePage(
        themeMode: _themeMode,
        onToggleTheme: _cycleThemeMode,
        settingsStorage: _settingsStorage,
      ),
    );
  }
}
