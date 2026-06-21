import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/views/login_page.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

class CaretakerProfilePage extends StatefulWidget {
  final String caretakerId;
  final String? loggedUid;

  const CaretakerProfilePage({super.key, required this.caretakerId, this.loggedUid});

  @override
  State<CaretakerProfilePage> createState() => _CaretakerProfilePageState();
}



class _CaretakerProfilePageState extends State<CaretakerProfilePage> {
  Map<String, dynamic>? caretakerData;
  Map<String, dynamic>? vehicleData;
  bool isLoading = true;
  final Color primaryColor = const Color(0xFF9B59B6);
  final Color bgColor = const Color(0xFFF3E5F5); // สีพื้นหลังม่วงพาสเทลตามรูป
  final Color borderColor = const Color(
    0xFF757575,
  ); // สีขอบการ์ด (เทาเข้มเกือบดำ)

  // สถานะปฏิทิน (ตั้งค่าให้ตรงกับในรูปจำลอง)
  DateTime _focusedDay = DateTime(2024, 3, 4); // เริ่มต้นที่ มี.ค. 2024

  // จำลองข้อมูลวันที่ ว่าง (Green) และ เต็ม (Red)
  final List<int> freeDays = [
    5,
    6,
    8,
    9,
    11,
    12,
    14,
    15,
    16,
    18,
    19,
    21,
    22,
    23,
    25,
    26,
    28,
    29,
    30,
  ];
  final List<int> busyDays = [7, 10, 13, 17, 20, 24, 27, 31];

  @override
  void initState() {
    super.initState();
    loadCaretaker();
  }

