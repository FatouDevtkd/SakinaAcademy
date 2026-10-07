
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TafsirScreen extends StatelessWidget {
  const TafsirScreen({super.key});

  final List<Map<String, String>> episodes = const [
    {'title': 'Épisode 1 : Introduction au Tafsir', 'type': 'video', 'url': 'https://example.com/tafsir1.mp4'},
    {'title': 'Épisode 2 : Sourate Al-Fatiha', 'type': 'audio', 'url': 'https://example.com/fatiha.mp3'},
    {'title': 'Épisode 3 : Sourate Al-Baqara', 'type': 'video', 'url': 'https://example.com/baqara.mp4'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coran et Exégèse (Tafsir)'),
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
              subtitle: Text("Type : ${episode['type']}"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaPlayerScreen(
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

class MediaPlayerScreen extends StatefulWidget {
  final String title;
  final String mediaUrl;
  final bool isVideo;

  const MediaPlayerScreen({
    super.key,
    required this.title,
    required this.mediaUrl,
    required this.isVideo,
  });

  @override
  State<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends State<MediaPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl));
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.teal,
      ),
      body: widget.isVideo
          ? FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    VideoPlayer(_controller),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.audiotrack, size: 100, color: Colors.teal),
            const SizedBox(height: 16),
            Text('Lecture audio : {widget.title}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // À compléter avec un package audio comme just_audio
              },
              child: const Text('Lire l\'audio'),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.isVideo
          ? FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      )
          : null,
    );
  }
}
