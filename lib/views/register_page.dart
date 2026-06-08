import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- เปลี่ยน Path ให้ตรงกับโฟลเดอร์ในโปรเจกต์ของคุณ ---
import '../services/auth_service.dart';
import '../models/caretaker_model.dart';
import '../models/patient_model.dart';
import '../models/relative_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Service สำหรับจัดการ Firebase Auth และ Realtime Database
  final AuthService _authService = AuthService();

  // สถานะของหน้าจอ
  bool _isCaretaker = false;
  bool _isObscure = true;
  bool _isLoading = false;

  // โทนสี
  final Color primaryColor = const Color(0xFF9B59B6);
  final Color lightPurple = const Color(0xFFF4E8FA);
  final Color bgColor = const Color(0xFFFAFAFA);

  // ==========================================
  // Controllers สำหรับดึงข้อมูลจากฟอร์ม "ผู้ป่วย/ญาติ"
  // ==========================================
  final TextEditingController _patUsernameController = TextEditingController(); 
  final TextEditingController _patEmailController = TextEditingController();
  final TextEditingController _patPasswordController = TextEditingController();
  final TextEditingController _patIdCardController = TextEditingController();
  final TextEditingController _patFirstNameController = TextEditingController();
  final TextEditingController _patLastNameController = TextEditingController();
  final TextEditingController _patPhoneController = TextEditingController();
  final TextEditingController _patLineIdController = TextEditingController();
  final TextEditingController _patAddressController = TextEditingController();
  
  final TextEditingController _relFirstNameController = TextEditingController();
  final TextEditingController _relLastNameController = TextEditingController();
  final TextEditingController _relPhoneController = TextEditingController();
  final TextEditingController _relLineIdController = TextEditingController();
  final TextEditingController _relRelationController = TextEditingController();

  // ==========================================
  // Controllers สำหรับดึงข้อมูลจากฟอร์ม "ผู้ดูแล"
  // ==========================================
  final TextEditingController _careUsernameController = TextEditingController(); // 🛠️ เพิ่มเพื่อให้ฝั่งอาสาสมัครมีช่องเก็บ Username
  final TextEditingController _careIdCardController = TextEditingController();
  final TextEditingController _careEmailController = TextEditingController();
  final TextEditingController _carePasswordController = TextEditingController();
  final TextEditingController _careFirstNameController = TextEditingController();
  final TextEditingController _careLastNameController = TextEditingController();
  final TextEditingController _carePhoneController = TextEditingController();
  final TextEditingController _careAddressController = TextEditingController(); 
  final TextEditingController _careVehicleDescController = TextEditingController();
  final TextEditingController _careVehicleRegController = TextEditingController();

  @override
  void dispose() {
    // 🗑️ คืนแรมทำลายทิ้งตัวควบคุมทั้งหมดเมื่อปิดหน้าจอ
    _careUsernameController.dispose();
    _careIdCardController.dispose();
    _careEmailController.dispose();
    _carePasswordController.dispose();
    _careFirstNameController.dispose();
    _careLastNameController.dispose();
    _carePhoneController.dispose();
    _careAddressController.dispose();
    _careVehicleDescController.dispose();
    _careVehicleRegController.dispose();
    
    _patUsernameController.dispose();
    _patEmailController.dispose();
    _patPasswordController.dispose();
    _patIdCardController.dispose();
    _patFirstNameController.dispose();
    _patLastNameController.dispose();
    _patPhoneController.dispose();
    _patLineIdController.dispose();
    _patAddressController.dispose();
    
    _relFirstNameController.dispose();
    _relLastNameController.dispose();
    _relPhoneController.dispose();
    _relLineIdController.dispose();
    _relRelationController.dispose();
    super.dispose(); 
  }

  // ฟังก์ชันจัดการการสมัครสมาชิก
  void _handleRegister() async {
    setState(() {
      _isLoading = true; // เปิดโหลดหมุนๆ
    });

    try {
      String username = _isCaretaker ? _careUsernameController.text.trim() : _patUsernameController.text.trim();
      String email = _isCaretaker ? _careEmailController.text.trim() : _patEmailController.text.trim();
      String password = _isCaretaker ? _carePasswordController.text.trim() : _patPasswordController.text.trim();

      // ตรวจสอบค่าว่างเบื้องต้น
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูล ชื่อผู้ใช้ อีเมล และรหัสผ่าน ให้ครบถ้วน')));
        setState(() => _isLoading = false);
        return;
      }

      UserCredential? userCredential;

      // 🛠️ แยกทางเดินในการเรียกใช้ Method ตามประเภทผู้ใช้งานจริง
      if (_isCaretaker) {
        // 1. มัดรวมโมเดลผู้ดูแล
        CaretakerModel caretakerData = CaretakerModel(
          caretakerId: "", // จะถูกนำไปเขียนทับด้วย UID ในหลังบ้านครับ
          profilephoto: "",
          firstname: _careFirstNameController.text.trim(),
          lastname: _careLastNameController.text.trim(),
          gender: "ไม่ระบุ", 
          birthdate: DateTime.now(), 
          phonenumber: _carePhoneController.text.trim(),
          email: email,
          aboutme: "",
          equipmentdetails: "${_careVehicleDescController.text.trim()} ทะเบียน ${_careVehicleRegController.text.trim()}", 
          address: _careAddressController.text.trim(),
          admincomment: "",
          servicestatus: "pending",
          accountstatus: "active",
          latitude: 0.0,
          longitude: 0.0,
        );

        // 2. ส่งคำขอไปที่ฟังก์ชันสมัครสมาชิกของผู้ดูแล
        userCredential = await _authService.registerCaretaker(
          username: username,
          password: password,
          usertype: 'caretaker',
          caretaker: caretakerData,
        );

      } else {
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
          patientId: _patIdCardController.text.trim().isNotEmpty ? _patIdCardController.text.trim() : "PAT_TEMP",
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

        // 3. ส่งคำขอไปที่ฟังก์ชันสมัครสมาชิกของญาติพ่วงข้อมูลคนไข้
        userCredential = await _authService.registerRelative(
          username: username,
          password: password,
          usertype: 'relative',
          relative: relativeData,
          patient: patientData,
        );
      }

      // ตรวจสอบผลลัพธ์การทำงาน
      if (userCredential != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สมัครสมาชิกสำเร็จและบันทึกข้อมูลเรียบร้อย!')));
        Navigator.pop(context); // เด้งกลับไปหน้าเข้าสู่ระบบ
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดในการสมัครสมาชิก หรือชื่อผู้ใช้นี้อาจถูกใช้ไปแล้ว')));
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false; // ปิดโหลดหมุนๆ
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('สมัครสมาชิก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              _buildTabToggle(),
              const SizedBox(height: 25),
              _buildProfileUpload(),
              const SizedBox(height: 25),
              
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isCaretaker ? _buildCaretakerForm() : _buildRelativeForm(),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('สมัครสมาชิก', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('มีบัญชีอยู่แล้ว? ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('เข้าสู่ระบบ', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
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

  Widget _buildRelativeForm() {
    return Column(
      key: const ValueKey('RelativeForm'),
      children: [
        _buildSection(title: 'ข้อมูลบัญชีเข้าสู่ระบบ', children: [
          _buildTextField(hint: 'ชื่อผู้ใช้ (Username)', controller: _patUsernameController), 
          _buildTextField(hint: 'อีเมลใช้สำหรับติดต่อจริง', controller: _patEmailController),
          _buildTextField(hint: 'รหัสผ่าน', controller: _patPasswordController, isPassword: true),
        ]),
        _buildSection(title: 'ข้อมูลส่วนตัวผู้ป่วย', children: [
          _buildTextField(hint: 'หมายเลขบัตรประชาชนผู้ป่วย', controller: _patIdCardController),
          Row(
            children: [
              Expanded(child: _buildTextField(hint: 'ชื่อจริงผู้ป่วย', controller: _patFirstNameController)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(hint: 'นามสกุลผู้ป่วย', controller: _patLastNameController)),
            ],
          ),
          _buildTextField(hint: 'เบอร์โทรศัพท์ผู้ป่วย', controller: _patPhoneController),
        ]),
        _buildSection(title: 'ข้อมูลที่อยู่ผู้ป่วย', children: [
          _buildTextField(hint: 'รายละเอียดที่อยู่...', controller: _patAddressController, maxLines: 3),
        ]),
        _buildSection(title: 'ข้อมูลติดต่อญาติ (ผู้สมัครหลัก)', children: [
          Row(
            children: [
              Expanded(child: _buildTextField(hint: 'ชื่อจริงญาติ', controller: _relFirstNameController)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(hint: 'นามสกุลญาติ', controller: _relLastNameController)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTextField(hint: 'เบอร์โทรติดต่อญาติ', controller: _relPhoneController)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(hint: 'ไอดีไลน์ญาติ', controller: _relLineIdController)),
            ],
          ),
          _buildTextField(hint: 'สถานะความสัมพันธ์ (เช่น ลูก, หลาน)', controller: _relRelationController),
        ]),
      ],
    );
  }

  Widget _buildCaretakerForm() {
    return Column(
      key: const ValueKey('CaretakerForm'),
      children: [
        _buildSection(title: 'ข้อมูลบัญชีเข้าสู่ระบบ', children: [
          _buildTextField(hint: 'ชื่อผู้ใช้ (Username)', controller: _careUsernameController),
          _buildTextField(hint: 'อีเมลใช้สำหรับติดต่อจริง', controller: _careEmailController),
          _buildTextField(hint: 'รหัสผ่าน', controller: _carePasswordController, isPassword: true),
        ]),
        _buildSection(title: 'ข้อมูลส่วนตัวผู้ดูแล', children: [
          _buildTextField(hint: 'หมายเลขบัตรประชาชน', controller: _careIdCardController),
          Row(
            children: [
              Expanded(child: _buildTextField(hint: 'ชื่อจริง', controller: _careFirstNameController)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(hint: 'นามสกุล', controller: _careLastNameController)),
            ],
          ),
          _buildTextField(hint: 'เบอร์โทรศัพท์', controller: _carePhoneController),
        ]),
        _buildSection(title: 'ข้อมูลที่อยู่', children: [
          _buildTextField(hint: 'ที่อยู่ปัจจุบันคร่าวๆ', controller: _careAddressController, maxLines: 2),
        ]),
        _buildSection(title: 'ข้อมูลยานพาหนะเบื้องต้น', children: [
          _buildTextField(hint: 'เช่น รถยนต์ Toyota Fortuner สีขาว', controller: _careVehicleDescController),
          _buildTextField(hint: 'ทะเบียนรถ (เช่น กข 1234 เชียงใหม่)', controller: _careVehicleRegController),
        ]),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: primaryColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCaretaker = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isCaretaker ? primaryColor : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                ),
                alignment: Alignment.center,
                child: Text('ผู้ป่วย / ญาติ', style: TextStyle(color: !_isCaretaker ? Colors.white : primaryColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCaretaker = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isCaretaker ? primaryColor : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                ),
                alignment: Alignment.center,
                child: Text('ผู้ดูแล', style: TextStyle(color: _isCaretaker ? Colors.white : primaryColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileUpload() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(radius: 40, backgroundColor: Colors.grey.shade300, child: const Icon(Icons.person, size: 50, color: Colors.black54)),
            Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.camera_alt, size: 20, color: primaryColor)),
          ],
        ),
        const SizedBox(height: 10),
        const Text('อัปโหลดรูปโปรไฟล์', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({required String hint, TextEditingController? controller, bool isPassword = false, int maxLines = 1}) {
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                )
              : null,
        ),
      ),
    );
  }
}