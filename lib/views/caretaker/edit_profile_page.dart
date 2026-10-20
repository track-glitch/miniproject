import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:miniproject/views/caretaker/view_review_page.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/location_picker_widget.dart';
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

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF9B59B6);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color bgColor = const Color(0xFF9B59B6);
  final Color greyBorder = const Color(0xFF9B59B6);
  final Color headerGradientStart = const Color(0xFF9B59B6);
  final Color headerGradientEnd = const Color(0xFF9B59B6);
  final Color bgGradientTop = const Color.fromARGB(255, 225, 202, 255);
  final Color bgGradientBottom = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;

  bool isServiceOn = false;
  bool isSuspended = false;
  int _selectedIndex = 1;

  String profileImageUrl = '';
  String citizenId = '';
  String vehicleType = '';
  String vehicleColor = '';
  String vehicleBrand = '';
  String vehicleModel = '';
  String vehiclePlate = '';
  String vehicleProvince = '';
  List<String> vehicleImages = [];
  List<Map<String, dynamic>> recentReviews = [];
  int _currentImageIndex = 0;

  String? selectedGender;
  final List<String> genderOptions = ['ชาย', 'หญิง', 'อื่นๆ'];
  // 🌟 เพิ่มตัวแปรสำหรับแผนที่
  LatLng _selectedLocation = const LatLng(13.7563, 100.5018);
  bool _hasPinned = false;

  TextEditingController fnameController = TextEditingController();
  TextEditingController lnameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController experienceController = TextEditingController();
  TextEditingController servicedescController = TextEditingController();
  TextEditingController serviceAreaController = TextEditingController();

  // 🌟 เพิ่ม Controller สำหรับวันเกิดและอายุให้เหมือนฝั่งญาติ
  TextEditingController birthDateController = TextEditingController();
  TextEditingController ageController = TextEditingController();

  // 🌟 ตัวแปรสำหรับเก็บเบอร์โทรศัพท์เดิมเพื่อใช้ตรวจสอบกรณีมีการแก้ไข
  String _initialPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    fnameController.dispose();
    lnameController.dispose();
    phoneController.dispose();
    experienceController.dispose();
    servicedescController.dispose();
    serviceAreaController.dispose();
    birthDateController.dispose();
    ageController.dispose();
    super.dispose();
  }

  // 🌟 ฟังก์ชันคำนวณอายุอัตโนมัติจากสตริง DD/MM/YYYY
  void _calculateAge(String birthDateStr) {
    if (birthDateStr.isEmpty) {
      ageController.text = '';
      return;
    }
    try {
      List<String> parts = birthDateStr.split('/');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);

        if (year > 2400) {
          year -= 543;
        }

        DateTime birthDate = DateTime(year, month, day);
        DateTime today = DateTime.now();

        int age = today.year - birthDate.year;
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }

        ageController.text = age >= 0 ? '$age ปี' : '0 ปี';
      }
    } catch (e) {
      ageController.text = '';
    }
  }

  Future<void> _selectBirthDate() async {
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 20),
    );
    try {
      if (birthDateController.text.isNotEmpty) {
        final parts = birthDateController.text.split('/');
        int year = int.parse(parts[2]);
        if (year > 2400) year -= 543;
        initialDate = DateTime(year, int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        birthDateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year + 543}";
        _calculateAge(birthDateController.text);
      });
    }
  }

  ImageProvider _getSafeBase64Image(String base64String) {
    try {
      String cleanBase64 = base64String;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      int padding = cleanBase64.length % 4;
      if (padding > 0) {
        cleanBase64 += '=' * (4 - padding);
      }
      return MemoryImage(base64Decode(cleanBase64));
    } catch (e) {
      return MemoryImage(base64Decode('R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs='));
    }
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

  // 🌟 ฟังก์ชันใหม่สำหรับดึงรีวิวโดยตรงจากฐานข้อมูล (รองรับกรณีญาติมีผู้ป่วยหลายคน)
  Future<void> _fetchRecentReviewsDirectly() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login').get();
      if (!snapshot.exists || snapshot.value == null) return;

      final allUsers = Map<dynamic, dynamic>.from(snapshot.value as Map);
      List<Map<String, dynamic>> tempReviews = [];

      allUsers.forEach((userKey, userValue) {
        if (userValue is Map && userValue.containsKey('Relative')) {
          var relNode = userValue['Relative'];
          if (relNode is Map && relNode.containsKey('Request')) {
            var requests = relNode['Request'];
            if (requests is Map) {
              requests.forEach((reqId, reqData) {
                if (reqData is Map && reqData['caretakerId'] != null) {
                  // เช็คว่าบริการนี้เป็นของอาสาคนนี้หรือไม่ (ใช้ citizenId หรือ UID)
                  String cId = reqData['caretakerId'].toString();
                  if (cId == citizenId || cId == widget.uid) {
                    var reviewData = reqData['Review'] ?? reqData['review'];
                    if (reviewData != null && reviewData is Map) {
                      // 1. ดึงคะแนน
                      double ratingScore = 0.0;
                      var rawRating =
                          reviewData['ratingscore'] ?? reviewData['rating'];
                      if (rawRating != null) {
                        ratingScore =
                            double.tryParse(rawRating.toString()) ?? 5.0;
                      }

                      // 2. ดึงคอมเมนต์และวันที่
                      String commentStr =
                          reviewData['comment']?.toString() ?? '';
                      String reviewDateStr =
                          reviewData['reviewdate']?.toString() ??
                          DateTime.now().toIso8601String();

                      // 3. เตรียมชื่อญาติ (ใช้ชื่อญาติเป็นหลักในการโชว์คนรีวิว)
                      String rFirstname = (relNode['firstname'] ?? '')
                          .toString();
                      String rLastname = (relNode['lastname'] ?? '').toString();
                      String reviewerName = "$rFirstname $rLastname".trim();
                      if (reviewerName.isEmpty) reviewerName = 'ผู้ใช้บริการ';

                      // 4. ดึงรูปโปรไฟล์ (พยายามดึงรูปญาติก่อน ถ้าไม่มีค่อยไปหารูปผู้ป่วยในคำขอนั้นๆ)
                      String reviewerImage =
                          relNode['profilephoto']?.toString() ?? '';

                      // 🌟 ส่วนที่ปรับแก้เพื่อรองรับผู้ป่วยหลายคน (หา PatientId จากคำขอ แล้วไปค้นรูปในโหนด Patient/patients)
                      if (reviewerImage.isEmpty) {
                        String requestedPatientId =
                            reqData['patientId']?.toString() ?? '';
                        dynamic pNode =
                            relNode['Patient'] ?? relNode['patients'];

                        if (pNode != null && pNode is Map) {
                          // ถ้ามี patientId ระบุในคำขอ ให้ดึงรูปคนนั้นมา
                          if (requestedPatientId.isNotEmpty &&
                              pNode.containsKey(requestedPatientId)) {
                            reviewerImage =
                                pNode[requestedPatientId]['patientphoto']
                                    ?.toString() ??
                                '';
                          }
                          // ถ้าหาไม่เจอ หรือเป็นโครงสร้างแบบเก่า ดึงรูปคนแรกมาแสดงแทน
                          else if (pNode.isNotEmpty) {
                            final firstPatient = pNode.values.first;
                            if (firstPatient is Map) {
                              reviewerImage =
                                  firstPatient['patientphoto']?.toString() ??
                                  '';
                            }
                          }
                        }
                      }

                      tempReviews.add({
                        'ratingscore': ratingScore,
                        'comment': commentStr,
                        'reviewdate': reviewDateStr,
                        'reviewerName': reviewerName,
                        'reviewerImage': reviewerImage,
                      });
                    }
                  }
                }
              });
            }
          }
        }
      });

      // เรียงลำดับจากใหม่สุดไปเก่าสุด
      tempReviews.sort((a, b) => b['reviewdate'].compareTo(a['reviewdate']));

      // จัดรูปแบบเวลาให้สวยงามก่อนแสดงผล และเอามาแค่ 2 อันล่าสุด
      List<Map<String, dynamic>> finalReviewsList = tempReviews.take(2).map((
        item,
      ) {
        String formattedDate = '';
        try {
          DateTime dt = DateTime.parse(item['reviewdate']);
          formattedDate = "${dt.day}/${dt.month}/${dt.year + 543}";
        } catch (_) {}

        return {
          'rating': item['ratingscore'],
          'comment': item['comment'],
          'timeAgo': formattedDate,
          'reviewerName': item['reviewerName'],
          'reviewerImage': item['reviewerImage'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          recentReviews = finalReviewsList;
        });
      }
    } catch (e) {
      print('Error directly fetching reviews: $e');
    }
  }

  Future<void> _loadProfileData() async {
    final data = await _service.getCaretakerProfile(widget.uid);
    if (data != null) {
      setState(() {
        String accStatus = (data['accountstatus']?.toString() ?? '')
            .trim()
            .toLowerCase();
        isSuspended = (accStatus == 'suspended');

        isServiceOn =
            (data['servicestatus'] == 'ON' ||
            data['servicestatus'] == 'online');
        fnameController.text = data['firstname'] ?? '';
        lnameController.text = data['lastname'] ?? '';
        phoneController.text = data['phonenumber'] ?? '';
        _initialPhoneNumber = (data['phonenumber'] ?? '').toString().trim();

        experienceController.text = data['experience'] ?? '';
        servicedescController.text = data['servicedesc'] ?? '';
        var locData = data['Location'] ?? data['location'];
        if (locData != null) {
          serviceAreaController.text = locData['address']?.toString() ?? '';

          // 🌟 ดึงพิกัดเดิมมาใส่แผนที่
          double lat =
              double.tryParse(locData['latitude']?.toString() ?? '0') ?? 0.0;
          double lng =
              double.tryParse(locData['longitude']?.toString() ?? '0') ?? 0.0;
          if (lat != 0.0 && lng != 0.0) {
            _selectedLocation = LatLng(lat, lng);
            _hasPinned = true;
          }
        }

        selectedGender = data['gender'];

        // 🌟 ดึงวันเกิดมาแสดงในรูปแบบ DD/MM/YYYY
        if (data['birthdate'] != null) {
          try {
            DateTime parsedDate = DateTime.parse(data['birthdate'].toString());
            birthDateController.text =
                "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year + 543}";
            _calculateAge(birthDateController.text);
          } catch (e) {
            birthDateController.text = data['birthdate'].toString();
            _calculateAge(birthDateController.text);
          }
        }

        profileImageUrl = data['profilephoto'] ?? '';
        citizenId = data['caretakerId'] ?? 'ไม่พบข้อมูล';

        if (data['Vehicle'] != null) {
          vehicleType = data['Vehicle']['vehicletype'] ?? '';
          vehicleColor = data['Vehicle']['color'] ?? '';
          vehicleBrand = data['Vehicle']['brand'] ?? '';
          vehicleModel = data['Vehicle']['model'] ?? '';
          vehiclePlate = data['Vehicle']['licenseplate'] ?? '';
          vehicleProvince = data['Vehicle']['province'] ?? '';

          vehicleImages.clear();
          final photos =
              data['Vehicle']['vehiclephotos'] ??
              data['Vehicle']['VehiclePhoto'];

          if (photos != null) {
            if (photos is List) {
              for (var photo in photos) {
                if (photo != null && photo['photo'] != null) {
                  vehicleImages.add(photo['photo'].toString());
                }
              }
            } else if (photos is Map) {
              for (var photo in photos.values) {
                if (photo != null && photo['photo'] != null) {
                  vehicleImages.add(photo['photo'].toString());
                }
              }
            }
          }
        }

        if (vehicleImages.isEmpty) {
          vehicleImages = [
            'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=500',
          ];
        }
      });

      // 🌟 หลังจากดึงข้อมูลโปรไฟล์ได้ citizenId แล้ว ให้ไปดึงรีวิวด้วยตัวเองเลย
      await _fetchRecentReviewsDirectly();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveProfile() async {
    String newPhone = phoneController.text.trim();

    // 🌟 ตรวจสอบเบอร์โทรศัพท์
    if (newPhone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกเบอร์โทรศัพท์')));
      return;
    }

    if (newPhone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(newPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง (ตัวเลข 10 หลัก)'),
        ),
      );
      return;
    }

    // 🌟 ตรวจสอบว่าเบอร์ซ้ำในระบบหรือไม่
    if (newPhone != _initialPhoneNumber) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final snapshot = await FirebaseDatabase.instance.ref('Login').get();
        if (snapshot.exists && snapshot.value is Map) {
          final allUsers = Map<String, dynamic>.from(snapshot.value as Map);

          for (var entry in allUsers.entries) {
            String userKey = entry.key;
            var userData = entry.value;

            if (userKey == widget.uid) continue;

            if (userData is Map) {
              if (userData['Caretaker'] is Map) {
                String cPhone = (userData['Caretaker']['phonenumber'] ?? '')
                    .toString()
                    .trim();
                if (cPhone == newPhone) {
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'เบอร์โทรศัพท์นี้ถูกใช้งานในระบบแล้ว กรุณาใช้เบอร์อื่น',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              if (userData['Relative'] is Map) {
                String rPhone = (userData['Relative']['phonenumber'] ?? '')
                    .toString()
                    .trim();
                if (rPhone == newPhone) {
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'เบอร์โทรศัพท์นี้ถูกใช้งานในระบบแล้ว กรุณาใช้เบอร์อื่น',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }
            }
          }
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการตรวจสอบเบอร์: $e')),
        );
        return;
      }
    }

    // 🌟 แปลงสตริงจากช่องกรอกกลับเป็น DateTime มาตรฐาน (ISO 8601) ก่อนส่งลงฐานข้อมูล
    DateTime? savedBirthDate;
    if (birthDateController.text.isNotEmpty) {
      try {
        final parts = birthDateController.text.split('/');
        int year = int.parse(parts[2]);
        if (year > 2400) year -= 543;
        savedBirthDate = DateTime(
          year,
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } catch (_) {}
    }

    Map<String, dynamic> updateData = {
      'firstname': fnameController.text,
      'lastname': lnameController.text,
      'phonenumber': newPhone,
      'experience': experienceController.text,
      'servicedesc': servicedescController.text,
      'gender': selectedGender,
      'birthdate': savedBirthDate?.toIso8601String(),
      'Location': {
        'address': serviceAreaController.text,
        'latitude': _hasPinned ? _selectedLocation.latitude : 0.0,
        'longitude': _hasPinned ? _selectedLocation.longitude : 0.0,
      },
    };
    try {
      await _service.updateCaretakerProfile(widget.uid, updateData);
      _initialPhoneNumber = newPhone;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก')),
        );
      }
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
          onPressed: () {
            // 🌟 ให้ทำงานเหมือนกดแท็บผู้ดูแล (สลับกลับไปหน้ารายการคำขอ)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ListRelativeRequestPage(uid: widget.uid),
              ),
            );
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
                            isEnabled: false,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  'ชื่อจริง',
                                  controller: fnameController,
                                  isReadOnly: true,
                                  isEnabled: false,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  'นามสกุล',
                                  controller: lnameController,
                                  isReadOnly: true,
                                  isEnabled: false,
                                ),
                              ),
                            ],
                          ),
                          // 🌟 เพศ ล็อกห้ามแก้ไข
                          _buildInputField(
                            'เพศ',
                            initialValue: selectedGender ?? 'ไม่ระบุ',
                            isReadOnly: true,
                            isEnabled: false,
                          ),
                          // 🌟 วันเกิด และ อายุ ล็อกห้ามแก้ไข
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildInputField(
                                  'วันเกิด [DD/MM/YYYY]',
                                  controller: birthDateController,
                                  isReadOnly: true,
                                  isEnabled: false,
                                  onTap: null,
                                  suffixIcon: const Icon(
                                    Icons.calendar_month,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 4,
                                child: _buildInputField(
                                  'อายุ',
                                  controller: ageController,
                                  isReadOnly: true,
                                  isEnabled: false,
                                ),
                              ),
                            ],
                          ),
                          // 🌟 เบอร์โทรศัพท์ยังคงพิมพ์แก้ไขได้
                          _buildInputField(
                            'เบอร์โทรศัพท์',
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                          ),
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
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4, left: 2),
                            child: Text(
                              'เขตอำเภอ/พื้นที่ ที่สะดวกให้บริการ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          LocationPickerWidget(
                            initialLocation: _selectedLocation,
                            initialAddress: serviceAreaController.text,
                            onLocationChanged: (newLocation, newAddress) {
                              setState(() {
                                _selectedLocation = newLocation;
                                serviceAreaController.text = newAddress;
                                _hasPinned = true;
                              });
                            },
                          ),
                          // แจ้งเตือนสีแดงถ้ายังไม่ได้ปักหมุด
                          if (!_hasPinned)
                            const Padding(
                              padding: EdgeInsets.only(top: 8, left: 4),
                              child: Text(
                                '* กรุณาแตะเพื่อปักหมุดที่อยู่บนแผนที่',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                ),
                              ),
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
                                  isEnabled: false,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  'สี',
                                  initialValue: vehicleColor,
                                  isReadOnly: true,
                                  isEnabled: false,
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
                                  isEnabled: false,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  'รุ่น',
                                  initialValue: vehicleModel,
                                  isReadOnly: true,
                                  isEnabled: false,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  'เลขป้ายทะเบียน',
                                  initialValue: vehiclePlate,
                                  isReadOnly: true,
                                  isEnabled: false,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  'จังหวัดป้ายทะเบียน',
                                  initialValue: vehicleProvince,
                                  isReadOnly: true,
                                  isEnabled: false,
                                ),
                              ),
                            ],
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
                                    : Image(
                                        image: _getSafeBase64Image(img),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
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
                          // 🌟 จุด Dot Indicators บ่งบอกจำนวนรูปภาพ
                          if (vehicleImages.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: vehicleImages.asMap().entries.map((
                                  entry,
                                ) {
                                  return Container(
                                    width: _currentImageIndex == entry.key
                                        ? 18.0
                                        : 8.0,
                                    height: 8.0,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4.0),
                                      color: _currentImageIndex == entry.key
                                          ? primaryColor
                                          : Colors.grey.shade300,
                                    ),
                                  );
                                }).toList(),
                              ),
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
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? (profileImageUrl.startsWith('http')
                            ? NetworkImage(profileImageUrl)
                            : _getSafeBase64Image(profileImageUrl))
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
                // 🌟 แก้สีจุดวงกลม: ถ้าโดนระงับเป็นสีแดง ถ้าไม่ก็ใช้สีเขียว/เทาตามเดิม
                color: isSuspended
                    ? Colors.red
                    : (isServiceOn ? Colors.green : Colors.grey.shade400),
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

        // 🌟 เช็กเงื่อนไขถ้าถูกระงับการใช้งาน (ซ่อนสวิตช์ โชว์ข้อความสีแดง)
        if (isSuspended) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, color: Colors.red, size: 20),
              const SizedBox(width: 6),
              const Text(
                'บัญชีถูกระงับการใช้งาน',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ไม่สามารถเปิดรับบริการได้ในขณะนี้',
            style: TextStyle(color: Colors.red.shade400, fontSize: 13),
          ),
        ]
        // 🌟 ถ้าบัญชีปกติ ไม่ถูกระงับ (แสดงสวิตช์ตามปกติ)
        else ...[
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
                  color: primaryColor,
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

  // 🌟 อัปเดตฟังก์ชัน Build ให้รองรับ onTap และ ReadOnly คล้ายหน้าฝั่งญาติ
  Widget _buildInputField(
    String label, {
    TextEditingController? controller,
    String? initialValue,
    bool isReadOnly = false,
    bool isEnabled = true,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        enabled: isEnabled,
        readOnly: isReadOnly,
        onTap: onTap,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 14,
          color: !isEnabled ? Colors.grey.shade600 : darkPurple,
        ),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF9B59B6)),
          filled: true,
          fillColor: !isEnabled
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
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF9B59B6)),
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
                    rating: review['rating'] ?? 5.0,
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
                        index < rating.floor() ? Icons.star : Icons.star_border,
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
