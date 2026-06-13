import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../models/caretaker_model.dart';
import '../models/vehicle_model.dart';
import '../models/document_model.dart';
import 'waiting_approval_page.dart';
import 'relative_register_page.dart';

class CaretakerRegisterPage extends StatefulWidget {
  const CaretakerRegisterPage({super.key});

  @override
  State<CaretakerRegisterPage> createState() => _CaretakerRegisterPageState();
}

class _CaretakerRegisterPageState extends State<CaretakerRegisterPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool _isObscure = true;
  bool _isLoading = false;
  String _selectedTab = "ผู้ดูแล";
  String _selectedGender = ""; // For gender dropdown

  // เก็บข้อมูลพิกัดละติจูด/ลองจิจูด จริง
  LatLng _selectedLocation = const LatLng(
    13.7563,
    100.5018,
  ); // ค่าเริ่มต้น: กรุงเทพฯ
  bool _hasPinned = false;
  bool _isLoadingLocation = false; // Loading status for location

  // ไฟล์รูปภาพจริงสำหรับแสดงผล Preview บนหน้าจอ
  File? _profileImageFile;
  File? _licenseImageFile;
  File? _insuranceImageFile;
  File? _firstAidImageFile;
  List<File> _vehicleImageFiles = [];

  // ชื่อไฟล์รูปภาพที่จะใช้นำไป insert ลงฐานข้อมูล
  String? _profilePhotoName;
  String? _licenseCardPhotoName;
  String? _insurancePhotoName;
  String? _firstAidPhotoName;
  List<String> _vehiclePhotoNames = [];

  // Controllers สำหรับ Form
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _citizenIdCtrl = TextEditingController();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _birthDateCtrl = TextEditingController();
  final TextEditingController _genderCtrl = TextEditingController();
  final TextEditingController _aboutMeCtrl = TextEditingController();
  final TextEditingController _equipmentCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  final TextEditingController _vehicleTypeCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _colorCtrl = TextEditingController();
  final TextEditingController _licensePlateCtrl = TextEditingController();

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF4E8FA);
  final Color greyBorder = const Color(0xFFD5D8DC);

  // ==========================================
  // ฟังก์ชันขออนุญาติการเข้าถึงตำแหน่ง
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
    } else if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar('กรุณาอนุญาติการเข้าถึงตำแหน่งจากการตั้งค่า');
      await Geolocator.openLocationSettings();
      return false;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ==========================================
  // ฟังก์ชันดึงตำแหน่งปัจจุบัน
  // ==========================================
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
      print("Error getting current location: $e");
      _showErrorSnackBar('ไม่สามารถดึงตำแหน่งปัจจุบันได้');
      return null;
    }
  }

  // ==========================================
  // ฟังก์ชันเลือกวันที่เกิด
  // ==========================================
  Future<void> _selectBirthDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) {
      setState(() {
        _birthDateCtrl.text =
            "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year + 543}"; // แสดงปีพุทธศักราช
      });
    }
  }

  // ==========================================
  // ฟังก์ชันเลือกรูปภาพจากมือถือจริง (ดึงทั้ง File และชื่อไฟล์)
  // ==========================================
  Future<void> _pickImageReal(String type) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // บีบอัดความละเอียดภาพเล็กน้อยเพื่อประหยัดพื้นที่
    );

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      // ตรวจสอบขนาดไฟล์ไม่ให้เกิน 20MB
      int fileSizeInBytes = await file.length();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 20) {
        _showErrorSnackBar(
          'ขนาดไฟล์ต้องไม่เกิน 20MB (ไฟล์ของคุณขนาด: ${fileSizeInMB.toStringAsFixed(2)} MB)',
        );
        return;
      }

      setState(() {
        String fileName =
            pickedFile.name; // ดึงชื่อไฟล์พร้อมนามสกุล เช่น image.jpg

        if (type == 'profile') {
          _profileImageFile = file;
          _profilePhotoName = fileName;
        } else if (type == 'license') {
          _licenseImageFile = file;
          _licenseCardPhotoName = fileName;
        } else if (type == 'insurance') {
          _insuranceImageFile = file;
          _insurancePhotoName = fileName;
        } else if (type == 'firstaid') {
          _firstAidImageFile = file;
          _firstAidPhotoName = fileName;
        } else if (type == 'vehicle') {
          if (_vehicleImageFiles.length < 4) {
            _vehicleImageFiles.add(file);
            _vehiclePhotoNames.add(fileName);
          } else {
            _showErrorSnackBar('อัปโหลดรูปยานพาหนะได้สูงสุด 4 รูป');
          }
        }
      });
    }
  }

  // ==========================================
  // ฟังก์ชันแปลงพิกัดละติจูด/ลองจิจูด เป็นที่อยู่ภาษาไทยผ่าน OpenStreetMap API
  // ==========================================
  Future<void> _getAddressFromLatLng(LatLng location) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&accept-language=th',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'CaretakerAppFlutter'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        if (address != null) {
          // ดึงรายละเอียดสถานที่ตามที่ OpenStreetMap ส่งกลับมา
          String subdistrict =
              address['subdistrict'] ??
              address['village'] ??
              address['suburb'] ??
              '';
          String district =
              address['district'] ?? address['city_district'] ?? '';
          String province = address['state'] ?? address['province'] ?? '';
          String postcode = address['postcode'] ?? '';

          setState(() {
            _selectedLocation = location;
            _hasPinned = true;
            // ประกอบข้อความแสดงใน Textbox ให้ผู้ใช้แก้ไขเพิ่มเติมได้
            _addressCtrl.text =
                "$subdistrict $district $province รหัสไปรษณีย์ $postcode";
          });
        }
      }
    } catch (e) {
      print("Error Reverse Geocoding: $e");
    }
  }

  // ==========================================
  // ส่วนแสดงหน้าต่างแผนที่ให้เลือกปักหมุด
  // ==========================================
  void _showMapModal() async {
    // ขออนุญาติและดึงตำแหน่งปัจจุบัน
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
                  const Text(
                    'คลิกบนแผนที่เพื่อย้ายตำแหน่งหมุด',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: tempLocation,
                          initialZoom: 16.5,
                          onTap: (tapPosition, point) {
                            setModalState(() => tempLocation = point);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.miniproject',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: tempLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _getAddressFromLatLng(tempLocation);
                      },
                      child: const Text(
                        'ยืนยันตำแหน่งนี้',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  bool get _hasAnyData {
    return [
          _usernameCtrl,
          _emailCtrl,
          _passwordCtrl,
          _citizenIdCtrl,
          _firstNameCtrl,
          _lastNameCtrl,
          _birthDateCtrl,
          _phoneCtrl,
          _addressCtrl,
          _vehicleTypeCtrl,
          _brandCtrl,
          _modelCtrl,
          _colorCtrl,
          _licensePlateCtrl,
        ].any((c) => c.text.trim().isNotEmpty) ||
        _profileImageFile != null ||
        _licenseImageFile != null ||
        _insuranceImageFile != null ||
        _firstAidImageFile != null ||
        _vehicleImageFiles.isNotEmpty ||
        _selectedGender.isNotEmpty ||
        _hasPinned;
  }

  void _handleBackNavigation() {
    if (_hasAnyData) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการออก'),
          content: const Text(
            'คุณมีข้อมูลที่กรอกไว้บางส่วน ต้องการออกจากหน้านี้หรือไม่? ข้อมูลที่กรอกจะไม่ถูกบันทึก',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'ออกจากหน้านี้',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ).then((exit) {
        if (exit == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RelativeRegisterPage(),
            ),
          );
        }
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _handleRegisterSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender.isEmpty) {
      _showErrorSnackBar('กรุณาเลือกเพศ');
      return;
    }

    if (_profilePhotoName == null) {
      _showErrorSnackBar('กรุณาอัปโหลดรูปโปรไฟล์ของคุณ');
      return;
    }
    if (_licenseCardPhotoName == null) {
      _showErrorSnackBar('กรุณาอัปโหลดรูปถ่ายใบอนุญาตขับขี่');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<DocumentModel> documentList = [];

      documentList.add(
        DocumentModel(
          documentId: "DOC-LICENSE-${DateTime.now().millisecondsSinceEpoch}",
          documenttype: "driver_license",
          filepath: _licenseCardPhotoName!, // ส่งชื่อไฟล์ที่เลือกไป insert
          uploaddate: DateTime.now(),
        ),
      );

      if (_insurancePhotoName != null) {
        documentList.add(
          DocumentModel(
            documentId:
                "DOC-INSURANCE-${DateTime.now().millisecondsSinceEpoch}",
            documenttype: "car_insurance",
            filepath: _insurancePhotoName!,
            uploaddate: DateTime.now(),
          ),
        );
      }

      if (_firstAidPhotoName != null) {
        documentList.add(
          DocumentModel(
            documentId: "DOC-FIRSTAID-${DateTime.now().millisecondsSinceEpoch}",
            documenttype: "first_aid_certificate",
            filepath: _firstAidPhotoName!,
            uploaddate: DateTime.now(),
          ),
        );
      }

      // Parse the birthdate from DD/MM/YYYY format (Buddhist calendar)
      DateTime parsedDate = DateTime.now();
      try {
        List<String> dateParts = _birthDateCtrl.text.split('/');
        if (dateParts.length == 3) {
          int day = int.parse(dateParts[0]);
          int month = int.parse(dateParts[1]);
          int year =
              int.parse(dateParts[2]) -
              543; // Convert from Buddhist to Gregorian
          parsedDate = DateTime(year, month, day);
        }
      } catch (e) {
        print("Error parsing date: $e");
      }

      CaretakerModel caretakerData = CaretakerModel(
        caretakerId: "",
        profilephoto: _profilePhotoName!, // ส่งชื่อไฟล์รูปโปรไฟล์ไป insert
        firstname: _firstNameCtrl.text.trim(),
        lastname: _lastNameCtrl.text.trim(),
        gender: _selectedGender,
        birthdate: parsedDate,
        phonenumber: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        aboutme: "",
        equipmentdetails: "",
        address: _addressCtrl.text.trim(),
        admincomment: "",
        servicestatus: "closed",
        accountstatus: "pending",
        latitude: _hasPinned ? _selectedLocation.latitude : 0.0,
        longitude: _hasPinned ? _selectedLocation.longitude : 0.0,
      );

      VehicleModel vehicleData = VehicleModel(
        vehicleId: "V-${DateTime.now().millisecondsSinceEpoch}",
        vehicletype: _vehicleTypeCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        licenseplate: _licensePlateCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
        vehiclePhotos: _vehiclePhotoNames, // ส่งอาเรย์ของชื่อไฟล์รูปภาพรถ
      );

      UserCredential? result = await _authService.registerCaretaker(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        usertype: 'caretaker',
        caretaker: caretakerData,
        vehicle: vehicleData,
        documents: documentList,
      );

      if (result != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WaitingApprovalPage()),
          (route) => false,
        );
      } else {
        _showErrorSnackBar(
          'การสมัครสมาชิกล้มเหลว หรือชื่อผู้ใช้นี้ถูกใช้งานแล้ว',
        );
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
                        title: 'ข้อมูลผู้ดูแล',
                        children: [
                          _buildLabelField('ชื่อผู้ใช้', isRequired: true),
                          _buildInputField(
                            hint: 'ชื่อผู้ใช้ (Username)',
                            controller: _usernameCtrl,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'กรุณากรอกชื่อผู้ใช้';
                              if (val.contains(' '))
                                return 'ต้องไม่มีเว้นวรรคหรือช่องว่าง';
                              if (val.length < 4 || val.length > 20)
                                return 'ความยาวต้องอยู่ระหว่าง 4-20 ตัวอักษร';
                              if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(val))
                                return 'ใช้อักษรภาษาอังกฤษ ตัวเลข และ (_, -, .) เท่านั้น';
                              if (RegExp(r'^[_.-]').hasMatch(val) ||
                                  RegExp(r'[_.-]$').hasMatch(val))
                                return 'ห้ามขึ้นต้นหรือลงท้ายด้วยอักขระพิเศษ';
                              return null;
                            },
                          ),
                          _buildLabelField('รหัสผ่าน', isRequired: true),
                          _buildInputField(
                            hint: 'รหัสผ่าน',
                            controller: _passwordCtrl,
                            isPassword: true,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'กรุณากรอกรหัสผ่าน';
                              if (val.contains(' '))
                                return 'ต้องไม่มีเว้นวรรคหรือช่องว่าง';
                              if (val.length < 8 || val.length > 16)
                                return 'ความยาวต้องอยู่ระหว่าง 8-16 ตัวอักษร';
                              if (!RegExp(
                                r'^[a-zA-Z0-9!#_.\s@]+$',
                              ).hasMatch(val))
                                return 'อนุญาตเฉพาะอักษร อังกฤษ เลข และ [!#_. @] เท่านั้น';
                              return null;
                            },
                          ),
                          _buildLabelField('อีเมล', isRequired: true),
                          _buildInputField(
                            hint: 'อีเมล',
                            controller: _emailCtrl,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'กรุณากรอกอีเมล';
                              if (!RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              ).hasMatch(val))
                                return 'รูปแบบอีเมลไม่ถูกต้อง';
                              return null;
                            },
                          ),
                        ],
                      ),

                      _buildSectionContainer(
                        title: 'ข้อมูลส่วนตัว',
                        children: [
                          _buildLabelField(
                            'หมายเลขบัตรประชาชน',
                            isRequired: true,
                          ),
                          _buildInputField(
                            hint: 'หมายเลขบัตรประชาชน',
                            controller: _citizenIdCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 13,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'กรุณากรอกเลขบัตรประชาชน';
                              if (val.contains(' '))
                                return 'ต้องไม่มีเว้นวรรคหรือช่องว่าง';
                              if (val.length != 13 ||
                                  !RegExp(r'^[0-9]+$').hasMatch(val))
                                return 'ต้องเป็นตัวเลขความยาว 13 หลัก';
                              return null;
                            },
                          ),
                          Row(
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
                                      controller: _firstNameCtrl,
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
                                      controller: _lastNameCtrl,
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
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabelField(
                                      'วันเกิด',
                                      isRequired: true,
                                    ),
                                    TextFormField(
                                      controller: _birthDateCtrl,
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                          _buildLabelField('เพศ', isRequired: true),
                          _buildGenderDropdown(),
                          _buildLabelField('เบอร์โทรศัพท์', isRequired: true),
                          _buildInputField(
                            hint: 'เบอร์โทรศัพท์',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            validator: (val) =>
                                val!.isEmpty ? 'กรุณากรอกเบอร์โทรศัพท์' : null,
                          ),
                          _buildLabelField('เกี่ยวกับฉัน', isRequired: true),
                          _buildInputField(
                            hint:
                                'อธิบายอะไรเกี่ยวกับตัวคุณหน่อย เช่น ประสบการณ์การดูแลผู้สูงอายุ หรือทักษะพิเศษที่มี',
                            controller: _aboutMeCtrl,
                            maxLines: 4,
                            maxLength: 500,
                            alignLabelWithHint: true,
                            validator: (val) => val!.isEmpty
                                ? 'กรุณากรอกข้อมูลเกี่ยวกับฉัน'
                                : null,
                          ),
                          _buildLabelField('อุปกรณ์ที่มี', isRequired: true),
                          _buildInputField(
                            hint: 'อธิบายอุปกรณ์ที่มี...',
                            controller: _equipmentCtrl,
                            maxLines: 4,
                            maxLength: 500,
                            alignLabelWithHint: true,
                            validator: (val) => val!.isEmpty
                                ? 'กรุณากรอกข้อมูลอุปกรณ์ที่มี'
                                : null,
                          ),
                        ],
                      ),

                      _buildSectionContainer(
                        title: 'ข้อมูลที่อยู่',
                        children: [
                          _buildInputField(
                            hint: 'รายละเอียดที่อยู่...',
                            controller: _addressCtrl,
                            maxLines: 4,
                            maxLength: 500,
                            validator: (val) => val!.isEmpty
                                ? 'กรุณากรอกรายละเอียดที่อยู่ หรือกดปักหมุดแผนที่ด้านล่าง'
                                : null,
                          ),
                          InkWell(
                            onTap: _showMapModal, // เรียกเปิดหน้าต่างแผนที่จริง
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'เลือกปักหมุดที่อยู่บนแผนที่',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.map, color: primaryColor),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      _buildSectionContainer(
                        title: 'ข้อมูลยานพาหนะ',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  hint: 'ประเภท (เช่น รถยนต์)',
                                  controller: _vehicleTypeCtrl,
                                  validator: (val) =>
                                      val!.isEmpty ? 'กรุณาระบุ' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  hint: 'ยี่ห้อ',
                                  controller: _brandCtrl,
                                  validator: (val) =>
                                      val!.isEmpty ? 'กรุณาระบุ' : null,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  hint: 'รุ่น',
                                  controller: _modelCtrl,
                                  validator: (val) =>
                                      val!.isEmpty ? 'กรุณาระบุ' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  hint: 'สี',
                                  controller: _colorCtrl,
                                  validator: (val) =>
                                      val!.isEmpty ? 'กรุณาระบุ' : null,
                                ),
                              ),
                            ],
                          ),
                          _buildLabelField('ป้ายทะเบียน', isRequired: true),
                          _buildInputField(
                            hint: 'ป้ายทะเบียน',
                            controller: _licensePlateCtrl,
                            validator: (val) =>
                                val!.isEmpty ? 'กรุณากรอกทะเบียนรถ' : null,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'ภาพถ่ายภายในและภายนอกยานพาหนะ (สูงสุด 4 รูป)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _pickImageReal('vehicle'),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: primaryColor),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: primaryColor,
                                    size: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 60,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _vehicleImageFiles.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: Stack(
                                          alignment: Alignment.topRight,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                _vehicleImageFiles[index],
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _vehicleImageFiles.removeAt(
                                                    index,
                                                  );
                                                  _vehiclePhotoNames.removeAt(
                                                    index,
                                                  );
                                                });
                                              },
                                              child: Container(
                                                color: Colors.red,
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      _buildSectionContainer(
                        title: 'ข้อมูลเอกสาร',
                        children: [
                          _buildUploadDocRow(
                            'รูปถ่ายใบอนุญาตขับขี่ *',
                            _licenseImageFile,
                            _licenseCardPhotoName,
                            () => _pickImageReal('license'),
                          ),
                          const Divider(),
                          _buildUploadDocRow(
                            'ประกันภัยรถยนต์',
                            _insuranceImageFile,
                            _insurancePhotoName,
                            () => _pickImageReal('insurance'),
                          ),
                          const Divider(),
                          _buildUploadDocRow(
                            'ใบรับรองการอบรมปฐมพยาบาล',
                            _firstAidImageFile,
                            _firstAidPhotoName,
                            () => _pickImageReal('firstaid'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

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
                          onPressed: _isLoading ? null : _handleRegisterSubmit,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
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
                            onPressed: () => _handleRegisterSubmit(),
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

  Widget _buildTopToggleTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      height: 45,
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _handleBackNavigation(),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTab == "ญาติ"
                      ? darkPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'ญาติ',
                  style: TextStyle(
                    color: _selectedTab == "ญาติ" ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {}, // อยู่หน้าเดียวกัน ไม่ต้องทำอะไร
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTab == "ผู้ดูแล"
                      ? darkPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'ผู้ดูแล',
                  style: TextStyle(
                    color: _selectedTab == "ผู้ดูแล"
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
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
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _profileImageFile != null
                  ? FileImage(_profileImageFile!)
                  : null,
              child: _profileImageFile == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
            InkWell(
              onTap: () => _pickImageReal('profile'),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(blurRadius: 3, color: Colors.black26)],
                ),
                child: Icon(Icons.camera_alt, size: 20, color: primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'อัปโหลดรูปโปรไฟล์ *',
          style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender.isEmpty ? null : _selectedGender,
      decoration: InputDecoration(
        hintText: 'เลือกเพศ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'ชาย', child: Text('ชาย')),
        DropdownMenuItem(value: 'หญิง', child: Text('หญิง')),
        DropdownMenuItem(value: 'อื่นๆ', child: Text('อื่นๆ')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGender = value ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'กรุณาเลือกเพศ';
        }
        return null;
      },
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

  Widget _buildUploadDocRow(
    String title,
    File? imageFile,
    String? fileName,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: imageFile != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                imageFile,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            )
          : Container(
              width: 40,
              height: 40,
              color: Colors.grey.shade200,
              child: const Icon(Icons.insert_drive_file, color: Colors.grey),
            ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: fileName != null
          ? Text(
              fileName,
              style: const TextStyle(fontSize: 11, color: Colors.green),
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: IconButton(
        icon: Icon(
          fileName != null ? Icons.check_circle : Icons.cloud_upload,
          color: primaryColor,
        ),
        onPressed: onTap,
      ),
    );
  }
}
