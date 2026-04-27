import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SuccessScreen1 extends StatefulWidget {
  final String? nextRoute;
  final String? amount;

  const SuccessScreen1({super.key, this.nextRoute, this.amount});

  @override
  State<SuccessScreen1> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen1>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _popController;

  static const _gradStart = Color(0xFF60A5FA);
  static const _gradEnd = Color(0xFFA78BFA);

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _popController.dispose();
    super.dispose();
  }

  void _handleDone() {
    if (widget.nextRoute != null && widget.nextRoute!.isNotEmpty) {
      context.pushReplacement(widget.nextRoute!);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.2,
            colors: [Color(0xFF1E3A8A), Color(0xFF0F172A), Color(0xFF020617)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGlowCheck(),
                      const SizedBox(height: 36),
                      _buildTitle(),
                      const SizedBox(height: 10),
                      const Text(
                        "Your payment was processed securely.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildAmountCard(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: _buildGradientButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowCheck() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildPulseRing(0.0),
          _buildPulseRing(0.5),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _popController,
              curve: Curves.elasticOut,
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _gradStart.withOpacity(0.2),
                        _gradEnd.withOpacity(0.2),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _gradStart.withOpacity(0.4),
                        blurRadius: 60,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_gradStart, _gradEnd],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseRing(double phaseOffset) {
    return AnimatedBuilder(
      animation: _ringController,
      builder: (context, _) {
        final t = (_ringController.value + phaseOffset) % 1.0;
        final scale = 0.8 + 0.6 * t;
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _gradStart.withOpacity(0.4),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.white, Color(0xFFCBD5E1)],
      ).createShader(bounds),
      child: const Text(
        "All Done!",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    final amount = widget.amount;
    if (amount == null || amount.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "AMOUNT PAID",
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_gradStart, _gradEnd],
                ).createShader(bounds),
                child: Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradStart, _gradEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: _gradStart.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _handleDone,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded,
                    size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
