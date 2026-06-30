import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- เปลี่ยน Path ให้ตรงกับโฟลเดอร์ในโปรเจกต์ของคุณ ---
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:miniproject/views/login_page.dart';
import 'package:miniproject/views/relative/track_status_notification_page.dart';
import 'package:miniproject/views/relative/view_doctor_advice_page.dart';

/// หน้ารายละเอียดคำขอ (View Request Detail Page)
/// ออกแบบตามภาพตัวอย่าง - ใช้ข้อมูลสมมุติ (Mock Data)
class ViewRequestDetailPage extends StatefulWidget {
  final String?
  loggedUid; // เพิ่มเพื่อรับค่าผู้ใช้ที่ล็อกอินสำหรับแถบเมนูด้านล่าง

  const ViewRequestDetailPage({super.key, this.loggedUid});

  @override
  State<ViewRequestDetailPage> createState() => _ViewRequestDetailPageState();
}

class _ViewRequestDetailPageState extends State<ViewRequestDetailPage> {
  // ── 🎨 ปรับให้เป็นโทนสีเดียวกับหน้า search_caretaker_profile_page ──
  static const Color primaryPurple = Color(0xFF8763E6); // ม่วงหลัก
  static const Color darkPurple = Color.fromARGB(
    255,
    153,
    116,
    255,
  ); // ม่วงเข้ม
  static const Color lightPink = Color(0xFFECE2FE); // ม่วงอ่อนมาก (แทนชมพูเดิม)
  static const Color bgGray = Color.fromARGB(
    255,
    225,
    202,
    255,
  ); // พื้นหลังม่วงอ่อน

  // สีสำหรับเมนูด้านล่างและ Dialog ให้เหมือนหน้า Search
  final Color bottomNavPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color searchPrimaryColor = const Color(0xFF8763E6);

