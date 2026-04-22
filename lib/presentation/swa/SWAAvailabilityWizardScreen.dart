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

  const SWAAvailabilityWizardScreen({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.listedPrice,
    required this.expectedPrice,
    required this.floorPrice,
  });

  @override
  State<SWAAvailabilityWizardScreen> createState() =>
      _SWAAvailabilityWizardScreenState();
}

class _SWAAvailabilityWizardScreenState
    extends State<SWAAvailabilityWizardScreen> {
  int _selectedWindow = 30;
  final Set<String> _selectedSlots = {'morning', 'evening'};
  String? _slotError;

  static const _windowOptions = [7, 15, 30, 60, 90];
  static const _slots = [
    _SlotOption('morning', 'Morning', '9 AM – 12 PM'),
    _SlotOption('afternoon', 'Afternoon', '12 – 5 PM'),
    _SlotOption('evening', 'Evening', '5 – 9 PM'),
    _SlotOption('weekend', 'Weekend', 'Sat & Sun'),
  ];

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
