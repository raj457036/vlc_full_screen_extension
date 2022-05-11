import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

part 'full_screen_controller.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  const FullScreenVideoPlayer({
    Key? key,
    required this.controller,
    required this.play,
  }) : super(key: key);

  final bool play;
  final FullScreenController controller;

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late final VlcPlayerController playerController;

  bool active = false;
  bool initialized = false;

  @override
  void initState() {
    createController();
    super.initState();
  }

  Future<void> createController() async {
    final prevController = widget.controller.primary;
    log("IS PAUSED: ${await prevController.isPlaying()}");
    if (widget.controller.dataSourceType == DataSourceType.network) {
      playerController = VlcPlayerController.network(
        widget.controller.dataSource,
        hwAcc: prevController.hwAcc,
        autoPlay: widget.play,
        options: prevController.options,
      );
    }

    if (widget.controller.dataSourceType == DataSourceType.file) {
      final path = RegExp('file://(.*)')
          .firstMatch(widget.controller.dataSource)
          ?.group(1);

      playerController = VlcPlayerController.file(
        File(path!),
        hwAcc: prevController.hwAcc,
        autoPlay: widget.play,
        options: prevController.options,
      );
    }

    if (widget.controller.dataSourceType == DataSourceType.asset) {
      playerController = VlcPlayerController.asset(
        widget.controller.dataSource,
        hwAcc: prevController.hwAcc,
        autoPlay: widget.play,
        options: prevController.options,
      );
    }

    playerController
      ..addOnInitListener(() async {
        widget.controller.onInit?.call(playerController);
      })
      ..addListener(_playerListener);

    setState(() {
      active = true;
    });
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
    await prevController.setTime(
      playerController.value.position.inMilliseconds,
    );
    if (playerController.value.isPlaying) {
      Future.delayed(const Duration(milliseconds: 200), prevController.play);
    }
    await widget.controller.exitFullScreen();
    await playerController.stopRendererScanning();
    await playerController.dispose();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return widget.controller.builder(
      context,
      playerController,
      widget.controller,
    );
  }
}