  // 🎯 ฟังก์ชันสำหรับเปิดแจ้งเตือนกรณีที่ยังไม่ได้เข้าสู่ระบบ
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // ปิด Dialog
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'ไปหน้าเข้าสู่ระบบ',
                      style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: bgColor, // สีพื้นหลังม่วงพาสเทลเต็มจอ
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ข้อมูลผู้ดูแล',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      // ย้าย SingleChildScrollView ออกมาครอบนอกสุด
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Container(
              color: Color.fromARGB(255, 239, 199, 255),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 12),
                      _buildPersonalInfo(),
                      const SizedBox(height: 12),
                      _buildAddressInfo(),
                      const SizedBox(height: 12),
                      _buildVehicleInfo(),
                      const SizedBox(height: 12),
                      _buildCalendar(),
                      const SizedBox(height: 12),
                      _buildReviews(),
                      const SizedBox(height: 20),
                      _buildRequestButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      // แถบเมนูด้านล่าง
      // แถบเมนูด้านล่าง (แก้ไขเพิ่มเติมเฉพาะส่วน onTap)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 1,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        
        // 🎯 1. เพิ่มฟังก์ชัน onTap ดักเงื่อนไขที่ตรงนี้
        onTap: (index) async {
          if (index == 3) { // เมื่อกดเมนู "ญาติ" (Index ลำดับที่ 3)
            // เช็คสิทธิ์ด้วยค่า loggedUid ตัวจริงก่อน
            String? uid = widget.loggedUid;

            if (uid == null) {
              final currentUser = FirebaseAuth.instance.currentUser;
              uid = currentUser?.uid;
            }

            // 💥 ถ้าไม่ได้ล็อกอิน (ค่า uid เป็น null) บังคับเด้ง Dialog เตือนทันที
            if (uid == null) {
              _showLoginRequiredDialog();
              return;
            }

            // 🚀 ถ้าล็อกอินผ่านแล้ว ให้ดึงข้อมูลและเปิดหน้าแก้ไขประวัติ (ดึงโค้ดดักของเดิมมาทำงาน)
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );

            try {
              final snapshot = await FirebaseDatabase.instance.ref('Login/$uid').get();
              if (context.mounted) Navigator.pop(context); // ปิด Loading

              if (snapshot.exists && snapshot.value is Map) {
                final userData = Map<String, dynamic>.from(snapshot.value as Map);
                RelativeModel relative;
                Map<String, dynamic> relativeMap = {};
                
                if (userData.containsKey('Relative')) {
                  relativeMap = Map<String, dynamic>.from(userData['Relative'] as Map);
                  relative = RelativeModel(
                    relativeId: relativeMap['relativeId'] ?? '',
                    firstname: relativeMap['firstname'] ?? '',
                    lastname: relativeMap['lastname'] ?? '',
                    phonenumber: relativeMap['phonenumber'] ?? '',
                    relationship: relativeMap['relationship'] ?? '',
                    email: relativeMap['email'] ?? '',
                  );
                } else {
                  relative = RelativeModel(relativeId: '', firstname: '', lastname: '', phonenumber: '', relationship: '', email: '');
                }

                PatientModel patient;
                if (relativeMap.containsKey('Patient')) {
                  final pData = Map<String, dynamic>.from(relativeMap['Patient'] as Map);
                  patient = PatientModel(
                    patientId: pData['patientId'] ?? '',
                    patientphoto: pData['patientphoto'] ?? '',
                    firstname: pData['firstname'] ?? '',
                    lastname: pData['lastname'] ?? '',
                    phonenumber: pData['phonenumber'] ?? '',
                    gender: pData['gender'] ?? '',
                    birthdate: pData['birthdate'] != null ? DateTime.tryParse(pData['birthdate'].toString()) : null,
                    disease: pData['disease'] ?? '',
                    mobility: pData['mobility'] ?? '',
                  );
                } else {
                  patient = PatientModel(patientId: '', patientphoto: '', firstname: '', lastname: '', phonenumber: '', gender: '');
                }

                if (context.mounted) {
                  // นำทางไปหน้าแก้ไขข้อมูล
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                          builder: (context) => EditRelativeInfoPage(currentPatient: patient, currentRelative: relative, loggedUid: uid!,), //
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลประวัติในระบบ')));
                }
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
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

  // 1. ส่วนหัวโปรไฟล์
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
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
                    color: Colors.black12,
                    width: 2,
                  ), // คืนค่ากรอบเดิม
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(
                    0xFFC8E6C9,
                  ), // สีพื้นหลังเขียวพาสเทล
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

              // จุดสถานะ
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: caretakerData?['servicestatus'] == 'Online'
                      ? Colors.green
                      : Colors.grey, // สีเทาเมื่อออฟไลน์ตามรูป
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // สถานะออนไลน์
          Text(
            caretakerData?['servicestatus'] == 'Online'
                ? 'พร้อมให้บริการ'
                : 'ไม่พร้อมให้บริการ',
            style: TextStyle(
              color: caretakerData?['servicestatus'] == 'Online'
                  ? Colors.green
                  : Colors.orange, // สีส้มตามรูป
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 6),

          // ชื่อ-นามสกุล
          Text(
            '${caretakerData?['firstname'] ?? 'สมหมาย'} ${caretakerData?['lastname'] ?? 'จากมา'}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // เลขบัตรประชาชน (caretakerId)
          Text(
            '${caretakerData?['caretakerId'] ?? '1520201258787'}',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  //ฟังชั้นคำนวณอายุจากวันเกิด
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

  //ฟังชั้นแปลงวันเกิดเป็นรูปแบบวันที่ไทย (วัน/เดือน/ปี พ.ศ.)
  String thaiDate(String? birthdate) {
    if (birthdate == null || birthdate.isEmpty) return '-';

    final d = DateTime.parse(birthdate);

    return '${d.day}/${d.month}/${d.year + 543}';
  }

  // 2. ข้อมูลส่วนตัว
  Widget _buildPersonalInfo() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.person_outline, size: 24, color: Colors.black87),
              SizedBox(width: 8),
              Text(
                'ข้อมูลส่วนตัว',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
        ],
      ),
    );
  }

  // 3. ข้อมูลที่อยู่
  Widget _buildAddressInfo() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.place, color: Colors.red.shade500, size: 40),
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ข้อมูลที่อยู่',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      caretakerData?['address'] ??
                          '14 หมู่ 8        ตำบล ปัว\nอำเภอ อวน  จังหวัด น่าน   50189',
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. ข้อมูลยานพาหนะ
  Widget _buildVehicleInfo() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ยานพาหนะ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          // สไลเดอร์รูปภาพรถ
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1.5,
              ), // คืนค่ากรอบรูปดั้งเดิม
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
          // จุดไข่ปลา
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
      width: isActive ? 8 : 6,
      height: isActive ? 8 : 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.black87 : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );
  }

  // 5. ปฏิทิน
  Widget _buildCalendar() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ตารางว่าง',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: const [
                  Icon(Icons.chevron_left, size: 20, color: Colors.black54),
                  SizedBox(width: 8),
                  Text(
                    'มี.ค. 2024',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20, color: Colors.black54),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerVisible: false,
            daysOfWeekHeight: 30,
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final weekdayNames = {
                  1: 'จ',
                  2: 'อ',
                  3: 'พ',
                  4: 'พฤ',
                  5: 'ศ',
                  6: 'ส',
                  7: 'อา',
                };
                return Center(
                  child: Text(
                    weekdayNames[day.weekday]!,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                Color textColor = Colors.black87;
                if (freeDays.contains(day.day)) {
                  textColor = Colors.green.shade600;
                } else if (busyDays.contains(day.day)) {
                  textColor = Colors.red.shade500;
                }
                return Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(6.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
              outsideBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(6.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const Divider(thickness: 1),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildLegendItem(Colors.green, 'ว่าง', isOutline: true),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.red, 'เต็ม', isOutline: true),
              const SizedBox(width: 16),
              _buildLegendItem(primaryColor, 'วันนี้', isOutline: false),
            ],
          ),
        ],
      ),
    );
  }

  // ตัวแปรสำหรับรีวิวแบบดั้งเดิม
  double rating = 0;
  int reviewCount = 0;

  // 6. รีวิวล่าสุด (คืนค่ากลับเป็นโค้ดเดิม ยังไม่มีรีวิว)
  Widget _buildReviews() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รีวิวล่าสุด',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating.round() ? Icons.star : Icons.star_border,
                color: Colors.orange, // คืนค่าสีส้มเดิม
                size: 16,
              );
            }),
          ),

          const SizedBox(height: 16),

          if (reviewCount == 0)
            const Text(
              'ยังไม่มีรีวิว',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            )
          else ...[
            Text('$rating คะแนน ($reviewCount รีวิว)'),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),

            // ค่อยใส่ _buildReviewItem ตอนดึงจาก Firebase ได้จริง
          ],
        ],
      ),
    );
  }

  // 7. ปุ่มขอใช้บริการ
  Widget _buildRequestButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            // 🎯 เริ่มต้นระบบเช็กสิทธิ์ล็อกอินโดยเช็กจากค่า loggedUid ตัวจริงก่อน
            String? uid = widget.loggedUid;

            if (uid == null) {
              final currentUser = FirebaseAuth.instance.currentUser;
              uid = currentUser?.uid;
            }

            // 🎯 หากยังไม่ได้ล็อกอิน (ค่า uid เป็น null) บังคับแสดงหน้าต่างแจ้งเตือนทันที
            if (uid == null) {
              _showLoginRequiredDialog();
              return;
            }

            // --- ส่วนของเงื่อนไขการส่งคำขอแบบปกติเมื่อล็อกอินถูกต้องแล้ว (โค้ดเดิมของคุณ) ---
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('กำลังดำเนินการส่งคำขอใช้บริการ...'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: const Text(
            'ขอใช้บริการ',
            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Widget Helper สำหรับกล่องข้อมูลต่างๆ
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label, {
    required bool isOutline,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isOutline ? Colors.white : color.withOpacity(0.6),
            border: Border.all(
              color: isOutline ? color : Colors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}
