import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';

// --- เปลี่ยน Path ให้ตรงกับโฟลเดอร์ในโปรเจกต์ของคุณ ---
import '../services/auth_service.dart';
import '../models/relative_model.dart';
import '../models/patient_model.dart';
import 'caretaker_register_page.dart';

class RelativeRegisterPage extends StatefulWidget {
  const RelativeRegisterPage({super.key});

  @override
  State<RelativeRegisterPage> createState() => _RelativeRegisterPageState();
}

class _RelativeRegisterPageState extends State<RelativeRegisterPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // สถานะของหน้าจอ
  bool _isObscure = true;
  bool _isLoading = false;
  final String _selectedTab = "ญาติ"; 
  
  String _selectedPatGender = ""; 
  DateTime? _patBirthDate;

  // เก็บข้อมูลพิกัดละติจูด/ลองจิจูด จริงของผู้ป่วย
  LatLng _selectedLocation = const LatLng(13.7563, 100.5018); // ค่าเริ่มต้น: กรุงเทพฯ
  bool _hasPinned = false;
  bool _isLoadingLocation = false;

  // ไฟล์รูปภาพและชื่อไฟล์จริงสำหรับโปรไฟล์ผู้ป่วย
  File? _profileImageFile;
  String? _profilePhotoName;
  String? _profilePhotoBase64; // เพิ่มตัวแปรสำหรับเก็บ Base64

  // ==========================================
  // ส่วนแก้ไข: ปรับเฉดสีให้เหมือนตามรูปภาพตัวอย่างเป๊ะๆ
  // ==========================================
  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF3E5F5); // สีม่วงพาสเทลของกล่อง Section หลังข้อความ
  final Color bgColor = const Color(0xFFFAFAFA);
  final Color greyBorder = const Color(0xFFE1BEE7); // สีกรอบของช่องกรอกข้อมูล (TextField) ด้านใน

  // Controllers ข้อมูลผู้ป่วย (ฝั่งบัญชีและการรักษา)
  final TextEditingController _patUsernameController = TextEditingController();
  final TextEditingController _patPasswordController = TextEditingController();
  final TextEditingController _patIdCardController = TextEditingController();
  final TextEditingController _patFirstNameController = TextEditingController();
  final TextEditingController _patLastNameController = TextEditingController();
  final TextEditingController _patBirthDateController = TextEditingController();
  final TextEditingController _patPhoneController = TextEditingController();
  final TextEditingController _patLineIdController = TextEditingController();
  final TextEditingController _patAddressController = TextEditingController();

  // Controllers ข้อมูลติดต่อญาติ
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

  // ฟังก์ชันเช็คการกรอกข้อมูลค้างไว้บนฟอร์ม
  bool get _hasAnyData {
    return [
      _patUsernameController, _patPasswordController, _patIdCardController,
      _patFirstNameController, _patLastNameController, _patPhoneController,
      _patLineIdController, _patAddressController, _relFirstNameController,
      _relLastNameController, _relPhoneController, _relLineIdController,
      _relRelationController
    ].any((c) => c.text.trim().isNotEmpty) || 
    _selectedPatGender.isNotEmpty || 
    _patBirthDate != null ||
    _profileImageFile != null ||
    _hasPinned;
  }

  // ==========================================
  // ฟังก์ชันสลับตำแหน่งหน้าจอและตรวจสอบความปลอดภัย
  // ==========================================
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CaretakerRegisterPage()),
                );
              },
              child: const Text('สลับหน้า', style: TextStyle(color: Colors.red)),
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

  // ==========================================
  // ฟังก์ชันและระบบจัดการสิทธิ์แผนที่ / พิกัดที่อยู่
  // ==========================================
  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('กรุณาอนุญาติการเข้าถึงตำแหน่งจากการตั้งค่า');
        await Geolocator.openLocationSettings();
        return false;
      }
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
      bool hasPermission = await _requestLocationPermission();
      if (!hasPermission) return null;
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      _showErrorSnackBar('ไม่สามารถดึงตำแหน่งปัจจุบันได้');
      return null;
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&accept-language=th',
    );
    try {
      final response = await http.get(url, headers: {'User-Agent': 'CaretakerAppFlutter'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          String subdistrict = address['subdistrict'] ?? address['village'] ?? address['suburb'] ?? '';
          String district = address['district'] ?? address['city_district'] ?? '';
          String province = address['state'] ?? address['province'] ?? '';
          String postcode = address['postcode'] ?? '';
          setState(() {
            _selectedLocation = location;
            _hasPinned = true;
            _patAddressController.text = "$subdistrict $district $province รหัสไปรษณีย์ $postcode";
          });
        }
      }
    } catch (e) {
      print("Error Reverse Geocoding: $e");
    }
  }

  void _showMapModal() async {
    setState(() => _isLoadingLocation = true);
    LatLng? currentLocation = await _getCurrentLocation();
    setState(() => _isLoadingLocation = false);

    LatLng initialLocation = currentLocation ?? _selectedLocation;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        LatLng tempLocation = initialLocation;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('คลิกบนแผนที่เพื่อย้ายตำแหน่งหมุด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: tempLocation,
                          initialZoom: 16.5,
                          onTap: (tapPosition, point) => setModalState(() => tempLocation = point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.miniproject',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: tempLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      onPressed: () {
                        Navigator.pop(context);
                        _getAddressFromLatLng(tempLocation);
                      },
                      child: const Text('ยืนยันตำแหน่งนี้', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // ระบบเลือกรูปภาพและแปลง Base64
  // ==========================================
  Future<void> _pickImageReal() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      int fileSizeInBytes = await file.length();
      if ((fileSizeInBytes / (1024 * 1024)) > 20) {
        _showErrorSnackBar('ขนาดไฟล์รูปภาพโปรไฟล์ต้องไม่เกิน 20MB');
        return;
      }

      // ดึง Base64 
      List<int> imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);

      setState(() {
        _profileImageFile = file;
        _profilePhotoName = pickedFile.name;
        _profilePhotoBase64 = base64String; // เก็บ Base64 ไว้ใช้ตอนกดสมัคร
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatGender.isEmpty) {
      _showErrorSnackBar('กรุณาเลือกเพศผู้ป่วย');
      return;
    }
    if (_profilePhotoBase64 == null) {
      _showErrorSnackBar('กรุณาอัปโหลดรูปภาพโปรไฟล์ของผู้ป่วย');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String username = _patUsernameController.text.trim();
      String password = _patPasswordController.text.trim();

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
        patientphoto: _profilePhotoBase64!, // เปลี่ยนไปส่งเป็น Base64
        firstname: _patFirstNameController.text.trim(),
        lastname: _patLastNameController.text.trim(),
        phonenumber: _patPhoneController.text.trim(),
        gender: _selectedPatGender,
        birthdate: _patBirthDate,
        disease: "", 
        mobility: "", 
        latitude: _hasPinned ? _selectedLocation.latitude : 0.0, 
        longitude: _hasPinned ? _selectedLocation.longitude : 0.0,
      );

      UserCredential? userCredential = await _authService.registerRelative(
        username: username,
        password: password,
        usertype: 'relative',
        relative: relativeData,
        patient: patientData,
      );

      if (userCredential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิกสำเร็จและบันทึกข้อมูลเรียบร้อย!')),
        );
        Navigator.pop(context);
      } else {
        _showErrorSnackBar('เกิดข้อผิดพลาดในการสมัครสมาชิก หรือชื่อผู้ใช้นี้อาจถูกใช้ไปแล้ว');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('สมัครสมาชิก', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTopToggleTab(),
                const SizedBox(height: 10),
                _buildProfileUpload(),
                const SizedBox(height: 20),

                // 1. ข้อมูลผู้ป่วย (บัญชีเข้าสู่ระบบ)
                _buildSection(
                  title: 'ข้อมูลผู้ป่วย',
                  children: [
                    _buildInputField(hint: 'ชื่อผู้ใช้', controller: _patUsernameController, validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อผู้ใช้' : null),
                    _buildInputField(hint: 'รหัสผ่าน', controller: _patPasswordController, isPassword: true, validator: (v) => v!.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null),
                  ],
                ),

                // 2. ข้อมูลส่วนตัวผู้ป่วย
                _buildSection(
                  title: 'ข้อมูลส่วนตัว',
                  children: [
                    _buildInputField(hint: 'หมายเลขบัตรประชาชน', controller: _patIdCardController, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'กรุณากรอกหมายเลขบัตรประชาชน' : null),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(hint: 'ชื่อจริง', controller: _patFirstNameController, validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อจริง' : null)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInputField(hint: 'นามสกุล', controller: _patLastNameController, validator: (v) => v!.isEmpty ? 'กรุณากรอกนามสกุล' : null)),
                      ],
                    ),
                    _buildDatePickerField(),
                    const SizedBox(height: 10),
                    _buildGenderDropdown(),
                    const SizedBox(height: 10),
                    _buildInputField(hint: 'เบอร์โทรศัพท์', controller: _patPhoneController, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'กรุณากรอกเบอร์โทรศัพท์' : null),
                    _buildInputField(hint: 'ไอดีไลน์', controller: _patLineIdController),
                  ],
                ),

                // 3. ข้อมูลที่อยู่ผู้ป่วยพร้อมปุ่มปักหมุดแผนที่ใช้งานจริง
                _buildSection(
                  title: 'ข้อมูลที่อยู่',
                  children: [
                    _buildInputField(hint: 'รายละเอียดที่อยู่...', controller: _patAddressController, maxLines: 3, validator: (v) => v!.isEmpty ? 'กรุณากรอกที่อยู่ หรือกดเลือกจากแผนที่ด้านล่าง' : null),
                    _buildMapButton(),
                  ],
                ),

                // 4. ข้อมูลติดต่อญาติ
                _buildSection(
                  title: 'ข้อมูลติดต่อญาติ',
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInputField(hint: 'ชื่อจริง', controller: _relFirstNameController, validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อญาติ' : null)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInputField(hint: 'นามสกุล', controller: _relLastNameController, validator: (v) => v!.isEmpty ? 'กรุณากรอกนามสกุลญาติ' : null)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildInputField(hint: 'เบอร์โทรติดต่อ', controller: _relPhoneController, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'กรุณากรอกเบอร์โทรติดต่อ' : null)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInputField(hint: 'ไอดีไลน์', controller: _relLineIdController)),
                      ],
                    ),
                    _buildInputField(hint: 'สถานะความสัมพันธ์', controller: _relRelationController, validator: (v) => v!.isEmpty ? 'กรุณากรอกความสัมพันธ์' : null),
                  ],
                ),

                const SizedBox(height: 15),

                // ปุ่มสมัครสมาชิกตามสไตล์รูปภาพ
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('สมัครสมาชิก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('มีบัญชีอยู่แล้ว? ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('เข้าสู่ระบบ', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  
  Widget _buildTopToggleTab() {
    return Center(
      child: Container(
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
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(21), bottomLeft: Radius.circular(21)),
                ),
                alignment: Alignment.center,
                child: const Text('ญาติ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _handleToggleToCaretaker,
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Text('ผู้ดูแล', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileUpload() {
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
                backgroundImage: _profileImageFile != null ? FileImage(_profileImageFile!) : null,
                child: _profileImageFile == null
                    ? const Icon(Icons.person, size: 55, color: Colors.black)
                    : null,
              ),
            ),
            InkWell(
              onTap: _pickImageReal,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('อัปโหลดรูปโปรไฟล์*', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        if (_profilePhotoName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _profilePhotoName!,
              style: const TextStyle(fontSize: 11, color: Colors.grey, overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
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
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkPurple)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDatePickerField() {
    return TextFormField(
      controller: _patBirthDateController,
      readOnly: true,
      onTap: _selectPatBirthDate,
      decoration: InputDecoration(
        hintText: 'วันเกิด [DD/MM/YYYY]',
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: greyBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: greyBorder)),
        suffixIcon: Icon(Icons.calendar_today, size: 18, color: primaryColor),
      ),
      validator: (v) => v!.isEmpty ? 'กรุณาระบุวันเกิดผู้ป่วย' : null,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPatGender.isEmpty ? null : _selectedPatGender,
      decoration: InputDecoration(
        hintText: 'เพศ',
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: greyBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: greyBorder)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: const [
        DropdownMenuItem(value: 'ชาย', child: Text('ชาย')),
        DropdownMenuItem(value: 'หญิง', child: Text('หญิง')),
      ],
      onChanged: (val) => setState(() => _selectedPatGender = val ?? ''),
    );
  }

  Widget _buildMapButton() {
    return InkWell(
      onTap: _showMapModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: greyBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _hasPinned ? 'แก้ไขพิกัดที่ตั้งบนแผนที่' : 'เลือกปักหมุดที่อยู่บนแผนที่',
              style: TextStyle(color: _hasPinned ? primaryColor : Colors.grey, fontSize: 13, fontWeight: _hasPinned ? FontWeight.bold : FontWeight.normal),
            ),
            Icon(Icons.map_outlined, color: Colors.green.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    TextEditingController? controller,
    bool isPassword = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: greyBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: greyBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor)),
          errorStyle: const TextStyle(fontSize: 11, color: Colors.red),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 18),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                )
              : null,
        ),
      ),
    );
  }
}