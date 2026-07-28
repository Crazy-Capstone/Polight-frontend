import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models/hospital_result.dart';

class HospitalCard extends StatelessWidget {
  final HospitalResult hospital;
  const HospitalCard({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAF5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('🏥', style: TextStyle(fontSize: 18.72)),
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
                        fontSize: 13.52,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1C3F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          hospital.formattedDistance,
                          style: const TextStyle(
                            fontSize: 11.44,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        if (hospital.rating != null) ...[
                          const Text(
                            ' · ',
                            style: TextStyle(
                                fontSize: 11.44, color: Color(0xFF6B7280)),
                          ),
                          const Icon(Icons.star_rounded,
                              size: 12, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 2),
                          Text(
                            hospital.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11.44,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hospital.address,
            style: const TextStyle(
              fontSize: 11.44,
              color: Color(0xFF9CA3AF),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openMaps,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFD0FF), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_rounded,
                      size: 14, color: Color(0xFF0E2A6E)),
                  SizedBox(width: 4),
                  Text(
                    '길찾기',
                    style: TextStyle(
                      fontSize: 12.48,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0E2A6E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(hospital.googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
