// ==========================================
// File: lib/views/caretaker/caretaker_edit_register_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:io';

import '../../services/auth_service.dart';
import '../../models/caretaker_model.dart';
import '../../models/document_model.dart';
import '../../models/location_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_photo_model.dart';

class CaretakerEditRegisterPage extends StatefulWidget {
  final String uid;

  const CaretakerEditRegisterPage({super.key, required this.uid});

  @override
  State<CaretakerEditRegisterPage> createState() =>
      _CaretakerEditRegisterPageState();
}

class _CaretakerEditRegisterPageState extends State<CaretakerEditRegisterPage> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoadingData = true;
  bool _isUpdating = false;
  bool _isUpdateSuccess = false;

  int _currentStep = 1; // 🌟 ข้ามหน้าเงื่อนไข เริ่มที่ข้อมูลส่วนตัวเลย
  int? _age;
  Map<String, String> _docStatuses = {};
  bool _isObscure = true;

  // --- Step 1: ข้อมูลส่วนตัว ---
  final _step1FormKey = GlobalKey<FormState>();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String _selectedGender = "";
  DateTime? _birthDate;

  File? _profileImageFile;
  String? _profilePhotoBase64;

  double _currentLat = 0.0;
  double _currentLng = 0.0;

  // --- Step 2: ข้อมูลยานพาหนะ ---
  final _step2FormKey = GlobalKey<FormState>();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  String _selectedVehicleType = "";
  String _selectedProvince = "";

  File? _exteriorImageFile;
  String? _exteriorPhotoBase64;
  File? _interiorImageFile;
  String? _interiorPhotoBase64;
  File? _storageImageFile;
  String? _storagePhotoBase64;

  // --- Step 3: เอกสาร ---
  File? _docIdCardFile;
  String? _docIdCardBase64;
  File? _docDriverLicenseFile;
  String? _docDriverLicenseBase64;
  File? _docVehicleRegFile;
  String? _docVehicleRegBase64;
  File? _docInsuranceFile;
  String? _docInsuranceBase64;
  File? _docResumeFile;
  String? _docResumeBase64;

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color greyBorder = const Color(0xFFE1BEE7);

  final List<String> _provinces = [
    "กรุงเทพมหานคร",
    "กระบี่",
    "กาญจนบุรี",
    "กาฬสินธุ์",
    "กำแพงเพชร",
    "ขอนแก่น",
    "จันทบุรี",
    "ฉะเชิงเทรา",
    "ชลบุรี",
    "ชัยนาท",
    "ชัยภูมิ",
    "ชุมพร",
    "เชียงราย",
    "เชียงใหม่",
    "ตรัง",
    "ตราด",
    "ตาก",
    "นครนายก",
    "นครปฐม",
    "นครพนม",
    "นครราชสีมา",
    "นครศรีธรรมราช",
    "นครสวรรค์",
    "นนทบุรี",
    "นราธิวาส",
    "น่าน",
    "บึงกาฬ",
    "บุรีรัมย์",
    "ปทุมธานี",
    "ประจวบคีรีขันธ์",
    "ปราจีนบุรี",
    "ปัตตานี",
    "พระนครศรีอยุธยา",
    "พะเยา",
    "พังงา",
    "พัทลุง",
    "พิจิตร",
    "พิษณุโลก",
    "เพชรบุรี",
    "เพชรบูรณ์",
    "แพร่",
    "ภูเก็ต",
    "มหาสารคาม",
    "มุกดาหาร",
    "แม่ฮ่องสอน",
    "ยโสธร",
    "ยะลา",
    "ร้อยเอ็ด",
    "ระนอง",
    "ระยอง",
    "ราชบุรี",
    "ลพบุรี",
    "ลำปาง",
    "ลำพูน",
    "เลย",
    "ศรีสะเกษ",
    "สกลนคร",
    "สงขลา",
    "สตูล",
    "สมุทรปราการ",
    "สมุทรสงคราม",
    "สมุทรสาคร",
    "สระแก้ว",
    "สระบุรี",
    "สิงห์บุรี",
    "สุโขทัย",
    "สุพรรณบุรี",
    "สุราษฎร์ธานี",
    "สุรินทร์",
    "หนองคาย",
    "หนองบัวลำภู",
    "อ่างทอง",
    "อำนาจเจริญ",
    "อุดรธานี",
    "อุตรดิตถ์",
    "อุทัยธานี",
    "อุบลราชธานี",
  ];

  @override
  void initState() {
    super.initState();
    _fetchCaretakerData();
    _fetchCurrentLocation();
  }

  // ===============================================
  // 🌟 ฟังก์ชันตัวช่วยโหลดรูป ป้องกันแอปเด้ง (Safe Decoder)
  // ===============================================
  ImageProvider? _getSafeImageProvider(File? file, String? base64Str) {
    if (file != null) {
      return FileImage(file);
    } else if (base64Str != null && base64Str.trim().isNotEmpty) {
      try {
        String cleanBase64 = base64Str.contains(',')
            ? base64Str.split(',').last
            : base64Str;
        return MemoryImage(base64Decode(cleanBase64));
      } catch (e) {
        print("Error decoding image: $e");
        return null;
      }
    }
    return null;
  }

  // ===============================================
  // 🌟 ดึงข้อมูลจาก Firebase (อัปเดตแก้บัคพิมพ์เล็ก/พิมพ์ใหญ่)
  // ===============================================
  Future<void> _fetchCaretakerData() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('Login/${widget.uid}/Caretaker')
          .get();

      if (snapshot.exists) {
        final dataMap = Map<String, dynamic>.from(snapshot.value as Map);

        setState(() {
          // ข้อมูลทั่วไป
          _idCardController.text = dataMap['caretakerId'] ?? '';
          _firstNameController.text = dataMap['firstname'] ?? '';
          _lastNameController.text = dataMap['lastname'] ?? '';
          _phoneController.text = dataMap['phonenumber'] ?? '';
          _emailController.text = dataMap['email'] ?? '';
          _experienceController.text = dataMap['experience'] ?? '';
          _selectedGender = dataMap['gender'] ?? '';
          _profilePhotoBase64 = dataMap['profilephoto'] ?? '';

          // 🌟 ที่อยู่: ดักจับทั้ง 'Location' (จาก toJson) และ 'location'
          final locData = dataMap['Location'] ?? dataMap['location'];
          if (locData != null) {
            final loc = Map<String, dynamic>.from(locData);
            _addressController.text = loc['address'] ?? '';
          }

          // วันเกิด
          if (dataMap['birthdate'] != null) {
            _birthDate = DateTime.tryParse(dataMap['birthdate'].toString());
            if (_birthDate != null) {
              _age = DateTime.now().year - _birthDate!.year;
              _birthDateController.text =
                  "${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year + 543}";
            }
          }

          // 🌟 ข้อมูลรถยนต์: ดักจับทั้ง 'Vehicle' (จาก toJson) และ 'vehicle'
          final vehData = dataMap['Vehicle'] ?? dataMap['vehicle'];
          if (vehData != null) {
            final v = Map<String, dynamic>.from(vehData);
            _brandController.text = v['brand'] ?? '';
            _modelController.text = v['model'] ?? '';
            _colorController.text = v['color'] ?? '';
            _licensePlateController.text = v['licenseplate'] ?? '';
            _selectedProvince = v['province'] ?? '';

            String vType = v['vehicletype'] ?? '';
            if ([
              'รถเก๋ง',
              'รถอเนกประสงค์',
              'รถกระบะ',
              'รถตู้',
            ].contains(vType)) {
              _selectedVehicleType = vType;
            }

            // 🌟 รูปรถ: ดักจับทั้ง 'VehiclePhoto' (จาก toJson) และ 'vehiclephotos'
            final photosData = v['VehiclePhoto'] ?? v['vehiclephotos'];
            if (photosData != null) {
              final photos = List<dynamic>.from(photosData);
              for (var p in photos) {
                if (p['vehiclephotoid'] == 'exterior_photo')
                  _exteriorPhotoBase64 = p['photo'];
                if (p['vehiclephotoid'] == 'interior_photo')
                  _interiorPhotoBase64 = p['photo'];
                if (p['vehiclephotoid'] == 'storage_photo')
                  _storagePhotoBase64 = p['photo'];
              }
            }
          }

          // 🌟 เอกสาร: ดักจับทั้ง 'Document' (จาก toJson) และ 'documents'
          final docsData = dataMap['Document'] ?? dataMap['documents'];
          if (docsData != null) {
            final docs = List<dynamic>.from(docsData);
            for (var doc in docs) {
              String dId = doc['documentId'] ?? '';
              String fPath = doc['filepath'] ?? '';
              _docStatuses[dId] = doc['status'] ?? 'PENDING';

              if (dId == 'doc_idcard') _docIdCardBase64 = fPath;
              if (dId == 'doc_driver_license') _docDriverLicenseBase64 = fPath;
              if (dId == 'doc_vehicle_reg') _docVehicleRegBase64 = fPath;
              if (dId == 'doc_insurance') _docInsuranceBase64 = fPath;
              if (dId == 'doc_resume') _docResumeBase64 = fPath;
            }
          }
        });
      }
    } catch (e) {
      print('Error fetching real data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
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

  Future<void> _pickImage(Function(File, String) onImagePicked) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      List<int> imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);
      onImagePicked(file, base64String);
    }
  }

  Future<void> _selectBirthDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _birthDate = selectedDate;
        _age = DateTime.now().year - selectedDate.year;
        _birthDateController.text =
            "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year + 543}";
      });
    }
  }

  void _showImagePreviewFromProvider(ImageProvider provider) {
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
                child: Image(image: provider, fit: BoxFit.contain),
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

  void _submitUpdate() async {
    setState(() => _isUpdating = true);
    try {
      // TODO: เรียก AuthService ส่งข้อมูล
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isUpdateSuccess = true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'แก้ไขข้อมูล (ขั้นที่ $_currentStep/3)',
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoadingData
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : _isUpdateSuccess
            ? _buildSuccessView()
            : _buildEditForm(),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
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
              _buildLabelField('หมายเลขบัตรประชาชน', isRequired: true),
              _buildTextField(
                controller: _idCardController,
                hint: 'ตัวเลข 13 หลัก',
                keyboardType: TextInputType.number,
                maxLength: 13,
                readOnly: true, // ห้ามแก้เลขบัตร
              ),
              _buildLabelField('อีเมล (ถ้ามี)', isRequired: false),
              _buildTextField(
                controller: _emailController,
                hint: 'เช่น example@gmail.com',
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          _buildSectionContainer(
            title: 'ข้อมูลส่วนตัว',
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
                            ),
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
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('ชาย'),
                        value: 'ชาย',
                        groupValue: _selectedGender,
                        activeColor: primaryColor,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (value) =>
                            setState(() => _selectedGender = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('หญิง'),
                        value: 'หญิง',
                        groupValue: _selectedGender,
                        activeColor: primaryColor,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (value) =>
                            setState(() => _selectedGender = value!),
                      ),
                    ),
                  ],
                ),
              ),
              _buildLabelField('ที่อยู่', isRequired: true),
              _buildTextField(
                controller: _addressController,
                hint: 'ระบุที่อยู่ปัจจุบัน, จังหวัด, รหัสไปรษณีย์',
                maxLines: 3,
              ),
              _buildLabelField('รายละเอียดประสบการณ์ทำงานเพิ่มเติม (ถ้ามี)'),
              _buildTextField(
                controller: _experienceController,
                hint: 'ตัวอย่าง: ดูแลผู้ป่วย 3 ปี',
                maxLength: 500,
                maxLines: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileUploadWidget() {
    ImageProvider? profileImage = _getSafeImageProvider(
      _profileImageFile,
      _profilePhotoBase64,
    );

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: () {
                if (profileImage != null)
                  _showImagePreviewFromProvider(profileImage);
              },
              child: CircleAvatar(
                radius: 43,
                backgroundColor: primaryColor,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: profileImage,
                  child: profileImage == null
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
            if (profileImage != null)
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
        if (profileImage != null)
          Text(
            _profileImageFile != null ? 'อัปโหลดรูปใหม่แล้ว' : 'รูปเดิมจากระบบ',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  // ================= STEP 2 : ข้อมูลยานพาหนะ =================
  Widget _buildStep2() {
    return Form(
      key: _step2FormKey,
      child: Column(
        children: [
          _buildSectionContainer(
            title: 'ข้อมูลยานพาหนะ',
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
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('ยี่ห้อ', isRequired: true),
                        _buildTextField(
                          controller: _brandController,
                          hint: 'เช่น Toyota',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelField('รุ่น', isRequired: true),
                        _buildTextField(
                          controller: _modelController,
                          hint: 'เช่น Altis',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildLabelField('สีรถ', isRequired: true),
              _buildTextField(
                controller: _colorController,
                hint: 'เช่น ขาว, ดำ',
              ),
              _buildLabelField(
                'ป้ายทะเบียนรถ (ไม่ต้องระบุจังหวัด)',
                isRequired: true,
              ),
              _buildTextField(
                controller: _licensePlateController,
                hint: 'เช่น กข 1234',
              ),

              // 🌟 เอากล่องเลือกจังหวัดกลับมาให้แล้วครับ
              _buildLabelField('จังหวัด (ป้ายทะเบียน)', isRequired: true),
              _buildProvinceAutocomplete(),
            ],
          ),

          _buildSectionContainer(
            title: 'อัปเดตรูปรถยนต์',
            children: [
              _buildPhotoUploadWidget(
                title: '1. รูปภายนอกรถ',
                description: '(ถ่ายให้เห็นลักษณะของรถชัดเจน)',
                imageFile: _exteriorImageFile,
                oldBase64: _exteriorPhotoBase64,
                onUpload: () => _pickImage(
                  (file, base64) => setState(() {
                    _exteriorImageFile = file;
                    _exteriorPhotoBase64 = base64;
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
                description: '(ถ่ายเบาะหลังหรือบริเวณที่ผู้ป่วยนั่ง)',
                imageFile: _interiorImageFile,
                oldBase64: _interiorPhotoBase64,
                onUpload: () => _pickImage(
                  (file, base64) => setState(() {
                    _interiorImageFile = file;
                    _interiorPhotoBase64 = base64;
                  }),
                ),
                onRemove: () => setState(() {
                  _interiorImageFile = null;
                  _interiorPhotoBase64 = null;
                }),
              ),
              const SizedBox(height: 10),
              _buildPhotoUploadWidget(
                title: '3. รูปที่เก็บสัมภาระ',
                description: '(ถ่ายบริเวณที่เก็บอุปกรณ์สัมภาระ)',
                imageFile: _storageImageFile,
                oldBase64: _storagePhotoBase64,
                onUpload: () => _pickImage(
                  (file, base64) => setState(() {
                    _storageImageFile = file;
                    _storagePhotoBase64 = base64;
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

  Widget _buildProvinceAutocomplete() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: _selectedProvince),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) return _provinces;
          return _provinces.where(
            (String option) => option.contains(textEditingValue.text),
          );
        },
        onSelected: (String selection) =>
            setState(() => _selectedProvince = selection),
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            onEditingComplete: onEditingComplete,
            decoration: InputDecoration(
              hintText: 'พิมพ์ค้นหา หรือ เลือกจังหวัด...',
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
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ),
            onChanged: (val) => _selectedProvince = val,
          );
        },
      ),
    );
  }

  // ================= STEP 3 : เอกสาร =================
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionContainer(
          title: 'อัปเดตเอกสารประกอบ',
          children: [
            const Text(
              'หากเอกสารใดถูกระบุว่า (ไม่ผ่านการตรวจสอบ) กรุณาอัปโหลดใหม่',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
            const SizedBox(height: 15),

            _buildDocumentUploadWidget(
              "1. สำเนาบัตรประชาชน",
              "doc_idcard",
              _docIdCardFile,
              _docIdCardBase64,
              () => _pickImage(
                (f, b) => setState(() {
                  _docIdCardFile = f;
                  _docIdCardBase64 = b;
                }),
              ),
              () => setState(() {
                _docIdCardFile = null;
                _docIdCardBase64 = null;
              }),
            ),
            _buildDocumentUploadWidget(
              "2. สำเนาใบขับขี่",
              "doc_driver_license",
              _docDriverLicenseFile,
              _docDriverLicenseBase64,
              () => _pickImage(
                (f, b) => setState(() {
                  _docDriverLicenseFile = f;
                  _docDriverLicenseBase64 = b;
                }),
              ),
              () => setState(() {
                _docDriverLicenseFile = null;
                _docDriverLicenseBase64 = null;
              }),
            ),
            _buildDocumentUploadWidget(
              "3. สำเนาทะเบียนรถ",
              "doc_vehicle_reg",
              _docVehicleRegFile,
              _docVehicleRegBase64,
              () => _pickImage(
                (f, b) => setState(() {
                  _docVehicleRegFile = f;
                  _docVehicleRegBase64 = b;
                }),
              ),
              () => setState(() {
                _docVehicleRegFile = null;
                _docVehicleRegBase64 = null;
              }),
            ),
            _buildDocumentUploadWidget(
              "4. สำเนาประกันภัยรถยนต์",
              "doc_insurance",
              _docInsuranceFile,
              _docInsuranceBase64,
              () => _pickImage(
                (f, b) => setState(() {
                  _docInsuranceFile = f;
                  _docInsuranceBase64 = b;
                }),
              ),
              () => setState(() {
                _docInsuranceFile = null;
                _docInsuranceBase64 = null;
              }),
            ),
            _buildDocumentUploadWidget(
              "5. ประวัติการทำงาน (Resume / CV)",
              "doc_resume",
              _docResumeFile,
              _docResumeBase64,
              () => _pickImage(
                (f, b) => setState(() {
                  _docResumeFile = f;
                  _docResumeBase64 = b;
                }),
              ),
              () => setState(() {
                _docResumeFile = null;
                _docResumeBase64 = null;
              }),
            ),
          ],
        ),
      ],
    );
  }

  // --- Helper Widgets ---
  Widget _buildPhotoUploadWidget({
    required String title,
    required String description,
    required File? imageFile,
    required String? oldBase64,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    ImageProvider? imageProvider = _getSafeImageProvider(imageFile, oldBase64);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(description, style: TextStyle(fontSize: 12, color: primaryColor)),
        const SizedBox(height: 8),
        if (imageProvider == null)
          InkWell(
            onTap: onUpload,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: greyBorder, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_a_photo, color: primaryColor, size: 30),
                  Text(
                    'แตะเพื่ออัปโหลดรูปภาพ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showImagePreviewFromProvider(imageProvider),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image(
                      image: imageProvider,
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
                      Text(
                        imageFile != null
                            ? 'อัปโหลดใหม่แล้ว'
                            : 'รูปเดิมจากระบบ',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'แตะที่รูปเพื่อดูขนาดเต็ม',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentUploadWidget(
    String title,
    String docId,
    File? file,
    String? oldBase64,
    VoidCallback onUpload,
    VoidCallback onRemove,
  ) {
    bool isRejected = _docStatuses[docId] == 'REJECTED';
    ImageProvider? imageProvider = _getSafeImageProvider(file, oldBase64);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isRejected)
              const Text(
                '(ไม่ผ่านการตรวจสอบ)',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (imageProvider == null)
          InkWell(
            onTap: onUpload,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isRejected ? Colors.red.shade50 : Colors.white,
                border: Border.all(
                  color: isRejected ? Colors.red : greyBorder,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file,
                    color: isRejected ? Colors.red : primaryColor,
                    size: 28,
                  ),
                  Text(
                    'แตะเพื่ออัปโหลดเอกสารใหม่',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRejected && file == null
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              border: Border.all(
                color: isRejected && file == null
                    ? Colors.red
                    : Colors.green.shade300,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showImagePreviewFromProvider(imageProvider),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image(
                      image: imageProvider,
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
                      Text(
                        file != null ? 'อัปโหลดใหม่แล้ว' : 'รูปเดิมจากระบบ',
                        style: TextStyle(
                          color: isRejected && file == null
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'กดที่รูปเพื่อดูขนาดเต็ม',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
        const SizedBox(height: 15),
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
                onPressed: _isUpdating
                    ? null
                    : () => setState(() => _currentStep--),
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
              onPressed: _isUpdating
                  ? null
                  : (_currentStep < 3
                        ? () => setState(() => _currentStep++)
                        : _submitUpdate),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _currentStep < 3 ? 'ถัดไป' : 'ส่งข้อมูลแก้ไข',
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
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if (isRequired) const Text(' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
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
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.green),
          SizedBox(height: 20),
          Text(
            'ส่งข้อมูลแก้ไขสำเร็จ!',
            style: TextStyle(
              color: Colors.green,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'กรุณารอแอดมินตรวจสอบข้อมูลอีกครั้ง',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
