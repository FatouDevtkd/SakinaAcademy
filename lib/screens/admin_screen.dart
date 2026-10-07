import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sakina_ac/admin_access.dart';
import 'package:sakina_ac/screens/course_admin_screen.dart';
import 'package:sakina_ac/screens/registrer_screen.dart';

class AdminTab extends StatelessWidget {
  const AdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.setLanguageCode('fr');

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de connexion. Réessayez.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
        if (user == null) {
          // Pas connecté -> renvoyer vers l’écran d’auth (login/inscription)
          return const AuthScreen();
        }

        if (!isSakinaAdmin(user)) {
          return _NoAccessView(user: user);
        }

        return const AdminDashboard();
      },
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading:
                const Icon(Icons.verified_user_outlined, color: Colors.teal),
            title: const Text('Administratrices autorisées'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Administratrices'),
                content: Text(adminEmails.join('\n')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.teal),
            title: const Text('Déposer et publier des cours'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CourseManagerScreen(),
              ),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.quiz_outlined, color: Colors.teal),
            title: const Text('Créer des questionnaires'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const QuizManagerScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoAccessView extends StatelessWidget {
  final User user;
  const _NoAccessView({required this.user});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _resendVerificationEmail(BuildContext context) async {
    try {
      await user.sendEmailVerification();
      if (!context.mounted) return;
      _showMessage(
        context,
        'Un nouveau lien de vérification a été envoyé à ${user.email}.',
      );
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;
      _showMessage(
        context,
        'Impossible d’envoyer le lien : ${error.message ?? error.code}',
      );
    }
  }

  Future<void> _refreshEmailVerification(BuildContext context) async {
    try {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      await refreshedUser?.getIdToken(true);
      if (!context.mounted) return;
      final isVerified = refreshedUser?.emailVerified ?? false;
      _showMessage(
        context,
        isVerified
            ? 'Adresse e-mail vérifiée. L’accès administratrice est actualisé.'
            : 'Adresse non vérifiée. Ouvrez le lien reçu par e-mail, puis réessayez.',
      );
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;
      _showMessage(
        context,
        'Impossible d’actualiser la vérification : ${error.message ?? error.code}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthorizedEmail = isSakinaAdminEmail(user.email);
    final isVerified = user.emailVerified;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Accès réservé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isAuthorizedEmail
                  ? isVerified
                      ? 'L’accès admin n’a pas pu être confirmé pour ${user.email}.'
                      : 'Confirmez l’adresse ${user.email} avec le lien envoyé par e-mail, puis actualisez la vérification.'
                  : 'Connectez-vous avec une adresse administratrice autorisée.\nCompte actuel : ${user.email ?? 'inconnu'}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isAuthorizedEmail && !isVerified) ...[
              FilledButton.icon(
                onPressed: () => _resendVerificationEmail(context),
                icon: const Icon(Icons.mark_email_unread_outlined),
                label: const Text('Renvoyer le lien de vérification'),
              ),
              OutlinedButton.icon(
                onPressed: () => _refreshEmailVerification(context),
                icon: const Icon(Icons.refresh),
                label: const Text('J’ai vérifié — actualiser'),
              ),
            ] else if (isAuthorizedEmail)
              FilledButton.icon(
                onPressed: () => _refreshEmailVerification(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser l’accès admin'),
              )
            else
              FilledButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
          ],
        ),
      ),
    );
  }
}
