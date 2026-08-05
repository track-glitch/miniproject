import 'package:flutter/material.dart';
// 🌟 ปรับ Path ให้ชี้ไปที่หน้า LoginPage ของคุณ
import '../views/login_page.dart';

class SuspendPage extends StatelessWidget {
  final String adminComment; // ตัวแปรรับข้อความเหตุผลการระงับ

  const SuspendPage({super.key, required this.adminComment});

  @override
  Widget build(BuildContext context) {
    // โทนสีสำหรับหน้าถูกระงับการใช้งาน
    final Color suspendColor = const Color(0xFFD32F2F); // สีแดงเข้ม
    final Color lightSuspendColor = const Color(0xFFFFEBEE); // สีแดงอ่อน
    final Color primaryColor = const Color(0xFF9B59B6);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'บัญชีถูกระงับการใช้งาน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: suspendColor,
        elevation: 0,
        automaticallyImplyLeading: false, // ซ่อนปุ่ม Back
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🌟 กล่องแจ้งสถานะระงับการใช้งาน
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: lightSuspendColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: suspendColor,
                            child: const Icon(
                              Icons.block,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'บัญชีของคุณถูกระงับ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: suspendColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'เนื่องจากพบการกระทำที่ผิดเงื่อนไขการให้บริการ\nหรือได้รับการรายงานพฤติกรรมที่ไม่เหมาะสม',
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

                    // 🌟 กล่องแสดงข้อความจาก Admin (เหตุผลการระงับ)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: suspendColor.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: suspendColor,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'สาเหตุการระงับบัญชี:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            adminComment.isNotEmpty
                                ? adminComment
                                : 'ไม่มีการระบุเหตุผล โปรดติดต่อผู้ดูแลระบบ',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🌟 กล่องข้อมูลติดต่อกลับ (Mockup)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ต้องการความช่วยเหลือ หรือขออุทธรณ์?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.email, color: primaryColor, size: 20),
                              const SizedBox(width: 10),
                              const Text('support@asa-hospital.com'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.phone, color: primaryColor, size: 20),
                              const SizedBox(width: 10),
                              const Text(
                                '02-999-9999 (จันทร์-ศุกร์ 09:00-18:00)',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.chat, color: primaryColor, size: 20),
                              const SizedBox(width: 10),
                              const Text('Line Official: @AsaHospitalCare'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🌟 ปุ่มกลับไปหน้า Login
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
