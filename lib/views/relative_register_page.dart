import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- เปลี่ยน Path ให้ตรงกับโฟลเดอร์ในโปรเจกต์ของคุณ ---
import '../services/auth_service.dart';
import '../models/patient_model.dart';
import '../models/relative_model.dart';

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

  // โทนสี
  final Color primaryColor = const Color(0xFF9B59B6);
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

      // 1. มัดรวมโมเดลญาติ
      RelativeModel relativeData = RelativeModel(
        relativeId: "",
        firstname: _relFirstNameController.text.trim(),
        lastname: _relLastNameController.text.trim(),
        email: email,
        phonenumber: _relPhoneController.text.trim(),
        lineid: _relLineIdController.text.trim(),
        relationship: _relRelationController.text.trim(),
      );

      // 2. มัดรวมโมเดลคนไข้
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
        address: _patAddressController.text.trim(),
        latitude: 0.0,
        longitude: 0.0,
      );

      // 3. ส่งคำขอสมัครสมาชิกของญาติพ่วงข้อมูลคนไข้
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
          'สมัครสมาชิก (ญาติ/ผู้ป่วย)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              _buildProfileUpload(),
              const SizedBox(height: 25),

              // ฟอร์มญาติและผู้ป่วย
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    TextEditingController? controller,
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
            borderSide: BorderSide(color: primaryColor),
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
