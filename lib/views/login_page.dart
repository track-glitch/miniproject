import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:miniproject/views/relative/view_caretaker_profile_page.dart';
import 'package:miniproject/views/relative_register_page.dart'; 
import '../services/auth_service.dart'; 
import 'relative/relative_home_page.dart'; 
import 'caretaker/caretaker_home_page.dart'; 
import 'waiting_approval_page.dart'; 
import 'relative/search_caretaker_profile_page.dart'; 

class LoginPage extends StatefulWidget {
  final String? caretakerId;

  const LoginPage({
    super.key,
    this.caretakerId,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController(); 
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
    _usernameController.dispose(); 
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
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')), 
      );
      return;
    }

    setState(() {
      _isLoading = true; 
    });

    final AuthService authService = AuthService(); 
    var result = await authService.loginWithUsername(
      _usernameController.text.trim(), 
      _passwordController.text.trim(), 
    );

    setState(() {
      _isLoading = false; 
    });

    if (result != null && result['success'] == true) {
      String usertype = result['usertype'].toString().toLowerCase(); 
      String uid = result['uid'].toString(); 

      String? accountStatus = await authService.getUserStatus(uid); 

      if (!mounted) return;

      if (usertype == 'relative') {
        // 🎯 ตรวจสอบก่อนว่ามี caretakerId ส่งมาจากหน้าก่อนหน้าหรือไม่เพื่อป้องกันการเกิด Null Error
        if (widget.caretakerId != null && widget.caretakerId!.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CaretakerProfilePage(
                caretakerId: widget.caretakerId!,
                loggedUid: uid,
              ),  
            ),
          );
        } else {
          // 🎯 หากเป็นการล็อกอินเข้าแอปตามปกติ ให้เปลี่ยนเส้นทางไปหน้าค้นหาผู้ดูแล (CaretakerSearchPage)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CaretakerSearchPage(
                loggedUid: uid,
              ),  
            ),
          );
        }
      } else if (usertype == 'caretaker') {
        if (accountStatus == 'Pending' ||
            result['accountstatus'] == 'Pending') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const WaitingApprovalPage(),
            ), 
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CaretakerHomePage()), 
        );
      } else if (usertype == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('หน้าจอสำหรับ Admin (กำลังพัฒนา)')),
            ),
          ),
        );
      }
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
                const Image(
                  image: AssetImage('assets/logo.png'),
                  width: 250, 
                  height: 250, 
                  fit: BoxFit.contain, 
                ),
                const SizedBox(height: 1), 

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

                      TextField(
                        controller: _usernameController, 
                        keyboardType: TextInputType.text, 
                        decoration: InputDecoration(
                          hintText: 'ชื่อผู้ใช้ (Username)', 
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
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          ) 
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    const Text(
                      'ยังไม่มีบัญชี?', 
                      style: TextStyle(fontWeight: FontWeight.bold), 
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RelativeRegisterPage(),
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