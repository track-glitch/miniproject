import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
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

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color bgColor = const Color(0xFFFAFAFA);
  final Color greyBorder = const Color(0xFFE1BEE7);

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
    _patAddressController.text = widget.currentPatient.address ?? '';
    _patLineIdController.text = widget.currentRelative.lineId ?? '';

    if (widget.currentPatient.latitude != null &&
        widget.currentPatient.longitude != null &&
        widget.currentPatient.latitude != 0.0) {
      _selectedLocation = LatLng(
        widget.currentPatient.latitude!,
        widget.currentPatient.longitude!,
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
      Navigator.pop(context);
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
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'แก้ไขข้อมูลผู้ป่วย',
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
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
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'ยกเลิก',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
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
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.4)),
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
            CircleAvatar(
              radius: 43,
              backgroundColor: primaryColor,
              child: CircleAvatar(
                radius: 41,
                backgroundColor: Colors.white,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(Icons.person, size: 55, color: Colors.black)
                    : null,
              ),
            ),
            InkWell(
              onTap: _pickImage,
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
        const Text(
          'รูปโปรไฟล์ผู้ป่วย',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (v) => v!.isEmpty ? 'กรุณากรอกข้อมูล' : null,
        decoration: InputDecoration(
          labelText: hint,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF7D3C98)),
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
            borderSide: BorderSide(color: primaryColor),
          ),
          errorStyle: const TextStyle(fontSize: 11, color: Colors.red),
        ),
      ),
    );
  }
}
