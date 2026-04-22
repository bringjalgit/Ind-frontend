import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:classifieds/data/cubit/Aadhaar/aadhaar_cubit.dart';
import 'package:classifieds/data/cubit/Aadhaar/aadhaar_states.dart';
import 'package:classifieds/model/AadhaarStatusModel.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import 'widgets/kyc_status_card.dart';

/// Aadhaar KYC verification screen (Phase 1).
///
/// State machine (drives the entire UI):
///   none     → instructions + upload-front + upload-back + submit CTA
///   pending  → "under review" card with submitted-on timestamp
///   approved → green success card with verified tick
///   rejected → red reason banner + resubmit form (upload-front + upload-back + submit CTA)
///
/// All mutations go through AadhaarCubit. The screen never calls the
/// data source directly — it reacts to state transitions.
class AadhaarVerificationScreen extends StatefulWidget {
  const AadhaarVerificationScreen({super.key});

  @override
  State<AadhaarVerificationScreen> createState() =>
      _AadhaarVerificationScreenState();
}

class _AadhaarVerificationScreenState extends State<AadhaarVerificationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AadhaarCubit>().loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final bg = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Verify Your Identity',
          style: AppTextStyles.titleLarge(textColor),
        ),
      ),
      body: BlocConsumer<AadhaarCubit, AadhaarState>(
        listener: (context, state) {
          if (state is AadhaarFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AadhaarInitial || state is AadhaarLoading) {
            return Container(color: bg, child: const Center(child: CircularProgressIndicator()));
          }
          if (state is AadhaarFailure && state.data == null) {
            return Container(
              color: bg,
              child: _ErrorView(
                message: state.message,
                onRetry: () => context.read<AadhaarCubit>().loadStatus(),
              ),
            );
          }

          // From here on, we have data — either Loaded, Uploading,
          // Submitting, or Failure(with-data). Unify by extracting.
          AadhaarStatusData data;
          String? pendingFrontUrl;
          String? pendingBackUrl;
          String? uploadingSide;
          bool isSubmitting = false;

          if (state is AadhaarLoaded) {
            data = state.data;
            pendingFrontUrl = state.pendingFrontUrl;
            pendingBackUrl = state.pendingBackUrl;
          } else if (state is AadhaarUploading) {
            data = state.data;
            pendingFrontUrl = state.pendingFrontUrl;
            pendingBackUrl = state.pendingBackUrl;
            uploadingSide = state.side;
          } else if (state is AadhaarSubmitting) {
            data = state.data;
            isSubmitting = true;
          } else if (state is AadhaarFailure) {
            data = state.data!;
            pendingFrontUrl = state.pendingFrontUrl;
            pendingBackUrl = state.pendingBackUrl;
          } else {
            return const SizedBox.shrink();
          }

          // Pending / approved → the A·Refined Dark KYC status card.
          // Theme-adaptive (light + dark) via WizardTokens inside the
          // widget, so nothing to pipe in from here.
          if (data.isApproved) {
            return const KycStatusCard(state: KycCardState.verified);
          }
          if (data.isPending) {
            return KycStatusCard(
              state: KycCardState.review,
              submittedAtIso: data.submittedAt,
            );
          }

          // none / rejected → scrollable upload form. Paint a solid dark
          // background behind the AppBar (since we enabled
          // extendBodyBehindAppBar).
          return Container(
            color: bg,
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildUploadForm(
                  context: context,
                  isDark: isDark,
                  textColor: textColor,
                  data: data,
                  pendingFrontUrl: pendingFrontUrl,
                  pendingBackUrl: pendingBackUrl,
                  uploadingSide: uploadingSide,
                  isSubmitting: isSubmitting,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Upload form only (none/rejected state). The aurora cards for pending
  /// and approved states are returned directly by the builder above —
  /// they need to bypass the SingleChildScrollView + padding to paint the
  /// whole screen.
  Widget _buildUploadForm({
    required BuildContext context,
    required bool isDark,
    required Color textColor,
    required AadhaarStatusData data,
    String? pendingFrontUrl,
    String? pendingBackUrl,
    String? uploadingSide,
    bool isSubmitting = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // M17 — hide rejection banner while a re-submit is in flight.
        // The user has clearly acted on the rejection; keeping the banner
        // visible during AadhaarSubmitting / AadhaarUploading is confusing.
        if (data.isRejected && data.rejectionReason != null && !isSubmitting) ...[
          _RejectionBanner(reason: data.rejectionReason!),
          const SizedBox(height: 16),
        ],
        const _StepIndicator(
          step: 1,
          total: 3,
          label: 'Document Upload',
        ),
        const SizedBox(height: 24),
        const _SectionLabel('GUIDELINES'),
        const SizedBox(height: 10),
        const _GuidelinesCard(),
        const SizedBox(height: 24),
        const _SectionLabel('UPLOAD DOCUMENTS'),
        const SizedBox(height: 10),
        _UploadTile(
          label: 'Aadhaar — Front',
          side: 'front',
          isUploading: uploadingSide == 'front',
          isDone: pendingFrontUrl != null,
          disabled: uploadingSide != null || isSubmitting,
          textColor: textColor,
          accentColor: const Color(0xFF8B5CF6), // purple
        ),
        const SizedBox(height: 12),
        _UploadTile(
          label: 'Aadhaar — Back',
          side: 'back',
          isUploading: uploadingSide == 'back',
          isDone: pendingBackUrl != null,
          disabled: uploadingSide != null || isSubmitting,
          textColor: textColor,
          accentColor: const Color(0xFF22D3EE), // teal
        ),
        const SizedBox(height: 24),
        _SubmitButton(
          canSubmit: pendingFrontUrl != null &&
              pendingBackUrl != null &&
              uploadingSide == null,
          isSubmitting: isSubmitting,
        ),
        const SizedBox(height: 16),
        const _FooterNote(),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────

/// Purple step-indicator pill with a trailing divider line. Shows the
/// user where they are in a multi-step flow. Only "Document Upload" is
/// wired right now (step 1 of 3); steps 2 and 3 are conceptual.
class _StepIndicator extends StatelessWidget {
  final int step;
  final int total;
  final String label;
  const _StepIndicator({
    required this.step,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF8B5CF6);
    final isDark = ThemeHelper.isDarkMode(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withOpacity(isDark ? 0.14 : 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withOpacity(0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Step $step of $total — $label',
                style: TextStyle(
                  // Light-mode uses the deeper accent for readability; dark
                  // keeps the soft lilac so it glows against the dark bg.
                  color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          ),
        ),
      ],
    );
  }
}

/// Small uppercase section header like "GUIDELINES" or "UPLOAD DOCUMENTS".
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: TextStyle(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.55),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

/// Dark bordered card containing the 4 guideline bullets with green check
/// circles. Kept as const-style so the entire card is cheap to rebuild.
class _GuidelinesCard extends StatelessWidget {
  const _GuidelinesCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Take a clear photo of both sides of your Aadhaar card.',
      'Make sure all text is readable and the card is fully visible.',
      'Avoid glare, shadows, and cropped edges.',
      'Images are used only for verification and stored securely.',
    ];
    final isDark = ThemeHelper.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF0D1220) : const Color(0xFFF8F9FB),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _GuidelineBullet(text: items[i]),
            if (i < items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _GuidelineBullet extends StatelessWidget {
  final String text;
  const _GuidelineBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withOpacity(0.16),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.55),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.check,
            size: 12,
            color: Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: (ThemeHelper.isDarkMode(context) ? Colors.white : Colors.black)
                  .withOpacity(0.82),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Footer text below the submit button. Two centered lines with "48 hours"
/// highlighted purple to draw attention to the review window.
class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final muted = (isDark ? Colors.white : Colors.black).withOpacity(0.5);
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(color: muted, fontSize: 12, height: 1.4),
            children: [
              const TextSpan(text: 'Your KYC will be reviewed within '),
              TextSpan(
                text: '48 hours',
                style: TextStyle(
                  // Light mode: deeper purple for contrast; dark: lilac.
                  color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'We keep your data private & encrypted.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String label;
  final String side;
  final bool isUploading;
  final bool isDone;
  final bool disabled;
  final Color textColor;
  final Color accentColor;

  const _UploadTile({
    required this.label,
    required this.side,
    required this.isUploading,
    required this.isDone,
    required this.disabled,
    required this.textColor,
    required this.accentColor,
  });

  Future<void> _pick(BuildContext context) async {
    if (disabled) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final onSurface = Theme.of(sheetContext).colorScheme.onSurface;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: onSurface),
                title: Text(
                  'Choose from gallery',
                  style: TextStyle(color: onSurface),
                ),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: onSurface),
                title: Text(
                  'Take a photo',
                  style: TextStyle(color: onSurface),
                ),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    // ignore: use_build_context_synchronously
    await context
        .read<AadhaarCubit>()
        .pickAndUpload(side: side, source: source);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    // Theme-adaptive colors. Light mode uses a soft cream card with faint
    // black borders so the tile reads as a card on white; dark mode keeps
    // the deep navy from the original design.
    final cardBg = isDark ? const Color(0xFF0D1220) : const Color(0xFFF8F9FB);
    final onCard = isDark ? Colors.white : Colors.black;
    final Color borderColor = isDone
        ? const Color(0xFF10B981).withOpacity(0.55)
        : onCard.withOpacity(0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : () => _pick(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              // Colored icon square (purple for front, teal for back). When
              // the side is done, swap to a green success square so the
              // visual state change is obvious at a glance.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDone
                      ? const Color(0xFF10B981).withOpacity(0.18)
                      : accentColor.withOpacity(0.18),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF10B981).withOpacity(0.55)
                        : accentColor.withOpacity(0.45),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  isDone
                      ? Icons.check_circle
                      : Icons.cloud_upload_outlined,
                  color: isDone
                      ? const Color(0xFF10B981)
                      : accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: onCard,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isUploading
                          ? 'Uploading…'
                          : isDone
                              ? 'Uploaded · Tap to replace'
                              : 'Tap to upload · JPG, PNG up to 5MB',
                      style: TextStyle(
                        color: onCard.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Trailing: spinner while uploading, otherwise a chevron
              if (isUploading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: accentColor,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: onCard.withOpacity(0.4),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool canSubmit;
  final bool isSubmitting;
  const _SubmitButton({required this.canSubmit, required this.isSubmitting});

  @override
  Widget build(BuildContext context) {
    // Ready to submit = both sides uploaded AND not already submitting.
    // Drives the gradient (full vs muted), the pulsing glow, and tappability.
    final ready = canSubmit && !isSubmitting;
    final isDark = ThemeHelper.isDarkMode(context);
    // Disabled state needs contrast against both dark and light backgrounds.
    final disabledOverlay = (isDark ? Colors.white : Colors.black).withOpacity(0.06);
    final disabledBorder = (isDark ? Colors.white : Colors.black).withOpacity(0.08);
    // Label/icon color for the disabled state — readable on either bg.
    final disabledText = isDark ? Colors.white : Colors.black;

    final button = Container(
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: ready
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF8B5CF6), // purple
                  Color(0xFF22D3EE), // cyan
                ],
              )
            : null,
        color: ready ? null : disabledOverlay,
        border: ready
            ? null
            : Border.all(color: disabledBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: ready
              ? () => context.read<AadhaarCubit>().submit()
              : null,
          child: Center(
            child: isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 19,
                        // Active state: always white over the gradient.
                        // Disabled: themed so it reads on either bg.
                        color: ready
                            ? Colors.white
                            : disabledText.withOpacity(0.4),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Submit for Verification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ready
                              ? Colors.white
                              : disabledText.withOpacity(0.4),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    // Glow only when the button is actually ready. When disabled (one or
    // both sides missing) or busy (submitting), no glow — keeps the user's
    // eye from being pulled to an inactive CTA.
    return _PulsingGlow(active: ready, child: button);
  }
}

// _PendingCard + _ApprovedCard + _Neumorphic* suite REMOVED 2026-04-21.
// Replaced by `KycStatusCard` at presentation/views/widgets/kyc_status_card.dart
// (A·Refined Dark design, theme-adaptive via WizardTokens).


class _RejectionBanner extends StatelessWidget {
  final String reason;
  const _RejectionBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your previous submission was rejected',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(color: Colors.red.shade900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please re-upload with the issues fixed.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Pulsing glow wrapper — breathing blue→purple box-shadow that pulls the
/// user's eye toward a call-to-action. Used on the Submit button once both
/// Aadhaar sides have been uploaded. When [active] is false (one or both
/// sides missing, or submission in flight) the child renders without the
/// shadow and the ticker is stopped — no CPU cost.
///
/// This is a local copy of the same widget used in ProfileScreen for the
/// "Verify Your Identity" tile. Deliberately duplicated rather than
/// extracted to a shared widget file because (a) there are only two call
/// sites, (b) the shared extraction would cost one more file and cross-
/// feature coupling, and (c) if the animation drifts between the two
/// places in the future that's fine — they're different UI contexts and
/// might want different timing.
class _PulsingGlow extends StatefulWidget {
  final Widget child;
  final bool active;
  const _PulsingGlow({required this.child, this.active = true});

  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value; // 0 → 1 → 0 cycle
        // Blue → purple lerp matches the ProfileScreen tile glow so the
        // design language feels consistent across the verification flow.
        final color = Color.lerp(
          const Color(0xFF1DA1F2),
          const Color(0xFF8B5CF6),
          t,
        )!;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25 + 0.35 * t),
                blurRadius: 14 + 18 * t,
                spreadRadius: 2 + 3 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
