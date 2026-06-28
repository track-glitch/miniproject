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
import 'caretaker_register_page.dart';
import '../models/location_model.dart';

class RelativeRegisterPage extends StatefulWidget {
  const RelativeRegisterPage({super.key});

  @override
  State<RelativeRegisterPage> createState() => _RelativeRegisterPageState();
}

class _RelativeRegisterPageState extends State<RelativeRegisterPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool _isObscure = true;
  bool _isLoading = false;
  // 🌟 เพิ่มตัวแปรเก็บข้อความ Error ใต้ปุ่ม (เหมือนหน้า Caretaker)
  String? _submitErrorMessage;

  final String _selectedTab = "ญาติ";
  String _selectedPatGender = "";
  DateTime? _patBirthDate;

  LatLng _selectedLocation = const LatLng(18.2881, 99.4921); // ค่าเริ่มต้น
  bool _hasPinned = false;

  File? _profileImageFile;
  String? _profilePhotoName;
  String? _profilePhotoBase64;

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color greyBorder = const Color(0xFFE1BEE7);

  final TextEditingController _patUsernameController = TextEditingController();
  final TextEditingController _patPasswordController = TextEditingController();
  final TextEditingController _patIdCardController = TextEditingController();
  final TextEditingController _patFirstNameController = TextEditingController();
  final TextEditingController _patLastNameController = TextEditingController();
  final TextEditingController _patBirthDateController = TextEditingController();
  final TextEditingController _patPhoneController = TextEditingController();
  final TextEditingController _patLineIdController = TextEditingController();
  final TextEditingController _patAddressController = TextEditingController();

  final TextEditingController _relFirstNameController = TextEditingController();
  final TextEditingController _relLastNameController = TextEditingController();
  final TextEditingController _relPhoneController = TextEditingController();
  final TextEditingController _relLineIdController = TextEditingController();
  final TextEditingController _relRelationController = TextEditingController();

  @override
  void dispose() {
    _patUsernameController.dispose();
    _patPasswordController.dispose();
    _patIdCardController.dispose();
    _patFirstNameController.dispose();
    _patLastNameController.dispose();
    _patBirthDateController.dispose();
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

  bool get _hasAnyData {
    return [
          _patUsernameController,
          _patPasswordController,
          _patIdCardController,
          _patFirstNameController,
          _patLastNameController,
          _patPhoneController,
          _patLineIdController,
          _patAddressController,
          _relFirstNameController,
          _relLastNameController,
          _relPhoneController,
          _relLineIdController,
          _relRelationController,
        ].any((c) => c.text.trim().isNotEmpty) ||
        _selectedPatGender.isNotEmpty ||
        _patBirthDate != null ||
        _profileImageFile != null ||
        _hasPinned;
  }

  void _handleToggleToCaretaker() {
    if (_hasAnyData) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการเปลี่ยนหน้า'),
          content: const Text(
            'คุณมีข้อมูลที่กรอกไว้บางส่วนในหน้าญาติ ต้องการสลับไปหน้าสมัครผู้ดูแลหรือไม่? ข้อมูลที่กรอกในหน้านี้จะไม่ถูกบันทึก',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CaretakerRegisterPage(),
                  ),
                );
              },
              child: const Text(
                'สลับหน้า',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CaretakerRegisterPage()),
      );
    }
  }

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
      String base64String = base64Encode(imageBytes);

      setState(() {
        _profileImageFile = file;
        _profilePhotoName = pickedFile.name;
        _profilePhotoBase64 = base64String;
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
                }, // สามารถเปลี่ยนไปเรียกกล้องได้ถ้าต้องการ
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

  // 🌟 ฟังก์ชันจัดการการสมัคร (รูปแบบเดียวกับ Caretaker)
  void _handleRegister() async {
    setState(() {
      _submitErrorMessage = null;
    });

    bool isFormValid = _formKey.currentState!.validate();

    if (!isFormValid ||
        _patAddressController.text.trim().isEmpty ||
        _selectedPatGender.isEmpty ||
        _profilePhotoBase64 == null) {
      setState(() {
        _submitErrorMessage = 'กรุณากรอกข้อมูลและอัปโหลดรูปภาพให้ครบถ้วน';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      RelativeModel relativeData = RelativeModel(
        relativeId: "",
        firstname: _relFirstNameController.text.trim(),
        lastname: _relLastNameController.text.trim(),
        email: "",
        phonenumber: _relPhoneController.text.trim(),
        lineId: _relLineIdController.text.trim(),
        relationship: _relRelationController.text.trim(),
      );

      PatientModel patientData = PatientModel(
        patientId: _patIdCardController.text.trim(),
        patientphoto: _profilePhotoBase64!,
        firstname: _patFirstNameController.text.trim(),
        lastname: _patLastNameController.text.trim(),
        phonenumber: _patPhoneController.text.trim(),
        gender: _selectedPatGender,
        birthdate: _patBirthDate,
        disease: "",
        mobility: "",
        location: LocationModel(
          address: _patAddressController.text.trim(),
          latitude: _hasPinned ? _selectedLocation.latitude : 0.0,
          longitude: _hasPinned ? _selectedLocation.longitude : 0.0,
        ),
      );

      UserCredential? userCredential = await _authService.registerRelative(
        username: _patUsernameController.text.trim(),
        password: _patPasswordController.text.trim(),
        usertype: 'relative',
        relative: relativeData,
        patient: patientData,
      );

      if (userCredential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สมัครสมาชิกสำเร็จและบันทึกข้อมูลเรียบร้อย!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          _submitErrorMessage =
              'การสมัครสมาชิกล้มเหลว หรือชื่อผู้ใช้นี้ถูกใช้งานแล้ว';
        });
      }
    } catch (e) {
      setState(() {
        _submitErrorMessage =
            'เกิดข้อผิดพลาดในการเชื่อมต่อ กรุณาลองใหม่อีกครั้ง';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'สมัครสมาชิก',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopToggleTab(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildProfileUploadWidget(),
                      const SizedBox(height: 20),

                      _buildSectionContainer(
                        title: 'ข้อมูลผู้ป่วย (บัญชีเข้าสู่ระบบ)',
                        children: [
                          _buildLabelField('ชื่อผู้ใช้', isRequired: true),
                          _buildInputField(
                            hint: 'ชื่อผู้ใช้ (Username)',
                            controller: _patUsernameController,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'กรุณากรอกชื่อผู้ใช้';
                              if (val.contains(' '))
                                return 'ต้องไม่มีเว้นวรรคหรือช่องว่าง';
                              if (val.length < 4 || val.length > 20)
                                return 'ความยาวต้องอยู่ระหว่าง 4-20 ตัวอักษร';
                              if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(val))
                                return 'ใช้อักษรภาษาอังกฤษ ตัวเลข และ (_, -, .) เท่านั้น';
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
                              if (val.contains(' '))
                                return 'ต้องไม่มีเว้นวรรคหรือช่องว่าง';
                              if (val.length < 8 || val.length > 16)
                                return 'ความยาวต้องอยู่ระหว่าง 8-16 ตัวอักษร';
                              return null;
                            },
                          ),
                        ],
                      ),

                      _buildSectionContainer(
                        title: 'ข้อมูลส่วนตัวผู้ป่วย',
                        children: [
                          _buildLabelField(
                            'หมายเลขบัตรประชาชน',
                            isRequired: true,
                          ),
                          _buildInputField(
                            hint: 'หมายเลขบัตรประชาชน',
                            controller: _patIdCardController,
                            keyboardType: TextInputType.number,
                            maxLength: 13,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'กรุณากรอกเลขบัตรประชาชน';
                              if (val.length != 13 ||
                                  !RegExp(r'^[0-9]+$').hasMatch(val))
                                return 'ต้องเป็นตัวเลข 13 หลัก';
                              return null;
                            },
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabelField(
                                      'ชื่อจริง',
                                      isRequired: true,
                                    ),
                                    _buildInputField(
                                      hint: 'ชื่อจริง',
                                      controller: _patFirstNameController,
                                      validator: (val) => val!.isEmpty
                                          ? 'กรุณากรอกชื่อจริง'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabelField(
                                      'นามสกุล',
                                      isRequired: true,
                                    ),
                                    _buildInputField(
                                      hint: 'นามสกุล',
                                      controller: _patLastNameController,
                                      validator: (val) => val!.isEmpty
                                          ? 'กรุณากรอกนามสกุล'
                                          : null,
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
                                    _buildLabelField(
                                      'วันเกิด',
                                      isRequired: true,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
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
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: greyBorder,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: greyBorder,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                        validator: (val) => val!.isEmpty
                                            ? 'กรุณาระบุวันเกิด'
                                            : null,
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
                              value: _selectedPatGender.isEmpty
                                  ? null
                                  : _selectedPatGender,
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
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 1.5,
                                  ),
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
                                  child: Text(
                                    'ชาย',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'หญิง',
                                  child: Text(
                                    'หญิง',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                              onChanged: (value) => setState(
                                () => _selectedPatGender = value ?? '',
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'กรุณาเลือกเพศ'
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
                          _buildLabelField('ไอดีไลน์', isRequired: true),
                          _buildInputField(
                            hint: 'ไอดีไลน์',
                            controller: _patLineIdController,
                          ),
                        ],
                      ),

                      // 🌟 ส่วนที่แก้ไข: นำ LocationPickerWidget มาใช้แทน
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
                                    _buildLabelField(
                                      'ชื่อจริง',
                                      isRequired: true,
                                    ),
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
                                    _buildLabelField(
                                      'นามสกุล',
                                      isRequired: true,
                                    ),
                                    _buildInputField(
                                      hint: 'นามสกุล',
                                      controller: _relLastNameController,
                                      validator: (val) => val!.isEmpty
                                          ? 'กรุณากรอกนามสกุล'
                                          : null,
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
                                    _buildLabelField(
                                      'เบอร์โทรศัพท์',
                                      isRequired: true,
                                    ),
                                    _buildInputField(
                                      hint: 'เบอร์โทรศัพท์',
                                      controller: _relPhoneController,
                                      keyboardType: TextInputType.phone,
                                      validator: (val) => val!.isEmpty
                                          ? 'กรุณากรอกเบอร์โทรศัพท์'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabelField(
                                      'ไอดีไลน์',
                                      isRequired: true,
                                    ),
                                    _buildInputField(
                                      hint: 'ไอดีไลน์',
                                      controller: _relLineIdController,
                                      validator: (val) => val!.isEmpty
                                          ? 'กรุณากรอกไอดีไลน์'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          _buildLabelField(
                            'ความสัมพันธ์กับผู้ป่วย',
                            isRequired: true,
                          ),
                          _buildInputField(
                            hint: 'เช่น บุตร, หลาน, พี่น้อง',
                            controller: _relRelationController,
                            validator: (val) =>
                                val!.isEmpty ? 'กรุณาระบุความสัมพันธ์' : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 🌟 แสดงข้อความแจ้งเตือนรวมใต้ฟอร์ม (ถ้ามี)
                      if (_submitErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
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

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleRegister,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets จัดให้ตรงกับหน้า Caretaker เป๊ะๆ ---

  Widget _buildTopToggleTab() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        width: 280,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: primaryColor, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedTab == "ญาติ"
                        ? primaryColor
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(21),
                      bottomLeft: Radius.circular(21),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'ญาติ',
                    style: TextStyle(
                      color: _selectedTab == "ญาติ"
                          ? Colors.white
                          : primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _handleToggleToCaretaker,
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedTab == "ผู้ดูแล"
                        ? primaryColor
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(21),
                      bottomRight: Radius.circular(21),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'ผู้ดูแล',
                    style: TextStyle(
                      color: _selectedTab == "ผู้ดูแล"
                          ? Colors.white
                          : primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
        if (_profilePhotoName != null)
          Text(
            _profilePhotoName!,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              overflow: TextOverflow.ellipsis,
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
