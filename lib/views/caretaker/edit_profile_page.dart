import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/location_picker_widget.dart';
import '../../services/caretaker_service.dart';
import '../../widgets/custom_header_nav.dart';
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

  // สถานะและพิกัด
  bool isServiceOn = false;
  LatLng selectedLocation = const LatLng(18.2881, 99.4921);
  int _selectedIndex = 2;
  // ข้อมูลที่ดึงมา
  String profileImageUrl = '';
  String citizenId = '';
  String vehicleType = '';
  String vehicleColor = '';
  String vehicleBrand = '';
  String vehicleModel = '';
  String vehiclePlate = '';
  List<String> vehicleImages = []; // รูปรถ
  int _currentImageIndex = 0; // ตำแหน่งรูป Carousel ปัจจุบัน

  // Controllers สำหรับฟิลด์ที่แก้ได้
  TextEditingController fnameController = TextEditingController();
  TextEditingController lnameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController aboutmeController = TextEditingController();
  TextEditingController equipmentController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // 🌟 ดึงข้อมูลจาก Firebase ทันทีที่เปิดหน้า
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
    if (data != null) {
      setState(() {
        isServiceOn = (data['servicestatus'] == 'ON');
        fnameController.text = data['firstname'] ?? '';
        lnameController.text = data['lastname'] ?? '';
        phoneController.text = data['phonenumber'] ?? '';
        aboutmeController.text = data['aboutme'] ?? '';
        equipmentController.text = data['equipmentdetails'] ?? '';
        addressController.text = data['address'] ?? '';

        // ข้อมูลที่ห้ามแก้
        profileImageUrl = data['profilephoto'] ?? '';
        citizenId = data['caretakerId'] ?? 'ไม่พบข้อมูล';

        if (data['latitude'] != null && data['longitude'] != null) {
          selectedLocation = LatLng(
            double.parse(data['latitude'].toString()),
            double.parse(data['longitude'].toString()),
          );
        }

        // สมมติการดึงข้อมูลรถ (ปรับตามโครงสร้าง DB จริงของคุณ)
        if (data['Vehicle'] != null) {
          vehicleType = data['Vehicle']['vehicletype'] ?? '';
          vehicleColor = data['Vehicle']['color'] ?? '';
          vehicleBrand = data['Vehicle']['brand'] ?? '';
          vehicleModel = data['Vehicle']['model'] ?? '';
          vehiclePlate = data['Vehicle']['licenseplate'] ?? '';
          // วนลูปดึงรูปรถ
          if (data['Vehicle']['vehiclephotos'] != null) {
            for (var photo in data['Vehicle']['vehiclephotos']) {
              vehicleImages.add(photo['photo']);
            }
          }
        }

        // ถ้าไม่มีรูปจำลองไปก่อน
        if (vehicleImages.isEmpty) {
          vehicleImages = [
            'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=500',
            'https://images.unsplash.com/photo-1550355291-bbee04a92027?auto=format&fit=crop&w=500',
          ];
        }
        _isLoading = false;
      });
    }
  }

  // บันทึกข้อมูลที่แก้ไข
  void _saveProfile() async {
    Map<String, dynamic> updateData = {
      'firstname': fnameController.text,
      'lastname': lnameController.text,
      'phonenumber': phoneController.text,
      'aboutme': aboutmeController.text,
      'equipmentdetails': equipmentController.text,
      'location': {
        'address': addressController.text,
        'latitude': selectedLocation.latitude,
        'longitude': selectedLocation.longitude,
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

  // อัปเดตสถานะรับงานทันทีที่กดสวิตช์
  void _toggleServiceStatus(bool val) async {
    setState(() => isServiceOn = val);
    String statusStr = val ? 'ON' : 'OFF';
    await _service.updateServiceStatus(widget.uid, statusStr);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('อัปเดตสถานะเป็น $statusStr แล้ว')));
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // โค้ดสำหรับการเปลี่ยนหน้า (ปรับเปลี่ยนตามชื่อหน้าของคุณ)
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ListRelativeRequestPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4EDFB),
      appBar: const CustomHeader(
        title: 'แก้ไขข้อมูลผู้ดูแล',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🌟 1. รูปโปรไฟล์และสถานะรับงาน (เปลี่ยนใน Firebase ทันที)
            Text(
              'รูปโปรไฟล์',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: profileImageUrl.length > 100
                  ? MemoryImage(base64Decode(profileImageUrl))
                  : null,
              child: profileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'สถานะรับงาน: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  isServiceOn ? 'พร้อมรับงาน' : 'พักงาน',
                  style: TextStyle(
                    color: isServiceOn ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Switch(
              value: isServiceOn,
              activeColor: Colors.green,
              onChanged: _toggleServiceStatus, // เรียกฟังก์ชันอัปเดต Real-time
            ),
            const SizedBox(height: 20),

            _buildCard('ข้อมูลส่วนตัว', [
              _buildTextField(
                'หมายเลขบัตรประชาชน',
                '',
                initialValue: citizenId,
                isReadOnly: true,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'ชื่อจริง',
                      '',
                      controller: fnameController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      'นามสกุล',
                      '',
                      controller: lnameController,
                    ),
                  ),
                ],
              ),
              _buildTextField('เบอร์โทรศัพท์', '', controller: phoneController),
              _buildTextField(
                'เกี่ยวกับฉัน',
                '',
                controller: aboutmeController,
                maxLines: 3,
              ),
              _buildTextField(
                'อุปกรณ์ช่วยเหลือ',
                '',
                controller: equipmentController,
                maxLines: 2,
              ),
            ]),

            // 🌟 2. แผนที่และที่อยู่ (เชื่อมโยงกัน)
            _buildCard('ที่อยู่ปัจจุบัน', [
              LocationPickerWidget(
                initialLocation: selectedLocation,
                initialAddress: addressController.text,
                onLocationChanged: (newLocation, newAddress) {
                  setState(() {
                    selectedLocation = newLocation;
                    addressController.text = newAddress;
                  });
                },
              ),
            ]),

            // 🌟 3. ข้อมูลรถและ Carousel แบบมีจุดแอนิเมชัน
            _buildCard('ยานพาหนะที่ใช้', [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'ประเภท',
                      '',
                      initialValue: vehicleType,
                      isReadOnly: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      'สี',
                      '',
                      initialValue: vehicleColor,
                      isReadOnly: true,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'ยี่ห้อ',
                      '',
                      initialValue: vehicleBrand,
                      isReadOnly: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      'รุ่น',
                      '',
                      initialValue: vehicleModel,
                      isReadOnly: true,
                    ),
                  ),
                ],
              ),
              _buildTextField(
                'ป้ายทะเบียน',
                '',
                initialValue: vehiclePlate,
                isReadOnly: true,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'ภาพถ่ายยานพาหนะ',
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              // Carousel ไม่เลื่อนอัตโนมัติ
              CarouselSlider(
                options: CarouselOptions(
                  height: 180.0,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false, // ปิดการวนซ้ำ
                  autoPlay: false, // 🌟 ปิดออโต้สไลด์ตามที่คุณต้องการ
                  onPageChanged: (index, reason) {
                    setState(() => _currentImageIndex = index);
                  },
                ),
                items: vehicleImages.map((img) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: img.length > 100
                        ? Image.memory(
                            base64Decode(img),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Image.network(
                            img,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // 🌟 จุดแอนิเมชัน (Dot Indicators)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: vehicleImages.asMap().entries.map((entry) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _currentImageIndex == entry.key ? 20.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentImageIndex == entry.key
                          ? const Color(0xFFA052BE)
                          : Colors.grey.shade300,
                    ),
                  );
                }).toList(),
              ),
            ]),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA052BE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _saveProfile,
                child: const Text(
                  'บันทึกข้อมูล',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 🌟 เพิ่มปุ่มออกจากระบบตรงนี้
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.red,
                    width: 1.5,
                  ), // ขอบสีแดง
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  _showLogoutConfirmation(); // เรียกใช้ Popup ยืนยันการออก
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  // Helper function ลดความซ้ำซ้อน
  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    TextEditingController? controller,
    String? initialValue,
    bool isReadOnly = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            initialValue: initialValue,
            enabled: !isReadOnly,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: isReadOnly
                  ? Colors.grey.shade200
                  : Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            style: TextStyle(
              color: isReadOnly ? Colors.grey.shade600 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
