import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';

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

  runApp(const MyApp());
}

/// Racine de l'application : ne porte que la configuration globale
/// (thème, orientation) et le point d'entrée de navigation (HomePage).
/// Le reste (paramètres, écrans) vit dans ses propres fichiers sous
/// screens/, pour garder ce fichier minimal à mesure que l'app grandit.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Par défaut on suit le thème du système (clair/sombre), mais
  // l'utilisateur peut le forcer via l'écran Paramètres. Cet état reste
  // ici (à la racine) car MaterialApp.themeMode ne peut être piloté que
  // depuis le widget qui le construit ; il est transmis en cascade aux
  // écrans qui en ont besoin (HomePage -> SettingsScreen).
  ThemeMode _themeMode = ThemeMode.system;

  void _cycleThemeMode() {
    setState(() {
      _themeMode = switch (_themeMode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };
    });
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

      home: HomePage(themeMode: _themeMode, onToggleTheme: _cycleThemeMode),
    );
  }
}
