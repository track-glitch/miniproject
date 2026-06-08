import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // ดึง AuthService ของคุณมาใช้งาน
import 'register_page.dart'; // นำเข้าหน้า Register (สมมติว่าชื่อไฟล์นี้)

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // สร้าง Controller สำหรับรับค่าจากช่องกรอกข้อความ
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // เรียกใช้งาน AuthService
  final AuthService _authService = AuthService();

  // ตัวแปรสำหรับซ่อน/แสดงรหัสผ่าน
  bool _isObscure = true;
  // ตัวแปรสำหรับแสดงสถานะโหลดตอนกดปุ่มเข้าสู่ระบบ
  bool _isLoading = false;

  // โทนสีหลักตาม UI ของคุณ (ปรับแก้รหัสสีได้ตามต้องการ)
  final Color primaryColor = const Color(0xFF9B59B6); // สีม่วงเข้ม
  final Color lightPurple = const Color(0xFFE8D4F4); // สีม่วงอ่อนของกล่อง

  // ฟังก์ชันจัดการการเข้าสู่ระบบ
  void _handleLogin() async {
    // ตรวจสอบว่ากรอกข้อมูลครบไหม
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // เรียกใช้ฟังก์ชัน loginMember จาก AuthService ของคุณ
    final user = await _authService.loginMember(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      // เข้าสู่ระบบสำเร็จ -> เปลี่ยนหน้าไปหน้าหลัก (Home)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ!')));
      // ตัวอย่างการเปลี่ยนหน้า (ให้เปลี่ยนเป็นหน้าหลักของคุณ)
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
    } else {
      // เข้าสู่ระบบไม่สำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง')),
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
                // โลโก้ และ ชื่อแอป (เปลี่ยนจาก Icon เป็นรูปภาพโลโก้ของคุณ)
                Image.asset(
                  'assets/logo.png', // ใส่ path ให้ตรงกับชื่อไฟล์ที่คุณตั้งไว้
                  height:
                      160, // กำหนดขนาดความสูงของรูป (ปรับตัวเลขได้ตามต้องการ)
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

                      // ช่องกรอก ชื่อผู้ใช้ (อีเมล)
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'ชื่อผู้ใช้ (อีเมล)',
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
                            // สมมติว่าหน้า Register ของคุณชื่อ RegisterPage
                            builder: (context) => const RegisterPage(),
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
