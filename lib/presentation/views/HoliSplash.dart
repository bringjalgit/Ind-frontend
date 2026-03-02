import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/widgets/CommonBackground.dart';

import '../../services/AuthService.dart';

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class HoliSplashscreen extends StatefulWidget {
  const HoliSplashscreen({super.key});

  @override
  State<HoliSplashscreen> createState() => _HoliSplashscreenState();
}

class _HoliSplashscreenState extends State<HoliSplashscreen> {
  late final VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();
    _setupVideo();
    _initialize();
    requestTrackingPermission();
  }

  /// 🔥 High-performance video setup
  void _setupVideo() {
    _controller = VideoPlayerController.asset(
      "assets/videos/holi.mp4",
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    _controller.initialize().then((_) {
      if (!mounted) return;

      _controller
        ..setLooping(false)
        ..setVolume(0)
        ..play();

      // Real-time listener instead of delayed timer
      _controller.addListener(_videoListener);

      setState(() {
        _isVideoInitialized = true;
      });
    });
  }

  /// 🔥 Navigate exactly when video ends (real-time)
  void _videoListener() {
    if (!_isNavigated &&
        _controller.value.isInitialized &&
        !_controller.value.isPlaying &&
        _controller.value.position >= _controller.value.duration) {
      _navigateToDashboard();
    }
  }

  Future<void> requestTrackingPermission() async {
    if (Platform.isIOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(milliseconds: 200));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }
  }

  Future<void> _initialize() async {
    await AuthService.getAccessToken();
  }

  void _navigateToDashboard() {
    if (!_isNavigated && mounted) {
      _isNavigated = true;
      context.pushReplacement("/dashboard");
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F5),
      body: Stack(
        children: [
          if (_isVideoInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),

          // if (!_isVideoInitialized)
          //   Center(
          //     child: Image.asset(
          //       "assets/images/appLogo.png",
          //       width: 200,
          //       height: 200,
          //     ),
          //   ),
        ],
      ),
    );
  }
}
