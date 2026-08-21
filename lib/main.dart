import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/app_log.dart';
import 'core/models/trip_document.dart';
import 'core/models/trip_session.dart';
import 'core/services/auth_service.dart';
import 'core/services/token_storage.dart';
import 'screens/home_screen.dart';
import 'screens/coverage_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 앱 전체에서 하나뿐인 하단 탭 네비게이션 화면을 가리킨다.
/// 다른 화면에서 push해서 들어온 흐름을 끝내고 특정 탭으로 돌아갈 때 쓴다.
final GlobalKey<_MainNavigationScreenState> _mainNavigationKey =
    GlobalKey<_MainNavigationScreenState>();

/// 분석이 끝난 여행/문서를 들고 '보장내역' 탭으로 전환한다.
/// 하단 GNB가 있는 화면으로 돌아가야 하므로, 이 화면 위로 쌓인 라우트를
/// 모두 pop한 뒤에 호출해야 한다.
void showCoverageTabForTrip({
  required TripSession trip,
  required TripDocument document,
}) {
  _mainNavigationKey.currentState?._showCoverageTab(
    trip: trip,
    document: document,
  );
}

/// 로그인 상태를 가리키는 최상위 화면. 로그아웃할 때 여기 상태를 되돌린다.
final GlobalKey<_RootScreenState> _rootScreenKey = GlobalKey<_RootScreenState>();

/// 저장된 토큰·프로필을 지우고 온보딩 화면으로 돌아간다.
Future<void> signOutToOnboarding() async {
  await _rootScreenKey.currentState?._signOut();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 디자인 기준 스마트폰 화면 크기. 웹에서 이 비율을 그대로 유지한다.
  static const Size _designSize = Size(390, 844);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066C3)),
      ),
      // 웹 브라우저에서 열었을 때 앱을 390x844 스마트폰 화면 크기로 고정하고
      // 양옆은 흰색으로 채운다. 창 크기와 상관없이 항상 이 크기 그대로이며
      // 창에 맞춰 늘어나거나 줄어들지 않는다. 앱/모바일 웹에서는 영향 없다.
      builder: (context, child) {
        if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();
        return Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: SizedBox(
            width: _designSize.width,
            height: _designSize.height,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(size: _designSize),
              child: child,
            ),
          ),
        );
      },
      home: _RootScreen(key: _rootScreenKey),
    );
  }
}

// ── 로그인 상태에 따라 온보딩 또는 메인 화면으로 분기한다 ──────────
// 이미 로그인돼 있으면(유효한 토큰이 있으면) 온보딩을 건너뛰고 바로 메인으로 진입한다.
class _RootScreen extends StatefulWidget {
  const _RootScreen({super.key});

  @override
  State<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<_RootScreen> {
  /// null이면 로그인 상태 확인 중.
  bool? _showOnboarding;

  /// 웹에서 카카오 리다이렉트로 돌아와 로그인을 시도했다가 실패했을 때의
  /// 안내 문구. 온보딩 화면에 한 번 전달하고 나면 비운다.
  String? _kakaoLoginError;

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    if (kIsWeb) {
      // 카카오 인증 페이지에서 이 주소(redirect_uri)로 돌아오면 앱이 이
      // 지점부터 새로 시작되므로, 주소에 code가 붙어 있는지 먼저 확인한다.
      final code = Uri.base.queryParameters['code'];
      appLog('RootScreen',
          '앱 시작: url=${Uri.base} code=${code == null ? '없음' : '있음'}');
      if (code != null && code.isNotEmpty) {
        try {
          await AuthService().loginWithKakao(code);
          if (!mounted) return;
          appLog('RootScreen', '카카오 리다이렉트 로그인 완료 → 홈으로');
          setState(() => _showOnboarding = false);
          return;
        } catch (e) {
          appLog('RootScreen', '카카오 리다이렉트 로그인 실패: $e');
          _kakaoLoginError = e is KakaoConfigException || e is AuthException
              ? (e as dynamic).message as String
              : '카카오 로그인 중 문제가 발생했어요. 다시 시도해 주세요.';
        }
      }
    }

    final accessToken = await TokenStorage().readValid();
    if (!mounted) return;
    appLog('RootScreen',
        '저장된 토큰 확인: ${accessToken == null ? '없음 → 온보딩' : '있음 → 홈'}');
    setState(() => _showOnboarding = accessToken == null);
  }

  /// 저장된 토큰·프로필을 지우고 온보딩으로 되돌린다.
  /// 웹에서는 주소에 남아 있는 ?code=... 때문에 앱을 새로 열면 이미 써버린
  /// 인가 코드로 다시 로그인을 시도하게 되므로, 그 쿼리도 함께 지운다.
  Future<void> _signOut() async {
    await TokenStorage().clear();
    appLog('RootScreen', '로그아웃 완료 → 온보딩');
    if (!mounted) return;
    setState(() {
      _kakaoLoginError = null;
      _showOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showOnboarding = _showOnboarding;
    if (showOnboarding == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0066C3)),
        ),
      );
    }

    if (showOnboarding) {
      final error = _kakaoLoginError;
      _kakaoLoginError = null;
      return OnboardingScreen(
        onFinished: () => setState(() => _showOnboarding = false),
        initialErrorMessage: error,
      );
    }
    return MainNavigationScreen(key: _mainNavigationKey);
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  /// 분석이 막 끝난 여행/문서. '보장내역' 탭이 처음부터 실데이터를 그리도록
  /// 넘겨준다. 없으면 그 탭이 스스로 최근 여행을 불러온다.
  TripSession? _coverageTrip;
  TripDocument? _coverageDocument;

  List<Widget> get _screens => [
    HomeScreen(onChatTap: () => setState(() => _currentIndex = 2)),
    CoverageScreen(trip: _coverageTrip, document: _coverageDocument),
    const ChatbotScreen(),
    const MypageScreen(),
  ];

  void _showCoverageTab({
    required TripSession trip,
    required TripDocument document,
  }) {
    setState(() {
      _coverageTrip = trip;
      _coverageDocument = document;
      _currentIndex = 1;
    });
  }

  static const Color _activeColor = Color(0xFF0066C3);
  static const Color _inactiveColor = Color(0xFF8BA3CC);

  static const List<_NavItem> _navItems = [
    _NavItem(icon: 'assets/images/nav_home.svg', label: '홈'),
    _NavItem(icon: 'assets/images/nav_list.svg', label: '보장내역'),
    _NavItem(icon: 'assets/images/nav_chat.svg', label: '챗봇'),
    _NavItem(icon: 'assets/images/nav_mypage.svg', label: '마이페이지'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E9FF), width: 1.2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _activeColor,
          unselectedItemColor: _inactiveColor,
          selectedLabelStyle: GoogleFonts.notoSansKr(
            fontSize: 10.4,
            fontWeight: FontWeight.w700,
            color: _activeColor,
          ),
          unselectedLabelStyle: GoogleFonts.notoSansKr(
            fontSize: 10.4,
            fontWeight: FontWeight.w600,
            color: _inactiveColor,
          ),
          items: List.generate(
            _navItems.length,
            (i) => BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: SvgPicture.asset(
                  _navItems[i].icon,
                  width: 14,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    _inactiveColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: SvgPicture.asset(
                  _navItems[i].icon,
                  width: 14,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    _activeColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              label: _navItems[i].label,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

