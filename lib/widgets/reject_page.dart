import 'package:flutter/material.dart';
// 🌟 ปรับ Path ให้ชี้ไปที่หน้า LoginPage ของคุณ
import '../views/login_page.dart';

class RejectedPage extends StatelessWidget {
  final String adminComment; // ตัวแปรรับข้อความเหตุผลจากแอดมิน

  const RejectedPage({super.key, required this.adminComment});

  @override
  Widget build(BuildContext context) {
    final Color errorColor = const Color(0xFFF44336); // สีแดง
    final Color lightErrorColor = const Color(0xFFFFEBEE); // สีแดงอ่อน

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ผลการสมัครสมาชิก',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: errorColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // 🌟 กล่องไอคอนและข้อความไม่อนุมัติ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: lightErrorColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: errorColor,
                      child: const Icon(
                        Icons.close,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ไม่ผ่านการอนุมัติ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: errorColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ขออภัย ข้อมูลการสมัครของคุณไม่ผ่านการตรวจสอบ\nโปรดดูเหตุผลจากผู้ดูแลระบบด้านล่าง',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 🌟 กล่องแสดงข้อความจาก Admin (admincomment)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: errorColor.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.message, color: errorColor, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'เหตุผลจากผู้ดูแลระบบ:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      adminComment.isNotEmpty
                          ? adminComment
                          : 'ไม่มีการระบุเหตุผล',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // ท้ายหน้าจอกลับไปหน้า Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'กลับสู่หน้าเข้าสู่ระบบ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
