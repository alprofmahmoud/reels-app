import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reels Local',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ReelsScreen(),
    );
  }
}

class ReelsScreen extends StatefulWidget {
  @override
  _ReelsScreenState createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  List<File> videoFiles = [];
  int currentIndex = 0;
  late VideoPlayerController _controller;

  Future<void> pickFolderAndLoadVideos() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final dir = Directory(result);
      final files = dir.listSync()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      setState(() {
        videoFiles = files
            .where((f) => f.path.endsWith('.mp4') || f.path.endsWith('.MP4'))
            .map((e) => File(e.path))
            .toList();
        currentIndex = 0;
        _loadVideo();
      });
    }
  }

  void _loadVideo() {
    if (videoFiles.isEmpty) return;
    final file = videoFiles[currentIndex];
    _controller?.dispose();
    _controller = VideoPlayerController.file(file)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void initState() {
    super.initState();
    pickFolderAndLoadVideos(); // أول ما يفتح، يطلب فولدر
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reels Local'), actions: [
        IconButton(icon: Icon(Icons.folder), onPressed: pickFolderAndLoadVideos)
      ]),
      body: videoFiles.isEmpty
          ? Center(child: Text('No videos. Tap folder icon to select.'))
          : PageView.builder(
              onPageChanged: (index) {
                setState(() => currentIndex = index);
                _loadVideo();
              },
              itemCount: videoFiles.length,
              controller: PageController(viewportFraction: 1.0),
              itemBuilder: (context, index) {
                return Center(
                  child: videoFiles[index]..existsSync() && _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : CircularProgressIndicator(),
                );
              },
            ),
    );
  }
}