  // ฟังก์ชันแจ้งเตือนให้เข้าสู่ระบบ (ยกมาจากหน้า Search)
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
    return DefaultTabController(
      length: 1,
      child: Scaffold(
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
                      _buildHospitalCard(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('ข้อมูลผู้ป่วย'),
                      const SizedBox(height: 8),
                      _buildPatientCard(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('ญาติ'),
                      const SizedBox(height: 8),
                      _buildRelativeCard(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('วันและเวลานัดหมาย'),
                      const SizedBox(height: 8),
                      _buildAppointmentCard(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('จุดรับจุดส่ง'),
                      const SizedBox(height: 8),
                      _buildMapCard(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('รายละเอียดคำขอ'),
                      const SizedBox(height: 8),
                      _buildRequestDetailCard(),
                      const SizedBox(height: 20),
                      _buildAppointmentButton(),
                      const SizedBox(height: 12),
                      _buildSummaryLink(),
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
                true, // ให้หน้าบ้าน/รายการ Active ไว้ตามหลัก
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
                  Navigator.pop(context);
                },
              ),
              _buildBottomNavItem(
                Icons.notifications_none,
                'แจ้งเตือน',
                false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackStatusNotificationPage(
                        loggedUid: widget.loggedUid,
                      ),
                    ),
                  );
                },
              ),
              _buildBottomNavItem(
                Icons.person_outline,
                'ญาติ',
                false,
                onTap: () async {
                  String currentUid =
                      widget.loggedUid ??
                      FirebaseAuth.instance.currentUser?.uid ??
                      '';

                  if (currentUid.isEmpty) {
                    _showLoginRequiredDialog();
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final snapshot = await FirebaseDatabase.instance
                        .ref('Login')
                        .get();
                    if (context.mounted) Navigator.pop(context);

                    String targetRelativeId = '';
                    Map<String, dynamic> targetUserData = {};
                    bool isFound = false;

                    if (snapshot.exists && snapshot.value is Map) {
                      final allUsers = Map<String, dynamic>.from(
                        snapshot.value as Map,
                      );

                      for (var key in allUsers.keys) {
                        if (key == currentUid) {
                          targetRelativeId = key;
                          targetUserData = Map<String, dynamic>.from(
                            allUsers[key] as Map,
                          );
                          isFound = true;
                          break;
                        }

                        var childData = allUsers[key];
                        if (childData is Map) {
                          var relNode = childData['Relative'];
                          if (childData['uid'] == currentUid ||
                              (relNode is Map &&
                                  relNode['relativeId'] == currentUid)) {
                            targetRelativeId = key;
                            targetUserData = Map<String, dynamic>.from(
                              childData,
                            );
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
                        relativeMap = Map<String, dynamic>.from(
                          targetUserData['Relative'] as Map,
                        );
                        relative = RelativeModel(
                          relativeId:
                              relativeMap['relativeId'] ?? targetRelativeId,
                          firstname: relativeMap['firstname'] ?? '',
                          lastname: relativeMap['lastname'] ?? '',
                          phonenumber: relativeMap['phonenumber'] ?? '',
                          relationship: relativeMap['relationship'] ?? '',
                          email: relativeMap['email'] ?? '',
                        );
                      } else {
                        relative = RelativeModel(
                          relativeId: targetRelativeId,
                          firstname: '',
                          lastname: '',
                          phonenumber: '',
                          relationship: '',
                          email: '',
                        );
                      }

                      PatientModel patient;
                      if (relativeMap.containsKey('Patient')) {
                        final pData = Map<String, dynamic>.from(
                          relativeMap['Patient'] as Map,
                        );
                        patient = PatientModel(
                          patientId: pData['patientId'] ?? '',
                          patientphoto: pData['patientphoto'] ?? '',
                          firstname: pData['firstname'] ?? '',
                          lastname: pData['lastname'] ?? '',
                          phonenumber: pData['phonenumber'] ?? '',
                          gender: pData['gender'] ?? '',
                          birthdate: pData['birthdate'] != null
                              ? DateTime.tryParse(pData['birthdate'].toString())
                              : null,
                          disease: pData['disease'] ?? '',
                          mobility: pData['mobility'] ?? '',
                        );
                      } else {
                        patient = PatientModel(
                          patientId: '',
                          patientphoto: '',
                          firstname: '',
                          lastname: '',
                          phonenumber: '',
                          gender: '',
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
                          const SnackBar(
                            content: Text(
                              'ไม่พบข้อมูลประวัติ (กรุณาลองเข้าสู่ระบบใหม่อีกครั้ง)',
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('เกิดข้อผิดพลาด: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
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
          // ✅ เปลี่ยนไอคอนให้เหมือนหน้า Search และแก้การทำงานเป็น pop
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'รายละเอียดคำขอ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer ให้ข้อความอยู่ตรงกลาง
        ],
      ),
    );
  }

  // ---------------- Section title ----------------
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: darkPurple,
          ),
        ),
        const SizedBox(height: 6),
        Container(width: double.infinity, height: 1, color: lightPink),
      ],
    );
  }

  // ---------------- Card wrapper ----------------
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ---------------- Hospital card ----------------
  Widget _buildHospitalCard() {
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
                  'โรงพยาบาลสันทราย',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'กำลังให้บริการ',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '# REQ-12345',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: lightPink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'กระดูกและข้อ',
              style: TextStyle(
                color: primaryPurple,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Patient card ----------------
  Widget _buildPatientCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: lightPink,
            child: Icon(Icons.person, color: primaryPurple, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      'นาง สมใจ รักดี',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'อายุ 68 ปี - เพศหญิง',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'เดินไปได้',
                        style: TextStyle(
                          color: Color(0xFFE65100),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.favorite, color: Colors.red, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'โรคหัวใจ',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.phone, color: Colors.grey, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'เบอร์ผู้ป่วย  062-345-6789',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Relative card ----------------
  Widget _buildRelativeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'นาย สมศักดิ์ รักดี',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: lightPink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'บุตร',
                  style: TextStyle(color: primaryPurple, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.phone, color: Colors.grey, size: 14),
              SizedBox(width: 4),
              Text(
                'เบอร์โทร  081-234-5678',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 14),
              SizedBox(width: 4),
              Text(
                'LINE ID  somsak_rd',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Appointment card ----------------
  Widget _buildAppointmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: lightPink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: primaryPurple,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'วันศุกร์ที่ 16 มกราคม 2568',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'เวลา 08:00 น.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'อีก 4 วัน',
              style: TextStyle(color: Color(0xFFE65100), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Map + route card ----------------
  Widget _buildMapCard() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                color: const Color(0xFFEFEFEF),
                child: CustomPaint(painter: _MapPlaceholderPainter()),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'ระยะทาง 12.4 กม.',
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoutePoint(
                  label: 'จุดรับ',
                  letter: 'A',
                  title: '99/12 หมู่ 5 ซอยสุขใจ ถ.เชียงใหม่-แม่โจ้',
                  subtitle: 'ต.หนองหาร อ.สันทราย จ.เชียงใหม่ 50290',
                  color: primaryPurple,
                ),
                const SizedBox(height: 10),
                _buildRoutePoint(
                  label: 'จุดส่ง',
                  letter: 'B',
                  title: 'โรงพยาบาลสันทราย (ทางเข้าหลัก)',
                  subtitle: null,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePoint({
    required String label,
    required String letter,
    required String title,
    String? subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Request detail card ----------------
  Widget _buildRequestDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Text(
        'ต้องการผู้แลคุณแม่อายุ 68 ปี ไปพบแพทย์ '
        'เพื่อตรวจติดตามอาการโรคหัวใจ ขอให้ดูแลเป็นพิเศษระหว่างเดินทาง',
        style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
      ),
    );
  }

  // ---------------- Buttons ----------------
  Widget _buildAppointmentButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ViewDoctorAdvicePage(),
            ),
          );},
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
        label: const Text(
          'นัดหมายและคำแนะนำ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSummaryLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ViewDoctorAdvicePage(),
            ),
          );
        },
        child: const Text(
          'รายงานผู้ดูแล',
          style: TextStyle(
            color: primaryPurple,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Widget สร้างปุ่มด้านล่างเหมือนหน้า Search
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

/// Painter วาดเส้นทางจำลองบนแผนที่ placeholder (mock route line)
class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.4,
      size.width * 0.6,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.6,
      size.width * 0.8,
      size.height * 0.25,
    );
    canvas.drawPath(path, linePaint);

    final pointPaintA = Paint()
      ..color = _ViewRequestDetailPageState.primaryPurple;
    final pointPaintB = Paint()..color = Colors.green;

    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.75),
      6,
      pointPaintA,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.25),
      6,
      pointPaintB,
    );

    final roadPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 2;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i + 20, size.height), roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
