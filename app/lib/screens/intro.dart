import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Ochilish videosi (ovoz bilan), so‘ng ilovaga silliq o‘tadi.
/// Вступительное видео (со звуком), затем плавный переход в приложение.
class IntroVideo extends StatefulWidget {
  final VoidCallback onDone;
  const IntroVideo({super.key, required this.onDone});

  @override
  State<IntroVideo> createState() => _IntroVideoState();
}

class _IntroVideoState extends State<IntroVideo> {
  // Videoning oxirgi kadri rangi / цвет последнего кадра видео
  static const Color _bg = Color(0xFF00102A);

  late final VideoPlayerController _c = VideoPlayerController.asset(
    'assets/video/intro.mp4',
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );
  Timer? _guard;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Har qanday holatda ham 9 soniyadan keyin ilovaga o‘tamiz.
    // В любом случае через 9 секунд переходим в приложение.
    _guard = Timer(const Duration(seconds: 9), _finish);
    _start();
  }

  Future<void> _start() async {
    try {
      await _c.initialize();
      if (!mounted) return;
      _c.addListener(_onTick);
      // Brauzer ovozli videoni o‘zi boshlashga ruxsat bermaydi — ovozsiz boshlaymiz.
      // Браузер не даёт автозапуск со звуком — запускаем без звука.
      await _c.setVolume(kIsWeb ? 0 : 1.0);
      await _c.play();
      setState(() {});
    } catch (_) {
      _finish();
    }
  }

  void _onTick() {
    final v = _c.value;
    if (v.hasError) {
      _finish();
      return;
    }
    if (v.isInitialized && v.duration > Duration.zero && v.position >= v.duration - const Duration(milliseconds: 60)) {
      _finish();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _guard?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _guard?.cancel();
    _c.removeListener(_onTick);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _c.value.isInitialized;
    return ColoredBox(
      color: _bg,
      child: AnimatedOpacity(
        opacity: ready ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: ready
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _c.value.size.width,
                    height: _c.value.size.height,
                    child: VideoPlayer(_c),
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
