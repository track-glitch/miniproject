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
  bool isLoading = true;

  final Color primaryColor = const Color.fromARGB(255, 153, 116, 255);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;
  final Color borderColor = const Color(0xFFDDD0F0);
  final Color accentPurple = const Color(0xFFB388FF);
  final Color labelColor = const Color(0xFF7E57C2);

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

          vehicleData = caretakerData!['Vehicle'] != null
              ? Map<String, dynamic>.from(caretakerData!['Vehicle'])
              : null;

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
                      // 🌟 Profile Header รวมปุ่มขอใช้บริการขนาดมินิมอลอยู่ใต้เลขบัตร
                      _buildProfileHeader(),
                      const SizedBox(height: 12),
                      _buildPersonalInfo(),
                      const SizedBox(height: 12),
                      _buildProfessionalInfo(),
                      const SizedBox(height: 12),
                      _buildVehicleInfo(),
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

  // 🌟 Profile Header: แสดงข้อความบอกเลขบัตรประชาชน + ย้ายปุ่มไว้ใต้เลขบัตร (Minimal Style)
  Widget _buildProfileHeader() {
    String rawStatus =
        (caretakerData?['servicestatus']?.toString() ?? 'ไม่พร้อมให้บริการ')
            .trim();
    bool isAvailable =
        rawStatus.toLowerCase() == 'online' ||
        rawStatus.toLowerCase() == 'on' ||
        rawStatus == 'พร้อมให้บริการ';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF8763E6),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8763E6).withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFE8D5FF),
                  backgroundImage:
                      caretakerData?['profilephoto'] != null &&
                          caretakerData!['profilephoto'].toString().isNotEmpty
                      ? MemoryImage(
                          base64Decode(
                            caretakerData!['profilephoto']
                                .toString()
                                .replaceAll('\n', '')
                                .trim(),
                          ),
                        )
                      : null,
                  child:
                      caretakerData?['profilephoto'] == null ||
                          caretakerData!['profilephoto'].toString().isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 50,
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
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAvailable ? 'พร้อมให้บริการ' : 'ไม่พร้อมให้บริการ',
            style: TextStyle(
              color: isAvailable ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${caretakerData?['firstname'] ?? 'อัศวิน'} ${caretakerData?['lastname'] ?? 'จินดา'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF8763E6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // 🌟 เขียนบอกชัดเจนว่าเป็นเลขบัตรประชาชน
          Text(
            'เลขบัตรประชาชน: ${caretakerData?['caretakerId'] ?? '1234567891011'}',
            style: const TextStyle(
              color: Color.fromARGB(255, 85, 85, 85),
              fontSize: 13,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          
          // 🌟 ปุ่มขอใช้บริการ ดีไซน์เล็กลง ดูมินิมอล อยู่ใต้เลขบัตรประชาชน
          _buildMinimalRequestButton(),
        ],
      ),
    );
  }

  // 🌟 ฟังก์ชันสร้างปุ่ม "ขอใช้บริการ" สไตล์มินิมอล ขนาดกะทัดรัด
  Widget _buildMinimalRequestButton() {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
        label: const Text(
          'ขอใช้บริการ',
          style: TextStyle(
            fontSize: 14,
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

  String thaiDate(String? birthdate) {
    if (birthdate == null || birthdate.isEmpty) return '-';
    final d = DateTime.parse(birthdate);
    return '${d.day}/${d.month}/${d.year + 543}';
  }

  Widget _buildPersonalInfo() {
    String addressText = '-';
    if (caretakerData?['location'] != null &&
        caretakerData!['location']['address'] != null &&
        caretakerData!['location']['address'].toString().isNotEmpty) {
      addressText = caretakerData!['location']['address'].toString();
    } else if (caretakerData?['address'] != null &&
        caretakerData!['address'].toString().isNotEmpty) {
      addressText = caretakerData!['address'].toString();
    } else {
      addressText = '14 หมู่ 8 ตำบล ปัว อำเภอ อวน จังหวัด น่าน 50189';
    }

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_outline, size: 22, color: Color(0xFF9B59B6)),
              SizedBox(width: 8),
              Text(
                'ข้อมูลส่วนตัว',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF8763E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('เพศ:', caretakerData?['gender'] ?? 'ชาย'),
          _buildInfoRow(
            'อายุ:',
            calculateAge(caretakerData?['birthdate']) == '-'
                ? '35 ปี'
                : calculateAge(caretakerData?['birthdate']),
          ),
          _buildInfoRow(
            'วันเกิด:',
            thaiDate(caretakerData?['birthdate']) == '-'
                ? '21/08/2534'
                : thaiDate(caretakerData?['birthdate']),
          ),
          _buildInfoRow(
            'เบอร์โทรศัพท์:',
            caretakerData?['phonenumber'] ?? '0861940622',
          ),
          _buildInfoRow('อีเมล:', caretakerData?['email'] ?? 'somk@gmail.com'),
          _buildInfoRow('ที่อยู่:', addressText),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.work_outline, size: 22, color: Color(0xFF9B59B6)),
              SizedBox(width: 8),
              Text(
                'ประสบการณ์และการบริการ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF8763E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'ประสบการณ์:',
            caretakerData?['experience'] ?? 'ไม่ได้ระบุ',
          ),
          const SizedBox(height: 12),
          const Text(
            'รายละเอียดการให้บริการ:',
            style: TextStyle(
              color: Color(0xFF9B59B6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caretakerData?['servicedesc'] ?? 'ไม่ได้ระบุรายละเอียด',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              height: 1.5,
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
                  const Text(
                    'รถยนต์',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${vehicleData?['brand'] ?? 'Honda'} ${vehicleData?['model'] ?? 'City'}, สี${vehicleData?['color'] ?? 'ขาว'}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Builder(
                builder: (context) {
                  try {
                    final vehicle = caretakerData?['Vehicle'];
                    if (vehicle == null)
                      return const Center(
                        child: Icon(
                          Icons.directions_car,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    final photos = vehicle['vehiclephotos'];
                    if (photos == null)
                      return const Center(
                        child: Icon(
                          Icons.directions_car,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );

                    if (photos is List && photos.isNotEmpty) {
                      final base64Image = photos[0]['photo'];
                      return Image.memory(
                        base64Decode(base64Image),
                        fit: BoxFit.cover,
                      );
                    }
                    if (photos is Map && photos.isNotEmpty) {
                      final firstPhoto = (photos.values.first as Map)['photo'];
                      return Image.memory(
                        base64Decode(firstPhoto),
                        fit: BoxFit.cover,
                      );
                    }
                    return const Center(
                      child: Icon(
                        Icons.directions_car,
                        size: 80,
                        color: Colors.grey,
                      ),
                    );
                  } catch (e) {
                    return const Center(
                      child: Icon(
                        Icons.directions_car,
                        size: 80,
                        color: Colors.grey,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(true),
              _buildDot(false),
              _buildDot(false),
              _buildDot(false),
            ],
          ),
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
                vehicleData?['licenseplate'] ?? 'กข 1234 น่าน',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9B59B6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }
}