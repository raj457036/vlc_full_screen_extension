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

  bool fullScreen = false;
  bool reInit = false;

  @override
  void initState() {
    super.initState();

    videoPlayerController = VlcPlayerController.network(
      'https://media.w3.org/2010/05/sintel/trailer.mp4',
      hwAcc: HwAcc.full,
      autoPlay: true,
      autoInitialize: false,
      options: VlcPlayerOptions(),
    )
      ..addOnInitListener(() {
        videoPlayerController.setLooping(true);
      })
      ..addListener(() async {
        if (!videoPlayerController.value.isInitialized) return;
        if (reInit && videoPlayerController.value.isPlaying) {
          videoPlayerController
              .setTime(videoPlayerController.value.duration.inMilliseconds);
          reInit = false;
        }
      });

    fullScreenController = FullScreenController(
      primary: videoPlayerController,
      builder: (context, playerController, fullScreenController) {
        final aspectRatio = MediaQuery.of(context).size.aspectRatio;

        return CustomVlcPlayer(
          key: UniqueKey(),
          controller: playerController,
          aspectRatio: aspectRatio,
          placeholder: const Center(child: CircularProgressIndicator()),
        );
      },
    )..addListener(() {
        setState(() {
          fullScreen = fullScreenController.isFullScreen;
        });
      });
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
    final player = CustomVlcPlayer(
      key: const ValueKey("fullScreen"),
      controller: videoPlayerController,
      aspectRatio: 16 / 9,
      placeholder: const Center(child: CircularProgressIndicator()),
    );

    return WillPopScope(child: Builder(builder: (context) {
      if (fullScreen) {
        return player;
      }

      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: player,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            fullScreenController.enterFullScreen();
            reInit = true;
          },
          child: const Icon(Icons.fullscreen),
        ),
      );
    }), onWillPop: () async {
      if (fullScreen) {
        fullScreenController.exitFullScreen();
        reInit = true;
      }

      return false;
    });
  }
}
