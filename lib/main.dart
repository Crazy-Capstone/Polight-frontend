import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/models/trip_document.dart';
import 'core/models/trip_session.dart';
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
      home: const _RootScreen(),
    );
  }
}

// ── 로그인 상태에 따라 온보딩 또는 메인 화면으로 분기한다 ──────────
// 이미 로그인돼 있으면(유효한 토큰이 있으면) 온보딩을 건너뛰고 바로 메인으로 진입한다.
class _RootScreen extends StatefulWidget {
  const _RootScreen();

  @override
  State<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<_RootScreen> {
  /// null이면 로그인 상태 확인 중.
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    final accessToken = await TokenStorage().readValid();
    if (!mounted) return;
    setState(() => _showOnboarding = accessToken == null);
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
      return OnboardingScreen(
        onFinished: () => setState(() => _showOnboarding = false),
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

