import 'package:flutter/material.dart';
import '../../models/caretaker_model.dart';
import '../../services/admin_service.dart';
import 'view_caretaker_registration_page.dart';
import '../../views/login_page.dart';
import 'dart:convert';

class ListCaretakerPage extends StatefulWidget {
  final String uid;
  const ListCaretakerPage({super.key, required this.uid});

  @override
  State<ListCaretakerPage> createState() => _ListCaretakerPageState();
}

class _ListCaretakerPageState extends State<ListCaretakerPage> {
  final AdminService _adminService = AdminService();
  String adminName = '';
  String _selectedStatus = 'Pending';

  final Color primaryColor = const Color(0xFFA052BE);
  final Color backgroundColor = const Color(0xFFEDE4FF);
  final Color cardColor = const Color(0xFFF6EFFF);

  @override
  void initState() {
    super.initState();
    _fetchAdminName();
  }

  Future<void> _fetchAdminName() async {
    String name = await AdminService().getAdminName(widget.uid);
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
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

  Widget _buildPendingCard(CaretakerModel caretaker, int age) {
    String address = caretaker.location?.address ?? 'ไม่ระบุที่อยู่';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE6A500).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE6A500).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${caretaker.firstname} ${caretaker.lastname}',
                  style: const TextStyle(
                    fontSize: 18,
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
                  color: const Color(0xFFE6A500).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'รอตรวจสอบ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE6A500),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF0F0F0)),

          // 🌟 ข้อมูลส่วนตัว (ไม่มี Icon)
          Text(
            'เพศ: ${caretaker.gender ?? '-'}   อายุ: $age ปี',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'เบอร์โทร: ${caretaker.phonenumber ?? '-'}',
            style: const TextStyle(fontSize: 14),
          ),
          if (caretaker.email != null && caretaker.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'อีเมล: ${caretaker.email}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const SizedBox(height: 4),
          Text('ที่อยู่: $address', style: const TextStyle(fontSize: 14)),

          const Divider(height: 24, color: Color(0xFFF0F0F0)),

          // 🌟 ส่วนอัปเดตเพิ่มเติมในอนาคต (รถยนต์, รีวิว, รีพอร์ต)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFutureStatusText('รถยนต์', 'รออัปเดต', Colors.grey),
              _buildFutureStatusText('รีวิว', '-', Colors.grey),
              _buildFutureStatusText('รีพอร์ต', '0 ครั้ง', Colors.green),
            ],
          ),

          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ViewCaretakerRegistrationPage(caretaker: caretaker),
                  ),
                ).then((_) => setState(() {}));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'ตรวจสอบเอกสาร',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget ช่วยแสดงผลสถานะย่อย
  Widget _buildFutureStatusText(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedCard(CaretakerModel caretaker, int age) {
    return _buildBaseCard(
      caretaker: caretaker,
      age: age,
      statusText: 'อนุมัติแล้ว',
      statusColor: const Color(0xFF00FF29),
      actionButton: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3498DB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('ดูรายงาน', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildSuspendedCard(CaretakerModel caretaker, int age) {
    return _buildBaseCard(
      caretaker: caretaker,
      age: age,
      statusText: 'ระงับสิทธิ์',
      statusColor: const Color(0xFFFF0000),
      actionButton: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('ดูหมายเหตุ', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildBaseCard({
    required CaretakerModel caretaker,
    required int age,
    required Color statusColor,
    required String statusText,
    required Widget actionButton,
    bool isPending = false, // 🌟 พารามิเตอร์ใหม่
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
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
          const Divider(height: 24, color: Color(0xFFF0F0F0)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF82CDA4),
                  backgroundImage: _getProfileImageProvider(
                    caretaker.profilephoto,
                  ),
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
                      Icons.person_outline,
                      '${caretaker.gender ?? '-'}, $age ปี',
                    ),
                    _buildInfoRow(
                      Icons.directions_car_outlined,
                      '${caretaker.vehicle?.vehicletype ?? '-'} ${caretaker.vehicle?.brand ?? ''}',
                    ),
                    if (!isPending) ...[
                      // ถ้าไม่ใช่ Pending ให้โชว์เบอร์โทรปกติ
                      _buildInfoRow(
                        Icons.phone_outlined,
                        caretaker.phonenumber ?? '-',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // 🌟 ดีไซน์พิเศษ: โชว์กล่องข้อมูลการติดต่อสำหรับ "รอตรวจสอบ"
          if (isPending) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6), // สีพื้นหลังเหลืองอ่อนๆ
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Column(
                children: [
                  _buildContactRow(
                    Icons.phone,
                    'เบอร์โทร',
                    caretaker.phonenumber ?? '-',
                  ),
                  const SizedBox(height: 8),
                  _buildContactRow(
                    Icons.email,
                    'อีเมล',
                    caretaker.email ?? '-',
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Align(alignment: Alignment.bottomRight, child: actionButton),
        ],
      ),
    );
  }

  // 🌟 ฟังก์ชันแยกสำหรับกล่อง Contact
  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE6A500)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

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

  Widget _buildTab(String title, String status, Color dotColor) {
    bool isActive = _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = status;
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

  ImageProvider? _getProfileImageProvider(String? data) {
    if (data == null || data.trim().isEmpty) return null;

    // 🌟 1. ดักจับว่าเป็น URL จากอินเทอร์เน็ต (Cloudinary) หรือไม่
    if (data.startsWith('http')) {
      return NetworkImage(data);
    }

    // 🌟 2. ถ้าเป็นชื่อไฟล์ที่มีนามสกุล (เช่น profile.png)
    if (data.contains('.')) {
      return AssetImage('assets/images/Profile/$data');
    }

    // 🌟 3. นอกเหนือจากนั้น ถือว่าเป็น Base64
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'ออกจากระบบ',
            onPressed: () => _showLogoutConfirmDialog(context),
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  _buildTab('รอตรวจสอบ', 'Pending', const Color(0xFFFFD600)),
                  _buildTab('อนุมัติแล้ว', 'Approved', const Color(0xFF00FF29)),
                  _buildTab(
                    'ระงับสิทธิ์',
                    'Suspended',
                    const Color(0xFFFF0000),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: FutureBuilder<List<CaretakerModel>>(
              future: _adminService.getCaretakersByStatus(_selectedStatus),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: primaryColor.withOpacity(0.3),
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

                    if (_selectedStatus == 'Pending')
                      return _buildPendingCard(caretaker, age);
                    if (_selectedStatus == 'Approved')
                      return _buildApprovedCard(caretaker, age);
                    if (_selectedStatus == 'Suspended')
                      return _buildSuspendedCard(caretaker, age);
                    return const SizedBox();
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
