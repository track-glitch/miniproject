import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:miniproject/views/relative/list_request_page.dart';
import 'package:miniproject/views/relative/track_status_notification_page.dart';
import 'package:miniproject/views/relative/view_caretaker_profile_page.dart';
import 'package:miniproject/views/login_page.dart';
import 'dart:convert';

class CaretakerSearchPage extends StatefulWidget {
  final String? loggedUid;
  const CaretakerSearchPage({super.key, this.loggedUid});

  @override
  State<CaretakerSearchPage> createState() => _CaretakerSearchPageState();
}

class _CaretakerSearchPageState extends State<CaretakerSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  // ── 🎨 ชุดสีหลักของธีม (รีโทนให้ใกล้เคียงภาพ Calmara ที่แนบมา) ──────────
  // ค่าสีด้านล่างนี้สุ่มมาจากพิกเซลจริงในภาพอ้างอิง: ปุ่ม Login/Get Started,
  // พื้นหลังอ่อนๆ, ช่องค้นหา และตัวอักษรหัวข้อ เพื่อให้โทนสีออกมา "เบา สะอาด
  // และนุ่มนวล" แบบเดียวกับภาพ แทนม่วงสดจัดแบบเดิม
  final Color primaryColor = const Color(
    0xFF8763E6,
  ); // ม่วงหลัก (จากปุ่ม Login/Get Started ในภาพ)
  final Color darkPurple = const Color.fromARGB(
    255,
    153,
    116,
    255,
  ); // ม่วงเข้ม สำหรับ AppBar/BottomNav/เงา
  final Color lightPurple = const Color(
    0xFFECE2FE,
  ); // ม่วงอ่อนมาก (จากช่องค้นหาในภาพ)
  final Color accentTeal = const Color(0xFF0F766E); // Teal เข้มขึ้นเล็กน้อย
  final Color accentPink = const Color(0xFFBE185D); // Pink accent
  final Color bgColor = const Color.fromARGB(
    255,
    225,
    202,
    255,
  ); // พื้นหลัง — ม่วงอ่อน "เห็นชัด" ว่าเป็นม่วง ไม่จางจนกลายเป็นขาว
  final Color greyBorder = const Color(
    0xFFD3C2F0,
  ); // ขอบ card — เข้มขึ้นพอให้แยกจากพื้นหลังได้ชัด

  // ── 🎨 สีที่เพิ่มเข้ามาเพื่อ "คุมโทน" ทั้งหน้าให้เป็นชุดเดียวกัน ─────────
  // เดิมในหน้านี้มีสี hex ฝังตรง ๆ กระจายอยู่หลายที่ (เช่น 0xFF5B21B6, 0xFFDDD0F0,
  // 0xFFC4B5FD ฯลฯ) ซึ่งใกล้เคียงกับชุดสีด้านบนแต่ไม่ใช่ตัวเดียวกัน ทำให้สีหลุดโทน
  // จึงรวบเป็น 3 สีหลักนี้ แล้วไปแทนที่สีฝังทั้งหมดในไฟล์ให้ใช้ชุดสีเดียวกัน
  final Color headingColor = const Color(
    0xFF241C2B,
  ); // เข้มเกือบดำ (จากตัวอักษร "Calmara" ในภาพ) ดูคลีนกว่าม่วงจัด
  final Color successColor = const Color(
    0xFF15803D,
  ); // เขียว สำหรับสถานะ "พร้อมให้บริการ"
  final Color dangerColor = const Color(
    0xFFB91C1C,
  ); // แดง สำหรับสถานะ "ไม่พร้อมให้บริการ"

  String _userName = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    String currentUid =
        widget.loggedUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentUid.isEmpty) {
      return; // ถ้าไม่ได้ล็อกอิน (Guest) ไม่ต้องดึงข้อมูลชื่อ
    }

    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login').get();
      if (snapshot.exists && snapshot.value is Map) {
        final allUsers = Map<String, dynamic>.from(snapshot.value as Map);

        for (var key in allUsers.keys) {
          bool isMatch = false;
          if (key == currentUid) {
            isMatch = true;
          } else {
            var childData = allUsers[key];
            if (childData is Map) {
              var relNode = childData['Relative'];
              if (childData['uid'] == currentUid ||
                  (relNode is Map && relNode['relativeId'] == currentUid)) {
                isMatch = true;
              }
            }
          }

          if (isMatch) {
            var childData = allUsers[key];
            if (childData is Map && childData.containsKey('Relative')) {
              var relNode = Map<String, dynamic>.from(
                childData['Relative'] as Map,
              );
              setState(() {
                _userName =
                    "${relNode['firstname'] ?? ''} ${relNode['lastname'] ?? ''}"
                        .trim();
              });
            }
            break;
          }
        }
      }
    } catch (e) {
      print("Error fetching username: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterCalendar() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: darkPurple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selectedDate != null) {}
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
                Icon(Icons.lock_person_outlined, size: 75, color: darkPurple),
                const SizedBox(height: 20),
                Text(
                  'กรุณาเข้าสู่ระบบก่อนใช้งาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPurple,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'คุณต้องลงชื่อเข้าใช้งานในระบบก่อน จึงจะสามารถส่งคำขอผู้ดูแลและแก้ไขข้อมูลได้',
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor, // ✅ ใช้สีจากชุดธีมแทนเลข hex ที่หลุดโทนเดิม
      appBar: AppBar(
        backgroundColor: darkPurple, // ✅ คุมโทนเดียวกับ bottomNavigationBar
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        centerTitle: false,
        actions: [
          if (_userName.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
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
                      const Icon(Icons.person, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _userName,
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
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'ตกลง',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CaretakerSearchPage(),
                    ),
                    (route) => false,
                  );
                }
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: ชื่อหน้า + ช่องค้นหา + ปุ่มใกล้ฉัน ───────────────
            // ✅ ห่อด้วย Container ไล่เฉดสี (gradient) เพื่อให้ส่วนหัวดูมีมิติ
            //    และคุมโทนเดียวกับชุดสีหลักของแอป (ไม่กระทบลอจิกใด ๆ ด้านล่าง)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [lightPurple, bgColor],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Column(
                children: [
                  // ชื่อหน้า
                  Text(
                    'ขอใช้บริการ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ช่องค้นหา
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: greyBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(
                          Icons.search_rounded,
                          color: primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  'ค้นหา ชื่อ-นามสกุล หรือ ที่อยู่ (อำเภอ จังหวัด)',
                              hintStyle: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _openFilterCalendar,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.calendar_month,
                              color: Colors.grey.shade500,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ปุ่มค้นหาใกล้ฉัน
                  // ✅ ปรับให้สวยขึ้น: ไล่เฉดสี + เงา + ระยะกดนิ้วใหญ่ขึ้น + เอฟเฟกต์ ripple
                  //    (ตัวฟังก์ชัน onTap ยังเป็น TODO เดิม ไม่แก้ไขลอจิกใด ๆ)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          // TODO: เชื่อมต่อ geolocator
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, darkPurple],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.my_location_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'ค้นหาบริเวณใกล้ฉัน',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── รายการ ────────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('Login').onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('เกิดข้อผิดพลาดในการดึงข้อมูล'),
                    );
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(
                      child: Text('ไม่พบข้อมูลผู้ดูแลในระบบ'),
                    );
                  }

                  final dynamic rootValue = snapshot.data!.snapshot.value;
                  List<Map<String, dynamic>> caretakersList = [];

                  if (rootValue is Map) {
                    rootValue.forEach((userUidKey, userNodeValue) {
                      if (userNodeValue is Map &&
                          userNodeValue.containsKey('Caretaker')) {
                        final caretakerRawData = userNodeValue['Caretaker'];
                        if (caretakerRawData != null) {
                          final data = Map<String, dynamic>.from(
                            caretakerRawData as Map,
                          );
                          data['id'] = userUidKey;

                          if (userNodeValue.containsKey('Vehicle')) {
                            data['vehicle'] = Map<String, dynamic>.from(
                              userNodeValue['Vehicle'],
                            );
                          }
                          caretakersList.add(data);
                        }
                      }
                    });
                  }

                  if (caretakersList.isEmpty) {
                    return const Center(
                      child: Text('ไม่พบข้อมูลผู้ดูแลระบบในคลังข้อมูล'),
                    );
                  }

                  final searchQuery = _searchController.text.toLowerCase();
                  final filteredList = caretakersList.where((data) {
                    final name =
                        "${data['firstname'] ?? ''} ${data['lastname'] ?? ''}"
                            .toLowerCase();
                    final address = (data['address'] ?? '').toLowerCase();
                    return name.contains(searchQuery) ||
                        address.contains(searchQuery);
                  }).toList();

                  filteredList.sort((a, b) {
                    String statusA = (a['servicestatus']?.toString() ?? '')
                        .trim();
                    String statusB = (b['servicestatus']?.toString() ?? '')
                        .trim();
                    bool isAvailableA =
                        (statusA.toLowerCase() == 'online' ||
                        statusA.toLowerCase() == 'on' ||
                        statusA == 'พร้อมให้บริการ');
                    bool isAvailableB =
                        (statusB.toLowerCase() == 'online' ||
                        statusB.toLowerCase() == 'on' ||
                        statusB == 'พร้อมให้บริการ');
                    if (isAvailableA && !isAvailableB)
                      return -1;
                    else if (!isAvailableA && isAvailableB)
                      return 1;
                    return 0;
                  });

                  if (filteredList.isEmpty) {
                    return const Center(child: Text('ไม่พบผลลัพธ์การค้นหา'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final data = filteredList[index];
                      return _buildCaretakerCard(data, data['id']);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: darkPurple, // ✅ คุมโทนเดียวกับ AppBar
          boxShadow: [
            BoxShadow(
              color: darkPurple.withOpacity(0.27),
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
              onTap: () {},
            ),
            _buildBottomNavItem(
              Icons.support_agent,
              'ขอใช้บริการ',
              true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListRequestPage(),
                  ),
                );
              },
            ),
            _buildBottomNavItem(
              Icons.notifications_none,
              'แจ้งเตือน',
              false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrackStatusNotificationPage(),
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
                      Navigator.push(
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ไม่พบข้อมูลประวัติ (กรุณาลองเข้าสู่ระบบใหม่อีกครั้ง)',
                          ),
                        ),
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
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaretakerCard(Map<String, dynamic> data, String docId) {
    // ── ข้อมูลพื้นฐาน ──────────────────────────────────────────────────────
    String firstname = data['firstname'] ?? 'ไม่ระบุ';
    String lastname = data['lastname'] ?? '';
    String fullName = '';
    String location = 'ไม่ระบุ';
    if (data['Location'] != null) {
      location = data['Location']['address'] ?? 'ไม่ระบุ';
    }
    String gender = data['gender'] ?? 'ไม่ระบุ';
    if (gender == "ชาย") {
      fullName = 'นาย $firstname $lastname'.trim();
    } else if (gender == "หญิง") {
      fullName = 'นาง $firstname $lastname'.trim();
    } else {
      fullName = 'คุณ $firstname $lastname'.trim();
    }
    String carDetail = 'ไม่ระบุ';
    if (data['Vehicle'] != null) {
      final v = Map<String, dynamic>.from(data['Vehicle'] as Map);
      String brand = v['brand'] ?? '';
      String model = v['model'] ?? '';
      carDetail = '$brand $model'.trim();
      if (carDetail.isEmpty) carDetail = 'ไม่ระบุ';
    }

    // ── สถานะ ───────────────────────────────────────────────────────────────
    String rawStatus =
        (data['servicestatus']?.toString() ?? 'ไม่พร้อมให้บริการ').trim();
    bool isAvailable =
        rawStatus.toLowerCase() == 'online' ||
        rawStatus.toLowerCase() == 'on' ||
        rawStatus == 'พร้อมให้บริการ';
    String displayStatus = isAvailable ? 'พร้อมให้บริการ' : 'ไม่พร้อมให้บริการ';

    // ── คะแนน ───────────────────────────────────────────────────────────────
    double rating = data['rating'] != null
        ? (data['rating'] as num).toDouble()
        : 0.0;
    int comments = data['comments'] ?? 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: darkPurple.withOpacity(0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── รูปโปรไฟล์ ──────────────────────────────────────────────
            CircleAvatar(
              radius: 30,
              backgroundColor: lightPurple,
              backgroundImage:
                  data['profilephoto'] != null &&
                      data['profilephoto'].toString().isNotEmpty
                  ? MemoryImage(
                      base64Decode(
                        data['profilephoto']
                            .toString()
                            .replaceAll('\n', '')
                            .trim(),
                      ),
                    )
                  : null,
              child:
                  data['profilephoto'] == null ||
                      data['profilephoto'].toString().isEmpty
                  ? Icon(Icons.person, size: 28, color: primaryColor)
                  : null,
            ),
            const SizedBox(width: 14),

            // ── ข้อมูลด้านขวา ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อ + badge สถานะ
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: headingColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? successColor.withOpacity(0.12)
                              : dangerColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isAvailable
                                ? successColor.withOpacity(0.5)
                                : dangerColor.withOpacity(0.45),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAvailable ? Icons.check_circle : Icons.cancel,
                              size: 12,
                              color: isAvailable ? successColor : dangerColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              displayStatus,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isAvailable ? successColor : dangerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // ดาว + คอมเมนต์
                  Row(
                    children: [
                      Text(
                        '$rating ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF555555),
                        ),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < rating.floor() ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFBBF24),
                            size: 14,
                          );
                        }),
                      ),
                      Text(
                        comments == 0
                            ? '  ยังไม่มีรีวิว'
                            : '  $comments คอมเมนต์',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ที่อยู่
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: primaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'พื้นที่ให้บริการ: $location',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // รถ
                  Row(
                    children: [
                      Icon(Icons.directions_car, size: 13, color: primaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'ยี่ห้อรถ: $carDetail',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ปุ่มดูรายละเอียด
                  // ✅ ปรับเป็นปุ่มไล่เฉดสี (gradient) + เงา ให้เข้าธีมเดียวกับปุ่ม "ค้นหาบริเวณใกล้ฉัน"
                  //    onPressed เดิมเปลี่ยนเป็น onTap แต่เนื้อโค้ดข้างใน (Navigator.push) เหมือนเดิมทุกบรรทัด
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CaretakerProfilePage(
                                caretakerId: data['id'],
                                loggedUid:
                                    widget.loggedUid ??
                                    FirebaseAuth.instance.currentUser?.uid,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, darkPurple],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.30),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'ดูรายละเอียด',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
