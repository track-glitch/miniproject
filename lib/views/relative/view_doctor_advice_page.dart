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
/// ออกแบบตามภาพตัวอย่าง - ใช้ข้อมูลสมมุติ (Mock Data)
/// ใช้โทนสีเดียวกับหน้า view_request_detail_page / search_caretaker_profile_page
class ViewDoctorAdvicePage extends StatefulWidget {
  final String? loggedUid; // เพิ่มเพื่อรับค่าผู้ใช้ที่ล็อกอินสำหรับแถบเมนูด้านล่าง

  const ViewDoctorAdvicePage({super.key, this.loggedUid});

  @override
  State<ViewDoctorAdvicePage> createState() => _ViewDoctorAdvicePageState();
}

class _ViewDoctorAdvicePageState extends State<ViewDoctorAdvicePage> {
  // ── 🎨 โทนสีเดียวกับหน้า view_request_detail_page ──
  static const Color primaryPurple = Color(0xFF8763E6); // ม่วงหลัก
  static const Color darkPurple = Color.fromARGB(255, 153, 116, 255); // ม่วงเข้ม
  static const Color lightPink = Color(0xFFECE2FE); // ม่วงอ่อนมาก
  static const Color bgGray = Color.fromARGB(255, 225, 202, 255); // พื้นหลังม่วงอ่อน

  // สีสำหรับเมนูด้านล่างและ Dialog ให้เหมือนหน้า Search
  final Color bottomNavPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color searchPrimaryColor = const Color(0xFF8763E6);

  bool _confirmNextAppointment = true;

  // ฟังก์ชันแจ้งเตือนให้เข้าสู่ระบบ (ยกมาจากหน้า Search)
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                Icon(Icons.lock_person_outlined, size: 75, color: bottomNavPurple),
                const SizedBox(height: 20),
                Text(
                  'กรุณาเข้าสู่ระบบก่อนใช้งาน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: bottomNavPurple),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      'ไปหน้าเข้าสู่ระบบ',
                      style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
      // ✅ นำ BottomNavigationBar รูปแบบหน้า Search มาใช้
      bottomNavigationBar: Container(
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
              false, // เป็นหน้าซ้อนเข้ามา เลยไม่ต้องตั้งให้ Active
              onTap: () {
                // กลับไปหน้าแรกสุด
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            _buildBottomNavItem(
              Icons.support_agent,
              'ขอใช้บริการ',
              false,
              onTap: () {
                // กลับไปหน้าแรกสุด หรือ pop 
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            _buildBottomNavItem(
              Icons.notifications_none,
              'แจ้งเตือน',
              false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrackStatusNotificationPage(loggedUid: widget.loggedUid)),
                );
              },
            ),
            _buildBottomNavItem(
              Icons.person_outline,
              'ญาติ',
              false,
              onTap: () async {
                String currentUid = widget.loggedUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

                if (currentUid.isEmpty) {
                  _showLoginRequiredDialog();
                  return;
                }

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final snapshot = await FirebaseDatabase.instance.ref('Login').get();
                  if (context.mounted) Navigator.pop(context);

                  String targetRelativeId = '';
                  Map<String, dynamic> targetUserData = {};
                  bool isFound = false;

                  if (snapshot.exists && snapshot.value is Map) {
                    final allUsers = Map<String, dynamic>.from(snapshot.value as Map);

                    for (var key in allUsers.keys) {
                      if (key == currentUid) {
                        targetRelativeId = key;
                        targetUserData = Map<String, dynamic>.from(allUsers[key] as Map);
                        isFound = true;
                        break;
                      }

                      var childData = allUsers[key];
                      if (childData is Map) {
                        var relNode = childData['Relative'];
                        if (childData['uid'] == currentUid || (relNode is Map && relNode['relativeId'] == currentUid)) {
                          targetRelativeId = key;
                          targetUserData = Map<String, dynamic>.from(childData);
                          isFound = true;
                          break;
                        }
                      }
                    }
                  }

                  if (isFound && targetRelativeId.isNotEmpty) {
                    RelativeModel relative;
                    Map<String, dynamic> relativeMap = {};

                    if (targetUserData.containsKey('Relative')) {
                      relativeMap = Map<String, dynamic>.from(targetUserData['Relative'] as Map);
                      relative = RelativeModel(
                        relativeId: relativeMap['relativeId'] ?? targetRelativeId,
                        firstname: relativeMap['firstname'] ?? '',
                        lastname: relativeMap['lastname'] ?? '',
                        phonenumber: relativeMap['phonenumber'] ?? '',
                        relationship: relativeMap['relationship'] ?? '',
                        email: relativeMap['email'] ?? '',
                      );
                    } else {
                      relative = RelativeModel(
                        relativeId: targetRelativeId, firstname: '', lastname: '', phonenumber: '', relationship: '', email: '',
                      );
                    }

                    PatientModel patient;
                    if (relativeMap.containsKey('Patient')) {
                      final pData = Map<String, dynamic>.from(relativeMap['Patient'] as Map);
                      patient = PatientModel(
                        patientId: pData['patientId'] ?? '',
                        patientphoto: pData['patientphoto'] ?? '',
                        firstname: pData['firstname'] ?? '',
                        lastname: pData['lastname'] ?? '',
                        phonenumber: pData['phonenumber'] ?? '',
                        gender: pData['gender'] ?? '',
                        birthdate: pData['birthdate'] != null ? DateTime.tryParse(pData['birthdate'].toString()) : null,
                        disease: pData['disease'] ?? '',
                        mobility: pData['mobility'] ?? '',
                      );
                    } else {
                      patient = PatientModel(
                        patientId: '', patientphoto: '', firstname: '', lastname: '', phonenumber: '', gender: '',
                      );
                    }

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditRelativeInfoPage(
                            currentPatient: patient,
                            currentRelative: relative,
                            loggedUid: targetRelativeId,
                          ),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ไม่พบข้อมูลประวัติ (กรุณาลองเข้าสู่ระบบใหม่อีกครั้ง)')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget สร้างปุ่มด้านล่างเหมือนหน้า Search
  Widget _buildBottomNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
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
          // ✅ เปลี่ยนไอคอนให้เหมือนหน้า Search และใช้ pop
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
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