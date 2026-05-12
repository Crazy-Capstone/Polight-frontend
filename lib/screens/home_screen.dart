import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _locationText = '위치 불러오는 중...';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocation('위치 서비스가 꺼져 있어요');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setLocation('위치 권한이 없어요');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final country = place.country ?? '';
        final city = place.locality?.isNotEmpty == true
            ? place.locality!
            : (place.administrativeArea ?? '');
        final flag = _codeToFlag(place.isoCountryCode ?? '');
        _setLocation('$flag $country · $city');
      } else {
        _setLocation('위치를 불러올 수 없어요');
      }
    } catch (_) {
      _setLocation('위치를 불러올 수 없어요');
    }
  }

  void _setLocation(String text) {
    if (!mounted) return;
    setState(() {
      _locationText = text;
      _isLoadingLocation = false;
    });
  }

  String _codeToFlag(String code) {
    if (code.length != 2) return '🌐';
    return code.toUpperCase().runes
        .map((r) => String.fromCharCode(r + 0x1F1A5))
        .join();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '좋은 아침이에요, 류지님 👋';
    if (hour >= 12 && hour < 18) return '좋은 오후예요, 류지님 👋';
    return '좋은 밤이에요, 류지님 👋';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildTravelCard(),
              const SizedBox(height: 28),
              _buildQuickMenu(),
              const SizedBox(height: 28),
              _buildInsuranceSummary(),
              const SizedBox(height: 20),
              _buildAiAssistant(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 헤더 ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '내 여행 현황',
              style: TextStyle(
                color: Color(0xFF001635),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF1FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF004D9D),
                  size: 22,
                ),
              ),
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF004D9D),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 여행 카드 ────────────────────────────────────────────────────────────
  Widget _buildTravelCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF004D9D), Color(0xFF0066C3), Color(0xFF0888F6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              const Text(
                '현재 여행 중',
                style: TextStyle(color: Color(0xFF9EBEFE), fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _isLoadingLocation
              ? const SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '위치 불러오는 중...',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Text(
                  _locationText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          const SizedBox(height: 6),
          const Text(
            '2025. 04. 08 — 04. 18 · D-7',
            style: TextStyle(color: Color(0xFFA6C8E8), fontSize: 12,fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFF4ADE80), size: 8),
                    SizedBox(width: 6),
                    Text(
                      '보험 활성',
                      style: TextStyle(
                        color: Color(0xFF9EBEFE),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                '보장률 92%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 빠른 메뉴 ────────────────────────────────────────────────────────────
  Widget _buildQuickMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 메뉴',
          style: TextStyle(
            color: Color(0xFF001635),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [

            Expanded(child: _buildQuickMenuCard(
              emoji: '📞',
              iconBgColor: const Color(0xFFF9DEDC),
              title: '긴급 전화',
              subtitle: '바로가기',
              subtitleColor: const Color(0xFFC0392B),
              borderColor: const Color(0xFFFFCCCC),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickMenuCard(
              emoji: '📄',
              iconBgColor: const Color(0xFFEBF1FF),
              title: '새 보험 업로드',
              subtitle: '바로가기',
              subtitleColor: const Color(0xFF0888F6),
              borderColor: const Color(0xFFE2E9FF),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickMenuCard({
    required String emoji,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required Color subtitleColor,
    Color borderColor = const Color(0xFFE5E7EB),
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 보험 현황 요약 ───────────────────────────────────────────────────────
  Widget _buildInsuranceSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '보험 현황 요약',
          style: TextStyle(
            color: Color(0xFF001635),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InsuranceItem(emoji: '🏥', label: '의료비', amount: '최대 1억원'),
              _InsuranceItem(emoji: '✈️', label: '항공 지연', amount: '최대 30만원'),
              _InsuranceItem(emoji: '🧳', label: '수하물', amount: '최대 50만원'),
              _InsuranceItem(emoji: '🚑', label: '긴급 이송', amount: '한도 없음'),
            ],
          ),
        ),
      ],
    );
  }

  // ─── AI 어시스턴트 배너 ───────────────────────────────────────────────────
  Widget _buildAiAssistant() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0888F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🤖', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 4),
                    Text(
                      'AI 어시스턴트',
                      style: TextStyle(color: Color(0xFFCEDDFE), fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '무엇이든 바로 물어보세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFFCEDDFE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '채팅하기',
              style: TextStyle(
                color: Color(0xFF001635),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 보험 항목 위젯 ───────────────────────────────────────────────────────
class _InsuranceItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String amount;

  const _InsuranceItem({
    required this.emoji,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
        ),
      ],
    );
  }
}
