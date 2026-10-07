import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

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
  late final AudioPlayer _audioPlayer;
  late final Future<void> _initializeAudioPlayerFuture;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl));
      _initializeVideoPlayerFuture = _controller.initialize();
      _controller.setLooping(true);
    } else {
      _audioPlayer = AudioPlayer();
      _initializeAudioPlayerFuture =
          Uri.tryParse(widget.mediaUrl)?.hasScheme == true
              ? _audioPlayer.setUrl(widget.mediaUrl)
              : _audioPlayer.setAsset(widget.mediaUrl);
    }
  }

  @override
  void dispose() {
    if (widget.isVideo) {
      _controller.dispose();
    } else {
      _audioPlayer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: widget.isVideo
            ? FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_controller),
                          VideoProgressIndicator(_controller,
                              allowScrubbing: true),
                          Positioned(
                            bottom: 20,
                            child: IconButton(
                              icon: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                              onPressed: () {
                                setState(() {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              )
            : FutureBuilder<void>(
                future: _initializeAudioPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Impossible de charger cet audio : ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const CircularProgressIndicator();
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.audiotrack,
                          size: 100, color: Colors.teal),
                      const SizedBox(height: 20),
                      Text(
                        'Lecture audio : ${widget.title}',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<PlayerState>(
                        stream: _audioPlayer.playerStateStream,
                        builder: (context, playerSnapshot) {
                          final isPlaying =
                              playerSnapshot.data?.playing ?? false;
                          return IconButton.filled(
                            iconSize: 36,
                            onPressed: () async {
                              if (isPlaying) {
                                await _audioPlayer.pause();
                              } else {
                                await _audioPlayer.play();
                              }
                            },
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
