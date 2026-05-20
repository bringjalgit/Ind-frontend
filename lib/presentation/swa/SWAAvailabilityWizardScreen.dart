import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/wizard_theme.dart';

/// S3 — SWA Wizard Step 2: Availability & Pickup.
///
/// "A · Refined Dark" design, theme-adaptive via WizardTokens.
/// Seller picks the on-duration (7/15/30/60/90 days) and which
/// pickup slots they're available for.
class SWAAvailabilityWizardScreen extends StatefulWidget {
  final String listingId;
  final String listingTitle;
  final int listedPrice;
  final int expectedPrice;
  final int floorPrice;
  // ISO timestamps for the listing's plan window. The chip filter uses
  // (expires - created) — the listing's plan-total validity — not
  // (expires - now), because `.inDays` truncation would otherwise hide
  // the matching chip within an hour of listing creation (a fresh
  // 30-day listing would compute 29 days remaining and lose the 30
  // chip). Null when the entry point didn't supply them; we then fall
  // back to all five chips (backend still caps at 90).
  final String? expiresListDate;
  final String? createdAt;

  const SWAAvailabilityWizardScreen({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.listedPrice,
    required this.expectedPrice,
    required this.floorPrice,
    this.expiresListDate,
    this.createdAt,
  });

  @override
  State<SWAAvailabilityWizardScreen> createState() =>
      _SWAAvailabilityWizardScreenState();
}

