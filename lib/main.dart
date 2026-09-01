import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:miniproject/services/auto_cancel_service.dart';
import 'package:miniproject/views/caretaker/add_doctor_advice_page.dart';
import 'package:miniproject/views/caretaker/test_add_relative.dart';
import 'views/login_page.dart';
import 'views/admin/list_caretaker_page.dart';

import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'views/caretaker/edit_profile_page.dart';
import 'views/caretaker/test_page.dart';
import 'widgets/search_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('th_TH');
  AutoCancelService.checkAndCancelExpiredRequests();
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
        fontFamily: 'Kanit',
      ),
      //  แก้ไขจาก relative/search_caretaker_profile_page() เป็นชื่อคลาส Widget จริง
      home: const LoginPage(),
    );
  }
}
