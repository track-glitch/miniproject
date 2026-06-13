import 'package:flutter/material.dart';
import '../../models/caretaker_model.dart';
import '../../services/admin_service.dart';
import 'view_caretaker_registration_page.dart'; // อย่าลืม import หน้าดูรายละเอียด

class ListCaretakerPage extends StatefulWidget {
  const ListCaretakerPage({super.key});

  @override
  State<ListCaretakerPage> createState() => _ListCaretakerPageState();
}

class _ListCaretakerPageState extends State<ListCaretakerPage> {
  final AdminService _adminService = AdminService();

  // ตัวแปรเก็บสถานะแท็บปัจจุบัน ค่าเริ่มต้นคือรอดำเนินการ
  String _selectedStatus = 'Pending'; 

  final Color primaryColor = const Color(0xFFA052BE);
  final Color backgroundColor = const Color(0xFFEDE4FF);
  final Color cardColor = const Color(0xFFF6EFFF);

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
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        centerTitle: true,
        title: const Text(
          'แอดมิน มิก',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'รายการสมัครผู้ดูแล',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 16),
          
          // ส่วนของแท็บ (Tabs)
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
                  _buildTab('', 'Suspended', const Color(0xFFFF0000)), // หรือ 'Rejected' ตาม DB
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
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('ไม่มีข้อมูลในหมวดหมู่นี้', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }

                final caretakers = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: caretakers.length,
                  itemBuilder: (context, index) {
                    final caretaker = caretakers[index];
                    final int age = _calculateAge(caretaker.birthdate);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12, height: 12,
                                decoration: const BoxDecoration(color: Color(0xFFFFD600), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${caretaker.firstname} ${caretaker.lastname}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: const Color(0xFF82CDA4),
                                backgroundImage: caretaker.profilephoto.isNotEmpty
                                    ? AssetImage('assets/images/Profile/${caretaker.profilephoto}')
                                    : null,
                                child: caretaker.profilephoto.isEmpty
                                    ? const Icon(Icons.person, size: 36, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(TextSpan(
                                      text: 'เบอร์ติดต่อ: ',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black),
                                      children: [TextSpan(text: caretaker.phonenumber, style: const TextStyle(fontWeight: FontWeight.w300))],
                                    )),
                                    const SizedBox(height: 2),
                                    Text.rich(TextSpan(
                                      text: 'เพศ/อายุ: ',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black),
                                      children: [TextSpan(text: '${caretaker.gender}, $age ปี', style: const TextStyle(fontWeight: FontWeight.w300))],
                                    )),
                                    const SizedBox(height: 2),
                                    Text.rich(TextSpan(
                                      text: 'อุปกรณ์/รถ: ',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black),
                                      children: [
                                        TextSpan(
                                          text: caretaker.equipmentdetails.isNotEmpty ? caretaker.equipmentdetails : '-',
                                          style: const TextStyle(fontWeight: FontWeight.w300)
                                        )
                                      ],
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton(
                              onPressed: () {
                                // โค้ดสำหรับไปหน้า ViewCaretakerRegistrationPage
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('ตรวจสอบรายละเอียด', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    );
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