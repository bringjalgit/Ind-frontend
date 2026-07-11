import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../utils/legal_link_handler.dart';

/// In-app viewer for the Payment, Cancellation, Refund & Shipping Policy.
///
/// Loads the bundled legal HTML (assets/legal/payment-policy.html) into a
/// WebView so the styled document renders faithfully. The page is local, so
/// there is no remote navigation. Reached from the Profile page.
class PaymentPolicyScreen extends StatefulWidget {
  const PaymentPolicyScreen({super.key});

  @override
  State<PaymentPolicyScreen> createState() => _PaymentPolicyScreenState();
}

class _PaymentPolicyScreenState extends State<PaymentPolicyScreen> {
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
      ..loadFlutterAsset('assets/legal/payment-policy.html');
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
          'Payment & Refund Policy',
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
