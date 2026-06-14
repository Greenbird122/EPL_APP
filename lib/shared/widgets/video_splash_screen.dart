import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// SharedPreferences key for whether the cinematic video splash has been shown.
const _videoSplashShownKey = 'video_splash_shown';

/// Returns true if the video splash hasn't been shown yet on this device.
Future<bool> shouldShowVideoSplash() async {
  final prefs = await SharedPreferences.getInstance();
  final shown = prefs.getBool(_videoSplashShownKey) ?? false;
  return !shown;
}

/// Marks the video splash as shown so it won't appear on subsequent launches.
Future<void> markVideoSplashShown() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_videoSplashShownKey, true);
}

/// A full-screen cinematic video splash that autoplays a background video,
/// applies dark gradient overlays, and shows REPAIR-AI branding with a
/// "Get Started" button.  Only displays on first launch.
class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key, required this.onGetStarted});

  /// Called when the user taps "Get Started".
  final VoidCallback onGetStarted;

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen>
    with TickerProviderStateMixin {
  late final VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _hasVideoError = false;
  bool _isExiting = false;

  // --- animation controllers ---
  late final AnimationController _fadeInController;
  late final Animation<double> _fadeIn;
  late final AnimationController _exitController;
  late final Animation<double> _exitFade;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset('assets/videos/video.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _isInitialized = true);
        _videoController
          ..setVolume(0) // muted
          ..setLooping(true)
          ..play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _hasVideoError = true);
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );
    _fadeInController.forward();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _exitController.dispose();
    _pulseController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Tap handler
  // ---------------------------------------------------------------

  Future<void> _onGetStarted() async {
    if (_isExiting) return;
    _isExiting = true;

    await markVideoSplashShown();

    _exitController.forward().then((_) {
      if (mounted) widget.onGetStarted();
    });
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;

    // Responsive typography – larger text on bigger screens.
    final double titleSize = shortestSide * 0.09;
    final double subtitleSize = shortestSide * 0.035;

    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        return Opacity(
          opacity: _exitFade.value,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ---- video layer ----
              _buildVideoLayer(),

              // ---- gradient overlays ----
              _buildGradientOverlays(),

              // ---- vignette border ----
              _buildVignette(),

              // ---- content ----
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: shortestSide * 0.06,
                    vertical: shortestSide * 0.08,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),

                      // Title
                      FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(_fadeInController),
                          child: Text(
                            'REPAIR-AI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleSize.clamp(28, 56),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 3,
                              height: 1.1,
                              shadows: const [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 24,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: shortestSide * 0.02),

                      // Subtitle
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Text(
                          'Maternal Health Platform',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: subtitleSize.clamp(14, 20),
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withAlpha(204),
                            letterSpacing: 1.2,
                            height: 1.4,
                          ),
                        ),
                      ),

                      SizedBox(height: shortestSide * 0.08),

                      // Get Started button
                      FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(_fadeInController),
                          child: SizedBox(
                            width: size.width * 0.75,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1A1A2E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 8,
                              ),
                              onPressed: _onGetStarted,
                              child: Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: subtitleSize.clamp(16, 20),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: shortestSide * 0.06),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // Layer builders
  // ---------------------------------------------------------------

  Widget _buildVideoLayer() {
    if (_hasVideoError || !_isInitialized) {
      if (_hasVideoError) {
        // Fallback: dark background with static splash content (handled by overlays above).
        return Container(color: const Color(0xFF0D0D1A));
      }
      // Loading: branded pulse animation.
      return Container(
        color: const Color(0xFF0D0D1A),
        child: Center(
          child: FadeTransition(
            opacity: _pulse,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'REPAIR-AI',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController.value.size.width,
          height: _videoController.value.size.height,
          child: VideoPlayer(_videoController),
        ),
      ),
    );
  }

  Widget _buildGradientOverlays() {
    return const IgnorePointer(
      child: Column(
        children: [
          // Top gradient – darkens the status bar area.
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Color(0xAA0D0D1A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom gradient – stronger dark fade near the CTA.
          Expanded(
            flex: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xDD0D0D1A),
                    Color(0xFF0A0A14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A soft inset shadow (vignette) around all edges.
  Widget _buildVignette() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D0D1A).withAlpha(140),
              blurRadius: 120,
              spreadRadius: 80,
            ),
          ],
        ),
      ),
    );
  }
}
