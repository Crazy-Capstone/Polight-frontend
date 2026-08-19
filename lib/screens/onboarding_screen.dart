import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/auth_service.dart';
import 'kakao_login_webview.dart';

// ── 데이터 모델 ───────────────────────────────────────────────
class _OnboardingSlide {
  final String image;
  final String title;
  final double titleFontSize;
  final String subtitle;
  final bool isFinal;

  const _OnboardingSlide({
    required this.image,
    required this.title,
    required this.titleFontSize,
    required this.subtitle,
    this.isFinal = false,
  });
}

const List<_OnboardingSlide> _kSlides = [
  _OnboardingSlide(
    image: 'assets/images/onboarding_01_welcome.png',
    title: '반가워요!\n여행 보험, 이제 Polight와',
    titleFontSize: 28,
    subtitle: '보장 확인부터 사고 대응까지\n한 앱에서 끝내요',
  ),
  _OnboardingSlide(
    image: 'assets/images/onboarding_02_coverage.png',
    title: '내 보장 내역을\n한눈에 확인하세요',
    titleFontSize: 26,
    subtitle: '의료비 · 항공 지연 · 수하물까지\n한도와 제외 항목을 바로 확인',
  ),
  _OnboardingSlide(
    image: 'assets/images/onboarding_03_chatbot.png',
    title: '궁금한 건 PoPo에게\n바로 물어보세요',
    titleFontSize: 26,
    subtitle: '지연 보상 기준부터 청구 방법까지\n24시간 즉시 답변해 드려요',
  ),
  _OnboardingSlide(
    image: 'assets/images/onboarding_04_hospital.png',
    title: '아플 때 가까운 병원,\n경찰서까지 바로 연결',
    titleFontSize: 26,
    subtitle: '현재 위치 기준 가까운 병원과\n주변 경찰서,대사관을 안내해요',
  ),
  _OnboardingSlide(
    image: 'assets/images/onboarding_05_kakao.png',
    title: '3초 만에 시작해요\n가입은 카카오로 간단하게',
    titleFontSize: 26,
    subtitle: '증권 업로드 한 번이면\nAI가 보장 내용을 정리해 드려요',
    isFinal: true,
  ),
];

