// ==========================================
// File: lib/views/caretaker_register_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:io';

import '../services/auth_service.dart';
import '../models/caretaker_model.dart';
import '../models/document_model.dart';
import '../models/location_model.dart';

class CaretakerRegisterPage extends StatefulWidget {
  const CaretakerRegisterPage({super.key});

  @override
  State<CaretakerRegisterPage> createState() => _CaretakerRegisterPageState();
}

class _CaretakerRegisterPageState extends State<CaretakerRegisterPage> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  // 🌟 ปรับ _currentStep เริ่มต้นที่ 1 (เหมือนหน้า Relative)
  int _currentStep = 1;
  bool _isLoading = false;
  bool _isRegistrationSuccess = false;
  String? _submitErrorMessage;

  // --- Step 1: ข้อมูลส่วนตัว ---
  final _step1FormKey = GlobalKey<FormState>();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _serviceAreaController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String _selectedGender = "";
  DateTime? _birthDate;
  File? _profileImageFile;
  String? _profilePhotoBase64;

  double _currentLat = 0.0;
  double _currentLng = 0.0;

  // --- Step 2: เอกสาร ---
  File? _doc1File;
  File? _doc2File;
  File? _doc3File;
  File? _resumeFile;

  // --- Step 3: เงื่อนไขการให้บริการ ---
  bool _isPolicyAccepted = false;
  bool _isObscure = true;

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color greyBorder = const Color(0xFFE1BEE7);

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _idCardController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _serviceAreaController.dispose();
    _birthDateController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // 🌟 เช็คว่ามีการกรอกข้อมูลค้างไว้หรือไม่ (เพื่อเตือนตอนกดออก)
  bool get _hasAnyData {
    return [
          _idCardController,
          _passwordController,
          _emailController,
          _firstNameController,
          _lastNameController,
          _phoneController,
          _serviceAreaController,
          _experienceController,
        ].any((c) => c.text.trim().isNotEmpty) ||
        _selectedGender.isNotEmpty ||
        _birthDate != null ||
        _profileImageFile != null ||
        _doc1File != null ||
        _doc2File != null ||
        _doc3File != null ||
        _resumeFile != null;
  }

  // 🌟 ฟังก์ชันเตือนก่อนออก
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

  Future<void> _fetchCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) {
          setState(() {
            _currentLat = position.latitude;
            _currentLng = position.longitude;
          });
        }
      }
    } catch (e) {
      print("ไม่สามารถดึงตำแหน่งได้: $e");
    }
  }

  Future<void> _pickImage(Function(File) onImagePicked) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      int fileSizeInBytes = await file.length();
      if ((fileSizeInBytes / (1024 * 1024)) > 20) {
        _showErrorSnackBar('ขนาดไฟล์ต้องไม่เกิน 20MB');
        return;
      }
      onImagePicked(file);
    }
  }

  Future<void> _pickProfileImage() async {
    await _pickImage((file) async {
      List<int> imageBytes = await file.readAsBytes();
      setState(() {
        _profileImageFile = file;
        _profilePhotoBase64 = base64Encode(imageBytes);
      });
    });
  }

  Future<void> _selectBirthDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      setState(() {
        _birthDate = selectedDate;
        _birthDateController.text =
            "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year + 543}";
      });
    }
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

  // 🌟 ฟังก์ชันจัดการ Step ถัดไป
  void _nextStep() {
    if (_currentStep == 1) {
      if (_step1FormKey.currentState!.validate()) {
        if (_profilePhotoBase64 == null) {
          _showErrorSnackBar('กรุณาเลือกรูปโปรไฟล์ของคุณ');
          return;
        }
        if (_selectedGender.isEmpty) {
          _showErrorSnackBar('กรุณาเลือกเพศ');
          return;
        }
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      if (_doc1File != null &&
          _doc2File != null &&
          _doc3File != null &&
          _resumeFile != null) {
        setState(() => _currentStep = 3);
      } else {
        _showErrorSnackBar('กรุณาอัปโหลดเอกสารให้ครบทุกช่องเพื่อดำเนินการต่อ');
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _submitRegistration() async {
    if (!_isPolicyAccepted) {
      _showErrorSnackBar('กรุณายอมรับเงื่อนไขการให้บริการก่อนกดยืนยัน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<DocumentModel> documentsList = [
        if (_doc1File != null)
          DocumentModel(
            documentId: "doc_idcard",
            documenttype: "สำเนาบัตรประชาชน",
            filepath: "base64_data",
            uploaddate: DateTime.now(),
          ),
        if (_doc2File != null)
          DocumentModel(
            documentId: "doc_insurance",
            documenttype: "สำเนาประกันภัยรถยนตร์",
            filepath: "base64_data",
            uploaddate: DateTime.now(),
          ),
        if (_doc3File != null)
          DocumentModel(
            documentId: "doc_training",
            documenttype: "เอกสารการฝึกอบรม",
            filepath: "base64_data",
            uploaddate: DateTime.now(),
          ),
        if (_resumeFile != null)
          DocumentModel(
            documentId: "doc_resume",
            documenttype: "Resume",
            filepath: "base64_data",
            uploaddate: DateTime.now(),
          ),
      ];
      CaretakerModel caretaker = CaretakerModel(
        caretakerId: _idCardController.text.trim(),
        password: _passwordController.text.trim(),
        usertype: 'caretaker',
        profilephoto: _profilePhotoBase64!,
        firstname: _firstNameController.text.trim(),
        lastname: _lastNameController.text.trim(),
        gender: _selectedGender,
        birthdate: _birthDate,
        phonenumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        experience: _experienceController.text.trim(),
        servicestatus: "Unavailable",
        accountstatus: "Pending",
        location: LocationModel(
          address: _serviceAreaController.text.trim(),
          latitude: _currentLat,
          longitude: _currentLng,
        ),
        vehicle: null,
        documents: documentsList,
      );

      var result = await _authService.registerCaretaker(
        password: _passwordController.text.trim(),
        caretaker: caretaker,
      );

      if (result != null) {
        setState(() {
          _isRegistrationSuccess = true;
        });
      } else {
        setState(
          () => _submitErrorMessage = 'สมัครสมาชิกไม่สำเร็จ กรุณาลองใหม่',
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
            'สมัครผู้ให้บริการ',
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
          child: _isRegistrationSuccess
              ? _buildWaitingApprovalView()
              : _buildRegistrationForm(),
        ),
      ),
    );
  }

  // 🌟 แบบฟอร์มหลักที่มี Step Indicator และปุ่มแบบเดียวกับญาติ
  Widget _buildRegistrationForm() {
    return Column(
      children: [
        _buildStepIndicator(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    );
  }

  // 🌟 แถบ Step Indicator (Custom)
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepCircle(1, 'ข้อมูลส่วนตัว'),
          _buildStepLine(),
          _buildStepCircle(2, 'เอกสาร'),
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

  // ================= STEP 1 : ข้อมูลส่วนตัว =================
  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: Column(
        children: [
          _buildProfileUploadWidget(),
          const SizedBox(height: 20),

          _buildSectionContainer(
            title: 'ข้อมูลบัญชี',
            children: [
              _buildLabelField(
                'หมายเลขบัตรประชาชน (ใช้เข้าสู่ระบบ)',
                isRequired: true,
              ),
              _buildTextField(
                controller: _idCardController,
                hint: 'ตัวเลข 13 หลัก',
                keyboardType: TextInputType.number,
                maxLength: 13, // 🌟 จำกัดความยาว 13 ตัว
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'กรุณากรอกเลขบัตรประชาชน';
                  if (val.length != 13 || !RegExp(r'^[0-9]+$').hasMatch(val))
                    return 'ต้องเป็นตัวเลข 13 หลักเท่านั้น';
                  return null;
                },
              ),
              _buildLabelField('รหัสผ่าน', isRequired: true),
              _buildTextField(
                controller: _passwordController,
                hint: 'รหัสผ่าน',
                isPassword: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'กรุณากรอกรหัสผ่าน';
                  if (val.contains(' ')) return 'ต้องไม่มีเว้นวรรคหรือช่องว่าง';
                  if (val.length < 8) return 'รหัสผ่านขั้นต่ำ 8 ตัวอักษร';
                  return null;
                },
              ),
              _buildLabelField('อีเมล (ใช้กู้คืนรหัสผ่าน)', isRequired: true),
              _buildTextField(
                controller: _emailController,
                hint: 'เช่น example@gmail.com',
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
            title: 'ข้อมูลส่วนตัว',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('ชื่อจริง', isRequired: true),
                        _buildTextField(
                          controller: _firstNameController,
                          hint: 'ชื่อจริง',
                          validator: (val) => val!.isEmpty ? 'ระบุชื่อ' : null,
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
                        _buildTextField(
                          controller: _lastNameController,
                          hint: 'นามสกุล',
                          validator: (val) =>
                              val!.isEmpty ? 'ระบุนามสกุล' : null,
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
                        _buildTextField(
                          controller: _phoneController,
                          hint: 'เบอร์โทรศัพท์',
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
                        _buildLabelField('วันเกิด', isRequired: true),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            onTap: _selectBirthDate,
                            decoration: InputDecoration(
                              hintText: 'วว/ดด/ปปปป',
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
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: Icon(
                                Icons.calendar_today,
                                color: primaryColor,
                                size: 18,
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
                  value: _selectedGender.isEmpty ? null : _selectedGender,
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
                  onChanged: (val) =>
                      setState(() => _selectedGender = val ?? ''),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'กรุณาเลือกเพศ' : null,
                ),
              ),
              _buildLabelField('ประสบการณ์การทำงาน (ถ้ามี)'),
              _buildTextField(
                controller: _experienceController,
                hint: 'ตัวอย่าง: ดูแลผู้ป่วย 3 ปี, เคยทำงานคลินิก',
                maxLength: 500,
                maxLines: 3,
              ),
            ],
          ),

          _buildSectionContainer(
            title: 'พื้นที่ให้บริการ',
            children: [
              _buildLabelField(
                'เขตอำเภอ/พื้นที่ ที่สะดวกให้บริการ',
                isRequired: true,
              ),
              _buildTextField(
                controller: _serviceAreaController,
                hint:
                    'ตัวอย่าง: สะดวกให้บริการเฉพาะในเขตอำเภอเมือง และอำเภอแม่ริม',
                maxLength: 500,
                maxLines: 3,
                validator: (val) =>
                    val!.isEmpty ? 'กรุณาระบุเขตอำเภอที่สะดวกให้บริการ' : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= STEP 2 : เอกสาร =================
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionContainer(
          title: 'อัปโหลดเอกสารประกอบ',
          children: [
            const Text(
              'กรุณาอัปโหลดเอกสารต่อไปนี้ให้ครบถ้วนเพื่อประกอบการพิจารณาอนุมัติบัญชี',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            _buildDocumentUploadWidget(
              "1. สำเนาบัตรประชาชน",
              _doc1File,
              true,
              () => _pickImage((f) => setState(() => _doc1File = f)),
              () => setState(() => _doc1File = null),
            ),
            _buildDocumentUploadWidget(
              "2. สำเนาประกันภัยรถยนตร์",
              _doc2File,
              true,
              () => _pickImage((f) => setState(() => _doc2File = f)),
              () => setState(() => _doc2File = null),
            ),
            _buildDocumentUploadWidget(
              "3. เอกสารการฝึกอบรม",
              _doc3File,
              true,
              () => _pickImage((f) => setState(() => _doc3File = f)),
              () => setState(() => _doc3File = null),
            ),
            _buildDocumentUploadWidget(
              "4. Resume",
              _resumeFile,
              true,
              () => _pickImage((f) => setState(() => _resumeFile = f)),
              () => setState(() => _resumeFile = null),
            ),
          ],
        ),
      ],
    );
  }

  // ================= STEP 3 : เงื่อนไข =================
  Widget _buildStep3() {
    return Column(
      children: [
        _buildSectionContainer(
          title: 'เงื่อนไขการให้บริการพาไปหาหมอ',
          children: [
            Container(
              height: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const SingleChildScrollView(
                child: Text(
                  "ผู้ดูแลจะได้รับค่าตอบแทนจากค่าบริการหลังจากหักค่าธรรมเนียมการใช้ระบบของแอปพลิเคชัน โดยผู้ดูแลจะได้รับ 85% ของค่าบริการ และแอปพลิเคชันจะได้รับ 15% เพื่อใช้ในการพัฒนาและดูแลระบบ ทั้งนี้ หากจุดรับส่งหรือพื้นที่ใช้บริการอยู่นอกเหนือเขตอำเภอที่ผู้ดูแลแต่ละท่านกำหนดว่าสะดวกให้บริการในระบบ จะมอบค่าเดินทางเพิ่มเติมให้ผู้ดูแลเต็มจำนวน",
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
                'ข้าพเจ้าได้อ่านและยอมรับเงื่อนไขในการให้บริการ',
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

  // 🌟 ปุ่มควบคุมด้านล่าง (ย้อนกลับ / ถัดไป / สมัคร) แบบเดียวกับหน้า Relative
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
                  : (_currentStep < 3 ? _nextStep : _submitRegistration),
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
                      _currentStep < 3 ? 'ถัดไป' : 'ส่งใบสมัคร',
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

  // 🌟 หน้าจอเมื่อสมัครสำเร็จ[cite: 7]
  Widget _buildWaitingApprovalView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 80, color: primaryColor),
            const SizedBox(height: 24),
            const Text(
              'ส่งข้อมูลสำเร็จ!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ข้อมูลส่วนตัวและเอกสารของคุณถูกส่งเข้าสู่ระบบแล้ว\nขณะนี้อยู่ในสถานะ "รอการตรวจสอบ"\n\nกรุณารอแอดมินตรวจสอบความถูกต้องและอนุมัติบัญชีของคุณ หากผ่านการพิจารณา คุณจะสามารถเข้าสู่ระบบเพื่อกรอกข้อมูลยานพาหนะและเริ่มรับงานได้',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'กลับสู่หน้าเข้าสู่ระบบ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          counterText: "",
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
              : null,
        ),
      ),
    );
  }

  Widget _buildProfileUploadWidget() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: () {
                if (_profileImageFile == null)
                  _pickProfileImage();
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
              onTap: _pickProfileImage,
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
                  onTap: () => setState(() {
                    _profileImageFile = null;
                    _profilePhotoBase64 = null;
                  }),
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
              'รูปโปรไฟล์ของคุณ',
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

  Widget _buildDocumentUploadWidget(
    String title,
    File? file,
    bool isRequired,
    VoidCallback onUpload,
    VoidCallback onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelField(title, isRequired: isRequired),
        const SizedBox(height: 5),
        if (file == null)
          InkWell(
            onTap: onUpload,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: greyBorder, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.upload_file, color: primaryColor, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'แตะเพื่อเลือกรูปภาพ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showImagePreview(file),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      file,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'อัปโหลดสำเร็จ',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _showImagePreview(file),
                        child: const Text(
                          'กดที่รูปเพื่อดูขนาดเต็ม',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'ลบรูปภาพ',
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        const SizedBox(height: 15),
      ],
    );
  }
}
