import 'package:flutter/material.dart';
import 'package:sakina_ac/screens/video_player.dart';

class FiqhMalikiScreen extends StatelessWidget {
  const FiqhMalikiScreen({super.key});

  final List<Map<String, String>> episodes = const [
    {
      'title': 'Épisode 1 : Les sources du droit',
      'type': 'video',
      'url': 'https://example.com/fiqh1.mp4',
    },
    {
      'title': 'Épisode 2 : La purification',
      'type': 'audio',
      'url': 'https://example.com/purification.mp3',
    },
    {
      'title': 'Épisode 3 : La prière',
      'type': 'video',
      'url': 'https://example.com/priere.mp4',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurisprudence Malikite (Fiqh Maliki)'),
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
                episode['type'] == 'video' ? Icons.play_circle_fill : Icons.audiotrack,
                color: Colors.teal,
              ),
              title: Text(episode['title']!),
              subtitle: Text('Type : ${episode['type']}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(
                      title: episode['title']!,
                      mediaUrl: episode['url']!,
                      isVideo: episode['type'] == 'video',
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