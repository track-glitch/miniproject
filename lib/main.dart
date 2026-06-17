import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'views/login_page.dart';
import 'views/admin/list_caretaker_page.dart';

Future<void> main() async { 
  WidgetsFlutterBinding.ensureInitialized();
 
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
      //  แก้ไขจาก relative/search_caretaker_profile_page() เป็นชื่อคลาส Widget จริง
      home: const LoginPage(), 
    );
  }
}
