import 'package:flutter/material.dart';
import '../core/models/hospital_result.dart';

class HospitalCard extends StatelessWidget {
  final HospitalResult hospital;
  const HospitalCard({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAF5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEBFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('🏥', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.name,
                  style: const TextStyle(
                    fontSize: 12.48,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF001635),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '한국어 통역 가능 · ${hospital.formattedDistance}',
                  style: const TextStyle(
                    fontSize: 10.4,
                    color: Color(0xFF4A6080),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '제휴',
              style: TextStyle(
                fontSize: 10.4,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0066C3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
