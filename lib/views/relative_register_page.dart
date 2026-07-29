import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:io';

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

final List<String> _relationOptions = [
  'บิดา/มารดา',
  'บุตร',
  'คู่สมรส',
  'พี่น้อง',
  'ญาติ',
  'ผู้ปกครอง',
  'เพื่อน',
];

class _RelativeRegisterPageState extends State<RelativeRegisterPage> {
  final AuthService _authService = AuthService();

  final _patientFormKey = GlobalKey<FormState>();
  final _relativeFormKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();

  bool _isObscure = true;
  bool _isLoading = false;
  String? _submitErrorMessage;

  int _currentStep = 1;
  bool _isPolicyAccepted = false;

  String _selectedPatGender = "";
  String _selectedPatMobility = "";
  DateTime? _patBirthDate;
  int? _patAge;

  LatLng _selectedLocation = const LatLng(18.2881, 99.4921);
  bool _hasPinned = false;

  File? _profileImageFile;
  String? _profilePhotoName;
  String? _profilePhotoBase64;

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color greyBorder = const Color(0xFFE1BEE7);

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

  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
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
        _patAge = _calculateAge(selectedDate);

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
      if (!_isPolicyAccepted) {
        _showErrorSnackBar('กรุณายอมรับเงื่อนไขการให้บริการก่อนดำเนินการต่อ');
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_patientFormKey.currentState!.validate()) {
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

  void _handleRegister() async {
    if (!_relativeFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    setState(() => _submitErrorMessage = null);

    try {
      PatientModel patientData = PatientModel(
        patientId: _patIdCardController.text.trim(),
        patientphoto: _profilePhotoBase64!,
        firstname: _patFirstNameController.text.trim(),
        lastname: _patLastNameController.text.trim(),
        phonenumber: _patPhoneController.text.trim(),
        gender: _selectedPatGender,
        birthdate: _patBirthDate,
        disease: _patDiseaseController.text.trim(),
        mobility: _selectedPatMobility,
        location: LocationModel(
          address: _patAddressController.text.trim(),
          latitude: _hasPinned ? _selectedLocation.latitude : 0.0,
          longitude: _hasPinned ? _selectedLocation.longitude : 0.0,
        ),
      );

      RelativeModel relativeData = RelativeModel(
        relativeId: _patIdCardController.text.trim(),
        password: _patPasswordController.text.trim(),
        usertype: 'relative',
        firstname: _relFirstNameController.text.trim(),
        lastname: _relLastNameController.text.trim(),
        email: _relEmailController.text.trim(),
        phonenumber: _relPhoneController.text.trim(),
        lineId: _relLineIdController.text.trim(),
        relationship: _relRelationController.text.trim(),
        patient: patientData,
      );

      UserCredential? userCredential = await _authService.registerRelative(
        password: _patPasswordController.text.trim(),
        relative: relativeData,
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

  // Step 1: ข้อตกลงและเงื่อนไข
  Widget _buildStep1() {
    final List<String> terms = [
      '1. ผู้ใช้บริการต้องลงทะเบียนและให้ข้อมูลส่วนบุคคลของตนเองและผู้สูงอายุที่ถูกต้อง ครบถ้วน และเป็นปัจจุบัน',
      '2. ผู้ใช้บริการต้องแจ้งข้อมูลสภาพร่างกาย โรคประจำตัว เพื่อความปลอดภัยในการให้บริการ',
      '3. ผู้ใช้บริการต้องตรวจสอบรายละเอียดการจอง เช่น วัน เวลา สถานที่รับ–ส่ง และข้อมูลผู้ดูแล ก่อนยืนยันการใช้บริการ',
      '4. ผู้ใช้บริการต้องชำระค่าบริการและค่าใช้จ่ายอื่น ๆ (ถ้ามี) ตามอัตราที่กำหนด',
      '5. หากต้องการยกเลิกหรือเปลี่ยนแปลงการจอง ควรดำเนินการผ่านระบบก่อนเวลานัดหมายตามเงื่อนไขที่กำหนด',
      '6. ผู้ใช้บริการต้องปฏิบัติต่อผู้ดูแลด้วยความสุภาพ และไม่กระทำการที่ก่อให้เกิดความเสียหายหรืออันตรายต่อผู้ดูแล',
      '7. ผู้ใช้บริการรับทราบว่าผู้ดูแลมีหน้าที่อำนวยความสะดวกในการเดินทางและดูแลผู้สูงอายุระหว่างการใช้บริการเท่านั้น ไม่สามารถวินิจฉัยโรคหรือให้การรักษาทางการแพทย์ได้',
      '8. ผู้ใช้บริการยินยอมให้ระบบจัดเก็บและใช้ข้อมูลที่จำเป็นสำหรับการจอง การให้บริการ และการติดต่อ ตามนโยบายคุ้มครองข้อมูลส่วนบุคคล',
      '9. ผู้ใช้บริการสามารถให้คะแนนและแสดงความคิดเห็นหลังเสร็จสิ้นการใช้บริการ โดยข้อมูลดังกล่าวต้องเป็นความจริงและไม่เป็นการหมิ่นประมาทผู้อื่น',
      '10. การกดยอมรับข้อตกลงและเงื่อนไขนี้ ถือว่าผู้ใช้บริการได้อ่าน ทำความเข้าใจ และยินยอมปฏิบัติตามเงื่อนไขทั้งหมด',
    ];

    return Column(
      children: [
        const SizedBox(height: 20),
        _buildSectionContainer(
          title: 'ข้อตกลงและเงื่อนไขการใช้บริการ',
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
      ],
    );
  }

  // Step 2: ข้อมูลผู้ป่วย
  Widget _buildStep2() {
    return Form(
      key: _patientFormKey,
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
                          padding: const EdgeInsets.only(bottom: 6),
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

                        if (_patAge != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Row(
                              children: [
                                Icon(Icons.cake, size: 16, color: primaryColor),
                                const SizedBox(width: 5),
                                Text(
                                  'อายุ $_patAge ปี',
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
                      _selectedPatGender.isEmpty ? 'กรุณาเลือกเพศ' : null,
                  builder: (FormFieldState<String> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Radio<String>(
                              value: 'ชาย',
                              groupValue: _selectedPatGender,
                              activeColor: primaryColor,
                              onChanged: (value) {
                                setState(() => _selectedPatGender = value!);
                                state.didChange(value);
                              },
                            ),
                            const Text('ชาย', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 20),
                            Radio<String>(
                              value: 'หญิง',
                              groupValue: _selectedPatGender,
                              activeColor: primaryColor,
                              onChanged: (value) {
                                setState(() => _selectedPatGender = value!);
                                state.didChange(value);
                              },
                            ),
                            const Text('หญิง', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
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

              _buildLabelField('โรคประจำตัว'),
              _buildInputField(
                hint: 'เช่น เบาหวาน, ความดัน (ถ้าไม่มีให้เว้นว่าง)',
                controller: _patDiseaseController,
              ),
              _buildLabelField('สภาพร่างกายในการเคลื่อนไหว', isRequired: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedPatMobility.isEmpty
                      ? null
                      : _selectedPatMobility,
                  decoration: InputDecoration(
                    hintText: 'เลือกระดับสภาพร่างกาย',
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
                      ? 'กรุณาระบุสภาพร่างกาย'
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
              _buildLabelField('ไอดีไลน์'),
              _buildInputField(
                hint: 'ไอดีไลน์ (ถ้ามี)',
                controller: _patLineIdController,
              ),
            ],
          ),

          _buildSectionContainer(
            title: 'บัญชีเข้าสู่ระบบของผู้ป่วย',
            children: [
              _buildLabelField('หมายเลขบัตรประชาชนผู้ป่วย', isRequired: true),
              _buildInputField(
                hint: 'ตัวเลข 13 หลัก',
                controller: _patIdCardController,
                keyboardType: TextInputType.number,
                maxLength: 13,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'กรุณากรอกเลขบัตรประชาชน';
                  }
                  if (val.length != 13 || !RegExp(r'^[0-9]+$').hasMatch(val)) {
                    return 'ต้องเป็นตัวเลข 13 หลัก';
                  }
                  return null;
                },
              ),
              _buildLabelField('รหัสผ่าน', isRequired: true),
              _buildInputField(
                hint: 'รหัสผ่าน',
                controller: _patPasswordController,
                isPassword: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'กรุณากรอกรหัสผ่าน';
                  }
                  if (val.contains(' ')) return 'ต้องไม่มีเว้นวรรคหรือช่องว่าง';
                  if (val.length < 8 || val.length > 16) {
                    return 'ความยาวต้องอยู่ระหว่าง 8-16 ตัวอักษร';
                  }
                  return null;
                },
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

  // Step 3: ข้อมูลญาติ
  Widget _buildStep3() {
    return Form(
      key: _relativeFormKey,
      child: Column(
        children: [
          _buildSectionContainer(
            title: 'ข้อมูลญาติผู้ดูแล',
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
                        _buildLabelField(
                          'เบอร์โทรศัพท์ติดต่อ',
                          isRequired: true,
                        ),
                        _buildInputField(
                          hint: 'เบอร์โทรศัพท์ 10 หลัก',
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

              // 🌟 ปรับปรุง: เอาบังคับกรอกออก (isRequired: false)
              _buildLabelField('อีเมล (ถ้ามี)', isRequired: false),
              _buildInputField(
                hint: 'เช่น example@gmail.com',
                controller: _relEmailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  // หากมีการกรอกข้อมูลเข้ามา ค่อยตรวจสอบความถูกต้องของรูปแบบอีเมล
                  if (val != null && val.trim().isNotEmpty) {
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(val.trim())) {
                      return 'รูปแบบอีเมลไม่ถูกต้อง';
                    }
                  }
                  return null; // ยินยอมให้เว้นว่างได้
                },
              ),

              _buildLabelField('ความสัมพันธ์กับผู้ป่วย', isRequired: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'กรุณาเลือกความสัมพันธ์',
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
                  value: _relRelationController.text.isNotEmpty
                      ? _relRelationController.text
                      : null,
                  items: _relationOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _relRelationController.text = newValue ?? '';
                    });
                  },
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'กรุณาระบุความสัมพันธ์'
                      : null,
                ),
              ),
            ],
          ),

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
        ],
      ),
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