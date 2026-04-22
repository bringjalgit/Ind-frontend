import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/theme/ThemeHelper.dart';
import 'package:classifieds/theme/app_colors.dart';
import 'package:classifieds/Components/CutomAppBar.dart';
import 'package:classifieds/Components/CustomAppButton.dart';
import 'package:classifieds/services/ApiClient.dart';
import 'package:classifieds/services/api_endpoint_urls.dart';

/// Seller Settings screen for an active SWA listing.
///
/// Editable (non-price) fields:
///   • Pickup slots (morning / afternoon / evening / weekend)
///   • Chat mode (disabled / human / keyword_chat)
///   • Availability window (3–90 days)
///   • Auto-negotiate toggle
///   • Quick response toggle
///   • Delivery available toggle
///
/// Price fields (expected/floor) require deactivate → reactivate.
///
/// Route: /swa-settings/:listingId (receives current config via extra)
class SWASettingsScreen extends StatefulWidget {
  final String listingId;
  final Map<String, dynamic> currentConfig;

  const SWASettingsScreen({
    super.key,
    required this.listingId,
    required this.currentConfig,
  });

  @override
  State<SWASettingsScreen> createState() => _SWASettingsScreenState();
}

class _SWASettingsScreenState extends State<SWASettingsScreen> {
  late Set<String> _pickupSlots;
  late String _chatMode;
  late int _availabilityWindow;
  late bool _autoNegotiate;
  late bool _quickResponse;
  late bool _deliveryAvailable;

  bool _saving = false;
  String? _error;
  bool _hasChanges = false;

  final List<int> _windowOptions = [7, 15, 30, 60, 90];
  final List<_SlotOption> _slotOptions = [
    _SlotOption('morning', 'Morning', '9 AM – 12 PM', Icons.wb_sunny_outlined),
    _SlotOption('afternoon', 'Afternoon', '12 – 5 PM', Icons.wb_cloudy_outlined),
    _SlotOption('evening', 'Evening', '5 – 9 PM', Icons.nights_stay_outlined),
    _SlotOption('weekend', 'Weekend', 'Sat & Sun', Icons.weekend_outlined),
  ];
  final List<_ChatModeOption> _chatModeOptions = [
    _ChatModeOption('disabled', 'Pills Only', 'Buyers tap preset options'),
    _ChatModeOption('keyword_chat', 'Keyword Chat', 'AI answers common questions'),
    _ChatModeOption('human', 'Human Chat', 'Buyers type freely, you reply'),
  ];

