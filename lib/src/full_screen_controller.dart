part of 'full_screen_video_player.dart';

class FullScreenController with ChangeNotifier {
  FullScreenController({
    required this.primary,
    required this.builder,
    this.onInit,
  }) {
    dataSource = primary.dataSource;
    dataSourceType = primary.dataSourceType;
  }

  final VlcPlayerController primary;

  final Widget Function(
    BuildContext context,
    VlcPlayerController playerController,
    FullScreenController fullScreenController,
  ) builder;

  final void Function(VlcPlayerController controller)? onInit;

  late String dataSource;
  late DataSourceType dataSourceType;

  void setDataSource(String dataSource, DataSourceType dataSourceType) {
    this.dataSource = dataSource;
    this.dataSourceType = dataSourceType;
    notifyListeners();
  }

  bool _fullScreen = false;

  /// Whether the video is in full screen mode.
  bool get isFullScreen => _fullScreen;

  /// exit full screen mode
  Future<void> exitFullScreen([BuildContext? context]) async {
    if (!_fullScreen) return;

    await Future.wait([
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    ]);
    if (context != null) {
      Future.delayed(Duration.zero, () => Navigator.of(context).pop());
    }
    _fullScreen = false;
    notifyListeners();
  }

  /// enter full screen mode
  Future<void> enterFullScreen(BuildContext context) async {
    if (_fullScreen) return;
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return AnimatedBuilder(
          animation: CurvedAnimation(
            curve: Curves.ease,
            parent: animation,
            reverseCurve: Curves.ease,
          ),
          builder: (BuildContext context, Widget? child) {
            return FullScreenVideoPlayer(
              controller: this,
            );
          },
        );
      },
    );
    await Future.wait([
      _setOrientationForVideo(),
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    ]);
    Future.delayed(Duration.zero, () => Navigator.push(context, route));

    _fullScreen = true;

    notifyListeners();
  }

  Future<void> _setOrientationForVideo() async {
    final double videoWidth = primary.value.size.width;
    final double videoHeight = primary.value.size.height;
    final bool isLandscapeVideo = videoWidth > videoHeight;
    final bool isPortraitVideo = videoWidth < videoHeight;

    /// if video has more width than height set landscape orientation
    if (isLandscapeVideo) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    /// otherwise set portrait orientation
    else if (isPortraitVideo) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    /// if they are equal allow both
    else {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }
}
