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
import 'package:intl/intl.dart';

class RelativeHomePage extends StatefulWidget {
  final String? loggedUid; // 🌟 รับค่า uid ของ User ที่ล็อกอิน
  const RelativeHomePage({super.key, this.loggedUid});

  @override
  State<RelativeHomePage> createState() => _RelativeHomePageState();
}

class _RelativeHomePageState extends State<RelativeHomePage> {
  final TextEditingController _searchController = TextEditingController();

  // ── 🎨 ชุดสีหลักของธีม ──────────
  final Color primaryColor = const Color(0xFF8763E6);
  final Color darkPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color lightPurple = const Color(0xFFECE2FE);
  final Color accentTeal = const Color(0xFF0F766E);
  final Color accentPink = const Color(0xFFBE185D);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color greyBorder = const Color(0xFFD3C2F0);

  final Color headingColor = const Color(0xFF241C2B);
  final Color successColor = const Color(0xFF15803D);
  final Color dangerColor = const Color(0xFFB91C1C);

  String _userName = '';
  DateTime? _selectedFilterDate;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // รีเฟรชหน้าจอเมื่อพิมพ์ข้อความค้นหา
    });
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    String currentUid =
        widget.loggedUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    print(currentUid);
    if (currentUid.isEmpty) return;

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
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: darkPurple,
        elevation: 0,
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
                      builder: (context) => const RelativeHomePage(),
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
                  // ชื่อหน้า (เปลี่ยนเป็น ค้นหาผู้ดูแล ให้สมเหตุสมผลกับหน้า Home)
                  Text(
                    'ค้นหาผู้ดูแล',
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
                            child: Row(
                              children: [
                                if (_selectedFilterDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Text(
                                      DateFormat(
                                        'dd/MM',
                                      ).format(_selectedFilterDate!),
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                Icon(
                                  Icons.calendar_month,
                                  color: _selectedFilterDate != null
                                      ? primaryColor
                                      : Colors.grey.shade500,
                                  size: 22,
                                ),
                                // ปุ่มกากบาทล้างวันที่
                                if (_selectedFilterDate != null)
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedFilterDate = null,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ปุ่มค้นหาใกล้ฉัน
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

            // ── รายการ (พร้อมคำนวณ Review และซ่อนคนไม่ว่าง) ───────────
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
                  Map<String, List<double>> caregiverReviewsMap = {};

                  // 🌟 ตัวแปรเก็บวันที่ไม่ว่างของอาสาแต่ละคน
                  Map<String, List<String>> busyDatesMap = {};

                  if (rootValue is Map) {
                    // 🌟 1. วนลูปกวาดหา Review ทั้งหมดของระบบมารวมไว้ก่อน
                    rootValue.forEach((userKey, userValue) {
                      if (userValue is Map && userValue['Relative'] != null) {
                        var relativeNode = userValue['Relative'];
                        if (relativeNode is Map &&
                            relativeNode['Request'] != null) {
                          var requests = relativeNode['Request'];
                          if (requests is Map) {
                            requests.forEach((reqId, reqData) {
                              if (reqData is Map &&
                                  reqData['caretakerId'] != null) {
                                // ตรวจสอบว่าคำขอนี้มีการใส่ Review ไว้หรือไม่
                                var reviewData =
                                    reqData['Review'] ?? reqData['review'];
                                if (reviewData != null) {
                                  String cId = reqData['caretakerId']
                                      .toString();
                                  double ratingScore = 0.0;
                                  var rawRating =
                                      reviewData['rating'] ??
                                      reviewData['ratingscore'];
                                  if (rawRating != null) {
                                    ratingScore =
                                        double.tryParse(rawRating.toString()) ??
                                        0.0;
                                  }

                                  String status =
                                      (reqData['requeststatus'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  if (status == 'pending' ||
                                      status == 'accepted' ||
                                      status == 'pending_advice') {
                                    String apptDateStr =
                                        reqData['appointmentdate'] ?? '';
                                    if (apptDateStr.isNotEmpty) {
                                      try {
                                        DateTime d = DateTime.parse(
                                          apptDateStr,
                                        );
                                        String formattedDate =
                                            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                                        if (!busyDatesMap.containsKey(cId))
                                          busyDatesMap[cId] = [];
                                        busyDatesMap[cId]!.add(formattedDate);
                                      } catch (e) {}
                                    }
                                  }

                                  if (!caregiverReviewsMap.containsKey(cId)) {
                                    caregiverReviewsMap[cId] = [];
                                  }
                                  caregiverReviewsMap[cId]!.add(ratingScore);
                                }
                              }
                            });
                          }
                        }
                      }
                    });

                    // 🌟 2. ดึงข้อมูล Caretaker และประกอบร่างกับคะแนน Review
                    rootValue.forEach((userUidKey, userNodeValue) {
                      if (userNodeValue is Map &&
                          userNodeValue.containsKey('Caretaker')) {
                        final caretakerRawData = userNodeValue['Caretaker'];
                        if (caretakerRawData != null) {
                          final data = Map<String, dynamic>.from(
                            caretakerRawData as Map,
                          );
                          data['id'] =
                              userUidKey; // เก็บ UID เอาไว้กดดูรายละเอียด

                          if (userNodeValue.containsKey('Vehicle')) {
                            data['vehicle'] = Map<String, dynamic>.from(
                              userNodeValue['Vehicle'],
                            );
                          }

                          // คำนวณค่าเฉลี่ยดาวจาก Map ที่เราเตรียมไว้ด้านบน
                          String idCard = data['caretakerId']?.toString() ?? '';
                          List<double> scores =
                              caregiverReviewsMap[idCard] ?? [];

                          if (scores.isEmpty) {
                            data['rating'] = 0.0;
                            data['comments'] = 0;
                          } else {
                            double sum = scores.reduce((a, b) => a + b);
                            data['rating'] = sum / scores.length;
                            data['comments'] = scores.length;
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

                  // 🌟 3. คัดกรองข้อมูล (ตัดคนไม่พร้อมทำงานทิ้ง)
                  final filteredList = caretakersList.where((data) {
                    String rawStatus =
                        (data['servicestatus']?.toString() ??
                                'ไม่พร้อมให้บริการ')
                            .trim();
                    bool isAvailable =
                        rawStatus.toLowerCase() == 'online' ||
                        rawStatus.toLowerCase() == 'on' ||
                        rawStatus == 'พร้อมให้บริการ';

                    // ถ้าไม่พร้อมให้บริการ ตัดทิ้ง (return false ทันที)
                    if (!isAvailable) return false;

                    if (_selectedFilterDate != null) {
                      String filterDateStr =
                          "${_selectedFilterDate!.year}-${_selectedFilterDate!.month.toString().padLeft(2, '0')}-${_selectedFilterDate!.day.toString().padLeft(2, '0')}";
                      String idCard = data['caretakerId']?.toString() ?? '';
                      List<String> busyDates = busyDatesMap[idCard] ?? [];
                      if (busyDates.contains(filterDateStr)) {
                        return false; // ติดคิว! ซ่อนคนนี้
                      }
                    }

                    // ค้นหาจากชื่อหรือที่อยู่
                    final name =
                        "${data['firstname'] ?? ''} ${data['lastname'] ?? ''}"
                            .toLowerCase();
                    var address = '';
                    if (data['address'] != null) {
                      address = (data['address'] ?? '').toLowerCase();
                    } else if (data['Location']['address'] != null) {
                      address = (data['Location']['address'] ?? '')
                          .toLowerCase();
                    }
                    return name.contains(searchQuery) ||
                        address.contains(searchQuery);
                  }).toList();

                  // 🌟 4. เรียงลำดับเอาคนที่ดาวเยอะๆ ขึ้นก่อน (เรียงจากมากไปน้อย)
                  filteredList.sort((a, b) {
                    return (b['rating'] as double).compareTo(
                      a['rating'] as double,
                    );
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

      // ── 🌟 Bottom Navigation Bar ───────────────────────────────────────────
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: darkPurple,
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
            // แท็บ "บ้าน" เป็น Active และกดแล้วไม่ต้องเด้งไปไหน (อยู่หน้าเดิม)
            _buildBottomNavItem(
              Icons.home_outlined,
              'บ้าน',
              true,
              onTap: () {},
            ),

            // แท็บ "ขอใช้บริการ" กดแล้วเด้งไปหน้ารายการคำขอ (ListRequestPage)
            _buildBottomNavItem(
              Icons.support_agent,
              'ขอใช้บริการ',
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
              Icons.notifications_none,
              'แจ้งเตือน',
              false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackStatusNotificationPage(
                      loggedUid: widget.loggedUid,
                    ),
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
    String firstname = data['firstname'] ?? 'ไม่ระบุ';
    String lastname = data['lastname'] ?? '';
    String fullName = '$firstname $lastname'.trim();
    String location = '';

    if (data['address'] != null) {
      location = data['address'];
    } else if (data['Location']['address'] != null) {
      location = data['Location']['address'];
    } else {
      location == 'ไม่พบข้อมูล';
    }

    String carDetail = 'ไม่ระบุ';
    if (data['Vehicle'] != null) {
      final v = Map<String, dynamic>.from(data['Vehicle'] as Map);
      String brand = v['brand'] ?? '';
      String model = v['model'] ?? '';
      carDetail = '$brand $model'.trim();
      if (carDetail.isEmpty) carDetail = 'ไม่ระบุ';
    }

    String rawStatus =
        (data['servicestatus']?.toString() ?? 'ไม่พร้อมให้บริการ').trim();
    bool isAvailable =
        rawStatus.toLowerCase() == 'online' ||
        rawStatus.toLowerCase() == 'on' ||
        rawStatus == 'พร้อมให้บริการ';
    String displayStatus = isAvailable ? 'พร้อมให้บริการ' : 'ไม่พร้อมให้บริการ';

    // 🌟 ดึงข้อมูลคะแนนรีวิวที่เราเพิ่งคำนวณมาสดๆ ร้อนๆ
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  Row(
                    children: [
                      Text(
                        '${rating.toStringAsFixed(1)} ', // โชว์ทศนิยม 1 ตำแหน่งสวยๆ
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
                        comments == 0 ? '  ยังไม่มีรีวิว' : '  $comments รีวิว',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

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
                                selectedDate: _selectedFilterDate,
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