  @override
  void initState() {
    super.initState();
    final config = widget.currentConfig;
    _pickupSlots = Set<String>.from(
      (config['pickup_slots'] as List<dynamic>?)?.map((e) => e.toString()) ?? ['morning', 'evening'],
    );
    _chatMode = config['chat_mode']?.toString() ?? 'disabled';
    _availabilityWindow = config['availability_window'] as int? ?? 30;
    _autoNegotiate = config['auto_negotiate'] == true;
    _quickResponse = config['quick_response'] == true;
    _deliveryAvailable = config['delivery_available'] == true;
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _saveSettings() async {
    if (_pickupSlots.isEmpty) {
      setState(() => _error = 'Select at least one pickup slot');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final url = APIEndpointUrls.swaUpdateSettings(widget.listingId);
      final body = <String, dynamic>{
        'pickup_slots': _pickupSlots.toList(),
        'chat_mode': _chatMode,
        'availability_window': _availabilityWindow,
        'auto_negotiate': _autoNegotiate,
        'quick_response': _quickResponse,
        'delivery_available': _deliveryAvailable,
      };

      final response = await ApiClient.post(url, data: body);

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
        context.pop(true); // pass true to indicate refresh needed
      } else {
        setState(() {
          _error = response.data?['message']?.toString() ?? 'Failed to save';
          _saving = false;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.response?.data?['message']?.toString() ?? 'Connection error';
        _saving = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Something went wrong';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final secondaryText = AppColors.unselect;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F5),
      appBar: CustomAppBar1(title: 'Smart Assist Settings', actions: const []),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Pickup slots ──────────────────────────────────────
              _sectionTitle('Pickup Slots', textColor),
              const SizedBox(height: 4),
              Text(
                'When are you available to hand over the item?',
                style: TextStyle(fontSize: 12, color: secondaryText),
              ),
              if (_error != null && _error!.contains('slot')) ...[
                const SizedBox(height: 4),
                Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
              ],
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _slotOptions.map((slot) {
                  final isSelected = _pickupSlots.contains(slot.id);
                  return _slotCard(slot, isSelected, isDark, textColor, secondaryText);
                }).toList(),
              ),

              const SizedBox(height: 28),

              // ── Chat mode ─────────────────────────────────────────
              _sectionTitle('Chat Mode', textColor),
              const SizedBox(height: 4),
              Text(
                'How should buyers communicate?',
                style: TextStyle(fontSize: 12, color: secondaryText),
              ),
              const SizedBox(height: 12),
              ..._chatModeOptions.map((opt) {
                final isSelected = _chatMode == opt.id;
                return _chatModeCard(opt, isSelected, isDark, textColor, secondaryText);
              }),

              const SizedBox(height: 28),

              // ── Availability window ───────────────────────────────
              _sectionTitle('Active Duration', textColor),
              const SizedBox(height: 4),
              Text(
                'How long should Smart Assist stay active?',
                style: TextStyle(fontSize: 12, color: secondaryText),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _windowOptions.map((days) {
                  final isSelected = _availabilityWindow == days;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _availabilityWindow = days);
                      _markChanged();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD1D5DB)),
                        ),
                      ),
                      child: Text(
                        '$days days',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // ── Toggle settings ───────────────────────────────────
              _sectionTitle('Advanced', textColor),
              const SizedBox(height: 12),
              _toggleRow('Auto-Negotiate', 'AI counters and accepts offers automatically', _autoNegotiate, (v) {
                setState(() => _autoNegotiate = v);
                _markChanged();
              }, isDark, textColor, secondaryText, cardBg),
              const SizedBox(height: 10),
              _toggleRow('Quick Response', 'Reply to buyer queries instantly', _quickResponse, (v) {
                setState(() => _quickResponse = v);
                _markChanged();
              }, isDark, textColor, secondaryText, cardBg),
              const SizedBox(height: 10),
              _toggleRow('Delivery Available', 'Offer delivery option to buyers', _deliveryAvailable, (v) {
                setState(() => _deliveryAvailable = v);
                _markChanged();
              }, isDark, textColor, secondaryText, cardBg),

              const SizedBox(height: 28),

              // ── Price note ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: isDark ? const Color(0xFFFFD600) : const Color(0xFFB45309)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'To change pricing (expected price / floor price), pause Smart Assist and re-enable with new prices.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFFFD600) : const Color(0xFFB45309),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_error != null && !_error!.contains('slot')) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB))),
        ),
        child: CustomAppButton1(
          text: _saving ? 'Saving...' : 'Save Settings',
          onPlusTap: _saving ? null : _saveSettings,
        ),
      ),
    );
  }

  // ── Section title ────────────────────────────────────────────────────

  Widget _sectionTitle(String text, Color textColor) {
    return Text(
      text,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
    );
  }

  // ── Slot card ────────────────────────────────────────────────────────

  Widget _slotCard(_SlotOption slot, bool isSelected, bool isDark, Color textColor, Color secondaryText) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_pickupSlots.contains(slot.id)) {
            _pickupSlots.remove(slot.id);
          } else {
            _pickupSlots.add(slot.id);
          }
          _error = null;
        });
        _markChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? (isSelected ? AppColors.primary.withOpacity(0.1) : const Color(0xFF2A2A2A))
              : (isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD1D5DB)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF666666) : const Color(0xFFD1D5DB)),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(slot.label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: textColor)),
                  Text(slot.subtitle, style: TextStyle(fontSize: 10, color: secondaryText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chat mode card ───────────────────────────────────────────────────

  Widget _chatModeCard(_ChatModeOption opt, bool isSelected, bool isDark, Color textColor, Color secondaryText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _chatMode = opt.id);
          _markChanged();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? (isSelected ? AppColors.primary.withOpacity(0.1) : const Color(0xFF1E1E1E))
                : (isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD1D5DB)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF666666) : const Color(0xFFD1D5DB)),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.circle, size: 10, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: textColor)),
                    Text(opt.subtitle, style: TextStyle(fontSize: 11, color: secondaryText)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Toggle row ───────────────────────────────────────────────────────

  Widget _toggleRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged,
      bool isDark, Color textColor, Color secondaryText, Color cardBg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: secondaryText)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SlotOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  const _SlotOption(this.id, this.label, this.subtitle, this.icon);
}

class _ChatModeOption {
  final String id;
  final String label;
  final String subtitle;
  const _ChatModeOption(this.id, this.label, this.subtitle);
}
