import 'package:flutter/material.dart';
import '../../models/caretaker_model.dart';
import '../../services/admin_service.dart';
import 'view_caretaker_registration_page.dart'; // อย่าลืม import หน้าดูรายละเอียด
import '../../views/login_page.dart';
import 'dart:convert'; // 🌟 1. เพิ่มบรรทัดนี้ด้านบนสุดของไฟล์

class ListCaretakerPage extends StatefulWidget {
  final String uid;
  const ListCaretakerPage({super.key, required this.uid});

  @override
  State<ListCaretakerPage> createState() => _ListCaretakerPageState();
}

class _ListCaretakerPageState extends State<ListCaretakerPage> {
  final AdminService _adminService = AdminService();
  String adminName = '';
  // ตัวแปรเก็บสถานะแท็บปัจจุบัน ค่าเริ่มต้นคือรอดำเนินการ
  String _selectedStatus = 'Pending';

  final Color primaryColor = const Color(0xFFA052BE);
  final Color backgroundColor = const Color(0xFFEDE4FF);
  final Color cardColor = const Color(0xFFF6EFFF);

  @override
  void initState() {
    super.initState();
    // 3. ให้เรียกใช้ฟังก์ชันดึงข้อมูลทันทีที่เปิดหน้านี้ขึ้นมา
    _fetchAdminName();
  }

