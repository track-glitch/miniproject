// ==========================================
// File: lib/views/caretaker/caretaker_edit_register_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:io';

import '../../services/auth_service.dart';
import '../../models/caretaker_model.dart';
import '../../models/document_model.dart';
import '../../models/location_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/vehicle_photo_model.dart';

class CaretakerEditRegisterPage extends StatefulWidget {
  final String uid; // 🌟 รับ UID เพื่อไปดึงข้อมูล

  const CaretakerEditRegisterPage({super.key, required this.uid});

  @override
  State<CaretakerEditRegisterPage> createState() =>
      _CaretakerEditRegisterPageState();
}

class _CaretakerEditRegisterPageState extends State<CaretakerEditRegisterPage> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoadingData = true; // 🌟 ใช้สำหรับโชว์ตัวโหลดตอนดึงข้อมูลแรกเริ่ม
  bool _isUpdating = false; // 🌟 ใช้สำหรับตอนกดปุ่ม "อัปเดตข้อมูล"
  bool _isUpdateSuccess = false;

  int _currentStep = 1;
  int? _age;

  // ตัวแปรเก็บข้อมูลเดิมจาก Firebase
  CaretakerModel? _oldCaretakerData;
  Map<String, String> _docStatuses =
      {}; // 🌟 เก็บสถานะเอกสารว่าอันไหนผ่าน/ไม่ผ่าน

  // --- Step 1 ---
  bool _isPolicyAccepted = true; // ให้ติ๊กถูกไว้เลยเพราะเคยสมัครแล้ว

  // --- Step 2 ---
  final _step2FormKey = GlobalKey<FormState>();
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

  File? _profileImageFile; // กรณีอัปรูปใหม่
  String? _profilePhotoBase64; // รูปเดิมที่ดึงมา

  double _currentLat = 0.0;
  double _currentLng = 0.0;

  // --- Step 3 ---
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

  // --- Step 4 ---
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
    "กาญจนบุรี", // ... (ใส่ List จังหวัดของคุณให้ครบ)
  ];

  @override
  void initState() {
    super.initState();
    _fetchCaretakerData(); // 🌟 สั่งให้ดึงข้อมูลทันทีที่เปิดหน้า
  }

  // ===============================================
  // 🌟 1. ฟังก์ชันดึงข้อมูลจาก Firebase
  // ===============================================
  Future<void> _fetchCaretakerData() async {
    try {
      // ⚠️ ตรงนี้คุณต้องไปสร้างฟังก์ชันใน AuthService หรือดึงจาก Firebase ตรงๆ
      // เช่น var data = await _authService.getCaretakerProfile(widget.uid);

      // ผมสมมติข้อมูลเพื่อทดสอบการทำงานของฟอร์ม
      await Future.delayed(const Duration(seconds: 2)); // จำลองการโหลด

      /* --- ลบส่วนนี้ออกแล้วใช้ข้อมูลจริงจาก Firebase แทน --- */
      _oldCaretakerData = CaretakerModel(
        caretakerId: '1234567890123',
        firstname: 'สมชาย',
        lastname: 'ใจดี',
        phonenumber: '0891234567',
        gender: 'ชาย',
        profilephoto: '', // ใส่ Base64 รูป
        vehicle: VehicleModel(
          vehicletype: 'รถเก๋ง',
          brand: 'Honda',
          model: 'City',
          color: 'ขาว',
          licenseplate: 'กข 1234',
          province: 'กรุงเทพมหานคร',
        ),
        documents: [
          DocumentModel(
            documentId: 'doc_idcard',
            documenttype: 'สำเนาบัตรประชาชน',
            filepath: '',
            status: 'REJECTED',
          ), // ตัวอย่างเอกสารไม่ผ่าน
        ],
      );
      /* ----------------------------------------------------- */

      if (_oldCaretakerData != null) {
        _populateDataToForm();
      }
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // ===============================================
  // 🌟 2. ฟังก์ชันถมข้อมูลเก่าลงใน Form (Populate)
  // ===============================================
  void _populateDataToForm() {
    final data = _oldCaretakerData!;

    // Step 2: ข้อมูลส่วนตัว
    _idCardController.text = data.caretakerId ?? '';
    _firstNameController.text = data.firstname ?? '';
    _lastNameController.text = data.lastname ?? '';
    _phoneController.text = data.phonenumber ?? '';
    _experienceController.text = data.experience ?? '';
    _selectedGender = data.gender ?? '';
    _profilePhotoBase64 = data.profilephoto;

    if (data.birthdate != null) {
      _birthDate = data.birthdate;
      _age = DateTime.now().year - data.birthdate!.year;
      _birthDateController.text =
          "${data.birthdate!.day.toString().padLeft(2, '0')}/${data.birthdate!.month.toString().padLeft(2, '0')}/${data.birthdate!.year + 543}";
    }

    // Step 3: ข้อมูลยานพาหนะ
    if (data.vehicle != null) {
      _selectedVehicleType = data.vehicle!.vehicletype ?? '';
      _brandController.text = data.vehicle!.brand ?? '';
      _modelController.text = data.vehicle!.model ?? '';
      _colorController.text = data.vehicle!.color ?? '';
      _licensePlateController.text = data.vehicle!.licenseplate ?? '';
      _selectedProvince = data.vehicle!.province ?? '';

      // ดึงรูปถ่ายรถ 3 มุม
      if (data.vehicle!.vehiclephotos != null) {
        for (var photo in data.vehicle!.vehiclephotos!) {
          if (photo.vehiclephotoid == 'exterior_photo')
            _exteriorPhotoBase64 = photo.photo;
          if (photo.vehiclephotoid == 'interior_photo')
            _interiorPhotoBase64 = photo.photo;
          if (photo.vehiclephotoid == 'storage_photo')
            _storagePhotoBase64 = photo.photo;
        }
      }
    }

    // Step 4: สถานะเอกสาร
    if (data.documents != null) {
      for (var doc in data.documents!) {
        // เช็กสถานะว่าผ่านหรือโดน Reject
        _docStatuses[doc.documentId!] = doc.status ?? 'PENDING';

        // ดึงรูปเก่าเก็บไว้โชว์
        if (doc.documentId == 'doc_idcard') _docIdCardBase64 = doc.filepath;
        if (doc.documentId == 'doc_driver_license')
          _docDriverLicenseBase64 = doc.filepath;
        // ... (ทำต่อให้ครบทุกเอกสาร)
      }
    }
  }

  // ===============================================
  // 🌟 3. ฟังก์ชันอัปเดตข้อมูล (ส่งกลับไป Firebase)
  // ===============================================
  void _submitUpdate() async {
    setState(() => _isUpdating = true);

    try {
      // ⚠️ สร้าง Object CaretakerModel เหมือนตอนสมัคร แต่ดึง Base64 ตัวปัจจุบันส่งไปแทน
      // (ถ้าเปลี่ยนรูป มันจะเป็นค่าใหม่ ถ้าไม่เปลี่ยนก็เป็นค่าเก่า)

      // เรียก AuthService.updateCaretaker(widget.uid, caretakerModel)
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

  // ... (ฟังก์ชันเกี่ยวกับ _nextStep, _previousStep, _pickImage เหมือนหน้า Register เดิมเลยครับ) ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'แก้ไขข้อมูล (ขั้นที่ $_currentStep/4)',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: primaryColor,
      ),
      body: SafeArea(
        child: _isLoadingData
            ? Center(
                child: CircularProgressIndicator(color: primaryColor),
              ) // 🌟 โชว์ Loading ตอนเริ่ม
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
                if (_currentStep == 1)
                  const Text(
                    'ข้อตกลงและเงื่อนไข (ดึงมาจากหน้าสมัคร)',
                  ), // _buildStep1()
                if (_currentStep == 2)
                  const Text(
                    'ฟอร์มข้อมูลส่วนตัว (ดึงมาจากหน้าสมัคร)',
                  ), // _buildStep2()
                if (_currentStep == 3)
                  const Text(
                    'ฟอร์มยานพาหนะ (ดึงมาจากหน้าสมัคร)',
                  ), // _buildStep3()
                if (_currentStep == 4)
                  _buildStep4(), // 🌟 ผมเขียนตัวอย่างหน้าเอกสารให้ดูด้านล่าง
              ],
            ),
          ),
        ),
        _buildBottomControls(),
      ],
    );
  }

  // ===============================================
  // 🌟 4. ตัวอย่างการปรับ Widget เอกสารให้โชว์สถานะ Rejected
  // ===============================================
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ตรวจสอบและอัปเดตเอกสารที่ไม่ผ่าน',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),

        _buildDocumentEditWidget(
          title: "1. สำเนาบัตรประชาชน",
          docId: "doc_idcard",
          newFile: _docIdCardFile,
          oldBase64: _docIdCardBase64,
          onUpload: () {
            /* เรียก _pickImage */
          },
          onRemove: () {
            /* เคลียร์ไฟล์ */
          },
        ),

        // ... เพิ่มเอกสารอื่นๆ ...
      ],
    );
  }

  Widget _buildDocumentEditWidget({
    required String title,
    required String docId,
    required File? newFile,
    required String? oldBase64,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    // เช็กว่าเอกสารนี้ถูก Reject หรือไม่
    bool isRejected = _docStatuses[docId] == 'REJECTED';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRejected ? Colors.red.shade50 : Colors.white,
        border: Border.all(
          color: isRejected ? Colors.red : greyBorder,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (isRejected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    '(ไม่ผ่านการตรวจสอบ)',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (newFile == null && oldBase64 == null)
            ElevatedButton(onPressed: onUpload, child: const Text('เลือกไฟล์'))
          else
            Row(
              children: [
                // 🌟 เลือกว่าจะโชว์รูปใหม่จาก File หรือรูปเก่าจาก Base64
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: newFile != null
                      ? Image.file(
                          newFile,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : Image.memory(
                          base64Decode(oldBase64!),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    newFile != null ? 'อัปโหลดรูปใหม่แล้ว' : 'รูปเดิมจากระบบ',
                    style: TextStyle(
                      color: newFile != null ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onUpload,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          if (_currentStep > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: _isUpdating
                    ? null
                    : () => setState(() => _currentStep--),
                child: const Text('ย้อนกลับ'),
              ),
            ),
          if (_currentStep > 1) const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isUpdating
                  ? null
                  : (_currentStep < 4
                        ? () => setState(() => _currentStep++)
                        : _submitUpdate),
              child: _isUpdating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_currentStep < 4 ? 'ถัดไป' : 'อัปเดตข้อมูล'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return const Center(
      child: Text(
        'อัปเดตข้อมูลสำเร็จ! รอแอดมินตรวจสอบอีกครั้ง',
        style: TextStyle(color: Colors.green, fontSize: 18),
      ),
    );
  }
}
