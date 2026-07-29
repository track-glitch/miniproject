import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:miniproject/views/caretaker/view_review_page.dart';

import '../../services/caretaker_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../caretaker/list_relative_request_page.dart';
import '../login_page.dart';

class EditProfilePage extends StatefulWidget {
  final String uid;
  const EditProfilePage({super.key, required this.uid});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final CaretakerService _service = CaretakerService();
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF7C5CFC);
  final Color darkPurple = const Color(0xFF6E5ABF);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color greyBorder = const Color(0xFFB9A4F2);
  final Color headerGradientStart = const Color(0xFF8E6FF0);
  final Color headerGradientEnd = const Color(0xFF7C5CFC);
  final Color bgGradientTop = const Color.fromARGB(255, 225, 202, 255);
  final Color bgGradientBottom = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;

  bool isServiceOn = false;
  int _selectedIndex = 1;

  String profileImageUrl = '';
  String citizenId = '';
  String vehicleType = '';
  String vehicleColor = '';
  String vehicleBrand = '';
  String vehicleModel = '';
  String vehiclePlate = '';
  List<String> vehicleImages = [];
  List<Map<String, dynamic>> recentReviews = [];
  int _currentImageIndex = 0;

  String? selectedGender;
  DateTime? birthDate;
  final List<String> genderOptions = ['ชาย', 'หญิง', 'อื่นๆ'];

  // 🌟 1. เปลี่ยนตัวแปรมารับ Experience แทน
  TextEditingController fnameController = TextEditingController();
  TextEditingController lnameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController experienceController = TextEditingController();
  TextEditingController servicedescController = TextEditingController();
  TextEditingController serviceAreaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ออกจากระบบ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text(
              'ออกจากระบบ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProfileData() async {
    final data = await _service.getCaretakerProfile(widget.uid);
    final reviewsData = await _service.getRecentReviews(widget.uid, limit: 2);
    if (data != null) {
      setState(() {
        recentReviews = reviewsData;
        isServiceOn =
            (data['servicestatus'] == 'ON' ||
            data['servicestatus'] == 'online');
        fnameController.text = data['firstname'] ?? '';
        lnameController.text = data['lastname'] ?? '';
        phoneController.text = data['phonenumber'] ?? '';

        // 🌟 2. ดึงข้อมูล Experience
        experienceController.text = data['experience'] ?? '';
        servicedescController.text = data['servicedesc'] ?? '';

        // 🌟 3. ดักจับที่อยู่ทั้งแบบ Location (ใหม่) และ location (เก่า)
        var locData = data['Location'] ?? data['location'];
        serviceAreaController.text = locData != null
            ? (locData['address'] ?? '')
            : '';

        selectedGender = data['gender'];
        if (data['birthdate'] != null) {
          birthDate = DateTime.tryParse(data['birthdate'].toString());
        }

        profileImageUrl = data['profilephoto'] ?? '';
        citizenId = data['caretakerId'] ?? 'ไม่พบข้อมูล';

        if (data['Vehicle'] != null) {
          vehicleType = data['Vehicle']['vehicletype'] ?? '';
          vehicleColor = data['Vehicle']['color'] ?? '';
          vehicleBrand = data['Vehicle']['brand'] ?? '';
          vehicleModel = data['Vehicle']['model'] ?? '';
          vehiclePlate = data['Vehicle']['licenseplate'] ?? '';

          // 🌟 แก้ไข: เปลี่ยนจาก 'vehiclephotos' เป็น 'VehiclePhoto' ให้ตรงกับ Database
          if (data['Vehicle']['VehiclePhoto'] != null) {
            for (var photo in data['Vehicle']['VehiclePhoto']) {
              vehicleImages.add(photo['photo']);
            }
          }
        }

        if (vehicleImages.isEmpty) {
          vehicleImages = [
            'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=500',
          ];
        }
        _isLoading = false;
      });
    }
  }

  void _saveProfile() async {
    // 🌟 4. อัปเดตข้อมูลที่จะส่งไปเซฟให้ตรงกับ Model
    Map<String, dynamic> updateData = {
      'firstname': fnameController.text,
      'lastname': lnameController.text,
      'phonenumber': phoneController.text,
      'experience': experienceController.text,
      'servicedesc': servicedescController.text,
      'gender': selectedGender,
      'birthdate': birthDate?.toIso8601String(),
      'Location': {
        'address': serviceAreaController.text,
        'latitude': 0.0,
        'longitude': 0.0,
      },
    };
    try {
      await _service.updateCaretakerProfile(widget.uid, updateData);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก')),
      );
    }
  }

  void _toggleServiceStatus(bool val) async {
    setState(() => isServiceOn = val);
    String statusStr = val ? 'online' : 'offline';
    await _service.updateServiceStatus(widget.uid, statusStr);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('อัปเดตสถานะเป็น $statusStr แล้ว')));
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ListRelativeRequestPage(uid: widget.uid),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGradientBottom,
      appBar: AppBar(
        title: const Text(
          'แก้ไขข้อมูลอาสา',
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
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      _buildProfileImageSection(),
                      const SizedBox(height: 20),

                      _buildSectionContainer(
                        title: 'ข้อมูลส่วนตัว',
                        children: [
                          _buildInputField(
                            'หมายเลขบัตรประชาชน',
                            controller: null,
                            initialValue: citizenId,
                            isReadOnly: true,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  'ชื่อจริง',
                                  controller: fnameController,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  'นามสกุล',
                                  controller: lnameController,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: _buildGenderDropdown()),
                              const SizedBox(width: 10),
                              Expanded(child: _buildDatePicker('วันเกิด')),
                            ],
                          ),
                          _buildInputField(
                            'เบอร์โทรศัพท์',
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                          ),

                          // 🌟 5. ฟิลด์ประสบการณ์การทำงาน
                          _buildInputField(
                            'ประสบการณ์การทำงาน (ถ้ามี)',
                            controller: experienceController,
                            maxLines: 3,
                            maxLength: 500,
                          ),

                          _buildInputField(
                            'รายละเอียดการบริการ (ถ้ามี)',
                            controller: servicedescController,
                            maxLines: 3,
                            maxLength: 500,
                          ),
                        ],
                      ),

                      _buildSectionContainer(
                        title: 'ที่อยู่ปัจจุบัน',
                        children: [
                          _buildInputField(
                            'เขตอำเภอ/พื้นที่ ที่สะดวกให้บริการ',
                            controller: serviceAreaController,
                            maxLines: 3,
                            maxLength: 500,
                          ),
                        ],
                      ),

                      _buildSectionContainer(
                        title: 'ยานพาหนะที่ใช้',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  'ประเภท',
                                  initialValue: vehicleType,
                                  isReadOnly: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  'สี',
                                  initialValue: vehicleColor,
                                  isReadOnly: true,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  'ยี่ห้อ',
                                  initialValue: vehicleBrand,
                                  isReadOnly: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  'รุ่น',
                                  initialValue: vehicleModel,
                                  isReadOnly: true,
                                ),
                              ),
                            ],
                          ),
                          _buildInputField(
                            'ป้ายทะเบียน',
                            initialValue: vehiclePlate,
                            isReadOnly: true,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'ภาพถ่ายยานพาหนะ',
                            style: TextStyle(
                              fontSize: 13,
                              color: darkPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CarouselSlider(
                            options: CarouselOptions(
                              height: 150.0,
                              enlargeCenterPage: true,
                              enableInfiniteScroll: false,
                              autoPlay: false,
                              onPageChanged: (index, reason) {
                                setState(() => _currentImageIndex = index);
                              },
                            ),
                            items: vehicleImages.map((img) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: img.startsWith('http')
                                    ? Image.network(
                                        img,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        // 🌟 เพิ่ม loadingBuilder เพื่อโชว์ตอนรูปกำลังโหลด
                                        loadingBuilder:
                                            (
                                              BuildContext context,
                                              Widget child,
                                              ImageChunkEvent? loadingProgress,
                                            ) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  color: primaryColor,
                                                  value:
                                                      loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                        // 🌟 ดัก Error กรณีลิงก์รูปเสีย
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade200,
                                                width: double.infinity,
                                                child: const Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                      size: 40,
                                                    ),
                                                    Text(
                                                      'โหลดรูปภาพไม่สำเร็จ',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                      )
                                    : Image.memory(
                                        base64Decode(img),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        // 🌟 ดัก Error กรณีแปลง Base64 ไม่ผ่าน
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade200,
                                                width: double.infinity,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                    size: 40,
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      _buildReviewSection(),
                      const SizedBox(height: 10),
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
                                onPressed: _saveProfile,
                                child: const Text(
                                  'บันทึกข้อมูล',
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
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.logout,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                label: const Text(
                                  'ออกจากระบบ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: _showLogoutConfirmation,
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        uid: widget.uid,
      ),
    );
  }

  Widget _buildProfileImageSection() {
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
                  // 🌟 แก้ไขตรงนี้ ใช้ startsWith('http') เช็กว่าเป็นลิ้งก์หรือไม่
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? (profileImageUrl.startsWith('http')
                            ? NetworkImage(profileImageUrl)
                            : MemoryImage(base64Decode(profileImageUrl))
                                  as ImageProvider)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 55,
                          color: primaryColor.withOpacity(0.6),
                        )
                      : null,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isServiceOn ? Colors.green : Colors.grey.shade400,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isServiceOn ? 'เปิดบริการ' : 'ปิดบริการ',
              style: TextStyle(
                color: isServiceOn ? Colors.green : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Switch(
              value: isServiceOn,
              activeColor: Colors.green,
              activeTrackColor: Colors.green.shade200,
              onChanged: _toggleServiceStatus,
            ),
          ],
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

  Widget _buildInputField(
    String label, {
    TextEditingController? controller,
    String? initialValue,
    bool isReadOnly = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        enabled: !isReadOnly,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 14,
          color: isReadOnly ? Colors.grey.shade600 : darkPurple,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF8D7AE6)),
          filled: true,
          fillColor: isReadOnly
              ? Colors.grey.shade200
              : const Color(0xFFFAF8FF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          counterStyle: const TextStyle(fontSize: 11, color: Colors.grey),
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
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 2.3),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedGender,
        icon: Icon(Icons.arrow_drop_down, color: greyBorder),
        decoration: InputDecoration(
          labelText: 'เพศ',
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF8D7AE6)),
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
        ),
        items: genderOptions.map((String gender) {
          return DropdownMenuItem(
            value: gender,
            child: Text(
              gender,
              style: TextStyle(fontSize: 14, color: darkPurple),
            ),
          );
        }).toList(),
        onChanged: (val) => setState(() => selectedGender = val),
      ),
    );
  }

  Widget _buildDatePicker(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: birthDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            helpText: 'เลือกวันเกิด',
          );
          if (picked != null) {
            setState(() => birthDate = picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF8D7AE6)),
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
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                birthDate != null
                    ? "${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}"
                    : "วว/ดด/ปปปป",
                style: TextStyle(
                  fontSize: 14,
                  color: birthDate != null ? darkPurple : Colors.grey.shade500,
                ),
              ),
              Icon(Icons.calendar_today, size: 18, color: greyBorder),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รีวิวล่าสุด',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade900,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ViewReviewPage(caretakerId: widget.uid),
                    ),
                  );
                },
                child: Text(
                  'ดูทั้งหมด',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (recentReviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ไม่พบข้อมูล review',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentReviews.asMap().entries.map((entry) {
              int index = entry.key;
              var review = entry.value;
              bool isLast = index == recentReviews.length - 1;

              return Column(
                children: [
                  _buildReviewItem(
                    name: review['reviewerName'] ?? 'ไม่ระบุชื่อ',
                    rating: (review['rating'] ?? 5).toDouble(),
                    comment: review['comment'] ?? 'ไม่มีข้อความ',
                    timeAgo: review['timeAgo'] ?? '',
                    imageUrl: review['reviewerImage'] ?? '',
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Colors.grey.shade200),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReviewItem({
    required String name,
    required double rating,
    required String comment,
    required String timeAgo,
    required String imageUrl,
  }) {
    ImageProvider? imageProvider;
    if (imageUrl.isNotEmpty) {
      try {
        if (imageUrl.length > 100) {
          String cleanBase64 = imageUrl;
          if (cleanBase64.contains(',')) {
            cleanBase64 = cleanBase64.split(',').last;
          }
          cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');

          int padding = cleanBase64.length % 4;
          if (padding > 0) {
            cleanBase64 += '=' * (4 - padding);
          }

          imageProvider = MemoryImage(base64Decode(cleanBase64));
        } else {
          imageProvider = NetworkImage(imageUrl);
        }
      } catch (e) {
        print('Error decoding Review Image: $e');
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: imageProvider != null
                ? Image(
                    image: imageProvider!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Image rendering error: $error');
                      return Icon(
                        Icons.person,
                        color: Colors.grey.shade400,
                        size: 28,
                      );
                    },
                  )
                : Icon(Icons.person, color: Colors.grey.shade400, size: 28),
          ),
        ),
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating.floor()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFFFC107),
                        size: 18,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                timeAgo,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
