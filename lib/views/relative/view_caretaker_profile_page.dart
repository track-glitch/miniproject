import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:miniproject/views/relative/request_caretaker_service_page.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

class CaretakerProfilePage extends StatefulWidget {
  final String caretakerId;
  final String? loggedUid;
  final DateTime? selectedDate;

  const CaretakerProfilePage({
    super.key,
    required this.caretakerId,
    this.loggedUid,
    this.selectedDate,
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

  final Color primaryColor = const Color.fromARGB(255, 153, 116, 255);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;
  final Color borderColor = const Color(0xFFDDD0F0);

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

  @override
  void initState() {
    super.initState();
    loadCaretaker();
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
                      'ไปหน้าเข้าสู่ระบบ',
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

        if (!mounted) return;
        setState(() {
          caretakerData = Map<String, dynamic>.from(data['Caretaker'] ?? {});

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
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 2,
        shadowColor: const Color(0xFF7B1FA2).withOpacity(0.3),
        centerTitle: true,
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
                      // ส่วนรวมรูปโปรไฟล์และข้อมูลติดต่อ
                      _buildProfileHeader(),
                      const SizedBox(height: 12),

                      // ส่วนประสบการณ์และบริการ
                      _buildProfessionalInfo(),
                      const SizedBox(height: 12),

                      _buildVehicleInfo(),
                      const SizedBox(height: 24),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: 1,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: (index) async {
          if (index == 3) {
            String? uid = widget.loggedUid;

            if (uid == null) {
              final currentUser = FirebaseAuth.instance.currentUser;
              uid = currentUser?.uid;
            }

            if (uid == null) {
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
                  .ref('Login/$uid')
                  .get();
              if (context.mounted) Navigator.pop(context);

              if (snapshot.exists && snapshot.value is Map) {
                final userData = Map<String, dynamic>.from(
                  snapshot.value as Map,
                );
                RelativeModel relative;
                Map<String, dynamic> relativeMap = {};

                if (userData.containsKey('Relative')) {
                  relativeMap = Map<String, dynamic>.from(
                    userData['Relative'] as Map,
                  );
                  relative = RelativeModel(
                    relativeId: relativeMap['relativeId'] ?? '',
                    firstname: relativeMap['firstname'] ?? '',
                    lastname: relativeMap['lastname'] ?? '',
                    phonenumber: relativeMap['phonenumber'] ?? '',
                    relationship: relativeMap['relationship'] ?? '',
                    email: relativeMap['email'] ?? '',
                  );
                } else {
                  relative = RelativeModel(
                    relativeId: '',
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditRelativeInfoPage(
                        currentPatient: patient,
                        currentRelative: relative,
                        loggedUid: uid!,
                      ),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไม่พบข้อมูลประวัติในระบบ')),
                  );
                }
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
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'บ้าน'),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'ขอใช้บริการ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'แจ้งเตือน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'ญาติ',
          ),
        ],
      ),
    );
  }

  // 🌟 ส่วนรวมรูปโปรไฟล์ ชื่อ สถานะ และข้อมูลติดต่อ
  Widget _buildProfileHeader() {
    String rawStatus =
        (caretakerData?['servicestatus']?.toString() ?? 'ไม่พร้อมให้บริการ')
            .trim();
    bool isAvailable =
        rawStatus.toLowerCase() == 'online' ||
        rawStatus.toLowerCase() == 'on' ||
        rawStatus == 'พร้อมให้บริการ';

    // 🌟 จัดรูปแบบชื่อผู้ดูแลพร้อมคำนำหน้า นาย / นาง (เว้นวรรค)
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
                        color: const Color(0xFF8763E6),
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
                    const SizedBox(height: 5),
                    Text(
                      displayFullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFF8763E6),
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
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
                loggedUid: uid,
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

  Widget _buildContactInfo() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.contact_phone_outlined,
                size: 20,
                color: Color(0xFF9B59B6),
              ),
              SizedBox(width: 8),
              Text(
                'ข้อมูลติดต่อ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF8763E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniInfoItem('เพศ', caretakerData?['gender'] ?? '-'),
              _buildMiniInfoItem(
                'อายุ',
                calculateAge(caretakerData?['birthdate']),
              ),
              _buildMiniInfoItem(
                'เบอร์โทร',
                caretakerData?['phonenumber'] ?? '-',
              ),
            ],
          ),
        ],
      ),
    );
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
                  color: Color(0xFF8763E6),
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
              color: Color(0xFF8763E6),
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
}