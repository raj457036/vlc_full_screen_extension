import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:vlc_full_screen_extension/vlc_full_screen_extension.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final VlcPlayerController videoPlayerController;
  late final FullScreenController fullScreenController;

  @override
  void initState() {
    super.initState();

    videoPlayerController = VlcPlayerController.network(
      'https://media.w3.org/2010/05/sintel/trailer.mp4',
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    )..addOnInitListener(() {
        videoPlayerController.setLooping(true);
      });

    fullScreenController = FullScreenController(
      primary: videoPlayerController,
      builder: (context, playerController, fullScreenController) {
        final aspectRatio = MediaQuery.of(context).size.aspectRatio;

        return VlcPlayer(
          controller: playerController,
          aspectRatio: aspectRatio,
          placeholder: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  @override
  void dispose() async {
    super.dispose();
    fullScreenController.dispose();
    await videoPlayerController.stopRendererScanning();
    await videoPlayerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: VlcPlayer(
          controller: videoPlayerController,
          aspectRatio: 16 / 9,
          placeholder: const Center(child: CircularProgressIndicator()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          fullScreenController.enterFullScreen(context);
        },
        child: const Icon(Icons.fullscreen),
      ),
    );
  }
}