class _SWAAvailabilityWizardScreenState
    extends State<SWAAvailabilityWizardScreen> {
  int _selectedWindow = 30;
  // Pickup slots start EMPTY — the seller must pick at least one. Earlier
  // we pre-selected morning + evening which read as a quiet auto-decision
  // sellers didn't realise they'd made. The downstream validator in
  // _onNext catches the empty set and asks them to choose.
  final Set<String> _selectedSlots = <String>{};
  String? _slotError;

  // Phone-privacy toggle. When true (default), the seller's mobile number
  // is hidden from buyers chatting via SWA on this listing — the call
  // icon doesn't render in the buyer's chat. Auto-unlocks for any
  // conversation the seller takes over manually (status =
  // seller_takeover). Toggle survives deactivate/reactivate cycles. The
  // value is forwarded all the way to the activation API and persisted on
  // sell_with_ai_config.hide_phone_from_buyers.
  bool _hidePhoneFromBuyers = true;

  // Preset durations. Backend caps at 90; the visible subset is further
  // capped by the listing's remaining validity (see initState).
  static const _windowOptions = [7, 15, 30, 60, 90];

  // Largest window chip we'll render. Computed from expiresListDate at
  // mount; defaults to 90 when no expiry is supplied so the picker
  // behaves exactly like before for legacy entry points.
  int _maxWindowDays = 90;
  static const _slots = [
    _SlotOption('morning', 'Morning', '9 AM – 12 PM'),
    _SlotOption('afternoon', 'Afternoon', '12 – 5 PM'),
    _SlotOption('evening', 'Evening', '5 – 9 PM'),
    _SlotOption('weekend', 'Weekend', 'Sat & Sun'),
  ];

  @override
  void initState() {
    super.initState();
    final expiresRaw = widget.expiresListDate;
    final createdRaw = widget.createdAt;
    final expiresAt = (expiresRaw != null && expiresRaw.isNotEmpty)
        ? DateTime.tryParse(expiresRaw)
        : null;
    final createdAt = (createdRaw != null && createdRaw.isNotEmpty)
        ? DateTime.tryParse(createdRaw)
        : null;

    if (expiresAt != null && createdAt != null) {
      // Plan-total validity: invariant for the lifetime of the listing.
      // A 30-day listing always reads as 30 days here regardless of when
      // the seller is viewing the wizard.
      //
      // `.inDays` truncates, and the backend sets expires_list_date a
      // few milliseconds after created_at, so a 30-day plan computes as
      // 29 days, 23:59:59.99x → 29. Round to nearest day to recover the
      // integer the seller actually purchased.
      final diffMs = expiresAt.difference(createdAt).inMilliseconds;
      final planDays =
          (diffMs / Duration.millisecondsPerDay).round();
      _maxWindowDays = planDays < 7 ? 7 : (planDays > 90 ? 90 : planDays);
    } else if (expiresAt != null) {
      // Fallback when createdAt wasn't supplied: use remaining days.
      // Less accurate but better than no cap. Floor at 7 so a listing
      // about to expire still shows at least one chip.
      final remaining = expiresAt.difference(DateTime.now()).inDays;
      _maxWindowDays = remaining < 7 ? 7 : (remaining > 90 ? 90 : remaining);
    }
    // Clamp the initial selection if it's now out of range. 30 is the
    // default — for a 15-day listing that's invalid, so drop down to
    // the largest visible chip.
    if (_selectedWindow > _maxWindowDays) {
      final allowed =
          _windowOptions.where((d) => d <= _maxWindowDays).toList();
      _selectedWindow = allowed.isNotEmpty ? allowed.last : _maxWindowDays;
    }
  }

  void _toggleSlot(String id) {
    setState(() {
      if (_selectedSlots.contains(id)) {
        _selectedSlots.remove(id);
      } else {
        _selectedSlots.add(id);
      }
      _slotError = null;
    });
  }

  void _onNext() {
    if (_selectedSlots.isEmpty) {
      setState(() => _slotError = 'Select at least one pickup slot');
      return;
    }
    context.push(
      '/swa-wizard-chatmode',
      extra: {
        'listingId': widget.listingId,
        'listingTitle': widget.listingTitle,
        'listedPrice': widget.listedPrice,
        'expectedPrice': widget.expectedPrice,
        'floorPrice': widget.floorPrice,
        'availabilityWindow': _selectedWindow,
        'pickupSlots': _selectedSlots.toList(),
        'hidePhoneFromBuyers': _hidePhoneFromBuyers,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = WizardTokens.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: _buildTopBar(t, 'Availability'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WizardStepHeader(
                t: t,
                step: 2,
                totalSteps: 3,
                eyebrow: '02 · AVAILABILITY',
                title: 'When should we stay\nswitched on?',
              ),
              const SizedBox(height: 22),

              // ── DURATION ─────────────────────────────────────────
              _sectionLabel(t, 'DURATION'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _windowOptions
                    .where((d) => d <= _maxWindowDays)
                    .map((d) => _buildDurationPill(t, d))
                    .toList(),
              ),
              const SizedBox(height: 10),
              Text(
                'Pause or stop anytime from dashboard.',
                style: TextStyle(fontSize: 11, color: t.dim2),
              ),

              const SizedBox(height: 22),

              // ── PICKUP SLOTS ─────────────────────────────────────
              Row(
                children: [
                  _sectionLabel(t, 'PICKUP SLOTS'),
                  const Spacer(),
                  Text(
                    '${_selectedSlots.length} selected',
                    style: TextStyle(
                      fontSize: 11,
                      color: t.dim,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (_slotError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _slotError!,
                  style: TextStyle(fontSize: 11, color: t.danger),
                ),
              ],
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children:
                    _slots.map((s) => _buildSlotCard(t, s)).toList(),
              ),

              const SizedBox(height: 22),

              // ── PHONE PRIVACY ────────────────────────────────────
              _sectionLabel(t, 'PHONE PRIVACY'),
              const SizedBox(height: 12),
              _buildPrivacyCard(t),
              const SizedBox(height: 18),

              WizardTipChip(
                t: t,
                icon: Icons.lightbulb_outline_rounded,
                iconColor: t.warn,
                body: Text(
                  'More slots = faster deals. Buyers find a time that works for both.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: t.dim,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(t),
    );
  }

  Widget _sectionLabel(WizardTokens t, String label) => Text(
        label,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
          color: t.dim2,
        ),
      );

  /// Phone-privacy toggle card. Mirrors the slot/duration card surfaces
  /// so it visually lives inside the Availability step rather than feeling
  /// bolted on. The trailing Switch flips `_hidePhoneFromBuyers`; the
  /// hint line below the card swaps copy + dot colour based on state so
  /// the seller has unambiguous feedback about whether their number is
  /// reachable. Auto-unlock-on-takeover semantics are mentioned in the
  /// hint so the seller doesn't have to read the spec to understand the
  /// edge case.
  Widget _buildPrivacyCard(WizardTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.line),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.phonelink_lock_outlined,
                  color: t.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hide phone from buyers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Buyers can't see or dial your number while Smart "
                      'Assist is negotiating. They reach you only via this '
                      'chat.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: t.dim,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch.adaptive(
                value: _hidePhoneFromBuyers,
                activeColor: t.accent,
                onChanged: (v) => setState(() => _hidePhoneFromBuyers = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4, right: 8),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hidePhoneFromBuyers ? t.warn : t.success,
                ),
              ),
              Expanded(
                child: Text(
                  _hidePhoneFromBuyers
                      ? 'Active for every buyer on this listing. Auto-unlocks '
                          'for any conversation you take over.'
                      : 'Buyers on this listing can see your number and call '
                          'directly.',
                  style: TextStyle(
                    fontSize: 11,
                    color: t.dim2,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Duration pill with mono numeral on top of "days" label.
  Widget _buildDurationPill(WizardTokens t, int days) {
    final isSelected = _selectedWindow == days;
    return GestureDetector(
      onTap: () => setState(() => _selectedWindow = days),
      child: Container(
        constraints: const BoxConstraints(minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? t.accent : t.surface,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? null : Border.all(color: t.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$days',
              style: wizardMonoStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSelected ? t.onAccent : t.text,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'days',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? t.onAccent.withOpacity(0.7)
                    : t.text.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCard(WizardTokens t, _SlotOption s) {
    final on = _selectedSlots.contains(s.id);
    return GestureDetector(
      onTap: () => _toggleSlot(s.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: on ? t.accent.withOpacity(0.06) : t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: on ? t.accent : t.line,
            width: on ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: t.text,
                    ),
                  ),
                ),
                // Checkbox — filled tick when selected.
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: on ? t.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: on ? null : Border.all(color: t.lineHi, width: 1.5),
                  ),
                  child: on
                      ? Icon(Icons.check_rounded,
                          size: 12, color: t.onAccent)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              s.time,
              style: wizardMonoStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: t.dim,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(WizardTokens t, String title) {
    return AppBar(
      backgroundColor: t.bg,
      surfaceTintColor: t.bg,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: t.text,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: t.text),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: t.line),
      ),
    );
  }

  Widget _buildBottomBar(WizardTokens t) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: WizardPrimaryButton(
          t: t,
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _onNext,
        ),
      ),
    );
  }
}

class _SlotOption {
  final String id;
  final String label;
  final String time;
  const _SlotOption(this.id, this.label, this.time);
}
