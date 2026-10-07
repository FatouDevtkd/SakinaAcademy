import 'package:flutter/material.dart';


// Palette (si déjà définie chez toi, garde la tienne)
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

// Logo réutilisable + Hero pour une transition fluide entre écrans
class SakinaLogo extends StatelessWidget {
  final double size;
  final bool rounded; // si ton logo est carré, tu peux arrondir légèrement
  const SakinaLogo({super.key, this.size = 56, this.rounded = false});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/logo.jpg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    final logo = rounded
        ? ClipRRect(borderRadius: BorderRadius.circular(size * 0.2), child: image)
        : image;

    return Hero(tag: 'sakina-logo', child: logo);
  }
}

// AppBar en dégradé vert AVEC logo + titre
PreferredSizeWidget buildSakinaAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    titleSpacing: 12,
    title: Row(
      children: [
        const SakinaLogo(size: 28), // Hero fonctionne aussi depuis Login
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
    actions: actions,
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
