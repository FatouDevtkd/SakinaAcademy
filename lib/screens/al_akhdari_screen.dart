// lib/al_akhdari_screen.dart
import 'package:flutter/material.dart';
import 'package:sakina_ac/screens/media_player_screen.dart';

class AlAkhdariScreen extends StatelessWidget {
  const AlAkhdariScreen({super.key});

  static const List<Map<String, String>> episodes = [
    {'title': 'Épisode 1 : Introduction à Al Akhdari', 'url': 'assets/audios_clean/Al akhdari Intro.m4a'},
    {'title': 'Épisode 2 : Les actes de purification (I)', 'url': 'assets/audios_clean/Al Akhdari 1.m4a'},
    {'title': 'Épisode 3 : Les actes de purification (II)', 'url': 'assets/audios_clean/Al Akhdari 2.m4a'},
    {'title': 'Épisode 4 : Les conditions de la prière', 'url': 'assets/audios_clean/Al Akhdari 3.m4a'},
    {'title': 'Épisode 5 : Les piliers de la prière', 'url': 'assets/audios_clean/Al Akhdari 4.m4a'},
    {'title': 'Épisode 6 : Les sunan de la prière', 'url': 'assets/audios_clean/Al Akhdari 5.m4a'},
    {'title': 'Épisode 7 : Les annulatifs de la prière', 'url': 'assets/audios_clean/Al Akhdari 6.m4a'},
    {'title': 'Épisode 8 : La prière du voyageur', 'url': 'assets/audios_clean/Al Akhdari 7.m4a'},
    {'title': 'Épisode 9 : Les ablutions (wudūʾ)', 'url': 'assets/audios_clean/Al Akhdari 8.m4a'},
    {'title': 'Épisode 10 : Le tayammum', 'url': 'assets/audios_clean/Al Akhdari 9.m4a'},
    {'title': 'Épisode 11 : Le ghusl (grande purification)', 'url': 'assets/audios_clean/Al Akhdari 10.m4a'},
    {'title': 'Épisode 12 : Les temps de prière', 'url': 'assets/audios_clean/Al Akhdari 11.m4a'},
    {'title': 'Épisode 13 : Synthèse et révision', 'url': 'assets/audios_clean/Al Akhdari 12.m4a'},
  ];

  @override
  Widget build(BuildContext context) {
    const themeColor = Colors.teal;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Al Akhdari'),
        backgroundColor: themeColor,
      ),
      body: ListView.separated(
        itemCount: episodes.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return ListTile(
            leading: const Icon(Icons.audiotrack, color: Colors.teal),
            title: Text(episode['title']!),
            trailing: const Icon(Icons.play_arrow),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MediaPlayerScreen(
                    title: episode['title']!,
                    mediaUrl: episode['url']!,
                    isVideo: false,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
