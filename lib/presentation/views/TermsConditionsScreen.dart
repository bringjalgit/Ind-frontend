import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
        ),
      )
      ..loadFlutterAsset('assets/legal/terms-and-conditions.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        elevation: 0.5,
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
