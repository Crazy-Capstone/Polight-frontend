import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/models/trip_session.dart';

class ConcernSelectionScreen extends StatefulWidget {
  /// 이전 단계에서 생성된 여행 세션. 걱정 선택 결과를 저장할 때 함께 쓰인다.
  final TripSession trip;

  const ConcernSelectionScreen({super.key, required this.trip});

  @override
  State<ConcernSelectionScreen> createState() => _ConcernSelectionScreenState();
}

class _ConcernSelectionScreenState extends State<ConcernSelectionScreen> {
  String _selectedCategory = '전체';
  final Set<String> _selectedConcerns = {};

  static const List<String> _categories = ['전체', '건강·의료', '분실·도난', '항공·기타'];

  static const List<_ConcernCategory> _allCategories = [
    _ConcernCategory(
      name: '건강·의료',
      items: [
        _ConcernItem(emoji: '🏥', label: '다치거나 아플까 봐'),
        _ConcernItem(emoji: '🤒', label: '질병에 걸릴까 봐'),
        _ConcernItem(emoji: '🍱', label: '식중독에 걸릴까 봐'),
        _ConcernItem(emoji: '🦠', label: '특정 전염병 걸릴까 봐'),
      ],
    ),
    _ConcernCategory(
      name: '분실·도난',
      items: [
        _ConcernItem(emoji: '🧳', label: '짐이 분실·파손될까 봐'),
        _ConcernItem(emoji: '🛂', label: '여권을 잃어버릴까 봐'),
        _ConcernItem(emoji: '👜', label: '소매치기 당할까 봐'),
      ],
    ),
    _ConcernCategory(
      name: '항공·기타',
      items: [
        _ConcernItem(emoji: '✈️', label: '비행기 지연·결항될까 봐'),
        _ConcernItem(emoji: '🚨', label: '여행을 중단해야 할까 봐'),
        _ConcernItem(emoji: '⚖️', label: '남에게 피해줄까 봐'),
        _ConcernItem(emoji: '🩺', label: '큰 사고로 후유증 남을까 봐'),
      ],
    ),
  ];

  List<_ConcernCategory> get _visibleCategories {
    if (_selectedCategory == '전체') return _allCategories;
    return _allCategories.where((c) => c.name == _selectedCategory).toList();
  }

  void _toggleConcern(String label) {
    setState(() {
      if (_selectedConcerns.contains(label)) {
        _selectedConcerns.remove(label);
      } else {
        _selectedConcerns.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildStepIndicator(),
                    const SizedBox(height: 16),
                    _buildCategoryFilter(),
                    const SizedBox(height: 20),
                    ..._visibleCategories.map(_buildCategorySection),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Color(0xFF001635),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '걱정되는 상황 선택',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 18.72,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF001635),
                      ),
                    ),
                    Text(
                      '선택한 항목을 보장 내역 상단에 먼저 보여드려요',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11.44,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4A6080),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E9FF)),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ConcernStepCircle(
          number: 1,
          label: 'PDF 업로드',
          state: _ConcernStepState.completed,
        ),
        _ConcernStepLine(),
        _ConcernStepCircle(
          number: 2,
          label: '여행 정보',
          state: _ConcernStepState.completed,
        ),
        _ConcernStepLine(),
        _ConcernStepCircle(
          number: 3,
          label: '걱정 선택',
          state: _ConcernStepState.active,
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEBF3FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0066C3) : const Color(0xFFE2E9FF),
                  width: 1.5,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13.52,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF0066C3) : const Color(0xFF4A6080),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategorySection(_ConcernCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name,
          style: GoogleFonts.notoSansKr(
            fontSize: 13.52,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF001635),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 174 / 80,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: category.items.map(_buildConcernCard).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildConcernCard(_ConcernItem item) {
    final isSelected = _selectedConcerns.contains(item.label);
    return GestureDetector(
      onTap: () => _toggleConcern(item.label),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0066C3) : const Color(0xFFE2E9FF),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 27.04)),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11.44,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF001635),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0066C3) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0066C3)
                        : const Color(0xFFD0DCF0),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E9FF)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  '선택한 항목',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13.52,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A6080),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedConcerns.length}개',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12.48,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0066C3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedConcerns.isNotEmpty ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066C3),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD0DCF0),
                  disabledForegroundColor: const Color(0xFF8BA3CC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '다음',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 15.6,
                    fontWeight: FontWeight.w700,
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

enum _ConcernStepState { completed, active, inactive }

class _ConcernStepCircle extends StatelessWidget {
  final int number;
  final String label;
  final _ConcernStepState state;

  const _ConcernStepCircle({
    required this.number,
    required this.label,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = state == _ConcernStepState.completed;
    final isActive = state == _ConcernStepState.active;
    final isInactive = state == _ConcernStepState.inactive;

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: (isCompleted || isActive)
                ? const Color(0xFF0066C3)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: isInactive
                ? Border.all(color: const Color(0xFF8BA3CC), width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '$number',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12.48,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : const Color(0xFF8BA3CC),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 10.4,
            fontWeight: FontWeight.w700,
            color: (isCompleted || isActive)
                ? const Color(0xFF0066C3)
                : const Color(0xFF8BA3CC),
          ),
        ),
      ],
    );
  }
}

class _ConcernStepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 1,
      margin: const EdgeInsets.only(bottom: 20),
      color: const Color(0xFFD0DCF0),
    );
  }
}

class _ConcernCategory {
  final String name;
  final List<_ConcernItem> items;
  const _ConcernCategory({required this.name, required this.items});
}

class _ConcernItem {
  final String emoji;
  final String label;
  const _ConcernItem({required this.emoji, required this.label});
}
