import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:miniproject/views/relative/request_caretaker_service_page.dart';
import 'package:miniproject/views/relative/list_request_page.dart';
import 'package:miniproject/views/relative/relative_home_page.dart';
import 'package:miniproject/views/relative/view_caretaker_review.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

class CaretakerProfilePage extends StatefulWidget {
  final String caretakerId;
  final String? loggedUid;
  final DateTime? selectedDate;
  final List<Map<String, dynamic>>? reviews; // 🌟 รับรายการรีวิวเข้ามา

  const CaretakerProfilePage({
    super.key,
    required this.caretakerId,
    this.loggedUid,
    this.selectedDate,
    this.reviews,
  });

  @override
  State<CaretakerProfilePage> createState() => _CaretakerProfilePageState();
}

class _CaretakerProfilePageState extends State<CaretakerProfilePage> {
  Map<String, dynamic>? caretakerData;
  Map<String, dynamic>? vehicleData;
  List<String> vehiclePhotos = [];
  bool isLoading = true;
  int _currentVehiclePhotoIndex = 0;

  // 🌟 ตัวแปรรองรับข้อมูลรีวิว
  List<Map<String, dynamic>> reviewsList = [];
  double averageRating = 0.0;
  int reviewCount = 0;
  

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;
  final Color borderColor = const Color(0xFFDDD0F0);

  String _loggedInUserName = '';
  String _loggedInUserPhoto = '';

