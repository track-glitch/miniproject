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
import '../models/vehicle_model.dart';
import '../models/vehicle_photo_model.dart';

class CaretakerRegisterPage extends StatefulWidget {
  const CaretakerRegisterPage({super.key});

  @override
  State<CaretakerRegisterPage> createState() => _CaretakerRegisterPageState();
}

class _CaretakerRegisterPageState extends State<CaretakerRegisterPage> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  int? _age;
  int _currentStep = 1;
  bool _isLoading = false;
  bool _isRegistrationSuccess = false;
  String? _submitErrorMessage;

  // --- Step 1: เงื่อนไขการให้บริการ ---
  bool _isPolicyAccepted = false;
  bool _isObscure = true;

  // --- Step 2: ข้อมูลส่วนตัว ---
  final _step2FormKey = GlobalKey<FormState>();
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

  // --- Step 3: ข้อมูลยานพาหนะ ---
  final _step3FormKey = GlobalKey<FormState>();
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

  // --- Step 4: เอกสาร ---
  File? _docIdCardFile;
  File? _docDriverLicenseFile;
  File? _docVehicleRegFile;
  File? _docInsuranceFile;
  File? _docResumeFile; // Resume 1 ใบ A4
  final List<File> _docCertificateFiles = []; // ประกาศนียบัตร เพิ่มได้หลายไฟล์

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
    _brandController.dispose();
    _modelController.dispose();
    _licensePlateController.dispose();
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
          _colorController,
        ].any((c) => c.text.trim().isNotEmpty) ||
        _selectedGender.isNotEmpty ||
        _selectedVehicleType.isNotEmpty ||
        _selectedProvince.isNotEmpty ||
        _birthDate != null ||
        _profileImageFile != null ||
        _exteriorImageFile != null ||
        _docIdCardFile != null;
  }

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

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
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
      int fileSizeInBytes = await file.length();
      if ((fileSizeInBytes / (1024 * 1024)) > 20) {
        _showErrorSnackBar('ขนาดไฟล์ต้องไม่เกิน 20MB');
        return;
      }
      List<int> imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);
      onImagePicked(file, base64String);
    }
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
        _age = _calculateAge(selectedDate);
        _birthDateController.text =
            "${selectedDate.day.toString().padLeft(2, '0')}/"
            "${selectedDate.month.toString().padLeft(2, '0')}/"
            "${selectedDate.year + 543}";
      });
    }
  }

  Future<void> _pickResumeImage(Function(File, String) onImagePicked) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      int fileSizeInBytes = await file.length();
      double fileSizeInKB = fileSizeInBytes / 1024; // แปลงเป็น KB

      if (fileSizeInKB > 1500) {
        _showErrorSnackBar(
          'ขนาดไฟล์ใหญ่เกินไป (ต้องไม่เกิน 1,500 KB หรือ 1.5 MB)',
        );
        return;
      }

      List<int> imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);
      onImagePicked(file, base64String);
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

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_isPolicyAccepted) {
        _showErrorSnackBar('กรุณายอมรับเงื่อนไขการให้บริการก่อนดำเนินการต่อ');
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_step2FormKey.currentState!.validate()) {
        if (_profilePhotoBase64 == null) {
          _showErrorSnackBar('กรุณาเลือกรูปโปรไฟล์ของคุณ');
          return;
        }
        if (_selectedGender.isEmpty) {
          _showErrorSnackBar('กรุณาเลือกเพศ');
          return;
        }
        setState(() => _currentStep = 3);
      }
    } else if (_currentStep == 3) {
      if (_step3FormKey.currentState!.validate()) {
        if (_selectedVehicleType.isEmpty) {
          _showErrorSnackBar('กรุณาเลือกประเภทรถยนต์');
          return;
        }
        if (_selectedProvince.isEmpty ||
            !_provinces.contains(_selectedProvince.trim())) {
          _showErrorSnackBar('กรุณาเลือกจังหวัดป้ายทะเบียนให้ถูกต้อง');
          return;
        }
        if (_exteriorPhotoBase64 == null ||
            _interiorPhotoBase64 == null ||
            _storagePhotoBase64 == null) {
          _showErrorSnackBar('กรุณาอัปโหลดรูปถ่ายรถยนต์ให้ครบทั้ง 3 มุม');
          return;
        }
        setState(() => _currentStep = 4);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _submitRegistration() async {
    if (_docIdCardFile == null ||
        _docDriverLicenseFile == null ||
        _docVehicleRegFile == null ||
        _docInsuranceFile == null ||
        _docResumeFile == null) {
      _showErrorSnackBar('กรุณาอัปโหลดเอกสารที่จำเป็น (*) ให้ครบถ้วน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. จัดเตรียมข้อมูลเอกสาร
      List<DocumentModel> documentsList = [
        DocumentModel(
          documentId: "doc_idcard",
          documenttype: "สำเนาบัตรประชาชน",
          filepath: "base64_data",
          uploaddate: DateTime.now(),
        ),
        DocumentModel(
          documentId: "doc_driver_license",
          documenttype: "สำเนาใบขับขี่",
          filepath: "base64_data",
          uploaddate: DateTime.now(),
        ),
        DocumentModel(
          documentId: "doc_vehicle_reg",
          documenttype: "สำเนาทะเบียนรถ",
          filepath: "base64_data",
          uploaddate: DateTime.now(),
        ),
        DocumentModel(
          documentId: "doc_insurance",
          documenttype: "สำเนาประกันภัยรถยนต์",
          filepath: "base64_data",
          uploaddate: DateTime.now(),
        ),
        DocumentModel(
          documentId: "doc_resume",
          documenttype: "ประวัติการทำงาน (Resume)",
          filepath: "base64_data",
          uploaddate: DateTime.now(),
        ),
      ];

      // เพิ่มไฟล์ใบประกาศนียบัตร (ถ้ามีหลายไฟล์)
      for (int i = 0; i < _docCertificateFiles.length; i++) {
        documentsList.add(
          DocumentModel(
            documentId: "doc_certificate_${i + 1}",
            documenttype: "ใบประกาศนียบัตร ${i + 1}",
            filepath: "base64_data",
            uploaddate: DateTime.now(),
          ),
        );
      }

      // 2. จัดเตรียมข้อมูลยานพาหนะและรูปรถ
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

      VehicleModel vehicleData = VehicleModel(
        vehicleId: _licensePlateController.text.trim(),
        vehicletype: _selectedVehicleType,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        licenseplate: _licensePlateController.text.trim(),
        province: _selectedProvince.trim(),
        color: _colorController.text.trim(),
        vehiclephotos: vehiclePhotos,
      );

      // 3. ประกอบข้อมูล Caretaker ทั้งหมดเข้าด้วยกัน
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
        email: _emailController.text.trim(), // ส่งค่าว่างได้เนื่องจากไม่บังคับ
        experience: _experienceController.text.trim(),
        servicestatus: "Unavailable",
        accountstatus: "Pending",
        location: LocationModel(
          address: _serviceAreaController.text.trim(),
          latitude: _currentLat,
          longitude: _currentLng,
        ),
        vehicle: vehicleData,
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
          title: Text(
            'สมัครผู้ให้บริการ (ขั้นที่ $_currentStep/4)',
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
              : _buildRegistrationForm(),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
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
                if (_currentStep == 4) _buildStep4(),
              ],
            ),
          ),
        ),
        _buildBottomControls(),
      ],
    );
  }

  // ================= STEP 1 : เงื่อนไขการให้บริการ =================
  Widget _buildStep1() {
    final List<String> terms = [
      '1. ผู้ดูแลต้องลงทะเบียนด้วยข้อมูลที่ถูกต้อง ครบถ้วน และเป็นจริง พร้อมแนบเอกสารตามที่ระบบกำหนด',
      '2. ผู้ดูแลต้องปฏิบัติหน้าที่ด้วยความสุภาพ ซื่อสัตย์ และคำนึงถึงความปลอดภัยของผู้สูงอายุเป็นสำคัญ',
      '3. ผู้ดูแลต้องเดินทางไปรับ–ส่งผู้สูงอายุตามวัน เวลา และสถานที่ที่ได้รับมอบหมาย พร้อมอัปเดตสถานะผ่านระบบ',
      '4. ผู้ดูแลไม่มีอำนาจวินิจฉัยโรค สั่งยา หรือให้การรักษาทางการแพทย์ มีหน้าที่เพียงอำนวยความสะดวกและดูแลระหว่างใช้บริการ',
      '5. ผู้ดูแลต้องรักษาความลับของข้อมูลส่วนบุคคลและสุขภาพ ห้ามเปิดเผยแก่บุคคลภายนอก เว้นแต่ได้รับการยินยอมหรือตามกฎหมาย (PDPA)',
      '6. ผู้ดูแลต้องไม่เรียกรับค่าบริการหรือผลประโยชน์อื่นใด นอกเหนือจากที่ระบบกำหนด เว้นแต่เป็นค่าใช้จ่ายจริงที่ตกลงกันไว้',
      '7. หากได้รับการรายงาน (Report) ตั้งแต่ 3 ครั้งขึ้นไป และตรวจสอบพบว่ามีมูล ระบบขอสงวนสิทธิ์ในการระงับหรือยกเลิกบัญชีโดยไม่ต้องแจ้งล่วงหน้า',
      '8. ผู้ดูแลต้องปฏิบัติตามกฎหมาย และไม่กระทำการใด ๆ ที่ก่อให้เกิดความเสียหายต่อผู้ใช้บริการ ผู้สูงอายุ หรือชื่อเสียงของระบบ',
      '9. ผู้ดูแลจะได้รับค่าตอบแทนจากค่าบริการหลังหักค่าธรรมเนียมการใช้ระบบของแอปพลิเคชัน โดยผู้ดูแลจะได้รับร้อยละ 80 (80%) ของค่าบริการ และแอปพลิเคชันจะได้รับร้อยละ 20 (20%) เพื่อนำไปใช้ในการพัฒนาและดูแลระบบ ทั้งนี้ ค่าเดินทางเพิ่มเติม (หากมี) จะมอบให้ผู้ดูแลเต็มจำนวน',
      '10. การกดยอมรับข้อตกลงนี้ ถือว่าผู้ดูแลได้อ่าน ทำความเข้าใจ และยินยอมปฏิบัติตามเงื่อนไขทั้งหมด',
    ];

    return Column(
      children: [
        _buildSectionContainer(
          title: 'ข้อตกลงและเงื่อนไขการให้บริการ (สำหรับผู้ดูแล)',
          children: [
            Container(
              height: 400,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: terms.map((term) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        term,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'ฉันได้อ่านและยอมรับข้อตกลงและเงื่อนไขการให้บริการ',
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
      ],
    );
  }

  // ================= STEP 2 : ข้อมูลส่วนตัว =================
  Widget _buildStep2() {
    return Form(
      key: _step2FormKey,
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
              // 🌟 ปรับปรุง: อีเมล ไม่บังคับกรอก (isRequired: false)
              _buildLabelField('อีเมล (ถ้ามี)', isRequired: false),
              _buildTextField(
                controller: _emailController,
                hint: 'เช่น example@gmail.com',
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(val.trim())) {
                      return 'รูปแบบอีเมลไม่ถูกต้อง';
                    }
                  }
                  return null; // ยินยอมให้ส่งเป็นค่าว่างได้
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
                          padding: const EdgeInsets.only(bottom: 6),
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
                        if (_age != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.cake, size: 16, color: primaryColor),
                                const SizedBox(width: 5),
                                Text(
                                  'อายุ $_age ปี',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
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
                child: FormField<String>(
                  validator: (value) =>
                      _selectedGender.isEmpty ? 'กรุณาเลือกเพศ' : null,
                  builder: (FormFieldState<String> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('ชาย'),
                                value: 'ชาย',
                                groupValue: _selectedGender,
                                activeColor: primaryColor,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value!;
                                  });
                                  state.didChange(value);
                                },
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
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value!;
                                  });
                                  state.didChange(value);
                                },
                              ),
                            ),
                          ],
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              state.errorText!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              _buildLabelField('รายละเอียดประสบการณ์ทำงานเพิ่มเติม (ถ้ามี)'),
              _buildTextField(
                controller: _experienceController,
                hint: 'ตัวอย่าง: ดูแลผู้ป่วย 3 ปี, เคยทำงานคลินิก',
                maxLength: 500,
                maxLines: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= STEP 3 : ข้อมูลยานพาหนะ =================
  Widget _buildStep3() {
    return Form(
      key: _step3FormKey,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade800),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "ข้อควรระวัง: ข้อมูลรถยนต์ หมวดหมู่ และป้ายทะเบียนที่กรอกในส่วนนี้ จะต้องตรงกับ 'สำเนาทะเบียนรถ' ที่จะอัปโหลดในขั้นตอนถัดไป เพื่อความรวดเร็วในการตรวจสอบ",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade900,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                crossAxisAlignment: CrossAxisAlignment.start,
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
              _buildLabelField(
                'ป้ายทะเบียนรถ (ไม่ต้องระบุจังหวัด)',
                isRequired: true,
              ),
              _buildTextField(
                controller: _licensePlateController,
                hint: 'เช่น กข 1234',
                validator: (val) =>
                    val!.isEmpty ? 'กรุณาระบุป้ายทะเบียน' : null,
              ),

              _buildLabelField('จังหวัด (ป้ายทะเบียน)', isRequired: true),
              _buildProvinceAutocomplete(),
            ],
          ),

          _buildSectionContainer(
            title: 'อัปโหลดรูปรถยนต์เพื่อประเมินความพร้อม',
            children: [
              const Text(
                'ผู้ป่วยและญาติจะเห็นรูปเหล่านี้ก่อนตัดสินใจเรียกใช้บริการ กรุณาใช้รูปที่ชัดเจนและสว่าง',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 15),

              _buildPhotoUploadWidget(
                title: '1. รูปภายนอกรถ',
                description: '(ถ่ายให้เห็นลักษณะของรถชัดเจน)',
                imageFile: _exteriorImageFile,
                onUpload: () => _pickImage((file, base64) {
                  setState(() {
                    _exteriorImageFile = file;
                    _exteriorPhotoBase64 = base64;
                  });
                }),
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
                onUpload: () => _pickImage((file, base64) {
                  setState(() {
                    _interiorImageFile = file;
                    _interiorPhotoBase64 = base64;
                  });
                }),
                onRemove: () => setState(() {
                  _interiorImageFile = null;
                  _interiorPhotoBase64 = null;
                }),
              ),
              const SizedBox(height: 10),

              _buildPhotoUploadWidget(
                title: '3. รูปที่เก็บสัมภาระ',
                description: '(ถ่ายบริเวณที่เก็บอุปกรณ์สัมภาระของผู้ป่วย)',
                imageFile: _storageImageFile,
                onUpload: () => _pickImage((file, base64) {
                  setState(() {
                    _storageImageFile = file;
                    _storagePhotoBase64 = base64;
                  });
                }),
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
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return _provinces;
          }
          return _provinces.where((String option) {
            return option.contains(textEditingValue.text);
          });
        },
        onSelected: (String selection) {
          setState(() {
            _selectedProvince = selection;
          });
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            onEditingComplete: onEditingComplete,
            decoration: InputDecoration(
              hintText: 'พิมพ์ค้นหา หรือ เลือกจังหวัด...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
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
              errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ),
            onChanged: (val) {
              _selectedProvince = val;
            },
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'กรุณาระบุจังหวัด';
              if (!_provinces.contains(val.trim()))
                return 'กรุณาเลือกจังหวัดให้ถูกต้อง';
              return null;
            },
          );
        },
      ),
    );
  }

  // ================= STEP 4 : เอกสาร =================
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionContainer(
          title: 'อัปโหลดเอกสารประกอบ',
          children: [
            const Text(
              'กรุณาอัปโหลดเอกสารต่อไปนี้ให้ครบถ้วนเพื่อประกอบการพิจารณาอนุมัติบัญชี\n(ระบบรองรับไฟล์: PDF, PNG, JPG)',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 15),

            _buildDocumentUploadWidget(
              "1. สำเนาบัตรประชาชน",
              _docIdCardFile,
              true,
              () => _pickImage((f, b) => setState(() => _docIdCardFile = f)),
              () => setState(() => _docIdCardFile = null),
            ),

            _buildDocumentUploadWidget(
              "2. สำเนาใบขับขี่",
              _docDriverLicenseFile,
              true,
              () => _pickImage(
                (f, b) => setState(() => _docDriverLicenseFile = f),
              ),
              () => setState(() => _docDriverLicenseFile = null),
            ),

            _buildDocumentUploadWidget(
              "3. สำเนาทะเบียนรถ (ต้องตรงกับข้อมูลรถที่กรอกไว้)",
              _docVehicleRegFile,
              true,
              () =>
                  _pickImage((f, b) => setState(() => _docVehicleRegFile = f)),
              () => setState(() => _docVehicleRegFile = null),
            ),

            _buildDocumentUploadWidget(
              "4. สำเนาประกันภัยรถยนต์",
              _docInsuranceFile,
              true,
              () => _pickImage((f, b) => setState(() => _docInsuranceFile = f)),
              () => setState(() => _docInsuranceFile = null),
            ),

            _buildDocumentUploadWidget(
              "5. ประวัติการทำงาน (Resume / CV)",
              _docResumeFile,
              true,
              () => _pickResumeImage(
                (f, b) => setState(() => _docResumeFile = f),
              ),
              () => setState(() => _docResumeFile = null),
              subTitle:
                  "(ไฟล์ขนาดไม่เกิน 1.5 MB หรือ 1,500 KB | ส่งได้ 1 ใบ / ไฟล์)",
            ),

            // 🌟 ปรับปรุง 2: ใบประกาศนียบัตร - ไม่บังคับ และสามารถอัปโหลดได้หลายไฟล์
            _buildMultipleCertificateUploadWidget(),
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

  // Widget พิเศษรองรับการอัปโหลด "ใบประกาศนียบัตร" ได้หลายรูป/ไฟล์ (Optional)
  Widget _buildMultipleCertificateUploadWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelField("6. ใบประกาศนียบัตร (ถ้ามี)", isRequired: false),
        const Text(
          '(สามารถอัปโหลดเพิ่มเติมได้หลายรูป/หลายไฟล์)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),

        // รายการรูปที่อัปโหลดไปแล้ว
        if (_docCertificateFiles.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _docCertificateFiles.length,
            itemBuilder: (context, index) {
              final file = _docCertificateFiles[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
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
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ใบประกาศนียบัตรที่ ${index + 1}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'ลบรูปนี้',
                      onPressed: () {
                        setState(() {
                          _docCertificateFiles.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),

        // ปุ่มอัปโหลดเพิ่ม
        InkWell(
          onTap: () {
            _pickImage((f, b) {
              setState(() {
                _docCertificateFiles.add(f);
              });
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: greyBorder, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  _docCertificateFiles.isEmpty
                      ? 'แตะเพื่อเลือกไฟล์ ใบประกาศนียบัตร'
                      : '+ เพิ่มรูป/ไฟล์ ใบประกาศนียบัตรอีก',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
                  : (_currentStep < 4 ? _nextStep : _submitRegistration),
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
                      _currentStep < 4 ? 'ถัดไป' : 'ส่งใบสมัคร',
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
              'ข้อมูลส่วนตัว ยานพาหนะ และเอกสารของคุณถูกส่งเข้าสู่ระบบแล้ว\nขณะนี้อยู่ในสถานะ "รอการตรวจสอบ"\n\nกรุณารอแอดมินตรวจสอบความถูกต้องและอนุมัติบัญชีของคุณ หากผ่านการพิจารณา คุณจะสามารถเข้าสู่ระบบและเริ่มรับงานได้ทันที',
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
                  _pickImage(
                    (f, b) => setState(() {
                      _profileImageFile = f;
                      _profilePhotoBase64 = b;
                    }),
                  );
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(description, style: TextStyle(fontSize: 12, color: primaryColor)),
        const SizedBox(height: 8),
        if (imageFile == null)
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
                  const SizedBox(height: 8),
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
                  onTap: () => _showImagePreview(imageFile),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      imageFile,
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
                        onTap: () => _showImagePreview(imageFile),
                        child: const Text(
                          'แตะที่รูปเพื่อดูขนาดเต็ม',
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
      ],
    );
  }

  Widget _buildDocumentUploadWidget(
    String title,
    File? file,
    bool isRequired,
    VoidCallback onUpload,
    VoidCallback onRemove, {
    String? subTitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelField(title, isRequired: isRequired),
        if (subTitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              subTitle,
              style: TextStyle(fontSize: 12, color: primaryColor),
            ),
          ),
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
                    'แตะเพื่อเลือกไฟล์ หรือ รูปภาพ',
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
                  tooltip: 'ลบเอกสาร',
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
