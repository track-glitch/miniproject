// ==========================================
// File: lib/views/caretaker_register_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

import '../models/location_model.dart';
import '../services/auth_service.dart';
import '../models/caretaker_model.dart';
import '../models/vehicle_model.dart';
import '../models/document_model.dart';
import 'waiting_approval_page.dart';

class CaretakerRegisterPage extends StatefulWidget {
  const CaretakerRegisterPage({super.key});

  @override
  State<CaretakerRegisterPage> createState() => _CaretakerRegisterPageState();
}

class _CaretakerRegisterPageState extends State<CaretakerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  int _currentStep = 1;
  final int _totalSteps = 3;
  bool _isLoading = false;
  bool _isPolicyAccepted = false;

  final Color primaryColor = const Color(
    0xFF0F766E,
  ); // Teal theme for Caretaker
  final Color bgColor = const Color(0xFFF0FDF4);

  // Step 1: Info
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _citizenIdController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final TextEditingController _districtController =
      TextEditingController(); // เขตอำเภอที่ให้บริการ

  String? _selectedGender;
  DateTime? _selectedBirthDate;
  File? _profileImageFile;
  String? _profilePhotoBase64;
  LatLng _currentDeviceLocation = const LatLng(13.7563, 100.5018); // Default

  // Step 2: Documents
  Map<String, File?> _docFiles = {
    'driver_license': null,
    'car_insurance': null,
    'first_aid_certificate': null,
    'resume': null,
  };
  Map<String, String> _docBase64 = {};

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _citizenIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _aboutMeController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentDeviceLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _pickImage(String type) async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      List<int> bytes = await file.readAsBytes();
      setState(() {
        if (type == 'profile') {
          _profileImageFile = file;
          _profilePhotoBase64 = base64Encode(bytes);
        } else {
          _docFiles[type] = file;
          _docBase64[type] = base64Encode(bytes);
        }
      });
    }
  }

  Future<void> _selectBirthDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      if (_profilePhotoBase64 == null) {
        _showError('กรุณาอัปโหลดรูปโปรไฟล์');
        return;
      }
      if (_selectedGender == null || _selectedBirthDate == null) {
        _showError('กรุณาเลือกเพศและวันเกิด');
        return;
      }
    } else if (_currentStep == 2) {
      if (_docBase64['driver_license'] == null ||
          _docBase64['car_insurance'] == null ||
          _docBase64['first_aid_certificate'] == null ||
          _docBase64['resume'] == null) {
        _showError('กรุณาอัปโหลดเอกสารให้ครบทั้ง 4 รายการ');
        return;
      }
    }
    setState(() {
      if (_currentStep < _totalSteps) _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 1) _currentStep--;
    });
  }

  void _submitRegistration() async {
    if (!_isPolicyAccepted) {
      _showError('กรุณายอมรับเงื่อนไขในการให้บริการ');
      return;
    }

    setState(() => _isLoading = true);

    LocationModel locationData = LocationModel(
      locationId: "LOC-${DateTime.now().millisecondsSinceEpoch}",
      address: _districtController.text.trim(),
      latitude: _currentDeviceLocation.latitude,
      longitude: _currentDeviceLocation.longitude,
    );

    CaretakerModel caretaker = CaretakerModel(
      caretakerId: _citizenIdController.text.trim(),
      password: _passwordController.text,
      usertype: 'caretaker',
      profilephoto: _profilePhotoBase64,
      firstname: _firstNameController.text.trim(),
      lastname: _lastNameController.text.trim(),
      gender: _selectedGender,
      birthdate: _selectedBirthDate,
      phonenumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      experience: _aboutMeController.text.trim(),
      accountstatus: 'Pending',
      servicestatus: 'OFF',
      location: locationData,
    );

    // สร้าง List ของเอกสาร
    List<DocumentModel> docs = [];
    _docBase64.forEach((type, base64Data) {
      docs.add(
        DocumentModel(
          documentId: "DOC-${DateTime.now().millisecondsSinceEpoch}-$type",
          documenttype: type,
          filepath: base64Data,
          uploaddate: DateTime.now(),
        ),
      );
    });

    // Dummy VehicleModel for initial registration (Will be updated post-approval)
    VehicleModel dummyVehicle = VehicleModel(
      vehicleId: "VHC-${DateTime.now().millisecondsSinceEpoch}",
      vehicletype: '-',
      brand: '-',
      model: '-',
      licenseplate: '-',
      color: '-',
    );

    final result = await _authService.registerCaretaker(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      usertype: 'caretaker',
      caretaker: caretaker,
      vehicle: dummyVehicle,
      documents: docs,
    );

    setState(() => _isLoading = false);

    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WaitingApprovalPage()),
      );
    } else {
      _showError('เกิดข้อผิดพลาดในการสมัคร หรือมีชื่อผู้ใช้นี้ในระบบแล้ว');
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'ข้อมูลส่วนตัวและที่อยู่';
      case 2:
        return 'เอกสารอ้างอิง';
      case 3:
        return 'เงื่อนไขบริการ';
      default:
        return '';
    }
  }

  String _getNextStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'เอกสารอ้างอิง';
      case 2:
        return 'เงื่อนไขบริการ';
      case 3:
        return 'ยืนยันการสมัคร';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'สมัครเป็นผู้ให้บริการ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                _buildStepperHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: _buildCurrentStepContent(),
                    ),
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '$_currentStep/$_totalSteps',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStepTitle(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Next: ${_getNextStepTitle()}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    if (_currentStep == 1) return _buildStep1();
    if (_currentStep == 2) return _buildStep2();
    return _buildStep3();
  }

  Widget _buildStep1() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage('profile'),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _profileImageFile != null
                ? FileImage(_profileImageFile!)
                : null,
            child: _profileImageFile == null
                ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'อัปโหลดรูปโปรไฟล์',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        _buildInputField(
          'ชื่อผู้ใช้ (Username)',
          _usernameController,
          isRequired: true,
        ),
        _buildInputField(
          'รหัสผ่าน',
          _passwordController,
          isRequired: true,
          isPassword: true,
        ),
        _buildInputField(
          'เลขบัตรประชาชน',
          _citizenIdController,
          isRequired: true,
          keyboardType: TextInputType.number,
        ),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                'ชื่อจริง',
                _firstNameController,
                isRequired: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputField(
                'นามสกุล',
                _lastNameController,
                isRequired: true,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'เพศ *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: ['ชาย', 'หญิง', 'อื่นๆ']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'วันเกิด *',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _selectedBirthDate != null
                        ? "${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}"
                        : "เลือกวันเกิด",
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInputField(
          'เบอร์โทรศัพท์',
          _phoneController,
          isRequired: true,
          keyboardType: TextInputType.phone,
        ),
        _buildInputField(
          'อีเมล',
          _emailController,
          isRequired: true,
          keyboardType: TextInputType.emailAddress,
        ),
        _buildInputField(
          'ประสบการณ์ / เกี่ยวกับฉัน',
          _aboutMeController,
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'พื้นที่ให้บริการ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        _buildInputField(
          'เขตอำเภอที่สะดวกให้บริการ (เช่น อ.เมือง ลำปาง)',
          _districtController,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'กรุณาอัปโหลดเอกสารที่จำเป็นสำหรับการตรวจสอบ',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _buildDocUploadRow('ใบอนุญาตขับขี่', 'driver_license'),
        _buildDocUploadRow('ประกันภัยรถยนต์', 'car_insurance'),
        _buildDocUploadRow(
          'ใบรับรองปฐมพยาบาล (เบื้องต้น)',
          'first_aid_certificate',
        ),
        _buildDocUploadRow('Resume / ประวัติการทำงาน', 'resume'),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ข้อตกลงและเงื่อนไขการให้บริการ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            "เงื่อนไขในการให้บริการพาไปหาหมอ อัตราค่าบริการสำหรับแพ็กเกจครึ่งวัน 4 ชั่วโมง คิดราคา 800 บาท และแพ็กเกจเต็มวัน 8 ชั่วโมง คิดราคา 1,350 บาท กรณีการใช้บริการเกินเวลาที่กำหนดจะคิดเพิ่มชั่วโมงละ 200 บาท หากจุดรับส่งหรือพื้นที่ใช้บริการอยู่นอกเหนือเขตอำเภอที่ผู้ดูแลแต่ละท่านกำหนดว่าสะดวกให้บริการในระบบ จะมีการคิดค่าเดินทางเพิ่มเติมกิโลเมตรละ 10 บาท โดยคำนวณตามระยะทางจริงจากระบบแอปพลิเคชัน",
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 20),
        CheckboxListTile(
          title: const Text(
            'ข้าพเจ้าได้อ่านและยอมรับเงื่อนไขการให้บริการดังกล่าว',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          value: _isPolicyAccepted,
          activeColor: primaryColor,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (bool? value) {
            setState(() {
              _isPolicyAccepted = value ?? false;
            });
          },
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentStep > 1
              ? OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              : const SizedBox(width: 80),
          ElevatedButton(
            onPressed: _currentStep == _totalSteps
                ? _submitRegistration
                : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              _currentStep == _totalSteps ? 'ส่งข้อมูลสมัคร' : 'Next',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty))
            return 'กรุณากรอก $label';
          return null;
        },
      ),
    );
  }

  Widget _buildDocUploadRow(String title, String typeKey) {
    bool isUploaded = _docFiles[typeKey] != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUploaded ? primaryColor : Colors.grey.shade300,
          width: isUploaded ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.check_circle : Icons.upload_file,
            color: isUploaded ? primaryColor : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUploaded ? primaryColor : Colors.black87,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _pickImage(typeKey),
            style: ElevatedButton.styleFrom(
              backgroundColor: isUploaded
                  ? Colors.grey.shade200
                  : primaryColor.withOpacity(0.1),
              foregroundColor: isUploaded ? Colors.black87 : primaryColor,
              elevation: 0,
            ),
            child: Text(isUploaded ? 'เปลี่ยนรูป' : 'อัปโหลด'),
          ),
        ],
      ),
    );
  }
}
