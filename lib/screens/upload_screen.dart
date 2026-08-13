import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'trip_info_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedFile = result.files.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '파일을 불러오는 중 오류가 발생했어요',
              style: GoogleFonts.notoSansKr(),
            ),
            backgroundColor: const Color(0xFF001635),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFile() {
    setState(() => _selectedFile = null);
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildStepIndicator(),
                    const SizedBox(height: 18),
                    _buildDescription(),
                    const SizedBox(height: 18),
                    _selectedFile != null
                        ? _buildSelectedFileCard()
                        : _buildUploadCard(),
                    const SizedBox(height: 20),
                    _buildOrDivider(),
                    const SizedBox(height: 20),
                    _buildRecentFilesSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildNextButton(),
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
                      '증권 업로드',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 18.72,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF001635),
                      ),
                    ),
                    Text(
                      '보험 PDF를 업로드해 주세요',
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
        _StepCircle(number: 1, label: 'PDF 업로드', isActive: true),
        _StepLine(),
        _StepCircle(number: 2, label: '여행 정보', isActive: false),
        _StepLine(),
        _StepCircle(number: 3, label: '걱정 선택', isActive: false),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      children: [
        Text(
          '보험 증권 PDF를 업로드하면',
          style: GoogleFonts.notoSansKr(
            fontSize: 14.56,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4A6080),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          'AI가 보장 내용을 자동으로 분석해드려요',
          style: GoogleFonts.notoSansKr(
            fontSize: 14.56,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF001635),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E9FF), width: 1),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _PdfFileIcon(size: 64),
              Positioned(
                right: -10,
                bottom: -4,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0066C3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.upload, color: Colors.white, size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'PDF 파일을 선택해 주세요',
            style: GoogleFonts.notoSansKr(
              fontSize: 13.52,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF001635),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '최대 20MB · PDF 형식',
            style: GoogleFonts.notoSansKr(
              fontSize: 11.44,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8BA3CC),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066C3),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF8BA3CC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '파일 선택하기',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13.52,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFileCard() {
    final file = _selectedFile!;
    final sizeKb = file.size / 1024;
    final sizeText = sizeKb >= 1024
        ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
        : '${sizeKb.toStringAsFixed(0)} KB';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0066C3), width: 1.5),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _PdfFileIcon(size: 64),
              Positioned(
                right: -10,
                bottom: -4,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            file.name,
            style: GoogleFonts.notoSansKr(
              fontSize: 13.52,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF001635),
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            sizeText,
            style: GoogleFonts.notoSansKr(
              fontSize: 11.44,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8BA3CC),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _clearFile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4A6080),
                      side: const BorderSide(color: Color(0xFFE2E9FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      '파일 삭제',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13.52,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _pickFile,
                    style: ElevatedButton.styleFrom(

                      backgroundColor: const Color(0xFF0066C3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '파일 변경',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13.52,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E9FF), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '또는',
            style: GoogleFonts.notoSansKr(
              fontSize: 11.44,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8BA3CC),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E9FF), thickness: 1)),
      ],
    );
  }

  Widget _buildRecentFilesSection() {
    const files = [
      _FileItem(name: '여행자보험_증권_2025.pdf', meta: '345 KB · 2025.04.01'),
      _FileItem(name: '해외여행보험_삼성화재.pdf', meta: '512 KB · 2025.01.15'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 사용한 파일',
          style: GoogleFonts.notoSansKr(
            fontSize: 13.52,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF001635),
          ),
        ),
        const SizedBox(height: 10),
        ...files.map((f) => _buildFileListItem(f)),
      ],
    );
  }

  Widget _buildFileListItem(_FileItem file) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFile = PlatformFile(name: file.name, size: 0);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E9FF), width: 1),
        ),
        child: Row(
          children: [
            _PdfFileIcon(size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12.48,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF001635),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file.meta,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 10.4,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF4A6080),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF8BA3CC),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      color: const Color(0xFFF0F4FF),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _selectedFile != null
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TripInfoScreen(),
                    ),
                  )
              : null,
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
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;

  const _StepCircle({
    required this.number,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0066C3) : Colors.transparent,
            shape: BoxShape.circle,
            border: isActive
                ? null
                : Border.all(color: const Color(0xFF8BA3CC), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
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
            color: isActive ? const Color(0xFF0066C3) : const Color(0xFF8BA3CC),
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 1,
      margin: const EdgeInsets.only(bottom: 20),
      color: const Color(0xFFD0DCF0),
    );
  }
}

class _PdfFileIcon extends StatelessWidget {
  final double size;
  const _PdfFileIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    final double fontSize = size * 0.17;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(size * 0.14),
      ),
      child: Stack(
        children: [
          Positioned(
            top: size * 0.12,
            left: size * 0.14,
            right: size * 0.14,
            bottom: size * 0.12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.1),
                border: Border.all(color: const Color(0xFFE2E9FF), width: 1),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.18,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.1,
                  vertical: size * 0.04,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066C3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'PDF',
                  style: GoogleFonts.notoSansKr(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

class _FileItem {
  final String name;
  final String meta;
  const _FileItem({required this.name, required this.meta});
}
