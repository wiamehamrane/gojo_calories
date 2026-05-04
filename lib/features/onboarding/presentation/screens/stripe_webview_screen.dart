import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:gojocalories/core/theme/app_colors.dart';

class StripeWebViewScreen extends StatefulWidget {
  final String? url;
  final String? htmlContent;

  const StripeWebViewScreen({super.key, this.url, this.htmlContent});

  @override
  State<StripeWebViewScreen> createState() => _StripeWebViewScreenState();
}

class _StripeWebViewScreenState extends State<StripeWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasNavigatedToStripe = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
          onUrlChange: (UrlChange change) {
            final url = change.url?.toLowerCase() ?? '';
            if (url.contains('checkout.stripe.com')) {
              _hasNavigatedToStripe = true;
            } else if (_hasNavigatedToStripe && url.contains('gojocalories.com')) {
              if (mounted) context.pop(true);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            
            if (url.contains('checkout.stripe.com')) {
              _hasNavigatedToStripe = true;
            }

            // Intercept success/cancel if they contain specific markers
            if (url.contains('success') || url.contains('completed') || url.contains('session_id')) {
              context.pop(true); // Return true to indicate completion
              return NavigationDecision.prevent;
            }
            if (url.contains('cancel')) {
              context.pop(false);
              return NavigationDecision.prevent;
            }
            
            // If returning to our domain after checkout
            if (_hasNavigatedToStripe && url.contains('gojocalories.com')) {
              context.pop(true);
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    if (widget.htmlContent != null) {
      _controller.loadHtmlString(
        widget.htmlContent!,
        baseUrl: 'https://gojocalories.com',
      );
    } else if (widget.url != null) {
      _controller.loadRequest(Uri.parse(widget.url!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Secure Checkout', style: TextStyle(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(false),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
