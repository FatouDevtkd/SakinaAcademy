import 'package:flutter/material.dart';

// Exemple de MediaPlayerScreen à adapter selon ton besoin
class MediaPlayerScreen extends StatelessWidget {
  final String title;
  final String url;
  final String type;

  const MediaPlayerScreen({
    super.key,
    required this.title,
    required this.url,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Text('Lecture du média : $type\nURL : $url'),
      ),
    );
  }
}

class TheologieAqidaScreen extends StatelessWidget {
  const TheologieAqidaScreen({super.key});

  final List<Map<String, String>> episodes = const [
    {
      'title': 'Épisode 1 : Introduction à l’Aqida',
      'type': 'video',
      'url': 'https://example.com/video1.mp4',
    },
    {
      'title': 'Épisode 2 : Les fondements de la foi',
      'type': 'audio',
      'url': 'https://example.com/audio2.mp3',
    },
    {
      'title': 'Épisode 3 : Tawhid et ses implications',
      'type': 'video',
      'url': 'https://example.com/video3.mp4',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Théologie (Aqida)'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: episodes.length,
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(
                episode['type'] == 'video'
                    ? Icons.play_circle_fill
                    : Icons.audiotrack,
                color: Colors.teal,
              ),
              title: Text(episode['title']!),
              subtitle: Text('Type : ${episode['type']}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaPlayerScreen(
                      title: episode['title']!,
                      url: episode['url']!,
                      type: episode['type']!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}