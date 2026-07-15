// ==========================================
// File: lib/views/login_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:miniproject/views/admin/list_caretaker_page.dart';
import 'package:miniproject/views/caretaker/list_relative_request_page.dart';
import 'package:miniproject/views/relative/view_caretaker_profile_page.dart';
import 'package:miniproject/views/relative_register_page.dart';
import '../services/auth_service.dart';
import 'relative/relative_home_page.dart';
import 'caretaker/caretaker_home_page.dart';
import 'waiting_approval_page.dart';
import 'caretaker/edit_profile_page.dart';
import '../widgets/reject_page.dart';
import 'caretaker_register_page.dart';

// 🌟 Import หน้าเพิ่มข้อมูลรถยนต์ (แก้ชื่อให้ตรงกับที่คุณมีในโปรเจกต์)
// import 'caretaker/caretaker_vehicle_register_page.dart';

class LoginPage extends StatefulWidget {
  final String? caretakerId;

  const LoginPage({super.key, this.caretakerId});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 🌟 เปลี่ยนชื่อ Controller ให้เข้ากับเลขบัตรประชาชน[cite: 1]
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFE8D4F4);

  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermissionOnStartup();
  }

  @override
  void dispose() {
    _idCardController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermissionOnStartup() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (e) {
      print("Error requesting location permission: $e");
    }
  }

  void _handleLogin() async {
    if (_idCardController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final AuthService authService = AuthService();

    // 🌟 เรียกใช้ฟังก์ชัน Login แบบ Bridge Pattern[cite: 1, 9]
    var result = await authService.loginWithIdCard(
      _idCardController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null && result['success'] == true) {
      String usertype = result['usertype'].toString().toLowerCase();
      String uid = result['uid'].toString();

      if (!mounted) return;

      if (usertype == 'caretaker') {
        String accountStatus = result['accountstatus'] ?? 'Pending';

        // 🌟 ดักสถานะต่างๆ
        if (accountStatus == 'Pending') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const WaitingApprovalPage(),
            ),
          );
          return;
        } else if (accountStatus == 'Rejected') {
          // ไปหน้าแจ้งเตือนการปฏิเสธ พร้อมเหตุผล[cite: 1]
          String comment =
              result['admincomment'] ??
              'ข้อมูลไม่ผ่านเกณฑ์ โปรดตรวจสอบและแก้ไขข้อมูลใหม่';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RejectedPage(adminComment: comment),
            ),
          );
          return;
        } else if (accountStatus == 'Approved') {
          // 🌟 ถ้ายืนยันแล้ว เช็คว่ามีรถหรือยัง[cite: 10]
          bool hasVehicle = result['hasVehicle'] ?? false;

          if (!hasVehicle) {
            // ถ้ายังไม่มีรถ บังคับเด้งไปหน้ากรอกข้อมูลรถยนต์
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => CaretakerVehicleRegisterPage(uid: uid)),
            // );

            // หมายเหตุ: ใช้ SnackBar ชั่วคราว ถ้ายังไม่สร้างไฟล์ให้ uncomment ด้านบนออก
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('กรุณาเพิ่มข้อมูลยานพาหนะ (นำทางไปหน้าข้อมูลรถ)'),
              ),
            );
            return;
          }

          // 🌟 ถ้าทุกอย่างครบ (Approved + มีรถ) เข้าสู่หน้าหลัก[cite: 1]
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ListRelativeRequestPage(uid: uid),
            ),
          );
        }
      } else if (usertype == 'relative') {
        // 🌟 เพิ่มเงื่อนไขสำหรับญาติ พาล็อกอินเข้าหน้า Home ของญาติ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RelativeHomePage(loggedUid: uid), // เปลี่ยนหน้าปลายทางตามของคุณ
          ),
        );
      }
      // ... (ส่วนของ relative และ admin ปล่อยไว้แบบเดิมได้ หรือปรับแก้ logic คล้ายๆ กันถ้าต้องการ)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['message'] ?? 'เกิดข้อผิดพลาด'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'เข้าสู่ระบบ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Column(
                  children: [
                    Image(
                      image: const AssetImage('assets/logo.png'),
                      width: MediaQuery.of(context).size.width * 0.55,
                      fit: BoxFit.contain,
                    ),
                    const Text(
                      'อาสาพาไปโรงหมอ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 123, 69, 145),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: lightPurple,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'กรุณาเข้าสู่ระบบ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 🌟 เปลี่ยน Hint เป็น เลขบัตรประชาชน[cite: 1]
                      TextField(
                        controller: _idCardController,
                        keyboardType: TextInputType.number,
                        maxLength: 13,
                        decoration: InputDecoration(
                          hintText: 'เลขบัตรประชาชน',
                          counterText: "",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          hintText: 'รหัสผ่าน',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'ลืมรหัสผ่าน?',
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 16),
                // ==========================================
                // 🌟 ส่วนเลือกลิงก์สมัครสมาชิก
                // ==========================================
                Column(
                  children: [
                    const Text(
                      'ยังไม่มีบัญชีใช่หรือไม่?',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // ลิงก์ญาติ/ผู้ป่วย
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RelativeRegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            'สมัครสำหรับญาติ/ผู้ป่วย',
                            style: TextStyle(
                              color: primaryColor, // ใช้สีม่วง
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              decoration: TextDecoration
                                  .underline, // ขีดเส้นใต้ให้ดูเป็นลิงก์
                            ),
                          ),
                        ),

                        // เส้นคั่นตรงกลาง
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '|',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),

                        // ลิงก์ผู้ให้บริการ
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CaretakerRegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'สมัครสำหรับผู้ให้บริการ',
                            style: TextStyle(
                              color: Color(
                                0xFF0F766E,
                              ), // ใช้สีเขียวอมฟ้าเดิมของคุณ
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
