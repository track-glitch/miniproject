import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:io';

// --- เปลี่ยน Path ให้ตรงกับโฟลเดอร์ในโปรเจกต์ของคุณ ---
import '../widgets/location_picker_widget.dart';
import '../services/auth_service.dart';
import '../models/relative_model.dart';
import '../models/patient_model.dart';
import '../models/location_model.dart';

class RelativeRegisterPage extends StatefulWidget {
  const RelativeRegisterPage({super.key});

  @override
  State<RelativeRegisterPage> createState() => _RelativeRegisterPageState();
}

class _RelativeRegisterPageState extends State<RelativeRegisterPage> {
  final AuthService _authService = AuthService();

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  bool _isObscure = true;
  bool _isLoading = false;
  String? _submitErrorMessage;

  int _currentStep = 1;
  bool _isPolicyAccepted = false;

  String _selectedPatGender = "";
  String _selectedPatMobility = ""; // เพิ่มตัวนี้
  DateTime? _patBirthDate;

  LatLng _selectedLocation = const LatLng(18.2881, 99.4921);
  bool _hasPinned = false;

  File? _profileImageFile;
  String? _profilePhotoName;
  String? _profilePhotoBase64;

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color greyBorder = const Color(0xFFE1BEE7);

  // 🌟 ลบ _patUsernameController ออกทั้งหมด
  final TextEditingController _patPasswordController = TextEditingController();
  final TextEditingController _patIdCardController = TextEditingController();
  final TextEditingController _patFirstNameController = TextEditingController();
  final TextEditingController _patLastNameController = TextEditingController();
  final TextEditingController _patBirthDateController = TextEditingController();
  final TextEditingController _patPhoneController = TextEditingController();
  final TextEditingController _patLineIdController = TextEditingController();
  final TextEditingController _patAddressController = TextEditingController();
  final TextEditingController _relEmailController = TextEditingController();
  final TextEditingController _relFirstNameController = TextEditingController();
  final TextEditingController _relLastNameController = TextEditingController();
  final TextEditingController _relPhoneController = TextEditingController();
  final TextEditingController _relLineIdController = TextEditingController();
  final TextEditingController _relRelationController = TextEditingController();
  final TextEditingController _patDiseaseController = TextEditingController();
  final TextEditingController _patMobilityController = TextEditingController();

  @override
  void dispose() {
    _patPasswordController.dispose();
    _patIdCardController.dispose();
    _patFirstNameController.dispose();
    _patLastNameController.dispose();
    _patBirthDateController.dispose();
    _patPhoneController.dispose();
    _patLineIdController.dispose();
    _patAddressController.dispose();
    _relEmailController.dispose();
    _relFirstNameController.dispose();
    _relLastNameController.dispose();
    _relPhoneController.dispose();
    _relLineIdController.dispose();
    _relRelationController.dispose();
    _patDiseaseController.dispose();
    _patMobilityController.dispose();
    super.dispose();
  }

  bool get _hasAnyData {
    return [
          _patPasswordController,
          _patIdCardController,
          _patFirstNameController,
          _patLastNameController,
          _patPhoneController,
          _patLineIdController,
          _patAddressController,
          _relEmailController,
          _relFirstNameController,
          _relLastNameController,
          _relPhoneController,
          _relLineIdController,
          _relRelationController,
          _patDiseaseController,
        ].any((c) => c.text.trim().isNotEmpty) ||
        _selectedPatGender.isNotEmpty ||
        _selectedPatMobility.isNotEmpty ||
        _patBirthDate != null ||
        _profileImageFile != null ||
        _hasPinned;
  }

  // 🌟 ฟังก์ชันแจ้งเตือนก่อนออก (ถ้ามีข้อมูลค้าง)
  Future<bool> _onWillPop() async {
    if (!_hasAnyData) return true;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการออกจากหน้าต่าง'),
        content: const Text(
          'คุณมีข้อมูลที่กำลังกรอกค้างอยู่ ต้องการออกจากหน้านี้โดยไม่บันทึกข้อมูลหรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ออก', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  // --- ฟังก์ชันเกี่ยวกับรูปภาพและวันที่ ---
  Future<void> _pickImageReal() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      int fileSizeInBytes = await file.length();
      if ((fileSizeInBytes / (1024 * 1024)) > 20) {
        _showErrorSnackBar('ขนาดไฟล์รูปภาพโปรไฟล์ต้องไม่เกิน 20MB');
        return;
      }
      List<int> imageBytes = await file.readAsBytes();
      setState(() {
        _profileImageFile = file;
        _profilePhotoName = pickedFile.name;
        _profilePhotoBase64 = base64Encode(imageBytes);
      });
    }
  }

