import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:io';

import '../services/caretaker_service.dart';
import '../models/caretaker_model.dart';
import '../models/document_model.dart';
import '../models/location_model.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_photo_model.dart';
import '../services/auth_service.dart'; // เรียกใช้ AuthService

class CaretakerRegisterPage extends StatefulWidget {
  const CaretakerRegisterPage({super.key});

  @override
  State<CaretakerRegisterPage> createState() => _CaretakerRegisterPageState();
}

class _CaretakerRegisterPageState extends State<CaretakerRegisterPage> {
  final CaretakerService _caretakerService = CaretakerService();
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  int _currentStep = 1;
  final int _totalSteps = 4;

  bool _isLoading = false;
  bool _isRegistrationSuccess = false;
  String? _submitErrorMessage;

  // --- Step 1: ข้อมูลส่วนตัว & อายุ ---
  final _step1FormKey = GlobalKey<FormState>();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _serviceAreaController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String _selectedGender = "";
  DateTime? _birthDate;
  File? _profileImageFile;
  String? _profilePhotoBase64;

  double _currentLat = 0.0;
  double _currentLng = 0.0;

  // --- Step 2: เอกสารยืนยันตัวตน ---
  File? _docIdCardFile;
  File? _docPrbFile;
  File? _docVehicleBookFile;
  File? _docTrainingFile;

  // --- Step 3: ข้อมูลยานพาหนะ ---
  final _step3FormKey = GlobalKey<FormState>();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  String _selectedVehicleType = "";

  File? _exteriorImageFile;
  String? _exteriorPhotoBase64;
  File? _interiorImageFile;
  String? _interiorPhotoBase64;
  File? _storageImageFile;
  String? _storagePhotoBase64;

