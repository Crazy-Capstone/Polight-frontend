import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/services/auth_service.dart';

/// 카카오 로그인 동의 화면을 웹뷰로 띄우고, redirect_uri 로 돌아오면
/// 그 안의 `code` 파라미터(인가 코드)를 pop 결과로 돌려준다.
/// 사용자가 취소하거나 동의를 거부하면 null을 돌려준다.
class KakaoLoginWebView extends StatefulWidget {
  const KakaoLoginWebView({super.key});

  @override
  State<KakaoLoginWebView> createState() => _KakaoLoginWebViewState();
}

class _KakaoLoginWebViewState extends State<KakaoLoginWebView> {
  WebViewController? _controller;
  String? _configError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final authService = AuthService();
    try {
      final authorizeUri = authService.buildKakaoAuthorizeUri();
      final redirectUri = AuthService.kakaoRedirectUri;

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onNavigationRequest: (request) {
              if (request.url.startsWith(redirectUri)) {
                _handleRedirect(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(authorizeUri);
    } on KakaoConfigException catch (e) {
      _configError = e.message;
    }
  }

  void _handleRedirect(String url) {
    final code = Uri.parse(url).queryParameters['code'];
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF001635)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '카카오 로그인',
          style: TextStyle(color: Color(0xFF001635)),
        ),
      ),
      body: _configError != null
          ? _buildConfigError(_configError!)
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_isLoading) const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }

  Widget _buildConfigError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF4A6080)),
        ),
      ),
    );
  }
}
