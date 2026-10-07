// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sakina_ac/admin_access.dart';
import 'package:sakina_ac/screens/admin_screen.dart' show AdminDashboard;
import 'package:sakina_ac/screens/course_admin_screen.dart';

// Présentation
import 'package:sakina_ac/screens/sakina_presentation_screen.dart';

// Écrans de matières
import 'package:sakina_ac/screens/theologie_aqida_screen.dart';
import 'package:sakina_ac/screens/histoires_prophetes_screen.dart';
import 'package:sakina_ac/screens/sirah_nabawiyyah_screen.dart';
import 'package:sakina_ac/screens/tafsir_screen.dart';
import 'package:sakina_ac/screens/fiqh_maliki_screen.dart';
import 'package:sakina_ac/screens/ulum_hadith_screen.dart';
import 'package:sakina_ac/screens/langue_arabe_screen.dart';
import 'package:sakina_ac/screens/al_akhdari_screen.dart';

/// ------------------------------------------------------------
///                       PALETTE SAKINA
/// ------------------------------------------------------------
const sakinaGreen = Color(0xFF112623); // Vert principal (depuis ton image)
const sakinaGreenLight = Color(0xFF1E3A36); // Nuance plus claire (dégradé)
const sakinaMint = Color(0xFFE6F4F1); // Fond clair
const sakinaOutline = Color(0xFFB7CFCB); // Bordures subtiles

/// Logo réutilisable
class SakinaLogo extends StatelessWidget {
  final double size;
  const SakinaLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_sakina.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.school, size: size, color: Colors.grey.shade500),
    );
  }
}

/// AppBar avec dégradé et logo
PreferredSizeWidget buildSakinaAppBar(String title,
    {List<Widget>? actions, Widget? bottom}) {
  return AppBar(
    titleSpacing: 12,
    title: Row(
      children: [
        const SakinaLogo(size: 28),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
    actions: actions,
    bottom: bottom as PreferredSizeWidget?,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [sakinaGreen, sakinaGreenLight],
        ),
      ),
    ),
  );
}

/// Élément typé pour la liste des matières
class SubjectItem {
  final String title;
  final WidgetBuilder builder;
  const SubjectItem({required this.title, required this.builder});
}

/// ------------------------------------------------------------
///                      HOME SCREEN
/// ------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final List<SubjectItem> subjects = [
    SubjectItem(
        title: 'Théologie (Aqida)',
        builder: (_) => const TheologieAqidaScreen()),
    SubjectItem(
        title: 'Histoire des prophètes (Qasas Al-Anbiya)',
        builder: (_) => const HistoireProphetesScreen()),
    SubjectItem(
        title: 'Biographie du Prophète ﷺ (Sîrah Nabawiyyah)',
        builder: (_) => const SirahNabawiyyahScreen()),
    SubjectItem(
        title: 'Coran et Exégèse (Tafsir)',
        builder: (_) => const TafsirScreen()),
    SubjectItem(
        title: 'Jurisprudence Malikite (Fiqh Maliki)',
        builder: (_) => const FiqhMalikiScreen()),
    SubjectItem(
        title: 'Sciences du Hadith (Ulum al-Hadith)',
        builder: (_) => const UlumHadithScreen()),
    SubjectItem(
        title: 'Langue Arabe (pour débutants)',
        builder: (_) => const LangueArabeScreen()),
    SubjectItem(title: 'Al Akhdari', builder: (_) => const AlAkhdariScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = sakinaGreen;

    return Scaffold(
      appBar: buildSakinaAppBar(
        'Sakina Academy',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'À propos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SakinaPresentationPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                // Si tu utilises un AuthRouter, la redirection se fera automatiquement.
                // Sinon, tu peux pousser AuthScreen :
                // if (context.mounted) {
                //   Navigator.of(context).pushAndRemoveUntil(
                //     MaterialPageRoute(builder: (_) => const AuthScreen()),
                //     (route) => false,
                //   );
                // }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Erreur lors de la déconnexion : $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const SakinaLogo(size: 88),
          const SizedBox(height: 8),
          const Text(
            'Sakina Academy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: sakinaGreen,
            ),
          ),
          const SizedBox(height: 8),

          // Bandeau d’accueil doux
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sakinaMint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sakinaOutline),
            ),
            child: Row(
              children: const [
                Icon(Icons.menu_book_outlined, color: sakinaGreen),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bienvenue 👋  Explore les matières de la Sakina Academy',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Bloc Admin (affiché uniquement si l’utilisatrice admin est connectée)
          const _AdminCard(),

          const SizedBox(height: 8),

          // Liste des matières
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: subjects.length + 1,
              itemBuilder: (context, index) {
                if (index == subjects.length) {
                  return const PublishedCoursesSection();
                }
                final subject = subjects[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: sakinaOutline),
                  ),
                  elevation: 1.5,
                  shadowColor: primary.withValues(alpha: 0.10),
                  child: ListTile(
                    leading: Container(
                      decoration: BoxDecoration(
                        color: sakinaMint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                      child:
                          const Icon(Icons.school_outlined, color: sakinaGreen),
                    ),
                    title: Text(
                      subject.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: sakinaGreen),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: subject.builder),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
///                   BLOC ADMIN (conditionnel)
/// ------------------------------------------------------------
class _AdminCard extends StatelessWidget {
  const _AdminCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        if (!isSakinaAdmin(snap.data)) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: sakinaOutline),
          ),
          elevation: 1.5,
          shadowColor: sakinaGreen.withValues(alpha: 0.10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: sakinaGreen),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Espace administratrice',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings,
                      color: sakinaGreen),
                  label: const Text('Ouvrir'),
                  style: TextButton.styleFrom(foregroundColor: sakinaGreen),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ------------------------------------------------------------
///              ADMIN SCREEN (placeholder simple)
/// ------------------------------------------------------------
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSakinaAppBar('Administration'),
      body: const AdminDashboard(),
    );
  }
}