  Future<void> _selectPatBirthDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      setState(() {
        _patBirthDate = selectedDate;
        _patBirthDateController.text =
            "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year + 543}";
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('เลือกรูปจากแกลเลอรี (Gallery)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageReal();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('ถ่ายรูปใหม่ (Camera)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageReal();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImagePreview(File imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: false,
                minScale: 0.5,
                maxScale: 4,
                child: Image.file(imageFile, fit: BoxFit.contain),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white, size: 35),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_step1FormKey.currentState!.validate()) {
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      if (_step2FormKey.currentState!.validate()) {
        if (_profilePhotoBase64 == null) {
          _showErrorSnackBar('กรุณาเลือกรูปโปรไฟล์ผู้ป่วย');
          return;
        }
        if (_patAddressController.text.trim().isEmpty || !_hasPinned) {
          _showErrorSnackBar('กรุณาระบุที่อยู่และปักหมุดบนแผนที่');
          return;
        }
        setState(() => _currentStep = 3);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  // 🌟 ฟังก์ชันจัดการการสมัคร (อัปเดตตรงตาม Model ใหม่)
  void _handleRegister() async {
    if (!_isPolicyAccepted) {
      _showErrorSnackBar('กรุณายอมรับเงื่อนไขการให้บริการก่อนกดยืนยัน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. สร้างก้อนข้อมูล Patient
      PatientModel patientData = PatientModel(
        patientId: _patIdCardController.text.trim(),
        patientphoto: _profilePhotoBase64!,
        firstname: _patFirstNameController.text.trim(),
        lastname: _patLastNameController.text.trim(),
        phonenumber: _patPhoneController.text.trim(),
        gender: _selectedPatGender,
        birthdate: _patBirthDate,
        disease: _patDiseaseController.text.trim(),
        mobility: _selectedPatMobility, // 🌟 ใช้ตัวแปรจาก Dropdown
        location: LocationModel(
          address: _patAddressController.text.trim(),
          latitude: _hasPinned ? _selectedLocation.latitude : 0.0,
          longitude: _hasPinned ? _selectedLocation.longitude : 0.0,
        ), // 🌟 ไม่ต้องกังวลเรื่องชื่อ Key เพราะ Model จะแปลงเป็น 'Location' ให้เองตอน toJson[cite: 6]
      );

      // 2. สร้างก้อนข้อมูล Relative
      RelativeModel relativeData = RelativeModel(
        relativeId: _patIdCardController.text
            .trim(), // 🌟 สำคัญ: ยัดเลขบัตรประชาชนผู้ป่วยลงใน relativeId เพื่อใช้ Login
        password: _patPasswordController.text.trim(),
        usertype: 'relative',
        firstname: _relFirstNameController.text.trim(),
        lastname: _relLastNameController.text.trim(),
        email: _relEmailController.text.trim(),
        phonenumber: _relPhoneController.text.trim(),
        lineId: _relLineIdController.text.trim(),
        relationship: _relRelationController.text.trim(),
        patient: patientData, // ประกอบร่าง Patient เข้าไป
      );

      UserCredential? userCredential = await _authService.registerRelative(
        password: _patPasswordController.text.trim(),
        relative: relativeData, // 🌟 ส่งไปก้อนเดียวจบ
      );

      if (userCredential != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'สมัครสมาชิกสำเร็จ!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(
          () => _submitErrorMessage =
              'สมัครสมาชิกไม่สำเร็จ กรุณาตรวจสอบข้อมูลอีกครั้ง',
        );
      }
    } catch (e) {
      setState(() => _submitErrorMessage = 'เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 หุ้มด้วย PopScope เพื่อดักการกด Back กลับ (ของระบบ Android / Swipe)
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'สมัครสมาชิกสำหรับญาติ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      if (_currentStep == 1) _buildStep1(),
                      if (_currentStep == 2) _buildStep2(),
                      if (_currentStep == 3) _buildStep3(),
                    ],
                  ),
                ),
              ),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepCircle(1, 'ข้อมูลบัญชี'),
          _buildStepLine(),
          _buildStepCircle(2, 'ข้อมูลผู้ป่วย'),
          _buildStepLine(),
          _buildStepCircle(3, 'ยืนยัน'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String title) {
    bool isActive = _currentStep >= step;
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isActive ? primaryColor : Colors.grey.shade300,
          child: Text(
            step.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? primaryColor : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 8).copyWith(bottom: 15),
      ),
    );
  }

  // 🌟 Step 1: ย้ายเลขบัตรประชาชนมาไว้เป็นบัญชีเข้าสู่ระบบ (แทน Username)
  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: Column(
        children: [
          _buildSectionContainer(
            title: 'บัญชีเข้าสู่ระบบ',
            children: [
              _buildLabelField(
                'หมายเลขบัตรประชาชนผู้ป่วย (ใช้เข้าสู่ระบบ)',
                isRequired: true,
              ),
              _buildInputField(
                hint: 'ตัวเลข 13 หลัก',
                controller: _patIdCardController,
                keyboardType: TextInputType.number,
                maxLength: 13,
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'กรุณากรอกเลขบัตรประชาชน';
                  if (val.length != 13 || !RegExp(r'^[0-9]+$').hasMatch(val))
                    return 'ต้องเป็นตัวเลข 13 หลัก';
                  return null;
                },
              ),
              _buildLabelField('รหัสผ่าน', isRequired: true),
              _buildInputField(
                hint: 'รหัสผ่าน',
                controller: _patPasswordController,
                isPassword: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'กรุณากรอกรหัสผ่าน';
                  if (val.contains(' ')) return 'ต้องไม่มีเว้นวรรคหรือช่องว่าง';
                  if (val.length < 8 || val.length > 16)
                    return 'ความยาวต้องอยู่ระหว่าง 8-16 ตัวอักษร';
                  return null;
                },
              ),
              _buildLabelField(
                'อีเมลญาติ (ใช้กู้คืนรหัสผ่าน)',
                isRequired: true,
              ),
              _buildInputField(
                hint: 'เช่น example@gmail.com',
                controller: _relEmailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'กรุณากรอกอีเมล';
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(val))
                    return 'รูปแบบอีเมลไม่ถูกต้อง';
                  return null;
                },
              ),
            ],
          ),
          _buildSectionContainer(
            title: 'ข้อมูลติดต่อญาติ',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('ชื่อจริง', isRequired: true),
                        _buildInputField(
                          hint: 'ชื่อจริง',
                          controller: _relFirstNameController,
                          validator: (val) =>
                              val!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('นามสกุล', isRequired: true),
                        _buildInputField(
                          hint: 'นามสกุล',
                          controller: _relLastNameController,
                          validator: (val) =>
                              val!.isEmpty ? 'กรุณากรอกนามสกุล' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('เบอร์โทรศัพท์', isRequired: true),
                        _buildInputField(
                          hint: 'เบอร์โทรศัพท์',
                          controller: _relPhoneController,
                          keyboardType: TextInputType.phone,
                          validator: (val) =>
                              val!.isEmpty ? 'กรุณากรอกเบอร์โทรศัพท์' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🌟 ปลดล็อคไม่บังคับกรอก Line ID
                        _buildLabelField('ไอดีไลน์'),
                        _buildInputField(
                          hint: 'ไอดีไลน์ (ถ้ามี)',
                          controller: _relLineIdController,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildLabelField('ความสัมพันธ์กับผู้ป่วย', isRequired: true),
              _buildInputField(
                hint: 'เช่น บุตร, หลาน, พี่น้อง',
                controller: _relRelationController,
                validator: (val) =>
                    val!.isEmpty ? 'กรุณาระบุความสัมพันธ์' : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🌟 Step 2: ข้อมูลส่วนตัวผู้ป่วย (เอาเลขบัตรประชาชนออกไป Step 1 แล้ว)
  Widget _buildStep2() {
    return Form(
      key: _step2FormKey,
      child: Column(
        children: [
          _buildProfileUploadWidget(),
          const SizedBox(height: 20),
          _buildSectionContainer(
            title: 'ข้อมูลส่วนตัวผู้ป่วย',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('ชื่อจริง', isRequired: true),
                        _buildInputField(
                          hint: 'ชื่อจริง',
                          controller: _patFirstNameController,
                          validator: (val) =>
                              val!.isEmpty ? 'กรุณากรอกชื่อจริง' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('นามสกุล', isRequired: true),
                        _buildInputField(
                          hint: 'นามสกุล',
                          controller: _patLastNameController,
                          validator: (val) =>
                              val!.isEmpty ? 'กรุณากรอกนามสกุล' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('วันเกิด', isRequired: true),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: _patBirthDateController,
                            readOnly: true,
                            onTap: _selectPatBirthDate,
                            decoration: InputDecoration(
                              hintText: 'วว/ดด/ปปปป',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: greyBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: greyBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: primaryColor,
                              ),
                              errorStyle: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                              ),
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'กรุณาระบุวันเกิด' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildLabelField('เพศ', isRequired: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedPatGender.isEmpty ? null : _selectedPatGender,
                  decoration: InputDecoration(
                    hintText: 'เลือกเพศ',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: greyBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: greyBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ชาย',
                      child: Text('ชาย', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'หญิง',
                      child: Text('หญิง', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedPatGender = value ?? ''),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'กรุณาเลือกเพศ' : null,
                ),
              ),
              _buildLabelField('โรคประจำตัว'),
              _buildInputField(
                hint: 'เช่น เบาหวาน, ความดัน (ถ้าไม่มีให้เว้นว่าง)',
                controller: _patDiseaseController,
              ),
              _buildLabelField('ความคล่องตัวในการเคลื่อนไหว', isRequired: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedPatMobility.isEmpty
                      ? null
                      : _selectedPatMobility,
                  decoration: InputDecoration(
                    hintText: 'เลือกระดับความคล่องตัว',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: greyBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: greyBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'เดินได้ปกติ',
                      child: Text(
                        'เดินได้ปกติ',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'เดินได้ไม่คล่อง',
                      child: Text(
                        'เดินได้ไม่คล่อง',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'ต้องพยุง',
                      child: Text('ต้องพยุง', style: TextStyle(fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: 'ติดเตียง',
                      child: Text('ติดเตียง', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedPatMobility = value ?? ''),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณาระบุความคล่องตัว'
                      : null,
                ),
              ),
              _buildLabelField('เบอร์โทรศัพท์', isRequired: true),
              _buildInputField(
                hint: 'เบอร์โทรศัพท์',
                controller: _patPhoneController,
                keyboardType: TextInputType.phone,
                validator: (val) =>
                    val!.isEmpty ? 'กรุณากรอกเบอร์โทรศัพท์' : null,
              ),
              // 🌟 ปลดล็อคไม่บังคับกรอก Line ID
              _buildLabelField('ไอดีไลน์'),
              _buildInputField(
                hint: 'ไอดีไลน์ (ถ้ามี)',
                controller: _patLineIdController,
              ),
            ],
          ),
          _buildSectionContainer(
            title: 'ข้อมูลที่อยู่ผู้ป่วย',
            children: [
              LocationPickerWidget(
                initialLocation: _selectedLocation,
                initialAddress: _patAddressController.text,
                onLocationChanged: (newLocation, newAddress) {
                  setState(() {
                    _selectedLocation = newLocation;
                    _patAddressController.text = newAddress;
                    _hasPinned = true;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        _buildSectionContainer(
          title: 'ข้อตกลงและเงื่อนไขการใช้บริการ',
          children: [
            Container(
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const SingleChildScrollView(
                child: Text(
                  '1. ผู้ใช้บริการต้องให้ข้อมูลที่เป็นความจริงและถูกต้อง\n\n'
                  '2. แอปพลิเคชันเป็นเพียงสื่อกลางในการเชื่อมโยงระหว่างผู้ป่วยและผู้ดูแล ไม่มีส่วนรับผิดชอบต่อความเสียหายที่อาจเกิดขึ้นระหว่างการเดินทาง\n\n'
                  '3. ผู้ดูแลจะถูกตรวจสอบประวัติอาชญากรรมและเอกสารส่วนตัวก่อนให้บริการ\n\n'
                  '4. ผู้ใช้บริการยินยอมให้แอปพลิเคชันจัดเก็บและประมวลผลข้อมูลส่วนบุคคลตามนโยบายความเป็นส่วนตัว',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'ฉันได้อ่านและยอมรับข้อตกลงและเงื่อนไขการใช้บริการ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              value: _isPolicyAccepted,
              activeColor: primaryColor,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (bool? value) {
                setState(() => _isPolicyAccepted = value ?? false);
              },
            ),
          ],
        ),
        if (_submitErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFF44336),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _submitErrorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFF44336),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'ย้อนกลับ',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_currentStep > 1) const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_currentStep < 3 ? _nextStep : _handleRegister),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _currentStep < 3 ? 'ถัดไป' : 'สมัครสมาชิก',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ที่เหลือ ---
  Widget _buildProfileUploadWidget() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: () {
                if (_profileImageFile == null)
                  _pickImageReal();
                else
                  _showImagePreview(_profileImageFile!);
              },
              child: CircleAvatar(
                radius: 43,
                backgroundColor: primaryColor,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImageFile != null
                      ? FileImage(_profileImageFile!)
                      : null,
                  child: _profileImageFile == null
                      ? const Icon(Icons.person, size: 55, color: Colors.black)
                      : null,
                ),
              ),
            ),
            InkWell(
              onTap: _showImageSourceActionSheet,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
            if (_profileImageFile != null)
              Positioned(
                top: 0,
                right: 0,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _profileImageFile = null;
                      _profilePhotoName = null;
                      _profilePhotoBase64 = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'รูปโปรไฟล์ผู้ป่วย',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        if (_profileImageFile != null)
          const Text(
            'อัปโหลดรูปภาพแล้ว',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildSectionContainer({
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
        border: Border.all(color: greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: darkPurple,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabelField(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    TextEditingController? controller,
    bool isPassword = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool readOnly = false,
    int? maxLength,
    bool alignLabelWithHint = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: greyBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: greyBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                )
              : suffixIcon,
          alignLabelWithHint: alignLabelWithHint,
        ),
      ),
    );
  }
}
