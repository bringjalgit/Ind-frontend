import 'package:flutter/material.dart';

import '../model/SubcategoryProductsModel.dart';
import '../theme/ThemeHelper.dart';

/// Shown above a listing list when the backend's 50 km radius search
/// returned zero hits and we widened to nationwide. Tells the buyer
/// "nothing near your selected location" + the fallback listings sit
/// directly below, sorted by distance.
///
/// Renders nothing when the fallback didn't fire — safe to drop into
/// any screen that consumes a [SubcategoryProductsModel].
class LocationFallbackBanner extends StatelessWidget {
  final LocationMeta? locationMeta;
  final String? searchTerm;

  const LocationFallbackBanner({
    super.key,
    required this.locationMeta,
    this.searchTerm,
  });

  @override
  Widget build(BuildContext context) {
    if (locationMeta?.fellBackToNationwide != true) {
      return const SizedBox.shrink();
    }

    final textColor = ThemeHelper.textColor(context);
    final term = (searchTerm ?? '').trim();
    final headline = term.isEmpty
        ? 'No listings near your selected location'
        : "No '$term' near your selected location";

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_off_outlined, color: Colors.amber.shade800, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Showing listings from other locations, sorted by distance.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: textColor.withOpacity(0.75),
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
