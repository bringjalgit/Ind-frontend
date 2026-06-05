// lib/deep_link_mapper.dart
import 'package:flutter/cupertino.dart';

class DeepLinkMapper {
  static String? toLocation(Uri? uri) {
    if (uri == null) {
      debugPrint('DeepLinkMapper: received null uri');
      return null;
    }

    debugPrint('DeepLinkMapper: parsing -> $uri');

    // Validate scheme/host
    if (uri.hasScheme) {
      final scheme = uri.scheme.toLowerCase();
      if (scheme == 'https') {
        final host = uri.host.toLowerCase();
        final isOurDomain =
            host == 'indclassifieds.in' || host == 'www.indclassifieds.in';
        if (!isOurDomain) {
          debugPrint('DeepLinkMapper: foreign https host, ignore');
          return null;
        }
      }
    }

    final segs = uri.pathSegments
        .where((s) => s.isNotEmpty)
        .map((s) => s.toLowerCase())
        .toList();
    debugPrint('DeepLinkMapper: segs=$segs query=${uri.queryParameters}');

    // --- 1) Single Listing Details (old format) ---
    if (segs.isNotEmpty && segs.first == 'singlelistingdetails') {
      final subcatFromPath = segs.length >= 2 ? segs[1] : null;
      final listingFromQuery = uri.queryParameters['detailId'];
      final subcatFromQuery =
          uri.queryParameters['subcategory_id'] ?? uri.queryParameters['subCatId'];
      final listingAlt =
          uri.queryParameters['listingId'] ?? uri.queryParameters['id'];

      final listingId = listingFromQuery ?? listingAlt;
      final subcategoryId = subcatFromPath ?? subcatFromQuery;

      if (listingId == null || listingId.isEmpty) return null;

      final qp = <String, String>{
        'listingId': listingId,
        if (subcategoryId != null && subcategoryId.isNotEmpty)
          'subcategory_id': subcategoryId,
      };
      final loc = Uri(path: '/products_details', queryParameters: qp).toString();
      debugPrint('DeepLinkMapper: mapped (single) -> $loc');
      return loc;
    }

    // --- 2) Category Listing (new format) ---
    if (segs.isNotEmpty && segs.first == 'category') {
      // Last segment has the subcategoryId at the end (e.g., "...-130")
      final lastSeg = segs.length >= 2 ? segs[1] : null;
      String? subcategoryId;
      if (lastSeg != null) {
        final match = RegExp(r'-(\d+)$').firstMatch(lastSeg);
        if (match != null) subcategoryId = match.group(1);
      }

      final listingId = uri.queryParameters['detailId'];
      if (listingId == null || listingId.isEmpty) return null;

      final qp = <String, String>{
        'listingId': listingId,
        if (subcategoryId != null) 'subcategory_id': subcategoryId,
      };
      final loc = Uri(path: '/products_details', queryParameters: qp).toString();
      debugPrint('DeepLinkMapper: mapped (category) -> $loc');
      return loc;
    }

    debugPrint('DeepLinkMapper: no match, ignore');
    return null;
  }
}



