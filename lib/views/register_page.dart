import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- เปลี่ยน Path ให้ตรงกับโฟลเดอร์ในโปรเจกต์ของคุณ ---
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/caretaker_model.dart';
import '../models/patient_model.dart';
import '../models/relative_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Service สำหรับจัดการ Firebase
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

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
  final TextEditingController _careIdCardController = TextEditingController();
  final TextEditingController _careEmailController = TextEditingController();
  final TextEditingController _carePasswordController = TextEditingController();
  final TextEditingController _careFirstNameController = TextEditingController();
  final TextEditingController _careLastNameController = TextEditingController();
  final TextEditingController _carePhoneController = TextEditingController();
  final TextEditingController _careAddressController = TextEditingController(); // รวมที่อยู่คร่าวๆ
  final TextEditingController _careVehicleDescController = TextEditingController();
  final TextEditingController _careVehicleRegController = TextEditingController();

  // ฟังก์ชันจัดการการสมัครสมาชิก
  void _handleRegister() async {
    setState(() {
      _isLoading = true; // เปิดโหลดหมุนๆ
    });

    try {
      // 1. ดึงอีเมลและรหัสผ่านตามแท็บที่เลือก
      String email = _isCaretaker ? _careEmailController.text.trim() : _patEmailController.text.trim();
      String password = _isCaretaker ? _carePasswordController.text.trim() : _patPasswordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกอีเมลและรหัสผ่าน')));
        setState(() => _isLoading = false);
        return;
      }

      // 2. สมัครบัญชีผู้ใช้ใน Firebase Auth
      UserCredential? userCredential = await _authService.registerMember(email, password);

      if (userCredential != null && userCredential.user != null) {
        String uid = userCredential.user!.uid; // ได้รหัสประจำตัวผู้ใช้ (UID) มาแล้ว
        bool isSuccess = false;

        if (_isCaretaker) {
          // === บันทึกข้อมูล: ผู้ดูแล ===
          CaretakerModel newCaretaker = CaretakerModel(
            caretakerId: uid,
            profilephoto: "",
            firstname: _careFirstNameController.text,
            lastname: _careLastNameController.text,
            gender: "ไม่ระบุ", // TODO: นำค่าจาก Dropdown มาใส่
            birthdate: DateTime.now(), // TODO: นำค่าจาก DatePicker มาใส่
            phonenumber: _carePhoneController.text,
            email: email,
            aboutme: "",
            equipmentdetails: _careVehicleDescController.text, // ประยุกต์ใช้กับยานพาหนะเบื้องต้น
            address: _careAddressController.text,
            admincomment: "",
            servicestatus: "pending",
            accountstatus: "active",
            latitude: 0.0,
            longitude: 0.0,
          );
          
          isSuccess = await _dbService.saveCaretakerData(newCaretaker);

        } else {
          // === บันทึกข้อมูล: ผู้ป่วย และ ญาติ ===
          RelativeModel newRelative = RelativeModel(
            relativeId: uid, // ใช้ UID ผูกกับญาติที่เป็นคนสมัคร
            firstname: _relFirstNameController.text,
            lastname: _relLastNameController.text,
            email: email,
            phonenumber: _relPhoneController.text,
            lineid: _relLineIdController.text,
            relationship: _relRelationController.text,
          );

          PatientModel newPatient = PatientModel(
            patientId: "PAT_$uid", // สร้าง ID ผู้ป่วยอิงจากญาติ
            patientphoto: "",
            firstname: _patFirstNameController.text,
            lastname: _patLastNameController.text,
            phonenumber: _patPhoneController.text,
            gender: "ไม่ระบุ",
            birthdate: DateTime.now(),
            disease: "", // ค่าว่างไว้ก่อน (อาจให้แก้ในแอปทีหลัง)
            mobility: "",
            address: _patAddressController.text,
            latitude: 0.0,
            longitude: 0.0,
          );

          isSuccess = await _dbService.saveRelativeAndPatientData(newRelative, newPatient);
        }

        // 3. ตรวจสอบผลการบันทึกฐานข้อมูล
        if (isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')));
          // เด้งกลับไปหน้าเข้าสู่ระบบ
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อีเมลนี้ถูกใช้งานแล้ว หรือข้อมูลไม่ถูกต้อง')));
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
              
              // แสดงฟอร์มตามแท็บที่เลือก
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isCaretaker ? _buildCaretakerForm() : _buildRelativeForm(),
              ),

              const SizedBox(height: 20),

              // ปุ่มสมัครสมาชิก
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

  // ==========================================
  // WIDGET FORMS
  // ==========================================

  Widget _buildRelativeForm() {
    return Column(
      key: const ValueKey('RelativeForm'),
      children: [
        _buildSection(title: 'ข้อมูลผู้ป่วย', children: [
          _buildTextField(hint: 'ชื่อผู้ใช้ (อีเมล)', controller: _patEmailController),
          _buildTextField(hint: 'รหัสผ่าน', controller: _patPasswordController, isPassword: true),
        ]),
        _buildSection(title: 'ข้อมูลส่วนตัว', children: [
          _buildTextField(hint: 'หมายเลขบัตรประชาชน', controller: _patIdCardController),
          Row(
            children: [
              Expanded(child: _buildTextField(hint: 'ชื่อจริง', controller: _patFirstNameController)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(hint: 'นามสกุล', controller: _patLastNameController)),
            ],
          ),
          _buildTextField(hint: 'เบอร์โทรศัพท์', controller: _patPhoneController),
          _buildTextField(hint: 'ไอดีไลน์', controller: _patLineIdController),
        ]),
        _buildSection(title: 'ข้อมูลที่อยู่', children: [
          _buildTextField(hint: 'รายละเอียดที่อยู่...', controller: _patAddressController, maxLines: 3),
        ]),
        _buildSection(title: 'ข้อมูลติดต่อญาติ', children: [
          Row(
            children: [
              Expanded(child: _buildTextField(hint: 'ชื่อจริง', controller: _relFirstNameController)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(hint: 'นามสกุล', controller: _relLastNameController)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTextField(hint: 'เบอร์โทรติดต่อ', controller: _relPhoneController)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField(hint: 'ไอดีไลน์', controller: _relLineIdController)),
            ],
          ),
          _buildTextField(hint: 'สถานะความสัมพันธ์', controller: _relRelationController),
        ]),
      ],
    );
  }

  Widget _buildCaretakerForm() {
    return Column(
      key: const ValueKey('CaretakerForm'),
      children: [
        _buildSection(title: 'ข้อมูลผู้ดูแล', children: [
          _buildTextField(hint: 'หมายเลขบัตรประชาชน', controller: _careIdCardController),
          _buildTextField(hint: 'อีเมล', controller: _careEmailController),
          _buildTextField(hint: 'รหัสผ่าน', controller: _carePasswordController, isPassword: true),
        ]),
        _buildSection(title: 'ข้อมูลส่วนตัว', children: [
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
          _buildTextField(hint: 'ที่อยู่ปัจจุบัน', controller: _careAddressController, maxLines: 2),
        ]),
        _buildSection(title: 'ข้อมูลยานพาหนะและใบรับรอง', children: [
          _buildTextField(hint: 'เช่น รุ่นรถ สีรถยนต์ ประเภท', controller: _careVehicleDescController),
          _buildTextField(hint: 'ทะเบียนรถ', controller: _careVehicleRegController),
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