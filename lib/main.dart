import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Tes écrans
import 'screens/home_screen.dart';
import 'screens/registrer_screen.dart';
import 'screens/sakina_presentation_screen.dart';
import 'screens/admin_screen.dart' show AdminTab;

// Firebase options générées par `flutterfire configure`
import 'firebase_options.dart';

/// ------------------------------------------------------------
///                  PALETTE / THEME SAKINA
/// ------------------------------------------------------------
// Couleur principale (issue de ton image)
const sakinaGreen = Color(0xFF112623); // Vert profond Sakina
// Variante plus claire pour dégradés / hover
const sakinaGreenLight = Color(0xFF1E3A36); // Vert légèrement éclairci
// Variante sombre pour contraste (ex. texte clair sur fond vert)
// Variante sombre pour contraste (ex. texte clair sur fond vert)
const sakinaGreenDark = Color(0xFF0C1A18); // Encore plus sombre
// Couleur d’accent douce (mint)
const sakinaMint = Color(0xFFE6F4F1); // Fond clair pastel vert
// Bordures subtiles
const sakinaOutline = Color(0xFFB7CFCB); // Gris-vert doux

ThemeData sakinaLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: sakinaGreen,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
  );
}

ThemeData sakinaDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: sakinaGreen,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
  );
}

/// AppBar dégradé avec TabBar alignée à gauche
PreferredSizeWidget buildSakinaTabbedAppBar(TabBar tabBar) {
  return AppBar(
    titleSpacing: 12,
    title: const Text(
      'Sakina Academy',
      style: TextStyle(fontWeight: FontWeight.w800),
    ),
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [sakinaGreen, sakinaGreenDark],
        ),
      ),
    ),
    bottom: tabBar,
  );
}

/// ------------------------------------------------------------
///                       MAIN
/// ------------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SakinaApp());
}

class SakinaApp extends StatelessWidget {
  const SakinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sakina Academy',
      debugShowCheckedModeBanner: false,
      theme: sakinaLightTheme(),
      darkTheme: sakinaDarkTheme(),
      themeMode: ThemeMode.system,
      home: const SakinaRootTabs(), // ✅ Ouvre sur Présentation (onglet 0)
    );
  }
}

/// ------------------------------------------------------------
///                ROOT AVEC ONGLETS (Présentation / Accueil)
/// ------------------------------------------------------------
class SakinaRootTabs extends StatelessWidget {
  const SakinaRootTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      isScrollable: true, // ancré à gauche si peu d’onglets
      indicatorColor: Colors.white,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      tabs: const [
        Tab(text: 'Présentation'),
        Tab(text: 'Accueil'),
        Tab(icon: Icon(Icons.admin_panel_settings_outlined), text: 'Admin'),
      ],
    );

    return DefaultTabController(
      length: 3,
      initialIndex: 0, // ✅ ouvre sur Présentation
      child: Scaffold(
        appBar: buildSakinaTabbedAppBar(tabBar),
        body: const TabBarView(
          physics: BouncingScrollPhysics(),
          children: [
            // Onglet 1 : Présentation (public)
            SakinaPresentationPage(),

            // Onglet 2 : Accueil (protégé par l’auth)
            _AuthAwareHomeTab(),

            // 3) Admin (protégé par auth + email admin)
            AdminTab(),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
///     Onglet "Accueil" qui s’adapte à l’état d’auth Firebase
///  - Connecté   -> HomeScreen
///  - Non connecté -> AuthScreen (connexion/inscription)
/// ------------------------------------------------------------
class _AuthAwareHomeTab extends StatelessWidget {
  const _AuthAwareHomeTab();

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.setLanguageCode('fr');

    return ValueListenableBuilder<bool>(
      valueListenable: phoneSignupInProgress,
      builder: (context, signupInProgress, _) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de connexion. Réessayez.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null || signupInProgress) {
            return const AuthScreen();
          }

          return const HomeScreen();
        },
      ),
    );
  }
}