// ── 화면 ─────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  /// 온보딩을 마쳤을 때(건너뛰기 · 마지막 페이지 진행 · 카카오 시작) 호출된다.
  final VoidCallback? onFinished;

  const OnboardingScreen({super.key, this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  final _authService = AuthService();
  int _page = 0;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_page < _kSlides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onFinished?.call();
    }
  }

  /// '건너뛰기'는 로그인 자체를 건너뛰지 않고, 카카오 로그인 버튼이 있는
  /// 마지막 페이지로만 바로 이동시킨다.
  void _skipToLogin() {
    _controller.animateToPage(
      _kSlides.length - 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _startKakaoLogin() async {
    if (_isLoggingIn) return;
    setState(() => _isLoggingIn = true);

    try {
      final code = await Navigator.of(context).push<String?>(
        MaterialPageRoute(builder: (_) => const KakaoLoginWebView()),
      );
      if (code == null) return; // 사용자가 취소했거나 동의를 거부함

      await _authService.loginWithKakao(code);
      widget.onFinished?.call();
    } on KakaoConfigException catch (e) {
      _showError(e.message);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('카카오 로그인 중 문제가 발생했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 배경(히어로 이미지)만 스와이프로 움직인다
          PageView.builder(
            controller: _controller,
            itemCount: _kSlides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _OnboardingBackground(slide: _kSlides[i]),
          ),
          // 텍스트 · 인디케이터 · 버튼은 스와이프와 무관하게 한 자리에 고정된다
          _OnboardingOverlay(
            slide: _kSlides[_page],
            pageIndex: _page,
            pageCount: _kSlides.length,
            onNext: _goNext,
            onKakaoLogin: _startKakaoLogin,
            isLoggingIn: _isLoggingIn,
          ),
          // 마지막 페이지는 카카오 버튼이 곧 액션이라 건너뛰기를 두지 않는다
          if (!_kSlides[_page].isFinal)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 24, 0),
                  child: GestureDetector(
                    onTap: _skipToLogin,
                    child: Text(
                      '건너뛰기',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 14,
                        height: 1.21,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0888F6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 배경(히어로 이미지 + 페이드) ─────────────────────────────────
// PageView 안에 이것만 들어가서, 스와이프하면 이 배경만 움직인다.
class _OnboardingBackground extends StatelessWidget {
  final _OnboardingSlide slide;

  const _OnboardingBackground({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 히어로 이미지 (아이폰 시안 목업)
        Image.asset(
          slide.image,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        // 상단 텍스트가 잘 보이도록 위쪽을 흰색으로 서서히 덮는다
        const Positioned.fill(child: _TopFade()),
        // 버튼 영역이 잘 보이도록 아래쪽을 흰색으로 서서히 덮는다
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: slide.isFinal ? 260 : 200,
          child: const _BottomFade(),
        ),
      ],
    );
  }
}

// ── 고정 오버레이(텍스트 · 인디케이터 · 버튼) ─────────────────────
// PageView 밖의 Stack에 고정으로 얹혀서 스와이프에 반응하지 않고,
// 현재 페이지 내용만 그대로 갱신된다.
class _OnboardingOverlay extends StatelessWidget {
  final _OnboardingSlide slide;
  final int pageIndex;
  final int pageCount;
  final VoidCallback onNext;
  final VoidCallback onKakaoLogin;
  final bool isLoggingIn;

  const _OnboardingOverlay({
    required this.slide,
    required this.pageIndex,
    required this.pageCount,
    required this.onNext,
    required this.onKakaoLogin,
    required this.isLoggingIn,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 64),
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: slide.titleFontSize,
                height: 1.18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF001635),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              slide.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 15,
                height: 1.2,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF3F6DA8),
              ),
            ),
            const Spacer(),
            if (!slide.isFinal) ...[
              _DotsIndicator(activeIndex: pageIndex, count: pageCount),
              const SizedBox(height: 16),
              _NextButton(onTap: onNext),
            ] else ...[
              _KakaoButton(onTap: onKakaoLogin, isLoading: isLoggingIn),
              const SizedBox(height: 8),
              Text(
                '가입 시 이용약관 및 개인정보 처리방침에 동의합니다',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  height: 1.17,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7C93B5),
                ),
              ),
            ],
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ── 상단/하단 흰색 페이드 ─────────────────────────────────────
class _TopFade extends StatelessWidget {
  const _TopFade();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Colors.transparent(검정+alpha0)로 페이드하면 중간에 회색/어두운 띠가
          // 생긴다 — alpha만 0으로 가는 흰색(0x00FFFFFF)으로 페이드해야 깨끗하다.
          colors: [
            Colors.white,
            Colors.white,
            Color(0xB3FFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0, 0.3, 0.42, 0.58],
        ),
      ),
    );
  }
}

class _BottomFade extends StatelessWidget {
  const _BottomFade();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00FFFFFF), Colors.white, Colors.white],
          stops: [0, 0.7, 1],
        ),
      ),
    );
  }

}

// ── 페이지 인디케이터 ─────────────────────────────────────────
class _DotsIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;

  const _DotsIndicator({required this.activeIndex, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return Padding(
          padding: EdgeInsets.only(right: i == count - 1 ? 0 : 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF0888F6)
                  : const Color(0xFFCEDDFE),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

// ── 다음 버튼 ─────────────────────────────────────────────────
class _NextButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NextButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0888F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '다음',
          style: GoogleFonts.notoSansKr(
            fontSize: 17,
            height: 1.18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── 카카오로 시작하기 버튼 ─────────────────────────────────────
class _KakaoButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _KakaoButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE500),
          borderRadius: BorderRadius.circular(16),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Color(0xFF181600),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/onboarding_kakao_icon.svg',
                    width: 19.14,
                    height: 17.85,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '카카오로 시작하기',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 17,
                      height: 1.18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181600),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
