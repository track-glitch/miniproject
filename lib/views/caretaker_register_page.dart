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
import '../models/vehicle_photo_model.dart';
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
  final _selectedTab = "ผู้ดูแล";
  String _selectedGender = "";

  LatLng _selectedLocation = const LatLng(13.7563, 100.5018);
  bool _hasPinned = false;
  bool _isLoadingLocation = false;

  File? _profileImageFile;
  File? _licenseImageFile;
  File? _insuranceImageFile;
  File? _firstAidImageFile;
  final List<File> _vehicleImageFiles = [];

  // เก็บเป็น Base64 ตามที่ต้องการ
  String? _profilePhotoBase64;
  String? _licensePhotoBase64;
  String? _insurancePhotoBase64;
  String? _firstAidPhotoBase64;
  List<String> _vehiclePhotoBase64List = [];

  // ชื่อไฟล์รูปภาพ
  String? _profilePhotoName;
  String? _licenseCardPhotoName;
  String? _insurancePhotoName;
  String? _firstAidPhotoName;
  final List<String> _vehiclePhotoNames = [];

  // Controllers Form
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
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color greyBorder = const Color(0xFFE1BEE7);

  @override
  void dispose() {
    // 🧹 เคลียร์ Controllers ทั้งหมดเพื่อคืนพื้นที่หน่วยความจำ
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _citizenIdCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _birthDateCtrl.dispose();
    _genderCtrl.dispose();
    _aboutMeCtrl.dispose();
    _equipmentCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();

    _vehicleTypeCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _licensePlateCtrl.dispose();

    super.dispose();
  }

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
            "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year + 543}";
      });
    }
  }

  // -----------------------------------------------------------------
  // 🌟 ส่วนที่แก้ไขใหม่: เพิ่มการเลือก Camera/Gallery และ Preview รูป
  // -----------------------------------------------------------------

  // 1. ฟังก์ชันแสดง Action Sheet ให้เลือกว่าจะถ่ายรูปหรือเลือกจากไฟล์
  void _showImageSourceActionSheet(String type) {
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
                  _pickImageReal(type);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('ถ่ายรูปใหม่ (Camera)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageReal(type);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. ฟังก์ชันแสดง Popup รูปภาพขยายใหญ่กลางหน้าจอ
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
                // ทำให้ซูมรูปได้
                panEnabled: false,
                boundaryMargin: const EdgeInsets.all(20),
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

  // 3. ฟังก์ชันสำหรับลบรูปภาพที่เลือกไว้
  void _removeImage(String type) {
    setState(() {
      if (type == 'profile') {
        _profileImageFile = null;
        _profilePhotoName = null;
        _profilePhotoBase64 = null;
      } else if (type == 'license') {
        _licenseImageFile = null;
        _licenseCardPhotoName = null;
        _licensePhotoBase64 = null;
      } else if (type == 'insurance') {
        _insuranceImageFile = null;
        _insurancePhotoName = null;
        _insurancePhotoBase64 = null;
      } else if (type == 'firstaid') {
        _firstAidImageFile = null;
        _firstAidPhotoName = null;
        _firstAidPhotoBase64 = null;
      }
    });
  }

  // ปรับปรุง _pickImageReal ให้รับ ImageSource ด้วย
  Future<void> _pickImageReal(String type) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      int fileSizeInBytes = await file.length();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 20) {
        _showErrorSnackBar(
          'ขนาดไฟล์ต้องไม่เกิน 20MB (ไฟล์ของคุณขนาด: ${fileSizeInMB.toStringAsFixed(2)} MB)',
        );
        return;
      }

      String fileName = pickedFile.name;
      List<int> imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);

      setState(() {
        if (type == 'profile') {
          _profileImageFile = file;
          _profilePhotoName = fileName;
          _profilePhotoBase64 = base64String;
        } else if (type == 'license') {
          _licenseImageFile = file;
          _licenseCardPhotoName = fileName;
          _licensePhotoBase64 = base64String;
        } else if (type == 'insurance') {
          _insuranceImageFile = file;
          _insurancePhotoName = fileName;
          _insurancePhotoBase64 = base64String;
        } else if (type == 'firstaid') {
          _firstAidImageFile = file;
          _firstAidPhotoName = fileName;
          _firstAidPhotoBase64 = base64String;
        } else if (type == 'vehicle') {
          if (_vehicleImageFiles.length < 4) {
            _vehicleImageFiles.add(file);
            _vehiclePhotoNames.add(fileName);
            _vehiclePhotoBase64List.add(base64String);
          } else {
            _showErrorSnackBar('อัปโหลดรูปยานพาหนะได้สูงสุด 4 รูป');
          }
        }
      });
    }
  }
  // -----------------------------------------------------------------

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
            _addressCtrl.text =
                "$subdistrict $district $province รหัสไปรษณีย์ $postcode";
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

  void _handleToggleToRelative() {
    if (_hasAnyData) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการเปลี่ยนหน้า'),
          content: const Text(
            'คุณมีข้อมูลที่กรอกไว้บางส่วนในหน้าผู้ดูแล ต้องการสลับไปหน้าสมัครญาติหรือไม่? ข้อมูลที่กรอกในหน้านี้จะไม่ถูกบันทึก',
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
                    builder: (context) => const RelativeRegisterPage(),
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
        MaterialPageRoute(builder: (context) => const RelativeRegisterPage()),
      );
    }
  }

  void _handleRegisterSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender.isEmpty) {
      _showErrorSnackBar('กรุณาเลือกเพศ');
      return;
    }

    // 🌟 ส่วนที่แก้ไขใหม่: เพิ่มการ Validate เช็ครูปภาพให้ครบตามที่ UI ระบุว่าบังคับ
    if (_profilePhotoName == null) {
      _showErrorSnackBar('กรุณาอัปโหลดรูปโปรไฟล์ของคุณ');
      return;
    }
    if (_vehiclePhotoBase64List.isEmpty) {
      _showErrorSnackBar('กรุณาอัปโหลดภาพยานพาหนะอย่างน้อย 1 รูป');
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
          filepath: _licensePhotoBase64!,
          uploaddate: DateTime.now(),
        ),
      );

      if (_insurancePhotoBase64 != null) {
        documentList.add(
          DocumentModel(
            documentId:
                "DOC-INSURANCE-${DateTime.now().millisecondsSinceEpoch}",
            documenttype: "car_insurance",
            filepath: _insurancePhotoBase64!,
            uploaddate: DateTime.now(),
          ),
        );
      }

      if (_firstAidPhotoBase64 != null) {
        documentList.add(
          DocumentModel(
            documentId: "DOC-FIRSTAID-${DateTime.now().millisecondsSinceEpoch}",
            documenttype: "first_aid_certificate",
            filepath: _firstAidPhotoBase64!,
            uploaddate: DateTime.now(),
          ),
        );
      }

      DateTime parsedDate = DateTime.now();
      try {
        List<String> dateParts = _birthDateCtrl.text.split('/');
        if (dateParts.length == 3) {
          int day = int.parse(dateParts[0]);
          int month = int.parse(dateParts[1]);
          int year = int.parse(dateParts[2]) - 543;
          parsedDate = DateTime(year, month, day);
        }
      } catch (e) {
        print("Error parsing date: $e");
      }

      CaretakerModel caretakerData = CaretakerModel(
        caretakerId: "",
        profilephoto: _profilePhotoBase64!,
        firstname: _firstNameCtrl.text.trim(),
        lastname: _lastNameCtrl.text.trim(),
        gender: _selectedGender,
        birthdate: parsedDate,
        phonenumber: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        aboutme: _aboutMeCtrl.text.trim(),
        equipmentdetails: _equipmentCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        admincomment: "",
        servicestatus: "Offline",
        accountstatus: "Pending",
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
        vehiclephotos: _vehiclePhotoBase64List
            .map(
              (base64Str) => VehiclePhotoModel(
                vehiclephotoid: "VP-${DateTime.now().millisecondsSinceEpoch}",
                photo: base64Str,
              ),
            )
            .toList(),
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
                              if (val == null || val.trim().isEmpty) {
                                return 'กรุณากรอกชื่อผู้ใช้';
                              }
                              if (val.contains(' ')) {
                                return 'ต้องไม่มีเว้นวรรคหรือช่องว่าง';
                              }
                              if (val.length < 4 || val.length > 20) {
                                return 'ความยาวต้องอยู่ระหว่าง 4-20 ตัวอักษร';
                              }
                              if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(val)) {
                                return 'ใช้อักษรภาษาอังกฤษ ตัวเลข และ (_, -, .) เท่านั้น';
                              }
                              if (RegExp(r'^[_.-]').hasMatch(val) ||
                                  RegExp(r'[_.-]$').hasMatch(val)) {
                                return 'ห้ามขึ้นต้นหรือลงท้ายด้วยอักขระพิเศษ';
                              }
                              return null;
                            },
                          ),
                          _buildLabelField('รหัสผ่าน', isRequired: true),
                          _buildInputField(
                            hint: 'รหัสผ่าน',
                            controller: _passwordCtrl,
                            isPassword: true,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'กรุณากรอกรหัสผ่าน';
                              }
                              if (val.contains(' ')) {
                                return 'ต้องไม่มีเว้นวรรคหรือช่องว่าง';
                              }
                              if (val.length < 8 || val.length > 16) {
                                return 'ความยาวต้องอยู่ระหว่าง 8-16 ตัวอักษร';
                              }
                              if (!RegExp(
                                r'^[a-zA-Z0-9!#_.\s@]+$',
                              ).hasMatch(val)) {
                                return 'อนุญาตเฉพาะอักษร อังกฤษ เลข และ [!#_. @] เท่านั้น';
                              }
                              return null;
                            },
                          ),
                          _buildLabelField('อีเมล', isRequired: true),
                          _buildInputField(
                            hint: 'อีเมล',
                            controller: _emailCtrl,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'กรุณากรอกอีเมล';
                              }
                              if (!RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              ).hasMatch(val)) {
                                return 'รูปแบบอีเมลไม่ถูกต้อง';
                              }
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
                              if (val == null || val.trim().isEmpty) {
                                return 'กรุณากรอกเลขบัตรประชาชน';
                              }
                              if (val.contains(' ')) {
                                return 'ต้องไม่มีเว้นวรรคหรือช่องว่าง';
                              }
                              if (val.length != 13 ||
                                  !RegExp(r'^[0-9]+$').hasMatch(val)) {
                                return 'ต้องเป็นตัวเลขความยาว 13 หลัก';
                              }
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
                          SizedBox(height: 10),
                          _buildLabelField('เพศ', isRequired: true),
                          _buildGenderDropdown(),
                          SizedBox(height: 10),
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
                            hint: 'อุปกรณ์ที่มีในการรองรับผู้ป่วย',
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
                            onTap: _showMapModal,
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
                                child: _buildLabelField(
                                  'ประเภท',
                                  isRequired: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildLabelField(
                                  'ยี่ห้อ',
                                  isRequired: true,
                                ),
                              ),
                            ],
                          ),
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
                                child: _buildLabelField(
                                  'รุ่น',
                                  isRequired: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildLabelField('สี', isRequired: true),
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
                          const SizedBox(height: 3),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      'ภาพถ่ายภายในและภายนอกยานพาหนะสูงสุด 4 รูป',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            softWrap: true,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _pickImageReal(
                                  'vehicle',
                                ), // 🌟 เปลี่ยนมาเรียก Action Sheet
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
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _vehicleImageFiles
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          int index = entry.key;
                                          File file = entry.value;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            // 🌟 เพิ่มฟังก์ชันกดที่รูปรถเพื่อดูรูปแบบเต็มๆ และกดกากบาทลบได้
                                            child: Stack(
                                              alignment: Alignment.topRight,
                                              children: [
                                                GestureDetector(
                                                  onTap: () =>
                                                      _showImagePreview(
                                                        file,
                                                      ), // กดเพื่อพรีวิว
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.file(
                                                      file,
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _vehicleImageFiles
                                                          .removeAt(index);
                                                      _vehiclePhotoNames
                                                          .removeAt(index);
                                                      _vehiclePhotoBase64List
                                                          .removeAt(index);
                                                    });
                                                  },
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.all(2),
                                                    padding:
                                                        const EdgeInsets.all(2),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.red,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      size: 12,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        })
                                        .toList(),
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
                            'รูปถ่ายใบอนุญาตขับขี่',
                            _licenseImageFile,
                            _licenseCardPhotoName,
                            'license',
                            isRequired: true,
                          ),
                          const Divider(),
                          _buildUploadDocRow(
                            'ประกันภัยรถยนต์',
                            _insuranceImageFile,
                            _insurancePhotoName,
                            'insurance',
                            isRequired:
                                true, // 🌟 ลบดาวบังคับออกตามที่คุณเคยระบุไว้
                          ),
                          const Divider(),
                          _buildUploadDocRow(
                            'ใบรับรองการอบรมปฐมพยาบาล',
                            _firstAidImageFile,
                            _firstAidPhotoName,
                            'firstaid',
                            isRequired:
                                true, // 🌟 ลบดาวบังคับออกตามที่คุณเคยระบุไว้
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
                onTap: _handleToggleToRelative,
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
                onTap: () {},
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

  // 🌟 ปรับปรุง: การอัปโหลดรูปโปรไฟล์
  Widget _buildProfileUploadWidget() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: () {
                if (_profileImageFile == null) {
                  _pickImageReal('profile'); // ถ้ารูปว่าง ให้เปิดตัวเลือก
                } else {
                  _showImagePreview(
                    _profileImageFile!,
                  ); // ถ้ามีรูปแล้ว ให้เปิดพรีวิวเต็มจอ
                }
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
            // ปุ่มแก้ไขรูป (Camera Icon)
            InkWell(
              onTap: () => _showImageSourceActionSheet('profile'),
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
            // ปุ่มกากบาทลบรูป (จะโชว์ก็ต่อเมื่อมีรูปถูกเลือกแล้ว)
            if (_profileImageFile != null)
              Positioned(
                top: 0,
                right: 0,
                child: InkWell(
                  onTap: () => _removeImage('profile'),
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
            const Text(
              'อัปโหลดรูปโปรไฟล์',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(' *', style: TextStyle(color: Colors.red)),
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

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender.isEmpty ? null : _selectedGender,
      decoration: InputDecoration(
        hintText: 'เลือกเพศ',
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'ชาย', child: Text('ชาย')),
        DropdownMenuItem(value: 'หญิง', child: Text('หญิง')),
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

  // 🌟 ปรับปรุง: การอัปโหลดเอกสาร
  Widget _buildUploadDocRow(
    String title,
    File? imageFile,
    String? fileName,
    String type, {
    bool isRequired = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: GestureDetector(
        onTap: () {
          if (imageFile != null) {
            _showImagePreview(imageFile); // กดที่รูปเล็กๆ เพื่อดูรูปเต็มได้
          }
        },
        child: imageFile != null
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
      ),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            fontFamily: 'Sukhumvit',
          ),
          children: [
            TextSpan(text: title),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
      subtitle: fileName != null
          ? Text(
              fileName,
              style: const TextStyle(fontSize: 11, color: Colors.green),
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ปุ่มลบ จะโชว์เมื่อมีรูปแล้ว
          if (imageFile != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeImage(type),
            ),
          // ปุ่มเลือกรูป/เปลี่ยนรูป
          IconButton(
            icon: Icon(
              fileName != null
                  ? Icons.edit
                  : Icons.cloud_upload, // เปลี่ยนไอคอนให้เหมาะสม
              color: primaryColor,
            ),
            onPressed: () => _pickImageReal(type),
          ),
        ],
      ),
    );
  }
}
