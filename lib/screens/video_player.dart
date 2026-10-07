import 'package:flutter/material.dart';

class VideoPlayerScreen extends StatelessWidget {
  final String title;
  final String mediaUrl;
  final bool isVideo;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.mediaUrl,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          isVideo ? 'Lecture vidéo : $mediaUrl' : 'Lecture audio : $mediaUrl',
        ),
      ),
    );
  }
}