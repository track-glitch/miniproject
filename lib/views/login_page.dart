import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart'; // ดึง AuthService ของคุณมาใช้งาน
import 'caretaker_register_page.dart';
import 'relative/relative_home_page.dart';
import 'admin/list_caretaker_page.dart';
import 'caretaker/caretaker_home_page.dart';
import 'waiting_approval_page.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 🛠️ เปลี่ยนชื่อตัวแปรให้สื่อความหมายว่าเป็นช่องกรอก Username
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestLocationPermissionOnStartup();
  }

  @override
  void dispose() {
    // 🗑️ คืนแรมทำลายทิ้งตัวควบคุมทั้งหมดเมื่อปิดหน้าจอ
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // ฟังก์ชันขออนุญาติการเข้าถึงตำแหน่งตั้งแต่หน้า login
  // ==========================================
  Future<void> _requestLocationPermissionOnStartup() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      } else if (permission == LocationPermission.deniedForever) {
        await Geolocator.openLocationSettings();
      }
    } catch (e) {
      print("Error requesting location permission: \$e");
    }
  }

  // เรียกใช้งาน AuthService
  final AuthService _authService = AuthService();

  // ตัวแปรสำหรับซ่อน/แสดงรหัสผ่าน
  bool _isObscure = true;
  // ตัวแปรสำหรับแสดงสถานะโหลดตอนกดปุ่มเข้าสู่ระบบ
  bool _isLoading = false;

  // โทนสีหลักตาม UI
  final Color primaryColor = const Color(0xFF9B59B6); // สีม่วงเข้ม
  final Color lightPurple = const Color(0xFFE8D4F4); // สีม่วงอ่อนของกล่อง

  void _handleLogin() async {
    // ตรวจสอบว่ากรอกข้อมูลครบไหม
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 🚀 เรียกใช้ฟังก์ชันล็อกอินที่เราเพิ่งสร้าง
    var result = await _authService.loginWithUsername(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    // เช็กผลลัพธ์
    if (result != null && result['success'] == true) {
      String usertype = result['usertype']; // ดึงประเภทผู้ใช้ออกมา
      String uid = result['uid'];

      // 🔀 แยกการนำทาง (Navigation) ตามประเภทผู้ใช้งาน
      if (usertype == 'patient' || usertype == 'relative') {
        // ไปหน้าของญาติ/ผู้ป่วย
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RelativeHomePage()),
        );
      } else if (usertype == 'caretaker') {
        if (result['accountstatus'] == 'Pending') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const WaitingApprovalPage()));
          return;
        } 
        if (result['accountstatus'] == 'Suspended' || result['status'] == 'Rejected') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
          return;
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CaretakerHomePage()));
        print("ล็อกอินสำเร็จ! ไปหน้าผู้ดูแล"); 
      } else if (usertype == 'admin') {
        // ไปหน้าของแอดมิน (TODO: ใส่หน้าโฮมของแอดมิน)
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ListCaretakerPage(uid: uid,)));
        print("ล็อกอินสำเร็จ! ไปหน้าแอดมิน");
      }
    } else {
      // ถ้ารหัสผิด หรือ ไม่มีไอดี จะโชว์แจ้งเตือนด้านล่าง
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
      backgroundColor: const Color(0xFFFAFAFA), // สีพื้นหลัง
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
                // โลโก้ และ ชื่อแอป
                Image.asset(
                  'assets/logo.png',
                  height: 160,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 10),
                // กล่องใส่ข้อมูลการล็อกอิน (สีม่วงอ่อน)
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

                      // 🛠️ ช่องกรอก ชื่อผู้ใช้ (Username)
                      TextField(
                        controller: _usernameController,
                        keyboardType: TextInputType
                            .text, // เปลี่ยนจาก emailAddress เป็น text ธรรมดา
                        decoration: InputDecoration(
                          hintText:
                              'ชื่อผู้ใช้ (Username)', // 🛠️ เปลี่ยนคำบอกใบ้บนหน้าจอ
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

                      // ช่องกรอก รหัสผ่าน
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

                      // ลืมรหัสผ่าน
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: ใส่ฟังก์ชันลืมรหัสผ่าน
                          },
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

                // ปุ่มเข้าสู่ระบบ
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
                const SizedBox(height: 20),

                // ยังไม่มีบัญชี? สมัครสมาชิกใหม่
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ยังไม่มีบัญชี?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        // เปลี่ยนไปหน้าสมัครสมาชิก
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CaretakerRegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        'สมัครสมาชิกใหม่',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
