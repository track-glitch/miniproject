import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'package:miniproject/views/relative/relative_home_page.dart';
import 'package:miniproject/widgets/location_picker_widget.dart';

// 🌟 Import LocationPickerWidget เข้ามาใช้งาน (ตรวจสอบ Path ให้ตรงกับโปรเจกต์ของคุณ)
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';

class EditRelativeInfoPage extends StatefulWidget {
  final PatientModel currentPatient;
  final RelativeModel currentRelative;
  final String loggedUid;

  const EditRelativeInfoPage({
    super.key,
    required this.currentPatient,
    required this.currentRelative,
    required this.loggedUid,
  });

  @override
  State<EditRelativeInfoPage> createState() => _EditRelativeInfoPageState();
}

class _EditRelativeInfoPageState extends State<EditRelativeInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // 🌟 บังคับให้หน้าจอโหลดจนกว่าจะดึงที่อยู่เดิมเสร็จ
  bool _isLoading = true;

  // 🎨 Theme ใหม่ - อ้างอิงจากตัวอย่างหน้า "ค้นหาบัญชี" (โทนม่วงสบายตา การ์ดสีขาว)
  final Color primaryColor = const Color(
    0xFF7C5CFC,
  ); // ม่วงหลัก ใช้กับปุ่ม/ไอคอนสำคัญ
  final Color darkPurple = const Color(
    0xFF6E5ABF,
  ); // ม่วงเข้ม ใช้กับหัวข้อ/ตัวหนา
  final Color lightPurple = const Color(
    0xFFF3E5F5,
  ); // คงไว้เผื่อมีการใช้งานที่อื่น
  final Color bgColor = const Color.fromARGB(
    255,
    225,
    202,
    255,
  ); // พื้นหลังม่วงอ่อนสบายตา
  final Color greyBorder = const Color(0xFFB9A4F2); // เส้นขอบม่วงอ่อน

  // สีเพิ่มเติมสำหรับ Gradient ของ AppBar และพื้นหลัง ให้ตรงกับภาพตัวอย่าง
  final Color headerGradientStart = const Color(0xFF8E6FF0);
  final Color headerGradientEnd = const Color(0xFF7C5CFC);
  final Color bgGradientTop = const Color.fromARGB(255, 225, 202, 255);
  final Color bgGradientBottom = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;

  LatLng _selectedLocation = const LatLng(13.7563, 100.5018);
  bool _hasPinned = false;

  File? _profileImageFile;
  String? _profilePhotoBase64;

  final TextEditingController _patFirstNameController = TextEditingController();
  final TextEditingController _patLastNameController = TextEditingController();
  final TextEditingController _patIdCardController = TextEditingController();
  final TextEditingController _patLineIdController = TextEditingController();
  final TextEditingController _patPhoneController = TextEditingController();
  final TextEditingController _patGenderController = TextEditingController();
  final TextEditingController _patBirthDateController = TextEditingController();
  final TextEditingController _patDiseaseController = TextEditingController();
  final TextEditingController _patMobilityController = TextEditingController();
  final TextEditingController _patAddressController = TextEditingController();

  final TextEditingController _relFirstNameController = TextEditingController();
  final TextEditingController _relLastNameController = TextEditingController();
  final TextEditingController _relEmailController = TextEditingController();
  final TextEditingController _relPhoneController = TextEditingController();
  final TextEditingController _relLineIdController = TextEditingController();
  final TextEditingController _relRelationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
    // 🌟 รอจนกว่า _fetchAndForceShowData จะทำงานเสร็จค่อยปิด Loading
    _fetchAndForceShowData().then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _initData() {
    _patFirstNameController.text = widget.currentPatient.firstname ?? '';
    _patLastNameController.text = widget.currentPatient.lastname ?? '';
    _patIdCardController.text = widget.currentPatient.patientId ?? '';
    _patPhoneController.text = widget.currentPatient.phonenumber ?? '';
    _patGenderController.text = widget.currentPatient.gender ?? '';
    _patDiseaseController.text = widget.currentPatient.disease ?? '';
    _patMobilityController.text = widget.currentPatient.mobility ?? '';
    _patAddressController.text = widget.currentPatient.location?.address ?? '';
    _patLineIdController.text = widget.currentRelative.lineId ?? '';

    if (widget.currentPatient.location?.latitude != null &&
        widget.currentPatient.location?.longitude != null &&
        widget.currentPatient.location?.latitude != 0.0) {
      _selectedLocation = LatLng(
        widget.currentPatient.location!.latitude!,
        widget.currentPatient.location!.longitude!,
      );
      _hasPinned = true;
    }

    if (widget.currentPatient.birthdate != null) {
      final date = widget.currentPatient.birthdate!;
      _patBirthDateController.text =
          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year + 543}";
    }

    _relFirstNameController.text = widget.currentRelative.firstname ?? '';
    _relLastNameController.text = widget.currentRelative.lastname ?? '';
    _relEmailController.text = widget.currentRelative.email ?? '';
    _relPhoneController.text = widget.currentRelative.phonenumber ?? '';
    _relLineIdController.text = widget.currentRelative.lineId ?? '';
    _relRelationController.text = widget.currentRelative.relationship ?? '';
    _profilePhotoBase64 = widget.currentPatient.patientphoto;
  }

  Future<void> _fetchAndForceShowData() async {
    String uid = widget.loggedUid;

    if (uid.isNotEmpty) {
      final relSnapshot = await FirebaseDatabase.instance
          .ref('Login/$uid/Relative')
          .get();

      // 🌟 เพิ่มบรรทัดนี้: ถ้าผู้ใช้กดปิดหน้าไปแล้ว ให้หยุดทำงานทันที
      if (!mounted) return;

      if (relSnapshot.exists && relSnapshot.value is Map) {
        final relData = Map<String, dynamic>.from(relSnapshot.value as Map);
        _patLineIdController.text =
            relData['lineId'] ?? _patLineIdController.text;
        _relLineIdController.text =
            relData['lineId'] ?? _relLineIdController.text;
        _relEmailController.text = relData['email'] ?? _relEmailController.text;
      }

      final patSnapshot = await FirebaseDatabase.instance
          .ref('Login/$uid/Relative/Patient')
          .get();

      // 🌟 เพิ่มบรรทัดนี้: เช็คอีกครั้งก่อนเอาข้อมูล Patient มาแสดง
      if (!mounted) return;

      if (patSnapshot.exists && patSnapshot.value is Map) {
        final data = Map<String, dynamic>.from(patSnapshot.value as Map);
        _patAddressController.text =
            data['address'] ?? _patAddressController.text;
        _patDiseaseController.text =
            data['disease'] ?? _patDiseaseController.text;
        _patMobilityController.text =
            data['mobility'] ?? _patMobilityController.text;

        if (data['birthdate'] != null) {
          setState(() {
            _patBirthDateController.text = data['birthdate'].toString();
          });
        }

        double lat = data['latitude']?.toDouble() ?? 0.0;
        double lng = data['longitude']?.toDouble() ?? 0.0;
        if (lat != 0.0 && lng != 0.0) {
          _selectedLocation = LatLng(lat, lng);
          _hasPinned = true;
        }
      }
    }
  }

  @override
  void dispose() {
    _patFirstNameController.dispose();
    _patLastNameController.dispose();
    _patIdCardController.dispose();
    _patLineIdController.dispose();
    _patPhoneController.dispose();
    _patGenderController.dispose();
    _patBirthDateController.dispose();
    _patDiseaseController.dispose();
    _patMobilityController.dispose();
    _patAddressController.dispose();

    _relFirstNameController.dispose();
    _relLastNameController.dispose();
    _relEmailController.dispose();
    _relPhoneController.dispose();
    _relLineIdController.dispose();
    _relRelationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      List<int> imageBytes = await file.readAsBytes();
      setState(() {
        _profileImageFile = file;
        _profilePhotoBase64 = base64Encode(imageBytes);
      });
    }
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String uid = widget.loggedUid;

      if (uid.isNotEmpty) {
        await FirebaseDatabase.instance.ref('Login/$uid/Relative').update({
          'firstname': _relFirstNameController.text.trim(),
          'lastname': _relLastNameController.text.trim(),
          'email': _relEmailController.text.trim(),
          'phonenumber': _relPhoneController.text.trim(),
          'lineId': _relLineIdController.text.trim(),
          'relationship': _relRelationController.text.trim(),
        });

        await FirebaseDatabase.instance
            .ref('Login/$uid/Relative/Patient')
            .update({
              'patientId': _patIdCardController.text.trim(),
              'firstname': _patFirstNameController.text.trim(),
              'lastname': _patLastNameController.text.trim(),
              'phonenumber': _patPhoneController.text.trim(),
              'gender': _patGenderController.text.trim(),
              'birthdate': _patBirthDateController.text.trim(),
              'disease': _patDiseaseController.text.trim(),
              'mobility': _patMobilityController.text.trim(),
              'patientphoto': _profilePhotoBase64 ?? '',
              'address': _patAddressController.text.trim(),
              'latitude': _hasPinned ? _selectedLocation.latitude : 0.0,
              'longitude': _hasPinned ? _selectedLocation.longitude : 0.0,
            });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('แก้ไขข้อมูลสำเร็จแล้ว')));

      // ปรับปรุงการย้อนกลับหลัง Save สำเร็จ
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RelativeHomePage(loggedUid: widget.loggedUid),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGradientBottom,
      appBar: AppBar(
        title: const Text(
          'แก้ไขข้อมูลผู้ป่วย',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [headerGradientStart, headerGradientEnd],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(0),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            // เช็คว่าย้อนกลับแบบปกติได้ไหม ถ้าได้ให้ย้อน ถ้าไม่ได้ค่อยสร้างหน้าใหม่พร้อมส่ง UID
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RelativeHomePage(
                    loggedUid: widget
                        .loggedUid, // ส่ง UID กลับไปเพื่อไม่ให้หลุดล็อกอิน
                  ),
                ),
              );
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgGradientTop, bgGradientBottom],
            stops: const [0.0, 0.35],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ) // 🌟 แสดงโหลดดิ้งรอให้ดึงที่อยู่ให้เสร็จ
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfileImageSection(),
                        const SizedBox(height: 20),

                        _buildSectionContainer(
                          title: 'ข้อมูลผู้ป่วย',
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'ชื่อจริง',
                                    controller: _patFirstNameController,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'นามสกุล',
                                    controller: _patLastNameController,
                                  ),
                                ),
                              ],
                            ),
                            _buildInputField(
                              hint: 'หมายเลขบัตรประชาชน',
                              controller: _patIdCardController,
                              keyboardType: TextInputType.number,
                            ),
                            _buildInputField(
                              hint: 'ไอดีไลน์ผู้ป่วย',
                              controller: _patLineIdController,
                            ),
                            _buildInputField(
                              hint: 'เบอร์โทรศัพท์ผู้ป่วย',
                              controller: _patPhoneController,
                              keyboardType: TextInputType.phone,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'เพศ',
                                    controller: _patGenderController,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'วันเกิด [DD/MM/YYYY]',
                                    controller: _patBirthDateController,
                                  ),
                                ),
                              ],
                            ),
                            _buildInputField(
                              hint: 'โรคประจำตัว',
                              controller: _patDiseaseController,
                            ),
                            _buildInputField(
                              hint: 'ความคล่องตัว (Mobility)',
                              controller: _patMobilityController,
                            ),
                          ],
                        ),

                        // 🌟 2. ใช้งาน LocationPickerWidget เหมือนหน้า Register ทุกประการ
                        _buildSectionContainer(
                          title: 'ข้อมูลที่อยู่ผู้ป่วย',
                          children: [
                            LocationPickerWidget(
                              initialLocation: _selectedLocation,
                              initialAddress: _patAddressController
                                  .text, // ส่งที่อยู่ที่ดึงมาให้ Widget
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
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'ชื่อจริงญาติ',
                                    controller: _relFirstNameController,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'นามสกุลญาติ',
                                    controller: _relLastNameController,
                                  ),
                                ),
                              ],
                            ),
                            _buildInputField(
                              hint: 'อีเมล (Email)',
                              controller: _relEmailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'เบอร์โทรศัพท์ญาติ',
                                    controller: _relPhoneController,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'ไอดีไลน์ญาติ',
                                    controller: _relLineIdController,
                                  ),
                                ),
                              ],
                            ),
                            _buildInputField(
                              hint: 'ความสัมพันธ์กับผู้ป่วย',
                              controller: _relRelationController,
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    elevation: 4,
                                    shadowColor: primaryColor.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _handleSave,
                                  child: const Text(
                                    'ตกลง',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: primaryColor.withOpacity(0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    // ใช้โค้ดชุดเดียวกันกับปุ่ม Back
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    } else {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RelativeHomePage(
                                                loggedUid: widget.loggedUid,
                                              ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    'ยกเลิก',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: darkPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 16,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: darkPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    ImageProvider? imageProvider;

    try {
      if (_profileImageFile != null) {
        imageProvider = FileImage(_profileImageFile!);
      } else if (_profilePhotoBase64 != null &&
          _profilePhotoBase64!.isNotEmpty) {
        String cleanBase64 = _profilePhotoBase64!.trim();
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        imageProvider = MemoryImage(base64Decode(cleanBase64));
      }
    } catch (e) {
      imageProvider = null;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 43,
                backgroundColor: primaryColor,
                child: CircleAvatar(
                  radius: 41,
                  backgroundColor: Colors.white,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Icon(
                          Icons.person,
                          size: 55,
                          color: primaryColor.withOpacity(0.6),
                        )
                      : null,
                ),
              ),
            ),
            InkWell(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
        const SizedBox(height: 10),
        Text(
          'รูปโปรไฟล์ผู้ป่วย',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, color: Colors.black),
        validator: (v) => v!.isEmpty ? 'กรุณากรอกข้อมูล' : null,
        decoration: InputDecoration(
          labelText: hint,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          labelStyle: TextStyle(fontSize: 13, color: Color(0xFF8D7AE6)),
          filled: true,
          fillColor: const Color(0xFFFAF8FF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: greyBorder, width: 2.3),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: greyBorder, width: 2.3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2.3),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2.3),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2.3),
          ),
          errorStyle: const TextStyle(fontSize: 11, color: Colors.redAccent),
        ),
      ),
    );
  }
}
