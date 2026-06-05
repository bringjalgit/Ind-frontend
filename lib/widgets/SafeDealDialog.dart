import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CustomAppButton.dart';

import 'package:flutter/material.dart';

import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';
// import your ThemeCubit, ThemeHelper, AppTextStyles, CustomAppButton1, etc.

class SafeDealBottomSheet extends StatelessWidget {
  const SafeDealBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // THEME HOOKS
    final bg        = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    final card      = ThemeHelper.cardColor(context);
    final primary   = Theme.of(context).colorScheme.primary; // your app theme’s primary

    final tips = <Map<String, Object>>[
      {
        "icon": Icons.lock_outline,
        "title": "Protect your info",
        "desc":  "Never share OTP, UPI PIN, or scan unknown QR codes."
      },
      {
        "icon": Icons.money_off, // fixed icon
        "title": "No advance payments",
        "desc":  "Don’t pay or send products before meeting in person."
      },
      {
        "icon": Icons.report_gmailerrorred_outlined,
        "title": "Report suspicious users",
        "desc":  "If someone looks fishy, report them to IND Classifieds."
      },
      {
        "icon": Icons.privacy_tip_outlined,
        "title": "Stay private",
        "desc":  "Avoid sharing IDs or personal photos."
      },
      {
        "icon": Icons.handshake_outlined,
        "title": "Meet safely",
        "desc":  "Choose safe & public places for buyer-seller meetings."
      },
    ];

    return SafeArea(
      top: false,
      child: Container(
        // translucent scrim gap around rounded sheet
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.12),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // nice on small screens
              maxHeight: MediaQuery.of(context).size.height * 0.72                                                                        ,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // grab handle
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_moon_outlined, color: primary, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        "Tips for a Safe Deal",
                        style: AppTextStyles.titleLarge(primary)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // list (scrollable)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: tips.map((tip) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: primary.withOpacity(0.10),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  tip["icon"] as IconData,
                                  color: primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tip["title"] as String,
                                        style: AppTextStyles.titleMedium(textColor)
                                            .copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tip["desc"] as String,
                                        style: AppTextStyles.bodyMedium(
                                          textColor.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: CustomAppButton1(
                      text: "Continue to Chat",
                      onPlusTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


