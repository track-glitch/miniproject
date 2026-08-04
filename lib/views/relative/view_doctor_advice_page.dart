import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- เปลี่ยน Path ให้ตรงกับโฟลเดอร์ในโปรเจกต์ของคุณ ---
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:miniproject/views/login_page.dart';
import 'package:miniproject/views/relative/track_status_notification_page.dart';

/// หน้าวันนัดหมายและคำแนะนำ (View Doctor Advice Page)
class ViewDoctorAdvicePage extends StatefulWidget {
  final String? loggedUid;

  const ViewDoctorAdvicePage({super.key, this.loggedUid});

  @override
  State<ViewDoctorAdvicePage> createState() => _ViewDoctorAdvicePageState();
}

class _ViewDoctorAdvicePageState extends State<ViewDoctorAdvicePage> {
  // ── 🎨 โทนสีเดียวกับหน้า view_request_detail_page ──
  static const Color primaryPurple = Color(0xFF8763E6);
  static const Color darkPurple = Color.fromARGB(255, 153, 116, 255);
  static const Color lightPink = Color(0xFFECE2FE);
  static const Color bgGray = Color.fromARGB(
    255,
    245,
    239,
    255,
  ); // ปรับให้อ่อนลงนิดนึงเพื่อให้การ์ดดูเด่นขึ้น

  final Color bottomNavPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color searchPrimaryColor = const Color(0xFF8763E6);

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: searchPrimaryColor, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_person_outlined,
                  size: 75,
                  color: bottomNavPurple,
                ),
                const SizedBox(height: 20),
                Text(
                  'กรุณาเข้าสู่ระบบก่อนใช้งาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: bottomNavPurple,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'คุณต้องลงชื่อเข้าใช้งานในระบบก่อน จึงจะสามารถแก้ไขข้อมูลได้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: searchPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'ไปหน้าเข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGray,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      Icons.medical_information_outlined,
                      'ข้อมูลบริการปัจจุบัน',
                    ),
                    const SizedBox(height: 12),
                    _buildCurrentServiceCard(),

                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      Icons.calendar_month_outlined,
                      'การนัดหมายครั้งต่อไป',
                    ),
                    const SizedBox(height: 12),
                    _buildNextAppointmentCard(),

                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      Icons.speaker_notes_outlined,
                      'คำแนะนำจากแพทย์',
                    ),
                    const SizedBox(height: 12),
                    _buildAdditionalNoteCard(),

                    const SizedBox(height: 30),
                    _buildConfirmButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ---------------- UI Components ----------------

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: primaryPurple, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: darkPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkPurple, primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'คำแนะนำและวันนัดหมาย',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: primaryPurple.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildCurrentServiceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // ลบ parameter รูปไอคอนออกทั้งหมด
          _buildInfoRow('ผู้ป่วย', 'นาย ใจงาม จิตดี'),
          const Divider(height: 20, color: lightPink),
          _buildInfoRow('วัน/เวลา', '22 ก.พ. 2569 10:30 น.'),
          const Divider(height: 20, color: lightPink),
          _buildInfoRow('สถานที่', 'โรงพยาบาลแม่โจ้'),
          const Divider(height: 20, color: lightPink),
          _buildInfoRow('แผนก', 'ตรวจสุขภาพ'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildNextAppointmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ลบ parameter รูปไอคอนออกทั้งหมด
          _buildLabeledField('แพทย์ผู้นัด', 'นาย ประกอบ จันทร์รักษา'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildLabeledField('วันที่', '13/03/2569')),
              const SizedBox(width: 12),
              Expanded(child: _buildLabeledField('เวลา', '8:00 น.')),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabeledField('สถานที่', 'โรงพยาบาลแม่โจ้'),
          const SizedBox(height: 16),
          _buildLabeledField('แผนก', 'ตรวจสุขภาพ'),
        ],
      ),
    );
  }

  Widget _buildLabeledField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: lightPink.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lightPink, width: 1.5),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // อย่าลืมส่งค่า base64 จากฐานข้อมูลเข้ามาในฟังก์ชันนี้แทนค่า String ว่างนะครับ
  Widget _buildAdditionalNoteCard({String? base64String}) {
    Uint8List? imageBytes;

    // 🌟 ตรวจสอบและแปลง Base64 พร้อมจัดการ Padding ป้องกัน Error
    if (base64String != null && base64String.isNotEmpty) {
      try {
        String normalized = base64String.replaceAll(RegExp(r'\s+'), '');
        int padLength = (4 - (normalized.length % 4)) % 4;
        normalized = normalized.padRight(normalized.length + padLength, '=');
        imageBytes = base64Decode(normalized);
      } catch (e) {
        print("Error decoding image: $e");
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายละเอียดเพิ่มเติม',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightPink.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: lightPink, width: 1.5),
            ),
            child: const Text(
              'ร่างกายไม่ค่อยมีแรง พยายามเดินออกกำลังกายเบาๆ รับประทานอาหารให้ครบ 5 หมู่ และพักผ่อนให้เพียงพอ', // ดึงข้อมูลจริงมาใส่แทน
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ),

          // 🌟 แสดงส่วนรูปภาพก็ต่อเมื่อมีการแปลงไฟล์สำเร็จเท่านั้น
          if (imageBytes != null) ...[
            const SizedBox(height: 20),
            const Text(
              'รูปภาพ / เอกสารแนบ',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                // 🌟 กดเพื่อดูรูปขนาดเต็ม (InteractiveViewer ยืดขยายได้)
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(10),
                    child: InteractiveViewer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(imageBytes!),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  imageBytes,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.maybePop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          elevation: 4,
          shadowColor: primaryPurple.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: const Text(
          'รับทราบข้อมูล',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ---------------- Bottom Navigation ----------------
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: bottomNavPurple,
        boxShadow: [
          BoxShadow(
            color: bottomNavPurple.withOpacity(0.27),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(
            Icons.home_outlined,
            'บ้าน',
            false,
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
          _buildBottomNavItem(
            Icons.support_agent,
            'ขอใช้บริการ',
            false,
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
          _buildBottomNavItem(
            Icons.notifications_none,
            'แจ้งเตือน',
            false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TrackStatusNotificationPage(loggedUid: widget.loggedUid),
                ),
              );
            },
          ),
          _buildBottomNavItem(
            Icons.person_outline,
            'ญาติ',
            false,
            onTap: () {
              // ลอจิกเดิมของคุณ...
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 2;

    double y = 25;
    while (y < size.height - 15) {
      canvas.drawLine(
        Offset(size.width * 0.15, y),
        Offset(size.width * 0.85, y),
        linePaint,
      );
      y += 20;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
