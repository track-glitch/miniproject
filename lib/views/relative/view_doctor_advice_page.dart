import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:miniproject/views/login_page.dart';
import 'package:miniproject/views/relative/track_status_notification_page.dart';

/// หน้าวันนัดหมายและคำแนะนำ (View Doctor Advice Page)
class ViewDoctorAdvicePage extends StatefulWidget {
  final String? loggedUid;
  final Map<dynamic, dynamic>? doctorAdviceData;

  // 🌟 เพิ่มตัวแปรสำหรับรับข้อมูล "บริการปัจจุบัน" มาโชว์ด้านบนสุด
  final String? patientName;
  final String? dateTime;
  final String? hospital;
  final String? department;

  const ViewDoctorAdvicePage({
    super.key,
    this.loggedUid,
    this.doctorAdviceData,
    this.patientName,
    this.dateTime,
    this.hospital,
    this.department,
  });

  @override
  State<ViewDoctorAdvicePage> createState() => _ViewDoctorAdvicePageState();
}

class _ViewDoctorAdvicePageState extends State<ViewDoctorAdvicePage> {
  // ── 🎨 ชุดสีหลักของธีม ──
  static const Color primaryPurple = Color(0xFF9B59B6);
  static const Color darkPurple = Color(0xFF9B59B6);
  static const Color lightPink = Color(0xFFECE2FE);
  static const Color bgGray = Color.fromARGB(255, 225, 202, 255);
  static const Color borderColor = Color(0xFFD3C2F0);

  final Color bottomNavPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color searchPrimaryColor = const Color(0xFF9B59B6);

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
    final advice = widget.doctorAdviceData ?? {};

    // ตรวจสอบว่ามีการนัดหมายครั้งถัดไปหรือไม่
    String apptDate = advice['appointmentdate']?.toString() ?? '';
    bool hasNextAppt = apptDate.isNotEmpty && apptDate != 'null';

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
                    // 🌟 ข้อมูลบริการปัจจุบัน กลับมาเป็น 4 บรรทัดเหมือนเดิมแล้วครับ
                    _buildCurrentServiceCard(),
                    const SizedBox(height: 16),

                    // 🌟 ถ้ามีวันนัดหมายครั้งถัดไป ค่อยแสดงการ์ดนี้
                    if (hasNextAppt) ...[
                      _buildNextAppointmentCard(advice),
                      const SizedBox(height: 16),
                    ],

                    // 🌟 แสดงคำแนะนำ (ถ้าไม่มีรูป รูปจะถูกซ่อนอัตโนมัติ)
                    _buildAdditionalNoteCard(
                      advice['advicedetail']?.toString(),
                      advice['medicalphoto']?.toString(),
                    ),
                    const SizedBox(height: 24),

                    _buildConfirmButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI Components ----------------

  Widget _buildSectionHeaderInside(IconData icon, String title) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: primaryPurple, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: borderColor, thickness: 1),
        const SizedBox(height: 14),
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
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: primaryPurple.withOpacity(0.12),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  // 🌟 นำ Layout 4 บรรทัดกลับมา และใส่ข้อมูลจริง
  Widget _buildCurrentServiceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildSectionHeaderInside(
            Icons.medical_information_outlined,
            'ข้อมูลบริการปัจจุบัน',
          ),
          _buildInfoRow('ผู้ป่วย', widget.patientName ?? '-'),
          const Divider(height: 20, color: lightPink),
          _buildInfoRow('วัน/เวลา', widget.dateTime ?? '-'),
          const Divider(height: 20, color: lightPink),
          _buildInfoRow('สถานที่', widget.hospital ?? '-'),
          const Divider(height: 20, color: lightPink),
          _buildInfoRow('แผนก', widget.department ?? '-'),
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

  // 🌟 ฟังก์ชันสร้างการ์ดนัดหมาย โดยดึงข้อมูลมาจาก Firebase
  Widget _buildNextAppointmentCard(Map<dynamic, dynamic> advice) {
    String rawTime = advice['appointmenttime']?.toString() ?? '-';
    if (rawTime.contains('T')) {
      rawTime = '${rawTime.split('T').last.substring(0, 5)} น.';
    } else if (rawTime.length > 5 && rawTime.contains(':')) {
      rawTime = '${rawTime.substring(0, 5)} น.';
    }

    String rawDate = advice['appointmentdate']?.toString() ?? '-';
    if (rawDate.contains('-')) {
      final parts = rawDate.split('-');
      if (parts.length == 3) {
        rawDate = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }

    String doctor = advice['doctorname']?.toString() ?? '-';
    String hospital = advice['hospitalname']?.toString() ?? '-';
    String dept = advice['departmentname']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeaderInside(
            Icons.calendar_month_outlined,
            'การนัดหมายครั้งต่อไป',
          ),
          _buildLabeledField('แพทย์ผู้นัด', doctor.isEmpty ? '-' : doctor),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildLabeledField('วันที่', rawDate)),
              const SizedBox(width: 12),
              Expanded(child: _buildLabeledField('เวลา', rawTime)),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabeledField('สถานที่', hospital.isEmpty ? '-' : hospital),
          const SizedBox(height: 16),
          _buildLabeledField('แผนก', dept.isEmpty ? '-' : dept),
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
            border: Border.all(color: borderColor, width: 1.2),
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

  // 🌟 ฟังก์ชันสร้างการ์ดคำแนะนำ และเช็กว่ามีรูปภาพหรือไม่
  Widget _buildAdditionalNoteCard(String? adviceText, String? base64String) {
    Uint8List? imageBytes;

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
          _buildSectionHeaderInside(
            Icons.speaker_notes_outlined,
            'คำแนะนำจากแพทย์',
          ),
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
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Text(
              (adviceText == null || adviceText.trim().isEmpty)
                  ? 'ไม่มีคำแนะนำเพิ่มเติม'
                  : adviceText,
              style: TextStyle(
                fontSize: 14,
                color: (adviceText == null || adviceText.trim().isEmpty)
                    ? Colors.grey
                    : Colors.black87,
                height: 1.6,
              ),
            ),
          ),

          // 🌟 ถ้ามีรูปภาพแนบมา ค่อยโชว์ส่วนนี้
          if (imageBytes != null) ...[
            const SizedBox(height: 20),
            const Text(
              'ใบนัดแพทย์',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(10),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        InteractiveViewer(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(imageBytes!),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imageBytes,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.zoom_out_map, color: Colors.white),
                  ),
                ],
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
}
