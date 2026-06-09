import 'package:flutter/material.dart';

class WaitingApprovalPage extends StatelessWidget {
  const WaitingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF9B59B6);
    final Color lightPurple = const Color(0xFFF4E8FA);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('สมัครสมาชิก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false, // ปิดปุ่ม Back ย้อนกลับไปหน้าสมัครซ้ำ
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // กล่องไอคอนและข้อความรออนุมัติ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: lightPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryColor,
                      child: const Icon(Icons.hourglass_empty, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'รออนุมัติจากแอดมิน',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ข้อมูลของคุณได้รับการส่งเรียบร้อยแล้ว\nกรุณารอการตรวจสอบและอนุมัติ',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // กล่องแจ้งรายละเอียดระยะเวลาดำเนินการ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: lightPurple.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('ระยะเวลาดำเนินการ: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('1-3 วันทำการ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ระบบจะแจ้งผลผ่าน อีเมล และ SMS ที่ท่านลงทะเบียนไว้',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              
              // ท้ายหน้าจอกลับไปหน้า Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('มีบัญชีอยู่แล้ว? ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      // เด้งออกจากหน้านี้กลับไปหน้าแรกสุดของแอป (หน้า Login)
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Text('เข้าสู่ระบบ', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}