  // --- Step 4: ข้อตกลง PDPA ---
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
    _ageController.dispose();
    _experienceController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _licensePlateController.dispose();
    _provinceController.dispose();
    _colorController.dispose();
    super.dispose();
  }

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
          _brandController,
          _modelController,
          _licensePlateController,
          _provinceController,
          _colorController,
        ].any((c) => c.text.trim().isNotEmpty) ||
        _selectedGender.isNotEmpty ||
        _birthDate != null ||
        _profileImageFile != null ||
        _docIdCardFile != null ||
        _docPrbFile != null ||
        _docVehicleBookFile != null ||
        _docTrainingFile != null ||
        _exteriorImageFile != null ||
        _interiorImageFile != null ||
        _storageImageFile != null;
  }

  Future<bool> _onWillPop() async {
    if (!_hasAnyData) return true;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกการลงทะเบียน?'),
        content: const Text(
          'ข้อมูลที่คุณกรอกจะสูญหาย คุณต้องการออกจากหน้านี้หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('อยู่ต่อ'),
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

  // 🌟 ฟังก์ชันเลือกรูปภาพ พร้อมเช็กนามสกุลไฟล์ JPG / PNG
  Future<void> _pickImage(Function(File, String) onPicked) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      String path = pickedFile.path.toLowerCase();

      // Validation นามสกุลไฟล์
      if (!path.endsWith('.jpg') &&
          !path.endsWith('.jpeg') &&
          !path.endsWith('.png')) {
        _showErrorSnackBar(
          'รองรับเฉพาะไฟล์รูปภาพนามสกุล .JPG และ .PNG เท่านั้น',
        );
        return;
      }

      File file = File(pickedFile.path);
      int fileSizeInBytes = await file.length();
      if ((fileSizeInBytes / (1024 * 1024)) > 20) {
        _showErrorSnackBar('ขนาดไฟล์ต้องไม่เกิน 20MB');
        return;
      }

      List<int> imageBytes = await file.readAsBytes();
      String base64Str = base64Encode(imageBytes);
      onPicked(file, base64Str);
    }
  }

  // 🌟 คำนวณอายุและแยก Field
  Future<void> _selectBirthDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      DateTime now = DateTime.now();
      int age = now.year - selectedDate.year;
      if (now.month < selectedDate.month ||
          (now.month == selectedDate.month && now.day < selectedDate.day)) {
        age--;
      }

      setState(() {
        _birthDate = selectedDate;
        _birthDateController.text =
            "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year + 543}";
        _ageController.text = "$age ปี";
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

  void _showDocumentRequirementDialog({
    required String title,
    required List<String> requirements,
    required String sampleAssetOrUrl,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: darkPurple,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ข้อกำหนดของเอกสาร:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              ...requirements.map(
                (req) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '- ',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(req, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'ตัวอย่างรูปภาพที่ถูกต้อง:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: sampleAssetOrUrl.startsWith('http')
                      ? Image.network(
                          sampleAssetOrUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholderSample(),
                        )
                      : Image.asset(
                          sampleAssetOrUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholderSample(),
                        ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'เข้าใจแล้ว',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderSample() {
    return Container(
      height: 150,
      color: lightPurple,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 40, color: primaryColor),
            const SizedBox(height: 6),
            const Text(
              'ตัวอย่างเอกสารที่ถูกต้อง\n(ถ่ายให้ชัดเจน ไม่บังตัวอักษร)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // 🌟 ฟังก์ชันจัดการการเปลี่ยน Step
  void _nextStep() {
    if (_currentStep == 1) {
      if (!_step1FormKey.currentState!.validate()) return;
      if (_profilePhotoBase64 == null) {
        _showErrorSnackBar('กรุณาเลือกรูปโปรไฟล์ของคุณ');
        return;
      }
      if (_selectedGender.isEmpty) {
        _showErrorSnackBar('กรุณาเลือกเพศ');
        return;
      }
    } else if (_currentStep == 2) {
      if (_docIdCardFile == null ||
          _docPrbFile == null ||
          _docVehicleBookFile == null) {
        _showErrorSnackBar(
          'กรุณาอัปโหลดเอกสารสำคัญ (บัตรประชาชน, พ.ร.บ., เล่มทะเบียน) ให้ครบถ้วน',
        );
        return;
      }
    } else if (_currentStep == 3) {
      if (!_step3FormKey.currentState!.validate()) return;
      if (_selectedVehicleType.isEmpty) {
        _showErrorSnackBar('กรุณาเลือกประเภทรถยนต์');
        return;
      }
      if (_exteriorPhotoBase64 == null ||
          _interiorPhotoBase64 == null ||
          _storagePhotoBase64 == null) {
        _showErrorSnackBar('กรุณาอัปโหลดรูปถ่ายรถยนต์ให้ครบทั้ง 3 มุม');
        return;
      }
    }

    setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _submitRegistration() async {
    if (!_isPolicyAccepted) {
      _showErrorSnackBar(
        'กรุณายอมรับเงื่อนไขนโยบายความเป็นส่วนตัวก่อนกดยืนยัน',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<DocumentModel> documentsList = [
        DocumentModel(
          documentId: "doc_idcard",
          documenttype: "สำเนาบัตรประชาชน",
          filepath: "base64_data",
          uploaddate: DateTime.now(),
        ),
        DocumentModel(
          documentId: "doc_prb",
          documenttype: "พ.ร.บ. รถยนต์",
          filepath: "base64_data",
          uploaddate: DateTime.now(),
        ),
        DocumentModel(
          documentId: "doc_vehicle_book",
          documenttype: "สมุดเล่มทะเบียนรถยนต์",
          filepath: "base64_data",
          uploaddate: DateTime.now(),
        ),
        if (_docTrainingFile != null)
          DocumentModel(
            documentId: "doc_training",
            documenttype: "เอกสารการฝึกอบรม",
            filepath: "base64_data",
            uploaddate: DateTime.now(),
          ),
      ];

      List<VehiclePhotoModel> vehiclePhotos = [
        VehiclePhotoModel(
          vehiclephotoid: "exterior_photo",
          photo: _exteriorPhotoBase64,
        ),
        VehiclePhotoModel(
          vehiclephotoid: "interior_photo",
          photo: _interiorPhotoBase64,
        ),
        VehiclePhotoModel(
          vehiclephotoid: "storage_photo",
          photo: _storagePhotoBase64,
        ),
      ];

      VehicleModel vehicleModel = VehicleModel(
        vehicleId: _licensePlateController.text.trim(),
        vehicletype: _selectedVehicleType,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        licenseplate: _licensePlateController.text.trim(),
        province: _provinceController.text.trim(),
        color: _colorController.text.trim(),
        vehiclephotos: vehiclePhotos,
      );

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
        vehicle: vehicleModel,
        documents: documentsList,
      );

      var result = await _authService.registerCaretaker(
        password: _passwordController.text.trim(),
        caretaker: caretaker,
      );

      if (result != null) {
        setState(() => _isRegistrationSuccess = true);
      } else {
        setState(
          () => _submitErrorMessage = 'ลงทะเบียนไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
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
          title: Text(
            'สมัครผู้ให้บริการ (ขั้นตอนที่ $_currentStep/$_totalSteps)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
              : _buildStepView(),
        ),
      ),
    );
  }

  Widget _buildStepView() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _currentStep / _totalSteps,
          backgroundColor: lightPurple,
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _getStepContent(),
          ),
        ),
        _buildBottomControls(),
      ],
    );
  }

  Widget _getStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1PersonalData();
      case 2:
        return _buildStep2Documents();
      case 3:
        return _buildStep3VehicleData();
      case 4:
        return _buildStep4TermsAndPdpa();
      default:
        return Container();
    }
  }

  // --- STEP 1: ข้อมูลส่วนตัว ---
  Widget _buildStep1PersonalData() {
    return Form(
      key: _step1FormKey,
      child: Column(
        children: [
          _buildProfileUploadWidget(),
          const SizedBox(height: 20),
          _buildSectionContainer(
            title: '1. ข้อมูลบัญชีผู้ใช้',
            children: [
              _buildLabelField('หมายเลขบัตรประชาชน', isRequired: true),
              _buildTextField(
                controller: _idCardController,
                hint: 'ตัวเลข 13 หลัก',
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
              _buildTextField(
                controller: _passwordController,
                hint: 'รหัสผ่านอย่างน้อย 8 ตัวอักษร',
                isPassword: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'กรุณากรอกรหัสผ่าน';
                  if (val.contains(' ')) return 'ต้องไม่มีเว้นวรรค';
                  if (val.length < 8) return 'ขั้นต่ำ 8 ตัวอักษร';
                  return null;
                },
              ),
              _buildLabelField('อีเมล', isRequired: true),
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
            title: '2. ข้อมูลส่วนบุคคล',
            children: [
              Row(
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('วันเดือนปีเกิด', isRequired: true),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            onTap: _selectBirthDate,
                            decoration: InputDecoration(
                              hintText: 'วว/ดด/ปปปป',
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: greyBorder),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'ระบุวันเกิด' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('อายุ'),
                        _buildTextField(
                          controller: _ageController,
                          hint: 'คำนวณอัตโนมัติ',
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
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
                              val!.isEmpty ? 'กรุณากรอกเบอร์โทร' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('เพศ', isRequired: true),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender.isEmpty
                                ? null
                                : _selectedGender,
                            decoration: InputDecoration(
                              hintText: 'เลือกเพศ',
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: greyBorder),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'ชาย',
                                child: Text('ชาย'),
                              ),
                              DropdownMenuItem(
                                value: 'หญิง',
                                child: Text('หญิง'),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedGender = val ?? ''),
                            validator: (val) => (val == null || val.isEmpty)
                                ? 'กรุณาเลือกเพศ'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildLabelField('ประสบการณ์การทำงาน (ถ้ามี)'),
              _buildTextField(
                controller: _experienceController,
                hint: 'ตัวอย่าง: ดูแลผู้ป่วย 3 ปี, เคยเป็นบุคลากรทางการแพทย์',
                maxLength: 300,
                maxLines: 2,
              ),
              _buildLabelField('พื้นที่สะดวกให้บริการ', isRequired: true),
              _buildTextField(
                controller: _serviceAreaController,
                hint: 'ตัวอย่าง: อำเภอเมือง และอำเภอแม่ริม',
                maxLength: 300,
                maxLines: 2,
                validator: (val) => val!.isEmpty ? 'กรุณาระบุเขตพื้นที่' : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP 2: เอกสาร ---
  Widget _buildStep2Documents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionContainer(
          title: 'เอกสารยืนยันตัวตน (รองรับเฉพาะ JPG, PNG)',
          children: [
            const Text(
              'กรุณาอัปโหลดเอกสารที่ชัดเจน ไม่สะท้อนแสง โดยกดปุ่มไอคอนข้อมูลเพื่อดูตัวอย่างเอกสารที่ถูกต้อง',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildDocumentCard(
              title: '1. สำเนาบัตรประชาชน',
              file: _docIdCardFile,
              isRequired: true,
              onInfoPressed: () {
                _showDocumentRequirementDialog(
                  title: 'ข้อกำหนด: สำเนาบัตรประชาชน',
                  requirements: [
                    'ถ่ายรูปให้เห็นรายละเอียดบนบัตรชัดเจน ไม่มืดหรือสะท้อนแสง',
                    'บัตรประชาชนต้องยังไม่หมดอายุ',
                    'ต้องเห็นชื่อ-นามสกุล และเลขบัตร 13 หลักชัดเจน',
                  ],
                  sampleAssetOrUrl: 'assets/images/sample_idcard.png',
                );
              },
              onUpload: () =>
                  _pickImage((f, _) => setState(() => _docIdCardFile = f)),
              onRemove: () => setState(() => _docIdCardFile = null),
            ),
            _buildDocumentCard(
              title: '2. สำเนา พ.ร.บ. รถยนต์',
              file: _docPrbFile,
              isRequired: true,
              onInfoPressed: () {
                _showDocumentRequirementDialog(
                  title: 'ข้อกำหนด: พ.ร.บ. รถยนต์',
                  requirements: [
                    'ตารางกรมธรรม์คุ้มครองผู้ประสบภัยจากรถ (พ.ร.บ.)',
                    'ต้องยังมีผลคุ้มครอง ณ วันที่สมัคร (ไม่หมดอายุ)',
                    'เลขทะเบียนรถใน พ.ร.บ. ต้องตรงกับรถที่จะใช้บริการ',
                  ],
                  sampleAssetOrUrl: 'assets/images/sample_prb.png',
                );
              },
              onUpload: () =>
                  _pickImage((f, _) => setState(() => _docPrbFile = f)),
              onRemove: () => setState(() => _docPrbFile = null),
            ),
            _buildDocumentCard(
              title: '3. สำเนาเล่มทะเบียนรถยนต์',
              file: _docVehicleBookFile,
              isRequired: true,
              onInfoPressed: () {
                _showDocumentRequirementDialog(
                  title: 'ข้อกำหนด: เล่มทะเบียนรถยนต์',
                  requirements: [
                    'ถ่ายหน้าแสดงรายการจดทะเบียน (รายการคู่มือจดทะเบียน)',
                    'เห็นเลขทะเบียน, ยี่ห้อ, เลขตัวรถ และชื่อผู้ครอบครองชัดเจน',
                  ],
                  sampleAssetOrUrl: 'assets/images/sample_vehicle_book.png',
                );
              },
              onUpload: () =>
                  _pickImage((f, _) => setState(() => _docVehicleBookFile = f)),
              onRemove: () => setState(() => _docVehicleBookFile = null),
            ),
            _buildDocumentCard(
              title: '4. เอกสารการฝึกอบรม / ใบรับรอง (ถ้ามี)',
              file: _docTrainingFile,
              isRequired: false,
              onInfoPressed: () {
                _showDocumentRequirementDialog(
                  title: 'ข้อกำหนด: ใบรับรอง / เอกสารอบรม',
                  requirements: [
                    'ใบประกาศนียบัตรการปฐมพยาบาลเบื้องต้น (CPR)',
                    'หรือใบผ่านการอบรมผู้ดูแลผู้สูงอายุ / ผู้ป่วยพักฟื้น',
                  ],
                  sampleAssetOrUrl: 'assets/images/sample_training.png',
                );
              },
              onUpload: () =>
                  _pickImage((f, _) => setState(() => _docTrainingFile = f)),
              onRemove: () => setState(() => _docTrainingFile = null),
            ),
          ],
        ),
      ],
    );
  }

  // --- STEP 3: ข้อมูลยานพาหนะ ---
  Widget _buildStep3VehicleData() {
    return Form(
      key: _step3FormKey,
      child: Column(
        children: [
          _buildSectionContainer(
            title: 'ข้อมูลและรูปถ่ายยานพาหนะ',
            children: [
              _buildLabelField('ประเภทรถ', isRequired: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedVehicleType.isEmpty
                      ? null
                      : _selectedVehicleType,
                  decoration: InputDecoration(
                    hintText: 'เลือกประเภทรถ',
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'รถเก๋ง',
                      child: Text('รถเก๋ง (Sedan)'),
                    ),
                    DropdownMenuItem(
                      value: 'รถอเนกประสงค์',
                      child: Text('รถอเนกประสงค์ (SUV)'),
                    ),
                    DropdownMenuItem(
                      value: 'รถกระบะ',
                      child: Text('รถกระบะ (Pickup)'),
                    ),
                    DropdownMenuItem(
                      value: 'รถตู้',
                      child: Text('รถตู้ (Van)'),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedVehicleType = val ?? ''),
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'กรุณาเลือกประเภทรถ'
                      : null,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('ยี่ห้อ (Brand)', isRequired: true),
                        _buildTextField(
                          controller: _brandController,
                          hint: 'เช่น Toyota',
                          validator: (val) =>
                              val!.isEmpty ? 'ระบุยี่ห้อ' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('รุ่น (Model)', isRequired: true),
                        _buildTextField(
                          controller: _modelController,
                          hint: 'เช่น Altis',
                          validator: (val) => val!.isEmpty ? 'ระบุรุ่น' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildLabelField('สีรถ', isRequired: true),
              _buildTextField(
                controller: _colorController,
                hint: 'เช่น ขาว, ดำ, บรอนซ์เงิน',
                validator: (val) => val!.isEmpty ? 'ระบุสีรถ' : null,
              ),
              // 🌟 แยก Field เลขทะเบียน และ จังหวัด
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('เลขทะเบียนรถ', isRequired: true),
                        _buildTextField(
                          controller: _licensePlateController,
                          hint: 'เช่น กข 1234',
                          validator: (val) =>
                              val!.isEmpty ? 'ระบุทะเบียน' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('จังหวัด', isRequired: true),
                        _buildTextField(
                          controller: _provinceController,
                          hint: 'เช่น เชียงใหม่',
                          validator: (val) =>
                              val!.isEmpty ? 'ระบุจังหวัด' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'อัปโหลดรูปถ่ายรถยนต์ 3 มุม (รองรับ JPG, PNG):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 10),
              _buildPhotoUploadWidget(
                title: '1. รูปภายนอกรถ',
                description: '(ถ่ายให้เห็นตัวรถชัดเจน)',
                imageFile: _exteriorImageFile,
                onUpload: () => _pickImage(
                  (f, b) => setState(() {
                    _exteriorImageFile = f;
                    _exteriorPhotoBase64 = b;
                  }),
                ),
                onRemove: () => setState(() {
                  _exteriorImageFile = null;
                  _exteriorPhotoBase64 = null;
                }),
              ),
              const SizedBox(height: 10),
              _buildPhotoUploadWidget(
                title: '2. รูปภายในห้องโดยสาร',
                description: '(ถ่ายเบาะนั่งผู้ป่วย)',
                imageFile: _interiorImageFile,
                onUpload: () => _pickImage(
                  (f, b) => setState(() {
                    _interiorImageFile = f;
                    _interiorPhotoBase64 = b;
                  }),
                ),
                onRemove: () => setState(() {
                  _interiorImageFile = null;
                  _interiorPhotoBase64 = null;
                }),
              ),
              const SizedBox(height: 10),
              _buildPhotoUploadWidget(
                title: '3. รูปที่เก็บสัมภาระท้ายรถ',
                description: '(สำหรับวางรถเข็น/อุปกรณ์)',
                imageFile: _storageImageFile,
                onUpload: () => _pickImage(
                  (f, b) => setState(() {
                    _storageImageFile = f;
                    _storagePhotoBase64 = b;
                  }),
                ),
                onRemove: () => setState(() {
                  _storageImageFile = null;
                  _storagePhotoBase64 = null;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP 4: ข้อตกลง PDPA & Terms of Service ---
  Widget _buildStep4TermsAndPdpa() {
    return Column(
      children: [
        _buildSectionContainer(
          title: 'ข้อกำหนดนโยบายความเป็นส่วนตัว (PDPA) และเงื่อนไขบริการ',
          children: [
            Container(
              height: 250,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const SingleChildScrollView(
                child: Text(
                  "ข้อตกลงและนโยบายความเป็นส่วนตัว (Privacy Notice - PDPA)\n\n"
                  "1. วัตถุประสงค์การเก็บรวบรวมข้อมูลส่วนบุคคล\n"
                  "แอปพลิเคชันจะทำการเก็บรวบรวมข้อมูลส่วนบุคคลของท่าน เช่น ชื่อ-นามสกุล, เลขบัตรประชาชน, เบอร์โทรศัพท์, อีเมล, วันเดือนปีเกิด, รูปถ่ายโปรไฟล์, เอกสารยืนยันตัวตน และข้อมูลยานพาหนะ เพื่อวัตถุประสงค์ในการยืนยันตัวตน ตรวจสอบคุณสมบัติผู้ให้บริการ ป้องกันการทุจริต และจัดจับคู่บริการพาผู้ป่วยไปสถานพยาบาลอย่างปลอดภัย\n\n"
                  "2. การใช้งานและการเปิดเผยข้อมูล\n"
                  "ข้อมูลตำแหน่งที่ตั้ง (Location) และข้อมูลยานพาหนะของท่านจะถูกนำไปแสดงแก่ผู้ใช้บริการ (ญาติ/ผู้ป่วย) ในระหว่างการดำเนินงานบริการ เพื่ออำนวยความสะดวกในการติดตามสถานะและรับส่งผู้ป่วย\n\n"
                  "3. ระยะเวลาในการจัดเก็บข้อมูล\n"
                  "ระบบจะจัดเก็บข้อมูลส่วนบุคคลของท่านไว้ตลอดระยะเวลาที่ท่านยังเป็นสมาชิกผู้ให้บริการในระบบ และจะทำการลบข้อมูลภายในระยะเวลาที่กฎหมายกำหนดเมื่อมีการยกเลิกบัญชี\n\n"
                  "4. เงื่อนไขค่าตอบแทนการให้บริการ\n"
                  "ผู้ดูแลจะได้รับค่าตอบแทนจากค่าบริการหลังจากหักค่าธรรมเนียมการใช้ระบบ 15% (ผู้ดูแลได้รับ 85%) โดยหากพื้นที่บริการอยู่นอกเหนือเขตอำเภอที่กำหนด ท่านจะได้รับค่าเดินทางเพิ่มเติมเต็มจำนวนตามข้อตกลง",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'ข้าพเจ้าได้อ่าน ยินยอม และยอมรับนโยบายความเป็นส่วนตัว (PDPA) และเงื่อนไขการให้บริการทั้งหมด',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _submitErrorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_currentStep > 1) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_currentStep < _totalSteps
                        ? _nextStep
                        : _submitRegistration),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _currentStep < _totalSteps ? 'ถัดไป' : 'ยืนยันลงทะเบียน',
                      style: const TextStyle(
                        fontSize: 15,
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
              'ส่งข้อมูลการสมัครสำเร็จ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ข้อมูลส่วนตัว เอกสาร และข้อมูลยานพาหนะของคุณ\nถูกส่งเข้าสู่ระบบเรียบร้อยแล้ว\n\nขณะนี้อยู่ในสถานะรอการตรวจสอบจากผู้ดูแลระบบ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
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
                    fontSize: 15,
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

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(14),
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
              fontSize: 15,
              color: darkPurple,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabelField(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
    bool readOnly = false,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
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
            horizontal: 10,
            vertical: 10,
          ),
          errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required File? file,
    required bool isRequired,
    required VoidCallback onInfoPressed,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (isRequired)
                      const Text(' *', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.purple,
                  size: 20,
                ),
                tooltip: 'ดูเงื่อนไขและตัวอย่าง',
                onPressed: onInfoPressed,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (file == null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onUpload,
              icon: Icon(Icons.upload_file, color: primaryColor, size: 18),
              label: Text(
                'อัปโหลดไฟล์/รูปภาพ (JPG, PNG)',
                style: TextStyle(color: primaryColor, fontSize: 12),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showImagePreview(file),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        file,
                        width: 45,
                        height: 45,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'อัปโหลดแล้ว (แตะรูปเพื่อขยาย)',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: onRemove,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadWidget({
    required String title,
    required String description,
    required File? imageFile,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Text(' *', style: TextStyle(color: Colors.red)),
            const SizedBox(width: 6),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (imageFile == null)
          InkWell(
            onTap: onUpload,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: greyBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_a_photo, color: primaryColor, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    'แตะเพื่ออัปโหลด (JPG, PNG)',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showImagePreview(imageFile),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      imageFile,
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'อัปโหลดสำเร็จแล้ว',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
      ],
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
                if (_profileImageFile == null) {
                  _pickImage(
                    (f, b) => setState(() {
                      _profileImageFile = f;
                      _profilePhotoBase64 = b;
                    }),
                  );
                } else {
                  _showImagePreview(_profileImageFile!);
                }
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
              onTap: () => _pickImage(
                (f, b) => setState(() {
                  _profileImageFile = f;
                  _profilePhotoBase64 = b;
                }),
              ),
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
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'รูปโปรไฟล์ของคุณ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
      ],
    );
  }
}
