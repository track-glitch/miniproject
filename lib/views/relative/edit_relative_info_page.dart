import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:geolocator/geolocator.dart'; 
import 'package:http/http.dart' as http; 

// --- ตรวจสอบ Path ให้ตรงกับโฟลเดอร์จริงในโปรเจกต์ miniproject ของคุณ ---
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';

class EditRelativeInfoPage extends StatefulWidget {
  final PatientModel currentPatient;
  final RelativeModel currentRelative;
  final String loggedUid; // 🎯 1. รับค่า loggedUid จากหน้าก่อนหน้า

  const EditRelativeInfoPage({
    super.key,
    required this.currentPatient,
    required this.currentRelative,
    required this.loggedUid, // 🎯
  });

  @override
  State<EditRelativeInfoPage> createState() => _EditRelativeInfoPageState();
}

class _EditRelativeInfoPageState extends State<EditRelativeInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // เฉดสีควบคุมตามธีมหลัก
  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color bgColor = const Color(0xFFFAFAFA);
  final Color greyBorder = const Color(0xFFE1BEE7);

  LatLng _selectedLocation = const LatLng(13.7563, 100.5018);
  bool _hasPinned = false;

  File? _profileImageFile;
  String? _profilePhotoBase64;

  // Controllers ข้อมูลผู้ป่วย
  final TextEditingController _patFirstNameController = TextEditingController();
  final TextEditingController _patLastNameController = TextEditingController();
  final TextEditingController _patIdCardController = TextEditingController();
  final TextEditingController _patLineIdController = TextEditingController();
  final TextEditingController _patPhoneController = TextEditingController();
  final TextEditingController _patGenderController = TextEditingController();
  final TextEditingController _patBirthDateController = TextEditingController();
  final TextEditingController _patDiseaseController = TextEditingController();
  final TextEditingController _patAddressController = TextEditingController();

  // Controllers ข้อมูลติดต่อญาติ
  final TextEditingController _relFirstNameController = TextEditingController();
  final TextEditingController _relLastNameController = TextEditingController();
  final TextEditingController _relPhoneController = TextEditingController();
  final TextEditingController _relLineIdController = TextEditingController();
  final TextEditingController _relRelationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
    _fetchAndForceShowData();
  }

  void _initData() {
    _patFirstNameController.text = widget.currentPatient.firstname ?? '';
    _patLastNameController.text = widget.currentPatient.lastname ?? '';
    _patIdCardController.text = widget.currentPatient.patientId ?? '';
    _patPhoneController.text = widget.currentPatient.phonenumber ?? '';
    _patGenderController.text = widget.currentPatient.gender ?? '';
    _patDiseaseController.text = widget.currentPatient.disease ?? '';
    _patLineIdController.text = widget.currentRelative.lineId ?? ''; 

    if (widget.currentPatient.birthdate != null) {
      final date = widget.currentPatient.birthdate!;
      _patBirthDateController.text = 
          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year + 543}";
    }

    _relFirstNameController.text = widget.currentRelative.firstname ?? '';
    _relLastNameController.text = widget.currentRelative.lastname ?? '';
    _relPhoneController.text = widget.currentRelative.phonenumber ?? '';
    _relLineIdController.text = widget.currentRelative.lineId ?? '';
    _relRelationController.text = widget.currentRelative.relationship ?? '';
    _profilePhotoBase64 = widget.currentPatient.patientphoto;
  }

  Future<void> _fetchAndForceShowData() async {
    String uid = widget.loggedUid; // 🎯 2. ใช้ widget.loggedUid แทนการดึงจาก FirebaseAuth
    
    if (uid.isNotEmpty) {
      // 1. ดึงข้อมูลฝั่ง Relative
      final relSnapshot = await FirebaseDatabase.instance.ref('Login/$uid/Relative').get();
      if (relSnapshot.exists && relSnapshot.value is Map) {
        final relData = Map<String, dynamic>.from(relSnapshot.value as Map);
        setState(() {
          // 🎯 2. เซ็ตค่าลงทั้งช่องของผู้ป่วยและของญาติ
          _patLineIdController.text = relData['lineId'] ?? ''; 
          _relLineIdController.text = relData['lineId'] ?? ''; 
        });
      }

      // 2. ดึงข้อมูลฝั่ง Patient
      final patSnapshot = await FirebaseDatabase.instance.ref('Login/$uid/Relative/Patient').get();
      if (patSnapshot.exists && patSnapshot.value is Map) {
        final data = Map<String, dynamic>.from(patSnapshot.value as Map);
        setState(() {
          _patAddressController.text = data['address'] ?? ''; 
          
          double lat = data['latitude']?.toDouble() ?? 0.0;
          double lng = data['longitude']?.toDouble() ?? 0.0;
          if (lat != 0.0 && lng != 0.0) {
            _selectedLocation = LatLng(lat, lng);
            _hasPinned = true;
          }
        });
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
    _patAddressController.dispose();

    _relFirstNameController.dispose();
    _relLastNameController.dispose();
    _relPhoneController.dispose();
    _relLineIdController.dispose();
    _relRelationController.dispose();
    super.dispose();
  }

  // ระบบดึงพิกัดแผนที่
  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
      bool hasPermission = await _requestLocationPermission();
      if (!hasPermission) return null;
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
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
      print("Error: $e");
    }
  }

  void _showMapModal() async {
    setState(() => _isLoading = true);
    LatLng? currentLocation = await _getCurrentLocation();
    setState(() => _isLoading = false);

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

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
      String uid = widget.loggedUid; // 🎯 3. ใช้ widget.loggedUid
      
      if (uid.isNotEmpty) {
        // 🎯 3. แยกอัปเดต Relative ข้อมูลญาติ
        await FirebaseDatabase.instance
            .ref('Login/$uid/Relative')
            .update({
          'firstname': _relFirstNameController.text.trim(),
          'lastname': _relLastNameController.text.trim(),
          'phonenumber': _relPhoneController.text.trim(),
          'lineId': _relLineIdController.text.trim(), // 🎯 แก้จุดที่ผิดให้ใช้ของ relLineId 
          'relationship': _relRelationController.text.trim(),
        });

        // 🎯 3. แยกอัปเดต Patient ลงโหนดลึก เพื่อไม่ให้ทับโหนดอื่น
        await FirebaseDatabase.instance
            .ref('Login/$uid/Relative/Patient')
            .update({
          'patientId': _patIdCardController.text.trim(),
          'firstname': _patFirstNameController.text.trim(),
          'lastname': _patLastNameController.text.trim(),
          'phonenumber': _patPhoneController.text.trim(),
          'gender': _patGenderController.text.trim(),
          'disease': _patDiseaseController.text.trim(),
          'patientphoto': _profilePhotoBase64 ?? '',
          'address': _patAddressController.text.trim(),
          'latitude': _hasPinned ? _selectedLocation.latitude : 0.0,
          'longitude': _hasPinned ? _selectedLocation.longitude : 0.0,
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แก้ไขข้อมูลสำเร็จแล้ว')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
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
        title: const Text('แก้ไขข้อมูลผู้ป่วยและญาติ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileImageSection(), 
                    const SizedBox(height: 20),

                    // 1. ข้อมูลผู้ป่วย
                    _buildSectionContainer(
                      title: 'ข้อมูลผู้ป่วย',
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildInputField(hint: 'ชื่อจริง', controller: _patFirstNameController)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildInputField(hint: 'นามสกุล', controller: _patLastNameController)),
                          ],
                        ),
                        _buildInputField(hint: 'หมายเลขบัตรประชาชน', controller: _patIdCardController, keyboardType: TextInputType.number),
                        _buildInputField(hint: 'ไอดีไลน์', controller: _patLineIdController), // ช่องแสดงเฉยๆ
                        _buildInputField(hint: 'เบอร์โทรศัพท์', controller: _patPhoneController, keyboardType: TextInputType.phone),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(hint: 'เพศ', controller: _patGenderController)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildInputField(hint: 'วันเกิด [DD/MM/YYYY]', controller: _patBirthDateController)),
                          ],
                        ),
                        _buildInputField(hint: 'โรคประจำตัว', controller: _patDiseaseController),
                      ],
                    ),

                    // 2. ข้อมูลที่อยู่ผู้ป่วยพร้อมระบบปักหมุดแผนที่ใช้งานจริง
                    _buildSectionContainer(
                      title: 'ข้อมูลที่อยู่',
                      children: [
                        _buildInputField(hint: 'รายละเอียดที่อยู่...', controller: _patAddressController, maxLines: 3), 
                        const SizedBox(height: 5),
                        _buildMapButton(), 
                      ],
                    ),

                    // 3. ข้อมูลติดต่อญาติ
                    _buildSectionContainer(
                      title: 'ข้อมูลติดต่อญาติ',
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildInputField(hint: 'ชื่อจริงญาติ', controller: _relFirstNameController)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildInputField(hint: 'นามสกุลญาติ', controller: _relLastNameController)),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(hint: 'เบอร์โทรศัพท์ญาติ', controller: _relPhoneController, keyboardType: TextInputType.phone)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildInputField(hint: 'ไอดีไลน์', controller: _relLineIdController)), // 🎯 รับค่าตัวจริง
                          ],
                        ),
                        _buildInputField(hint: 'สถานะความสัมพันธ์', controller: _relRelationController),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ), 
                              onPressed: _handleSave,
                              child: const Text('ตกลง', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ), 
                              onPressed: () => Navigator.pop(context), 
                              child: const Text('ยกเลิก', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'บ้าน'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'ขอใช้บริการ'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'แจ้งเตือน'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'ญาติ'),
        ], 
      ), 
    ); 
  } 

  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
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

  Widget _buildProfileImageSection() {
    ImageProvider? imageProvider; 
    
    try {
      if (_profileImageFile != null) { 
        imageProvider = FileImage(_profileImageFile!); 
      } else if (_profilePhotoBase64 != null && _profilePhotoBase64!.isNotEmpty) { 
        String cleanBase64 = _profilePhotoBase64!.trim(); 
        if (cleanBase64.contains(',')) { 
          cleanBase64 = cleanBase64.split(',').last; 
        } 
        imageProvider = MemoryImage(base64Decode(cleanBase64)); 
      } 
    } catch (e) {
      imageProvider = null; 
      print("Error decoding profile image Base64: $e"); 
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
                decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle), 
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white), 
              ), 
            ), 
          ], 
        ), 
        const SizedBox(height: 8), 
        const Text('รูปโปรไฟล์ผู้ป่วย', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), 
      ], 
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
          hintText: hint, 
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey), 
          filled: true, 
          fillColor: Colors.white, 
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: greyBorder)), 
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: greyBorder)), 
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor)), 
          errorStyle: const TextStyle(fontSize: 11, color: Colors.red), 
        ), 
      ), 
    ); 
  } 
}