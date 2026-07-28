import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/coverage_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/mypage_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066C3)),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    HomeScreen(onChatTap: () => setState(() => _currentIndex = 2)),
    const CoverageScreen(),
    const ChatbotScreen(),
    const MypageScreen(),
  ];

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
