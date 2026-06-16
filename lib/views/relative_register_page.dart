import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- เปลี่ยน Path ให้ตรงกับโฟลเดอร์ในโปรเจกต์ของคุณ ---
import '../services/auth_service.dart';
import '../models/patient_model.dart';
import '../models/relative_model.dart';
import 'caretaker_register_page.dart'; // Import หน้าผู้ดูแลเพื่อใช้ในการสลับหน้า

class RelativeRegisterPage extends StatefulWidget {
  const RelativeRegisterPage({super.key});

  @override
  State<RelativeRegisterPage> createState() => _RelativeRegisterPageState();
}

class _RelativeRegisterPageState extends State<RelativeRegisterPage> {
  final AuthService _authService = AuthService();

  // สถานะของหน้าจอ
  bool _isObscure = true;
  bool _isLoading = false;
  
  // กำหนดค่า Tab ปัจจุบันของหน้านี้เป็น "ญาติ"
  final String _selectedTab = "ญาติ"; 

  // โทนสี
  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF4E8FA);
  final Color bgColor = const Color(0xFFFAFAFA);

  // Controllers สำหรับข้อมูลผู้ป่วย/ญาติ
  final TextEditingController _patUsernameController = TextEditingController();
  final TextEditingController _patEmailController = TextEditingController();
  final TextEditingController _patPasswordController = TextEditingController();
  final TextEditingController _patIdCardController = TextEditingController();
  final TextEditingController _patFirstNameController = TextEditingController();
  final TextEditingController _patLastNameController = TextEditingController();
  final TextEditingController _patPhoneController = TextEditingController();
  final TextEditingController _patAddressController = TextEditingController();

  final TextEditingController _relFirstNameController = TextEditingController();
  final TextEditingController _relLastNameController = TextEditingController();
  final TextEditingController _relPhoneController = TextEditingController();
  final TextEditingController _relLineIdController = TextEditingController();
  final TextEditingController _relRelationController = TextEditingController();

  @override
  void dispose() {
    _patUsernameController.dispose();
    _patEmailController.dispose();
    _patPasswordController.dispose();
    _patIdCardController.dispose();
    _patFirstNameController.dispose();
    _patLastNameController.dispose();
    _patPhoneController.dispose();
    _patAddressController.dispose();

    _relFirstNameController.dispose();
    _relLastNameController.dispose();
    _relPhoneController.dispose();
    _relLineIdController.dispose();
    _relRelationController.dispose();
    super.dispose();
  }

  // ฟังก์ชันเช็คว่าฝั่งญาติ/ผู้ป่วย มีการกรอกข้อมูลไว้บ้างหรือยัง
  bool get _hasAnyData {
    return [
      _patUsernameController,
      _patEmailController,
      _patPasswordController,
      _patIdCardController,
      _patFirstNameController,
      _patLastNameController,
      _patPhoneController,
      _patAddressController,
      _relFirstNameController,
      _relLastNameController,
      _relPhoneController,
      _relLineIdController,
      _relRelationController,
    ].any((c) => c.text.trim().isNotEmpty);
  }

  // ฟังก์ชันจัดการเมื่อกดสลับไปหน้า "ผู้ดูแล"
  void _handleToggleToCaretaker() {
    if (_hasAnyData) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการเปลี่ยนหน้า'),
          content: const Text(
            'คุณมีข้อมูลที่กรอกไว้บางส่วนในหน้าญาติ ต้องการสลับไปหน้าสมัครผู้ดูแลหรือไม่? ข้อมูลที่กรอกในหน้านี้จะไม่ถูกบันทึก',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ปิด Dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CaretakerRegisterPage()),
                );
              },
              child: const Text(
                'สลับหน้า',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CaretakerRegisterPage()),
      );
    }
  }

  void _handleRegister() async {
    setState(() => _isLoading = true);

    try {
      String username = _patUsernameController.text.trim();
      String email = _patEmailController.text.trim();
      String password = _patPasswordController.text.trim();

      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'กรุณากรอกข้อมูล ชื่อผู้ใช้ อีเมล และรหัสผ่าน ให้ครบถ้วน',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      RelativeModel relativeData = RelativeModel(
        relativeId: "",
        firstname: _relFirstNameController.text.trim(),
        lastname: _relLastNameController.text.trim(),
        email: email,
        phonenumber: _relPhoneController.text.trim(),
        lineId: _relLineIdController.text.trim(),
        relationship: _relRelationController.text.trim(),
      );

      PatientModel patientData = PatientModel(
        patientId: _patIdCardController.text.trim().isNotEmpty
            ? _patIdCardController.text.trim()
            : "PAT_TEMP",
        patientphoto: "",
        firstname: _patFirstNameController.text.trim(),
        lastname: _patLastNameController.text.trim(),
        phonenumber: _patPhoneController.text.trim(),
        gender: "ไม่ระบุ",
        birthdate: DateTime.now(),
        disease: "",
        mobility: "",
        latitude: 0.0,
        longitude: 0.0,
      );

      UserCredential? userCredential = await _authService.registerRelative(
        username: username,
        password: password,
        usertype: 'relative', 
        relative: relativeData,
        patient: patientData,
      );

      if (userCredential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สมัครสมาชิกสำเร็จและบันทึกข้อมูลเรียบร้อย!'),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการสมัครสมาชิก หรือชื่อผู้ใช้นี้อาจถูกใช้ไปแล้ว',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'สมัครสมาชิก',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            children: [
              // เมนูเลือกด้านบนสุด (Toggle Tab)
              _buildTopToggleTab(),
              const SizedBox(height: 10),

              _buildProfileUpload(),
              const SizedBox(height: 25),

              // ฟอร์มข้อมูลต่างๆ
              _buildSection(
                title: 'ข้อมูลบัญชีเข้าสู่ระบบ',
                children: [
                  _buildTextField(
                    hint: 'ชื่อผู้ใช้ (Username)',
                    controller: _patUsernameController,
                  ),
                  _buildTextField(
                    hint: 'อีเมลใช้สำหรับติดต่อจริง',
                    controller: _patEmailController,
                  ),
                  _buildTextField(
                    hint: 'รหัสผ่าน',
                    controller: _patPasswordController,
                    isPassword: true,
                  ),
                ],
              ),
              _buildSection(
                title: 'ข้อมูลส่วนตัวผู้ป่วย',
                children: [
                  _buildTextField(
                    hint: 'หมายเลขบัตรประชาชนผู้ป่วย',
                    controller: _patIdCardController,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          hint: 'ชื่อจริงผู้ป่วย',
                          controller: _patFirstNameController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          hint: 'นามสกุลผู้ป่วย',
                          controller: _patLastNameController,
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(
                    hint: 'เบอร์โทรศัพท์ผู้ป่วย',
                    controller: _patPhoneController,
                  ),
                ],
              ),
              _buildSection(
                title: 'ข้อมูลที่อยู่ผู้ป่วย',
                children: [
                  _buildTextField(
                    hint: 'รายละเอียดที่อยู่...',
                    controller: _patAddressController,
                    maxLines: 3,
                  ),
                ],
              ),
              _buildSection(
                title: 'ข้อมูลติดต่อญาติ (ผู้สมัครหลัก)',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          hint: 'ชื่อจริงญาติ',
                          controller: _relFirstNameController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          hint: 'นามสกุลญาติ',
                          controller: _relLastNameController,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          hint: 'เบอร์โทรติดต่อญาติ',
                          controller: _relPhoneController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          hint: 'ไอดีไลน์ญาติ',
                          controller: _relLineIdController,
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(
                    hint: 'สถานะความสัมพันธ์ (เช่น ลูก, หลาน)',
                    controller: _relRelationController,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ปุ่มสมัครสมาชิก
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'สมัครสมาชิก',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'มีบัญชีอยู่แล้ว? ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  
  // ส่วนประกอบระบบเลือกด้านบนสุด (Toggle Tab)
  Widget _buildTopToggleTab() {
    return Center(
      child: Container(
        width: 280,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: primaryColor, width: 1.5),
        ),
        child: Row(
          children: [
            // ฝั่งปุ่ม "ญาติ"
            Expanded(
              child: GestureDetector(
                onTap: () {}, // อยู่หน้าตัวเองอยู่แล้ว ไม่ต้องทำอะไร
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedTab == "ญาติ" ? primaryColor : Colors.transparent, // ใช้ primaryColor ไฮไลท์หน้าปัจจุบัน
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(21),
                      bottomLeft: Radius.circular(21),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'ญาติ',
                    style: TextStyle(
                      color: _selectedTab == "ญาติ" ? Colors.white : primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // ฝั่งปุ่ม "ผู้ดูแล"
            Expanded(
              child: GestureDetector(
                onTap: _handleToggleToCaretaker, // เรียกฟังก์ชันเช็คข้อมูลก่อนเปิดเพจผู้ดูแล
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedTab == "ผู้ดูแล" ? darkPurple : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(21),
                      bottomRight: Radius.circular(21),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'ผู้ดูแล',
                    style: TextStyle(
                      color: _selectedTab == "ผู้ดูแล" ? Colors.white : primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget _buildProfileUpload() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, size: 50, color: Colors.black54),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, size: 20, color: primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'อัปโหลดรูปโปรไฟล์',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkPurple),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController? controller,
    bool isPassword = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                )
              : null,
        ),
      ),
    );
  }
}