import 'package:flutter/material.dart';

// Couleur principale (issue de ton image)
const sakinaGreen = Color(0xFF112623);     // Vert profond Sakina
// Variante plus claire pour dégradés / hover
const sakinaGreenLight = Color(0xFF1E3A36); // Vert légèrement éclairci
// Variante sombre pour contraste (ex. texte clair sur fond vert)
const sakinaGreenDark = Color(0xFF0C1A18);  // Encore plus sombre
// Couleur d’accent douce (mint)
const sakinaMint = Color(0xFFE6F4F1);       // Fond clair pastel vert
// Bordures subtiles
const sakinaOutline = Color(0xFFB7CFCB);    // Gris-vert doux

class SakinaPresentationPage extends StatelessWidget {
  const SakinaPresentationPage({super.key});

  PreferredSizeWidget buildSakinaAppBar(String title) {
    return AppBar(
      titleSpacing: 12,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.jpg',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSakinaAppBar('À propos de Sakina'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [sakinaMint, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo centré
              Center(
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),

              // Titre principal
              Text(
                "Sakina, c’est avant tout un groupe de femmes unies par la soif de connaissance et le désir de grandir ensemble dans la foi.\n\n"
                    "Notre objectif est simple : offrir à chaque femme un espace bienveillant pour apprendre, partager et s’épanouir dans l’islam. "
                    "Chez Sakina, nous croyons que la quête du savoir est un droit, mais aussi un devoir pour chaque musulmane. "
                    "C’est pourquoi nous mettons l’accent sur l’accès à la science religieuse, l’entraide et la sororité.\n\n"
                    "Sakina, c’est aussi un lieu d’échange, de respect et de fraternité, où chacune peut poser ses questions, partager ses expériences et avancer à son rythme. "
                    "Ensemble, nous nous engageons dans une quête perpétuelle du savoir, convaincues que chaque pas vers la connaissance est un pas vers la lumière.",
                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
              ),
              const SizedBox(height: 24),

              // Citation stylée
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: sakinaGreen.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "« Celui qui emprunte un chemin par lequel il recherche une science, Allah lui fait prendre par cela un chemin vers le paradis. "
                          "Certes, les anges tendent leurs ailes par agrément pour celui qui recherche la science… »",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                        color: sakinaGreenDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "(Rapporté par Abou Daoud et authentifié par Cheikh Albani)",
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Message final
              Text(
                "Bienvenue chez Sakina, là où la femme retrouve sa place dans l’apprentissage de l’islam.",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: sakinaGreenDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}