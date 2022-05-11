import 'package:flutter/widgets.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:flutter_vlc_player_platform_interface/flutter_vlc_player_platform_interface.dart';

final VlcPlayerPlatform vlcPlayerPlatform = VlcPlayerPlatform.instance
// This will clear all open videos on the platform when a full restart is
// performed.
  ..init();

class CustomVlcPlayer extends StatefulWidget {
  final VlcPlayerController controller;
  final double aspectRatio;
  final Widget? placeholder;
  final bool virtualDisplay;

  const CustomVlcPlayer(
      {Key? key,

      /// The [VlcPlayerController] responsible for the video being rendered in
      /// this widget.
      required this.controller,

      /// The aspect ratio used to display the video.
      /// This MUST be provided, however it could simply be (parentWidth / parentHeight) - where parentWidth and
      /// parentHeight are the width and height of the parent perhaps as defined by a LayoutBuilder.
      required this.aspectRatio,

      /// Before the platform view has initialized, this placeholder will be rendered instead of the video player.
      /// This can simply be a [CircularProgressIndicator] (see the example.)
      this.placeholder,

      /// Specify whether Virtual displays or Hybrid composition is used on Android.
      /// iOS only uses Hybrid composition.
      this.virtualDisplay = true})
      : super(key: key);

  @override
  _CustomVlcPlayerState createState() => _CustomVlcPlayerState();
}

class _CustomVlcPlayerState extends State<CustomVlcPlayer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  _CustomVlcPlayerState() {
    _listener = () {
      if (!mounted) return;
      //
      final isInitialized = widget.controller.value.isInitialized;
      if (isInitialized != _isInitialized) {
        setState(() {
          _isInitialized = isInitialized;
        });
      }
    };
  }

  late VoidCallback _listener;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _isInitialized = widget.controller.value.isInitialized;
    // Need to listen for initialization events since the actual initialization value
    // becomes available after asynchronous initialization finishes.
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(CustomVlcPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_listener);
      _isInitialized = widget.controller.value.isInitialized;
      widget.controller.addListener(_listener);
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        children: <Widget>[
          Offstage(
            offstage: _isInitialized,
            child: widget.placeholder ?? Container(),
          ),
          Offstage(
            offstage: !_isInitialized,
            child: vlcPlayerPlatform.buildView(onPlatformViewCreated,
                virtualDisplay: widget.virtualDisplay),
          ),
        ],
      ),
    );
  }

  Future<void> onPlatformViewCreated(int id) async {
    widget.controller.onPlatformViewCreated(id);
    widget.controller.value =
        widget.controller.value.copyWith(isInitialized: false);
    await widget.controller.initialize();
  }
}
