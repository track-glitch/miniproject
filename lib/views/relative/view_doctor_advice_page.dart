import 'package:flutter/material.dart';

/// หน้าวันนัดหมายและคำแนะนำ (View Doctor Advice Page)
/// ออกแบบตามภาพตัวอย่าง - ใช้ข้อมูลสมมุติ (Mock Data)
/// ใช้โทนสีเดียวกับหน้า view_request_detail_page / search_caretaker_profile_page
class ViewDoctorAdvicePage extends StatefulWidget {
  const ViewDoctorAdvicePage({super.key});

  @override
  State<ViewDoctorAdvicePage> createState() => _ViewDoctorAdvicePageState();
}

class _ViewDoctorAdvicePageState extends State<ViewDoctorAdvicePage> {
  // ── 🎨 โทนสีเดียวกับหน้า view_request_detail_page ──
  static const Color primaryPurple = Color(0xFF8763E6); // ม่วงหลัก
  static const Color darkPurple = Color.fromARGB(255, 153, 116, 255); // ม่วงเข้ม
  static const Color lightPink = Color(0xFFECE2FE); // ม่วงอ่อนมาก
  static const Color bgGray = Color.fromARGB(255, 225, 202, 255); // พื้นหลังม่วงอ่อน

  bool _confirmNextAppointment = true;

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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentServiceCard(),
                    const SizedBox(height: 16),
                    _buildNextAppointmentCard(),
                    const SizedBox(height: 16),
                    _buildAdditionalNoteCard(),
                    const SizedBox(height: 20),
                    _buildConfirmButton(),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ---------------- Header ----------------
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'วันนัดหมายและคำแนะนำ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
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
      border: Border.all(color: lightPink),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ---------------- Current service info card ----------------
  Widget _buildCurrentServiceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ข้อมูลบริการปัจจุบัน',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkPurple,
                  ),
                ),
              ),
              const Text(
                '# REQ-12345',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow('ผู้ป่วย:', 'นาย ใจงาม จิตดี'),
          const SizedBox(height: 6),
          _buildInfoRow('วัน/เวลา:', '22 ก.พ. 2569 10:30 น.'),
          const SizedBox(height: 6),
          _buildInfoRow('สถานที่:', 'โรงพยาบาลแม่โจ้'),
          const SizedBox(height: 6),
          _buildInfoRow('แผนก:', 'ตรวจสุขภาพ'),
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
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Next appointment card ----------------
  Widget _buildNextAppointmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'การนัดหมายครั้งต่อไป',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkPurple,
                  ),
                ),
              ),
              Checkbox(
                value: _confirmNextAppointment,
                activeColor: primaryPurple,
                onChanged: (val) {
                  setState(() {
                    _confirmNextAppointment = val ?? false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildLabeledField('แพทย์ผู้นัด', 'นาย ประกอบ จันทร์รักษา'),
          const SizedBox(height: 12),
          _buildLabeledField('วันที่', '13/03/2569'),
          const SizedBox(height: 12),
          _buildLabeledField('เวลา', '8:00 น.'),
          const SizedBox(height: 12),
          _buildLabeledField('สถานที่', 'โรงพยาบาลแม่โจ้'),
          const SizedBox(height: 12),
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
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: lightPink,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: lightPink),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // ---------------- Additional note card ----------------
  Widget _buildAdditionalNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'รายละเอียด/คำแนะนำเพิ่มเติม',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkPurple,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightPink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'ร่างกายไม่ค่อยมีแรง พยายามเดินออกกำลังกายเบาๆ',
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          // Mock attached prescription / document image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              height: 140,
              color: const Color(0xFFEFEFEF),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 140),
                    painter: _DocumentPlaceholderPainter(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'นี่คือภาพตัวอย่าง',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  // ---------------- Confirm button ----------------
  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          Navigator.maybePop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'ตกลง',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ---------------- Bottom nav ----------------
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, 'บ้าน', false),
              _navItem(Icons.check_circle_outline, 'ยืนยันการจอง', false),
              _navItem(Icons.notifications_none, 'สถานะการจัดเตือน', false),
              _navItem(Icons.person_outline, 'ญาติ', true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    final color = active ? primaryPurple : Colors.grey;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: color, fontSize: 9),
            textAlign: TextAlign.center),
      ],
    );
  }
}

/// Painter วาดเอกสาร/ใบสั่งยาจำลอง (mock document lines) สำหรับรูปตัวอย่าง
class _DocumentPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 2;

    double y = 20;
    while (y < size.height - 10) {
      canvas.drawLine(
        Offset(size.width * 0.15, y),
        Offset(size.width * 0.85, y),
        linePaint,
      );
      y += 18;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
