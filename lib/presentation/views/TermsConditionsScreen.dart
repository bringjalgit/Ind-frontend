import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../utils/legal_link_handler.dart';

/// In-app viewer for the Terms & Conditions document.
///
/// Loads the bundled legal HTML (assets/legal/terms-and-conditions.html) into
/// a WebView so the full styled document — TOC, sections, fonts and the small
/// helper JS (active-section highlight, back-to-top) — renders faithfully.
/// JavaScript is enabled for those niceties; the page is local so there is no
/// remote navigation. Reached from the login screens' "Terms & Conditions"
/// link and the Smart Assist consent row.
class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFCFCFA))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) =>
              handleLegalLinkTap(request, context),
        ),
      )
      ..loadFlutterAsset('assets/legal/terms-and-conditions.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF1C2430),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF1C2430),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Color(0xFF1C2430),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