  Future<void> _fetchAdminName() async {
    // สังเกตว่าเราใช้ widget.uid เพื่อดึงค่า uid ที่ส่งมาจากหน้าก่อน
    String name = await AdminService().getAdminName(widget.uid);

    // 5. เมื่อได้ข้อมูลมาแล้ว ใช้ setState เพื่อสั่งให้หน้าจออัปเดตข้อความ
    setState(() {
      adminName = name;
    });
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ออกจากระบบ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // 1. ปิด Popup
              Navigator.pop(context);
              // 2. ล้างข้อมูลและเด้งกลับไปหน้า Login (แทนที่ LoginPage() ด้วยหน้าล็อกอินของคุณ)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ), // ใส่ชื่อคลาสหน้า Login
                (route) => false,
              );
            },
            child: const Text(
              'ออกจากระบบ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันคำนวณอายุจากวันเกิด
  int _calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    int month1 = currentDate.month;
    int month2 = birthDate.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthDate.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  // ==========================================
  // 🟡 การ์ดสำหรับแท็บ "รอตรวจสอบ"
  // ==========================================
  Widget _buildPendingCard(CaretakerModel caretaker, int age) {
    return _buildBaseCard(
      caretaker: caretaker,
      age: age,
      statusColor: const Color(
        0xFFE6A500,
      ), // ปรับเหลืองให้เข้มขึ้นเพื่อให้อ่านง่าย
      statusText: 'รอตรวจสอบ', // 🌟 เพิ่มบรรทัดนี้
      actionButton: ElevatedButton(
        onPressed: () {
          // ไปหน้ารายละเอียดเพื่อ อนุมัติ/ไม่อนุมัติ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ViewCaretakerRegistrationPage(caretaker: caretaker),
            ),
          ).then((_) {
            setState(() {}); // รีเฟรชหน้าเมื่อกลับมา
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('ตรวจสอบรายละเอียด', style: TextStyle(fontSize: 11)),
      ),
    );
  }

  // ==========================================
  // 🟢 การ์ดสำหรับแท็บ "อนุมัติแล้ว"
  // ==========================================
  Widget _buildApprovedCard(CaretakerModel caretaker, int age) {
    return _buildBaseCard(
      caretaker: caretaker,
      age: age,
      statusText: 'อนุมัติแล้ว',
      statusColor: const Color(0xFF00FF29), // สีเขียว
      actionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 💡 ในอนาคตคุณสามารถเพิ่มปุ่มอื่นๆ ตรงนี้ได้ เช่น ปุ่มดูโปรไฟล์, ปุ่มแบน
          ElevatedButton(
            onPressed: () {
              // TODO: 🚀 ใส่ฟังก์ชันไปหน้า "ดูรายงาน" ตรงนี้ในอนาคต
              print("ไปหน้าดูรายงานของ ${caretaker.firstname}");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFF3498DB,
              ), // ใช้สีฟ้าน้ำเงินสำหรับปุ่มรายงาน
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ดูรายงาน', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🔴 การ์ดสำหรับแท็บ "ระงับสิทธิ์"
  // ==========================================
  Widget _buildSuspendedCard(CaretakerModel caretaker, int age) {
    return _buildBaseCard(
      caretaker: caretaker,
      age: age,
      statusText: 'ระงับสิทธิ์',
      statusColor: const Color(0xFFFF0000), // สีแดง
      actionButton: ElevatedButton(
        onPressed: () {
          // TODO: อาจจะทำปุ่มให้กดดูเหตุผลที่โดนแบน หรือ ปุ่มปลดแบน
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('ดูหมายเหตุ', style: TextStyle(fontSize: 11)),
      ),
    );
  }

  // ==========================================
  // 🛠️ ฟังก์ชันฐาน (Base Card) สำหรับวาดโครงสร้างหลักที่เหมือนกัน
  // ==========================================
  // ==========================================
  // 🛠️ ฟังก์ชันฐาน (Base Card) ดีไซน์ใหม่
  // ==========================================
  Widget _buildBaseCard({
    required CaretakerModel caretaker,
    required int age,
    required Color statusColor,
    required String statusText, // 🌟 รับข้อความสถานะมาด้วย
    required Widget actionButton,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // เปลี่ยนพื้นเป็นสีขาวเพื่อให้เงาโดดเด่น
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15), // เงาสีม่วงฟุ้งๆ
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ ส่วนหัว: ชื่อ และ ป้ายสถานะแบบ Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${caretaker.firstname} ${caretaker.lastname}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF0F0F0)), // เส้นคั่นบางๆ
          // 👤 ส่วนเนื้อหา: รูปโปรไฟล์ และ ข้อมูล
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // กรอบรูปโปรไฟล์มีสีม่วงล้อมรอบนิดๆ
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF82CDA4),
                  backgroundImage: _getProfileImageProvider(
                    caretaker.profilephoto,
                  ), // 🌟 ดัก Base64 แล้ว
                  child: (caretaker.profilephoto?.isEmpty ?? true)
                      ? const Icon(Icons.person, size: 36, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      Icons.phone_outlined,
                      caretaker.phonenumber ?? '-',
                    ),
                    _buildInfoRow(
                      Icons.person_outline,
                      '${caretaker.gender ?? '-'}, $age ปี',
                    ),
                    _buildInfoRow(
                      Icons.directions_car_outlined,
                      '${caretaker.vehicle?.vehicletype} ${caretaker.vehicle?.brand}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(alignment: Alignment.bottomRight, child: actionButton),
        ],
      ),
    );
  }

  // 🌟 ฟังก์ชันวาดไอคอนนำหน้าข้อความ
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้าง UI ของแท็บ
  Widget _buildTab(String title, String status, Color dotColor) {
    bool isActive = _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = status; // อัปเดตสถานะเมื่อกดแท็บ
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 2. นำฟังก์ชันนี้ไปวางไว้ด้านใน _ListCaretakerPageState (วางไว้ใต้ตัวแปรสีก็ได้ครับ)
  ImageProvider? _getProfileImageProvider(String? data) {
    if (data == null || data.trim().isEmpty) return null;
    if (data.contains('.')) return AssetImage('assets/images/Profile/$data');
    try {
      return MemoryImage(base64Decode(data));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        centerTitle: true,
        title: Text(
          'Hello, $adminName',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'ออกจากระบบ',
            onPressed: () {
              _showLogoutConfirmDialog(
                context,
              ); // เรียกฟังก์ชันถามยืนยันก่อนออก
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'รายการสมัครผู้ดูแล',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // ส่วนของแท็บ (Tabs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  _buildTab('รอตรวจสอบ', 'Pending', const Color(0xFFFFD600)),
                  _buildTab('อนุมัติแล้ว', 'Approved', const Color(0xFF00FF29)),
                  _buildTab(
                    'ระงับสิทธิ์',
                    'Suspended',
                    const Color(0xFFFF0000),
                  ), // หรือ 'Rejected' ตาม DB
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // รายการการ์ดตามสถานะ
          Expanded(
            child: FutureBuilder<List<CaretakerModel>>(
              // ส่ง _selectedStatus ไปเพื่อดึงข้อมูลใหม่ทุกครั้งที่แท็บเปลี่ยน
              future: _adminService.getCaretakersByStatus(_selectedStatus),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                // ค้นหาบรรทัดนี้ในฟังก์ชัน build
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ไม่มีข้อมูลในหมวดหมู่นี้',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final caretakers = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: caretakers.length,
                  itemBuilder: (context, index) {
                    final caretaker = caretakers[index];
                    final int age = caretaker.birthdate != null
                        ? _calculateAge(caretaker.birthdate!)
                        : 0;

                    // 🔀 เช็กสถานะแท็บปัจจุบัน แล้วแยกไปเรียกการ์ดแต่ละแบบ
                    if (_selectedStatus == 'Pending') {
                      return _buildPendingCard(caretaker, age);
                    } else if (_selectedStatus == 'Approved') {
                      return _buildApprovedCard(caretaker, age);
                    } else if (_selectedStatus == 'Suspended') {
                      return _buildSuspendedCard(caretaker, age);
                    }

                    return const SizedBox(); // กันเหนียวกรณีไม่มีสถานะ
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
