import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';
import 'dart:math' as math;

class PremiumUpgradeDialog extends StatefulWidget {
  final bool isForceUpdate;
  final String? releaseNotes;
  final Function() onUpdatePressed;

  const PremiumUpgradeDialog({
    required this.isForceUpdate,
    required this.releaseNotes,
    required this.onUpdatePressed,
  });

  @override
  State<PremiumUpgradeDialog> createState() => PremiumUpgradeDialogState();
}

class PremiumUpgradeDialogState extends State<PremiumUpgradeDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();

    // Dialog entrance animations
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Icon animation (continuous)
    _iconController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Stagger animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeHelper.isDarkMode(context);
    final backgroundColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);

    // Get primary color (adjust based on your AppColors)
    const primaryColor = Color(0xff194795);
    const accentColor = Color(0xff4A90E2);

    return FadeTransition(
      opacity: _fadeController,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
        ),
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: primaryColor.withOpacity(0.08),
                  blurRadius: 80,
                  spreadRadius: 0,
                  offset: const Offset(0, 40),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [
                              cardColor,
                              cardColor.withOpacity(0.8),
                              Color(0xFF2A2A2A),
                            ]
                          : [
                              Colors.white,
                              Colors.white.withOpacity(0.95),
                              Colors.grey.shade50,
                            ],
                    ),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated Icon
                          _AnimatedUpdateIcon(
                            controller: _iconController,
                            isDarkMode: isDarkMode,
                          ),

                          const SizedBox(height: 28),

                          // Title
                          SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _slideController,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [primaryColor, accentColor],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Update Available! 🚀',
                                    style:
                                        AppTextStyles.headlineSmall(
                                          Colors.white,
                                        ).copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Get the latest features & improvements',
                                  style: AppTextStyles.bodyMedium(
                                    isDarkMode
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ).copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // // Release Notes
                          // if (widget.releaseNotes != null &&
                          //     widget.releaseNotes!.isNotEmpty)
                          //   SlideTransition(
                          //     position:
                          //         Tween<Offset>(
                          //           begin: const Offset(0, 0.2),
                          //           end: Offset.zero,
                          //         ).animate(
                          //           CurvedAnimation(
                          //             parent: _slideController,
                          //             curve: const Interval(
                          //               0.2,
                          //               1,
                          //               curve: Curves.easeOutCubic,
                          //             ),
                          //           ),
                          //         ),
                          //     child: Container(
                          //       padding: const EdgeInsets.all(16),
                          //       decoration: BoxDecoration(
                          //         color: isDarkMode
                          //             ? Colors.white.withOpacity(0.05)
                          //             : Colors.black.withOpacity(0.02),
                          //         borderRadius: BorderRadius.circular(16),
                          //         border: Border.all(
                          //           color: isDarkMode
                          //               ? Colors.white.withOpacity(0.08)
                          //               : Colors.black.withOpacity(0.05),
                          //         ),
                          //       ),
                          //       child: Column(
                          //         crossAxisAlignment: CrossAxisAlignment.start,
                          //         children: [
                          //           Text(
                          //             "What's New",
                          //             style: AppTextStyles.titleMedium(
                          //               textColor,
                          //             ).copyWith(fontWeight: FontWeight.w600),
                          //           ),
                          //           const SizedBox(height: 12),
                          //           Text(
                          //             widget.releaseNotes ?? '',
                          //             style:
                          //                 AppTextStyles.bodySmall(
                          //                   isDarkMode
                          //                       ? Colors.grey.shade300
                          //                       : Colors.grey.shade700,
                          //                 ).copyWith(
                          //                   height: 1.6,
                          //                   fontWeight: FontWeight.w500,
                          //                 ),
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   )
                          // else
                          SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _slideController,
                                    curve: const Interval(
                                      0.2,
                                      1,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                                ),
                            child: Text(
                              'A new version of the app is available with improvements, fixes, and new features.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium(
                                isDarkMode
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ).copyWith(height: 1.6),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Features List (if force update)
                          if (widget.isForceUpdate)
                            SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _slideController,
                                      curve: const Interval(
                                        0.3,
                                        1,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_rounded,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'This version is required to continue using the app',
                                        style: AppTextStyles.bodySmall(
                                          primaryColor,
                                        ).copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 28),

                          // Buttons
                          SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _slideController,
                                    curve: const Interval(
                                      0.4,
                                      1,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                                ),
                            child: Column(
                              children: [
                                // Update Button
                                _AnimatedButton(
                                  label: 'Update Now',
                                  icon: Icons.download_rounded,
                                  onPressed: () {
                                    widget.onUpdatePressed();
                                  },
                                  isPrimary: true,
                                  isDarkMode: isDarkMode,
                                ),

                                if (!widget.isForceUpdate) ...[
                                  const SizedBox(height: 12),
                                  // Later Button
                                  _AnimatedButton(
                                    label: 'Maybe Later',
                                    icon: Icons.schedule_rounded,
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    isPrimary: false,
                                    isDarkMode: isDarkMode,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Animated Update Icon
class _AnimatedUpdateIcon extends StatelessWidget {
  final AnimationController controller;
  final bool isDarkMode;

  const _AnimatedUpdateIcon({
    required this.controller,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff194795);
    const accentColor = Color(0xff4A90E2);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer rotating circle
        RotationTransition(
          turns: controller,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.3),
                  accentColor.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
                width: 2,
              ),
            ),
          ),
        ),

        // Middle pulsing circle
        ScaleTransition(
          scale: Tween<double>(begin: 1, end: 1.1).animate(
            CurvedAnimation(
              parent: controller,
              curve: const Interval(0, 0.5, curve: Curves.easeInOut),
            ),
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, accentColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: RotationTransition(
                turns: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(parent: controller, curve: Curves.linear),
                ),
                child: Icon(
                  Icons.system_update_alt_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Floating particles effect
        ..._buildFloatingParticles(controller),
      ],
    );
  }

  List<Widget> _buildFloatingParticles(AnimationController controller) {
    const primaryColor = Color(0xff194795);
    const accentColor = Color(0xff4A90E2);

    return List.generate(3, (index) {
      final angle = (index * 120) * 3.14159 / 180;
      final distance = 50.0;

      return PositionedTransition(
        rect: RelativeRectTween(
          begin: const RelativeRect.fromLTRB(50, 50, 50, 50),
          end: RelativeRect.fromLTRB(
            50 + (distance * math.cos(angle)),
            50 + (distance * math.sin(angle)),
            50 - (distance * math.cos(angle)),
            50 - (distance * math.sin(angle)),
          ),
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1, end: 0).animate(
            CurvedAnimation(
              parent: controller,
              curve: const Interval(0.5, 1, curve: Curves.easeOut),
            ),
          ),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index % 2 == 0 ? primaryColor : accentColor,
            ),
          ),
        ),
      );
    });
  }
}

// Animated Button
class _AnimatedButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Function() onPressed;
  final bool isPrimary;
  final bool isDarkMode;

  const _AnimatedButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
    required this.isDarkMode,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff194795);
    const accentColor = Color(0xff4A90E2);

    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _hoverController.forward(),
        onTapUp: (_) => _hoverController.reverse(),
        onTapCancel: () => _hoverController.reverse(),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1, end: 0.95).animate(
            CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.isPrimary
                      ? primaryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(16),
                splashColor: widget.isPrimary
                    ? Colors.white.withOpacity(0.2)
                    : primaryColor.withOpacity(0.1),
                highlightColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: widget.isPrimary
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [primaryColor, accentColor],
                          )
                        : null,
                    color: widget.isPrimary
                        ? null
                        : (widget.isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05)),
                    border: !widget.isPrimary
                        ? Border.all(
                            color: widget.isDarkMode
                                ? Colors.white.withOpacity(0.15)
                                : Colors.black.withOpacity(0.1),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        color: widget.isPrimary
                            ? Colors.white
                            : (widget.isDarkMode ? Colors.white : Colors.black),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style:
                            AppTextStyles.titleMedium(
                              widget.isPrimary
                                  ? Colors.white
                                  : (widget.isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                            ).copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
