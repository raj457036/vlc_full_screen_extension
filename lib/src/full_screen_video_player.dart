import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

part 'full_screen_controller.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  const FullScreenVideoPlayer({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final FullScreenController controller;

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late final VlcPlayerController playerController;

  bool initialized = false;

  @override
  void initState() {
    createController();
    super.initState();
  }

  void createController() {
    final prevController = widget.controller.primary;

    if (prevController.dataSourceType == DataSourceType.network) {
      playerController = VlcPlayerController.network(
        prevController.dataSource,
        hwAcc: prevController.hwAcc,
        autoPlay: prevController.value.isPlaying,
        options: prevController.options,
      );
    }

    if (prevController.dataSourceType == DataSourceType.file) {
      final path = RegExp('file:///(.*)')
          .firstMatch(prevController.dataSource)
          ?.group(1);

      playerController = VlcPlayerController.file(
        File(path!),
        hwAcc: prevController.hwAcc,
        autoPlay: prevController.value.isPlaying,
        options: prevController.options,
      );
    }

    if (prevController.dataSourceType == DataSourceType.asset) {
      playerController = VlcPlayerController.asset(
        prevController.dataSource,
        hwAcc: prevController.hwAcc,
        autoPlay: prevController.value.isPlaying,
        options: prevController.options,
      );
    }
    prevController.pause();
    playerController
      ..addOnInitListener(() async {
        widget.controller.onInit?.call(playerController);
      })
      ..addListener(_playerListener);
  }

  Future<void> _playerListener() async {
    _seekToLastKnownPosition();
  }

  void _seekToLastKnownPosition() {
    final prevController = widget.controller.primary;
    if (!initialized && playerController.value.isPlaying) {
      final ts = prevController.value.position.inMilliseconds;
      playerController.setTime(ts);
      initialized = true;
    }
  }

  Future<void> reset() async {
    final prevController = widget.controller.primary;
    prevController.setTime(
      playerController.value.position.inMilliseconds,
    );
    if (playerController.value.isPlaying) {
      prevController.play();
    }
  }

  @override
  Future<void> dispose() async {
    super.dispose();

    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) async {
      reset();
      widget.controller.exitFullScreen();
      await playerController.stopRendererScanning();
      await playerController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.controller.builder(
      context,
      playerController,
      widget.controller,
    );
  }
}
