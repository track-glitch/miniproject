import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. เพิ่มบรรทัดนี้ // 2. เพิ่มบรรทัดนี้ (ไฟล์ตั้งค่าที่ได้จาก FlutterFire CLI)
import 'views/login_page.dart';
import 'views/admin/list_caretaker_page.dart';

// 3. เปลี่ยนจาก void main() ธรรมดา เป็น Future<void> main() async
Future<void> main() async {
  // 4. สั่งให้ Flutter เตรียมระบบให้พร้อมก่อนรันคำสั่งอื่น
  WidgetsFlutterBinding.ensureInitialized();

  // 5. สั่งเริ่มต้นการทำงานของ Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'อาสาพาไปโรงหมอ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9B59B6)),
        useMaterial3: true,
      ),
      home: const ListCaretakerPage(),
    );
  }
}