  // 🌟 2. เพิ่มฟังก์ชันดึงข้อมูลโปรไฟล์ผู้ใช้งาน
  Future<void> _fetchLoggedUserData() async {
    String uid = widget.loggedUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login/$uid/Relative').get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        String activeId = data['activePatientNode']?.toString() ?? '';
        Map<String, dynamic>? currentPatient;

        if (activeId.isNotEmpty && data['Patient'] != null) {
          final patientNode = data['Patient'] as Map;
          if (patientNode[activeId] != null) {
            currentPatient = Map<String, dynamic>.from(patientNode[activeId]);
          }
        }

        if (mounted) {
          setState(() {
            if (currentPatient != null) {
              _loggedInUserName = formatFullNameWithTitle(
                gender: currentPatient['gender']?.toString(),
                firstname: currentPatient['firstname']?.toString(),
                lastname: currentPatient['lastname']?.toString(),
              );
              _loggedInUserPhoto = currentPatient['patientphoto']?.toString() ?? '';
            } else {
              _loggedInUserName = formatFullNameWithTitle(
                gender: data['gender']?.toString(),
                firstname: data['firstname']?.toString(),
                lastname: data['lastname']?.toString(),
              );
              _loggedInUserPhoto = data['profilephoto']?.toString() ?? '';
            }
          });
        }
      }
    } catch (e) {
      print("Error fetch logged user data: $e");
    }
  }

  // 🌟 ฟังก์ชันแปลงเพศเป็นคำนำหน้าชื่อ นาย / นาง
  String getPrefix(String? gender) {
    if (gender == null) return '';
    final g = gender.trim();
    if (g == 'ชาย' || g.toLowerCase() == 'male') {
      return 'นาย';
    } else if (g == 'หญิง' || g.toLowerCase() == 'female') {
      return 'นาง';
    }
    return '';
  }

  // 🌟 ฟังก์ชันรวมคำนำหน้า + ชื่อ + นามสกุล (เว้นวรรค 1 เคาะหลังคำนำหน้า)
  String formatFullNameWithTitle({
    required String? gender,
    required String? firstname,
    required String? lastname,
  }) {
    String prefix = getPrefix(gender);
    String fName = (firstname ?? '').trim();
    String lName = (lastname ?? '').trim();

    if (fName.isEmpty && lName.isEmpty) return 'ไม่ระบุ';
    String prefixWithSpace = prefix.isNotEmpty ? '$prefix ' : '';

    return '$prefixWithSpace$fName $lName'.trim();
  }

  void _calculateReviewStats() {
    if (reviewsList.isEmpty) {
      averageRating = 0.0;
      reviewCount = 0;
    } else {
      double sum = reviewsList.fold(
        0.0,
        (prev, item) =>
            prev +
            (double.tryParse(item['ratingscore']?.toString() ?? '0') ?? 0.0),
      );
      averageRating = sum / reviewsList.length;
      reviewCount = reviewsList.length;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.reviews != null) {
      reviewsList = List<Map<String, dynamic>>.from(widget.reviews!);
      _calculateReviewStats();
    }
    loadCaretaker();
    _fetchLoggedUserData();
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_outlined, size: 75, color: primaryColor),
                const SizedBox(height: 20),
                Text(
                  'กรุณาเข้าสู่ระบบก่อนใช้งาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'คุณต้องลงชื่อเข้าใช้งานในระบบก่อน จึงจะสามารถกดส่งคำขอเรียกใช้บริการผู้ดูแลคนนี้ได้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'ปิดหน้าต่าง',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> loadCaretaker() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('Login/${widget.caretakerId}')
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final cData = Map<String, dynamic>.from(data['Caretaker'] ?? {});
        final String cIdCard = cData['caretakerId']?.toString() ?? '';

        // 🌟 กรณีเปิดหน้านี้มาโดยไม่ได้ส่ง reviews มาด้วย ให้ query จาก Firebase Login
        if (reviewsList.isEmpty) {
          final allLoginSnap =
              await FirebaseDatabase.instance.ref('Login').get();
          if (allLoginSnap.exists && allLoginSnap.value is Map) {
            final allMap = Map<String, dynamic>.from(allLoginSnap.value as Map);
            List<Map<String, dynamic>> fetchedReviews = [];

            allMap.forEach((uKey, uVal) {
              if (uVal is Map && uVal['Relative'] != null) {
                var rel = uVal['Relative'];
                if (rel is Map && rel['Request'] != null) {
                  var reqs = rel['Request'];
                  if (reqs is Map) {
                    reqs.forEach((rId, rVal) {
                      if (rVal is Map && rVal['caretakerId'] != null) {
                        String reqCId = rVal['caretakerId'].toString();
                        if (reqCId == cIdCard ||
                            reqCId == widget.caretakerId) {
                          var rev = rVal['Review'] ?? rVal['review'];
                          if (rev != null && rev is Map) {
                            double score = double.tryParse(
                                  (rev['rating'] ??
                                          rev['ratingscore'] ??
                                          0)
                                      .toString(),
                                ) ??
                                0.0;
                            String rGender = (rel['Patient']?['gender'] ??
                                    rel['gender'] ??
                                    '')
                                .toString();
                            String rName = formatFullNameWithTitle(
                              gender: rGender,
                              firstname: (rel['firstname'] ?? '').toString(),
                              lastname: (rel['lastname'] ?? '').toString(),
                            );
                            if (rName.isEmpty || rName == 'ไม่ระบุ') {
                              rName = 'ผู้ใช้บริการ';
                            }
                            fetchedReviews.add({
                              'ratingscore': score,
                              'comment': rev['comment']?.toString() ?? '',
                              'reviewdate': rev['reviewdate']?.toString() ?? '',
                              'reviewerName': rName,
                              'reviewerImage': (rel['profilephoto'] ??
                                      rel['Patient']?['patientphoto'] ??
                                      '')
                                  .toString(),
                            });
                          }
                        }
                      }
                    });
                  }
                }
              }
            });
            reviewsList = fetchedReviews;
            _calculateReviewStats();
          }
        }

        if (!mounted) return;
        setState(() {
          caretakerData = cData;

          if (caretakerData!['Vehicle'] != null) {
            vehicleData = Map<String, dynamic>.from(caretakerData!['Vehicle']);

            final photos =
                vehicleData!['vehiclephotos'] ?? vehicleData!['VehiclePhoto'];

            if (photos != null) {
              if (photos is List) {
                vehiclePhotos = photos
                    .where((p) => p != null && p['photo'] != null)
                    .map((p) => p['photo'].toString())
                    .toList();
              } else if (photos is Map) {
                vehiclePhotos = photos.values
                    .where((p) => p != null && p['photo'] != null)
                    .map((p) => p['photo'].toString())
                    .toList();
              }
            }
          }

          isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR = $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0E6FF),
        body: Center(
          child: CircularProgressIndicator(color: const Color(0xFF9B59B6)),
        ),
      );
    }

    // 🌟 แปลงรูปโปรไฟล์ของผู้ใช้งานที่ล็อกอิน
    ImageProvider? userImageProvider;
    if (_loggedInUserPhoto.isNotEmpty) {
      try {
        String clean = _loggedInUserPhoto.replaceAll(RegExp(r'\s+'), '');
        if (clean.contains(',')) clean = clean.split(',').last;
        int pad = clean.length % 4;
        if (pad > 0) clean += '=' * (4 - pad);
        userImageProvider = MemoryImage(base64Decode(clean));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 2,
        shadowColor: const Color(0xFF7B1FA2).withOpacity(0.3),
        centerTitle: false, // 🌟 ขยับข้อความไปด้านหน้า
        titleSpacing: 0,    // 🌟 ลดระยะห่างจากปุ่มย้อนกลับ
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ข้อมูลผู้ดูแล',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        // 🌟 เพิ่มป้ายแสดงชื่อคนล็อกอินมุมขวาบน
        actions: [
          if (_loggedInUserName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white38, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage: userImageProvider,
                        child: userImageProvider == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _loggedInUserName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Container(
              color: bgColor,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      // 1. ข้อมูลโปรไฟล์และติดต่อ
                      _buildProfileHeader(),
                      const SizedBox(height: 12),

                      // 2. ข้อมูลประสบการณ์และบริการ
                      _buildProfessionalInfo(),
                      const SizedBox(height: 12),

                      // 3. ข้อมูลยานพาหนะ (รูปรถ)
                      _buildVehicleInfo(),
                      const SizedBox(height: 12),

                      // 🌟 4. รีวิวของผู้ดูแล (ย้ายมาไว้ต่อจากรูปรถตรงนี้)
                      _buildReviewSection(),
                      const SizedBox(height: 24),

                      // 5. ปุ่มส่งคำขอ
                      _buildMinimalRequestButton(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: primaryColor,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.27),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(
              Icons.home_outlined,
              'บ้าน',
              false,
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RelativeHomePage(loggedUid: widget.loggedUid),
                  ),
                  (route) => false,
                );
              },
            ),
            _buildBottomNavItem(
              Icons.support_agent,
              'รายการคำขอ',
              false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ListRequestPage(loggedUid: widget.loggedUid),
                  ),
                );
              },
            ),
            _buildBottomNavItem(
              Icons.person_outline,
              'ญาติ',
              false,
              onTap: () async {
                String currentUid =
                    widget.loggedUid ??
                    FirebaseAuth.instance.currentUser?.uid ??
                    '';
                if (currentUid.isEmpty) {
                  _showLoginRequiredDialog();
                  return;
                }
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  final snapshot = await FirebaseDatabase.instance
                      .ref('Login')
                      .get();
                  if (context.mounted) Navigator.pop(context);

                  String targetRelativeId = '';
                  Map<String, dynamic> targetUserData = {};
                  bool isFound = false;

                  if (snapshot.exists && snapshot.value is Map) {
                    final allUsers = Map<String, dynamic>.from(
                      snapshot.value as Map,
                    );
                    for (var key in allUsers.keys) {
                      if (key == currentUid) {
                        targetRelativeId = key;
                        targetUserData = Map<String, dynamic>.from(
                          allUsers[key] as Map,
                        );
                        isFound = true;
                        break;
                      }
                      var childData = allUsers[key];
                      if (childData is Map) {
                        var relNode = childData['Relative'];
                        if (childData['uid'] == currentUid ||
                            (relNode is Map &&
                                relNode['relativeId'] == currentUid)) {
                          targetRelativeId = key;
                          targetUserData = Map<String, dynamic>.from(childData);
                          isFound = true;
                          break;
                        }
                      }
                    }
                  }

                  if (isFound && targetRelativeId.isNotEmpty) {
                    RelativeModel relative;
                    Map<String, dynamic> relativeMap = {};
                    if (targetUserData.containsKey('Relative')) {
                      relativeMap = Map<String, dynamic>.from(
                        targetUserData['Relative'] as Map,
                      );
                      relative = RelativeModel(
                        relativeId:
                            relativeMap['relativeId'] ?? targetRelativeId,
                        firstname: relativeMap['firstname'] ?? '',
                        lastname: relativeMap['lastname'] ?? '',
                        phonenumber: relativeMap['phonenumber'] ?? '',
                        relationship: relativeMap['relationship'] ?? '',
                        email: relativeMap['email'] ?? '',
                      );
                    } else {
                      relative = RelativeModel(
                        relativeId: targetRelativeId,
                        firstname: '',
                        lastname: '',
                        phonenumber: '',
                        relationship: '',
                        email: '',
                      );
                    }

                    PatientModel patient;
                    if (relativeMap.containsKey('Patient')) {
                      final pData = Map<String, dynamic>.from(
                        relativeMap['Patient'] as Map,
                      );
                      patient = PatientModel(
                        patientId: pData['patientId'] ?? '',
                        patientphoto: pData['patientphoto'] ?? '',
                        firstname: pData['firstname'] ?? '',
                        lastname: pData['lastname'] ?? '',
                        phonenumber: pData['phonenumber'] ?? '',
                        gender: pData['gender'] ?? '',
                        birthdate: pData['birthdate'] != null
                            ? DateTime.tryParse(pData['birthdate'].toString())
                            : null,
                        disease: pData['disease'] ?? '',
                        mobility: pData['mobility'] ?? '',
                      );
                    } else {
                      patient = PatientModel(
                        patientId: '',
                        patientphoto: '',
                        firstname: '',
                        lastname: '',
                        phonenumber: '',
                        gender: '',
                      );
                    }

                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditRelativeInfoPage(
                            currentPatient: patient,
                            currentRelative: relative,
                            loggedUid: targetRelativeId,
                          ),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ไม่พบข้อมูลประวัติ (กรุณาลองเข้าสู่ระบบใหม่อีกครั้ง)',
                          ),
                        ),
                      );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('เกิดข้อผิดพลาด: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 ส่วนรวมรูปโปรไฟล์ ชื่อ สถานะ และคะแนนเฉลี่ย
  Widget _buildProfileHeader() {
    String rawStatus =
        (caretakerData?['servicestatus']?.toString() ?? 'ไม่พร้อมให้บริการ')
            .trim();
    bool isAvailable =
        rawStatus.toLowerCase() == 'online' ||
        rawStatus.toLowerCase() == 'on' ||
        rawStatus == 'พร้อมให้บริการ';

    String displayFullName = formatFullNameWithTitle(
      gender: caretakerData?['gender']?.toString(),
      firstname: caretakerData?['firstname']?.toString(),
      lastname: caretakerData?['lastname']?.toString(),
    );

    ImageProvider? caretakerImageProvider;
    if (caretakerData?['profilephoto'] != null &&
        caretakerData!['profilephoto'].toString().isNotEmpty) {
      String clean = caretakerData!['profilephoto'].toString();
      if (clean.contains(',')) clean = clean.split(',').last;
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      int pad = clean.length % 4;
      if (pad > 0) clean += '=' * (4 - pad);
      try {
        caretakerImageProvider = MemoryImage(base64Decode(clean));
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B59B6).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // แถวบน: รูปโปรไฟล์ + ชื่อและสถานะ
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF9B59B6),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: const Color(0xFFE8D5FF),
                      backgroundImage: caretakerImageProvider,
                      child: caretakerImageProvider == null
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.black87,
                            )
                          : null,
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: isAvailable ? Colors.green : Colors.grey,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? Colors.green.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAvailable ? 'พร้อมให้บริการ' : 'ไม่พร้อมให้บริการ',
                        style: TextStyle(
                          color: isAvailable
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayFullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFF9B59B6),
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // 🌟 แสดงคะแนนเฉลี่ยใต้ชื่อ
                    Row(
                      children: [
                        Text(
                          '${averageRating.toStringAsFixed(1)} ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF555555),
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < averageRating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFFFBBF24),
                              size: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '($reviewCount รีวิว)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 1, height: 1),
          const SizedBox(height: 12),

          // แถวล่าง: ข้อมูลติดต่อ (เพศ / อายุ / เบอร์โทร)
          Row(
            children: [
              Expanded(
                child: _buildMiniInfoItem(
                  'เพศ',
                  caretakerData?['gender'] ?? '-',
                ),
              ),
              Container(height: 24, width: 1, color: Colors.grey.shade200),
              Expanded(
                child: _buildMiniInfoItem(
                  'อายุ',
                  calculateAge(caretakerData?['birthdate']),
                ),
              ),
              Container(height: 24, width: 1, color: Colors.grey.shade200),
              Expanded(
                child: _buildMiniInfoItem(
                  'เบอร์โทร',
                  caretakerData?['phonenumber'] ?? '-',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🌟 การ์ดแสดงคะแนนและรีวิวจากผู้ใช้บริการ
  // 🌟 การ์ดแสดงคะแนนและรีวิว (แสดงต่อจากยานพาหนะ คัดกรองที่มีข้อความก่อน สูงสุด 3 อัน)
  Widget _buildReviewSection() {
    // 1. เรียงลำดับ: คัดรีวิวที่มีข้อความคอมเมนต์ขึ้นมาก่อน
    List<Map<String, dynamic>> sortedReviews = List.from(reviewsList);
    sortedReviews.sort((a, b) {
      final aHasComment =
          (a['comment']?.toString().trim().isNotEmpty ?? false);
      final bHasComment =
          (b['comment']?.toString().trim().isNotEmpty ?? false);
      if (aHasComment && !bHasComment) return -1;
      if (!aHasComment && bHasComment) return 1;
      return 0;
    });

    // 2. จำกัดแสดงผลสูงสุดแค่ 3 รายการ
    final displayReviews = sortedReviews.take(3).toList();

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'รีวิวและการให้คะแนน',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              if (reviewCount > 0)
                Text(
                  '$reviewCount รีวิว',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // แถบสรุปคะแนนเฉลี่ย
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F5FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ 5.0',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < averageRating.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFFFBBF24),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  reviewCount == 0
                      ? 'ยังไม่มีการรีวิว'
                      : 'ความพึงพอใจโดยรวม\nจากผู้รับบริการ',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          if (reviewsList.isEmpty) ...[
            const SizedBox(height: 12),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'ยังไม่มีประวัติการรีวิวสำหรับผู้ดูแลท่านนี้',
                  style: TextStyle(fontSize: 12.5, color: Colors.black45),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            // แสดงสูงสุด 3 รีวิวที่คัดเลือกมาแล้ว
            ...displayReviews.map((review) {
              double score = double.tryParse(
                    review['ratingscore']?.toString() ?? '0',
                  ) ??
                  0.0;
              String comment = (review['comment']?.toString() ?? '').trim();
              String reviewer =
                  review['reviewerName']?.toString() ?? 'ผู้ใช้บริการ';
              String rawImg = review['reviewerImage']?.toString() ?? '';
              String dateStr = review['reviewdate']?.toString() ?? '';

              ImageProvider? revImage;
              if (rawImg.isNotEmpty) {
                String cleanImg = rawImg.replaceAll(RegExp(r'\s+'), '');
                int pad = cleanImg.length % 4;
                if (pad > 0) cleanImg += '=' * (4 - pad);
                try {
                  revImage = MemoryImage(base64Decode(cleanImg));
                } catch (_) {}
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xFFE8D5FF),
                          backgroundImage: revImage,
                          child: revImage == null
                              ? const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.black54,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reviewer,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (dateStr.isNotEmpty)
                                Text(
                                  dateStr.split('T').first,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black45,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (idx) => Icon(
                              idx < score.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFFFBBF24),
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        comment,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),

            // 🌟 เงื่อนไข: ถ้ามีรีวิวทั้งหมดมากกว่า 3 รายการ ถึงจะแสดงปุ่มนี้ให้กดไปดูต่อ
            if (reviewsList.length > 3) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewCaretakerReview(
                          caretakerId: widget.caretakerId,
                          reviews: reviewsList,
                          caretakerData: caretakerData,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'ดูรีวิวทั้งหมด (${reviewsList.length} รีวิว)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMinimalRequestButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () {
          String? uid = widget.loggedUid;

          if (uid == null) {
            final currentUser = FirebaseAuth.instance.currentUser;
            uid = currentUser?.uid;
          }

          if (uid == null) {
            _showLoginRequiredDialog();
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceRequestPage(
                caretakerData: caretakerData!,
                caretakerId: widget.caretakerId,
                loggedUid: uid!,
                initialSelectedDate: widget.selectedDate,
              ),
            ),
          );
        },
        icon: const Icon(Icons.support_agent, color: Colors.white),
        label: const Text(
          'ขอใช้บริการผู้ดูแลคนนี้',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String calculateAge(String? birthdate) {
    if (birthdate == null || birthdate.isEmpty) return '-';
    final birth = DateTime.parse(birthdate);
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return '$age ปี';
  }

  Widget _buildMiniInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfessionalInfo() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.assignment_ind_outlined,
                size: 20,
                color: Color(0xFF9B59B6),
              ),
              SizedBox(width: 8),
              Text(
                'ประสบการณ์และบริการ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'ประสบการณ์การทำงาน:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caretakerData?['experience'] ?? 'ไม่ได้ระบุประสบการณ์',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(thickness: 1),
          ),
          const Text(
            'บริการเสริมที่มอบให้:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caretakerData?['servicedesc'] ?? 'ไม่ได้ระบุรายละเอียด',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfo() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ยานพาหนะ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF9B59B6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleData?['vehicletype'] ?? 'รถยนต์',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${vehicleData?['brand'] ?? '-'} ${vehicleData?['model'] ?? ''}, สี${vehicleData?['color'] ?? '-'}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (vehiclePhotos.isNotEmpty) ...[
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: PageView.builder(
                  itemCount: vehiclePhotos.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentVehiclePhotoIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    try {
                      String cleanBase64 = vehiclePhotos[index];
                      if (cleanBase64.contains(',')) {
                        cleanBase64 = cleanBase64.split(',').last;
                      }
                      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
                      int pad = cleanBase64.length % 4;
                      if (pad > 0) cleanBase64 += '=' * (4 - pad);

                      return Image.memory(
                        base64Decode(cleanBase64),
                        fit: BoxFit.cover,
                      );
                    } catch (e) {
                      print("Error decoding vehicle photo $index: $e");
                      return const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                vehiclePhotos.length,
                (index) => _buildDot(index == _currentVehiclePhotoIndex),
              ),
            ),
          ] else ...[
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                color: Colors.grey.shade100,
              ),
              child: const Center(
                child: Icon(Icons.directions_car, size: 80, color: Colors.grey),
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(thickness: 1),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ป้ายทะเบียน:',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                '${vehicleData?['licenseplate'] ?? '-'} ${vehicleData?['province'] ?? ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 10 : 7,
      height: isActive ? 10 : 7,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF9B59B6) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B59B6).withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}