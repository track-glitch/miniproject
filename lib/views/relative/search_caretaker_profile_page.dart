import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
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

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color bgColor = const Color(0xFFFAFAFA);
  final Color greyBorder = const Color(0xFFE1BEE7);

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
      backgroundColor: const Color.fromARGB(255, 239, 199, 255),
      appBar: AppBar(
        title: const Text(
          'ขอใช้บริการ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_userName.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
                  // 🎯 เปลี่ยนให้กลับไปที่หน้า CaretakerSearchPage แทนแบบไม่มี Uid
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
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),
            Text(
              'ค้นหาบัญชี',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black87, width: 1.2),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText:
                              'ค้นหา ชื่อ-นามสกุล หรือ ที่อยู่ (อำเภอ จังหวัด)',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.black54,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _openFilterCalendar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.transparent,
                      child: const Icon(
                        Icons.tune,
                        color: Colors.black,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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

                  // ภายใน StreamBuilder ของ CaretakerSearchPage
                  if (rootValue is Map) {
                    rootValue.forEach((userUidKey, userNodeValue) {
                      if (userNodeValue is Map &&
                          userNodeValue.containsKey('Caretaker')) {
                        final caretakerRawData = userNodeValue['Caretaker'];
                        if (caretakerRawData != null) {
                          // ใช้ Map<String, dynamic> เพื่อแปลงข้อมูลให้ชัวร์
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

                  // จัดเรียงให้คนที่ "พร้อมให้บริการ" ขึ้นก่อน
                  filteredList.sort((a, b) {
                    // ใช้ .trim() เพื่อตัดช่องว่างที่อาจติดมากับข้อความ
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

                    if (isAvailableA && !isAvailableB) {
                      return -1; // a พร้อมให้บริการ ให้อยู่บน
                    } else if (!isAvailableA && isAvailableB) {
                      return 1; // b พร้อมให้บริการ ให้อยู่บน
                    }
                    return 0; // สถานะเหมือนกัน ไม่ต้องสลับตำแหน่ง
                  });

                  if (filteredList.isEmpty) {
                    return const Center(child: Text('ไม่พบผลลัพธ์การค้นหา'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
        decoration: BoxDecoration(color: primaryColor),
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
              onTap: () {},
            ),
            _buildBottomNavItem(
              Icons.notifications_none,
              'แจ้งเตือน',
              false,
              onTap: () {},
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
    String firstname = data['firstname'] ?? 'ไม่ระบุ';
    String lastname = data['lastname'] ?? '';
    String fullName = "$firstname $lastname".trim();
    String location = data['address'] ?? 'ไม่ระบุ';
    String gender = data['gender'] ?? 'ไม่ระบุ';

    String carDetail = 'ไม่ระบุ';
    if (data['vehicle'] != null) {
      final v = Map<String, dynamic>.from(data['vehicle'] as Map);
      String brand = v['brand'] ?? '';
      String model = v['model'] ?? '';
      carDetail = "$brand $model".trim();
      if (carDetail.isEmpty) carDetail = 'ไม่ระบุ';
    }

    // 1. ดึงข้อมูลสถานะดิบจากฐานข้อมูล
    String rawStatus =
        (data['servicestatus']?.toString() ?? 'ไม่พร้อมให้บริการ').trim();

    // 2. เช็คเงื่อนไขว่าพร้อมให้บริการหรือไม่ (เผื่อระบบเก็บเป็น online หรือคำอื่นๆ)
    bool isAvailable =
        (rawStatus.toLowerCase() == 'online' || 
        rawStatus.toLowerCase() == 'on' || 
        rawStatus == 'พร้อมให้บริการ');

    // 3. กำหนดข้อความภาษาไทยที่จะแสดงผลตายตัว
    String displayStatus = isAvailable ? 'พร้อมให้บริการ' : 'ไม่พร้อมให้บริการ';

    double rating = data['rating'] != null
        ? (data['rating'] as num).toDouble()
        : 0.0;
    int comments = data['comments'] ?? 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
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
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // 4. ส่วนของ Tag สถานะที่ปรับปรุงดีไซน์ใหม่
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // ปรับสีพื้นหลังให้อ่อนลงเพื่อให้ตัวหนังสืออ่านง่าย
                        color: isAvailable
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        // เพิ่มขอบ (Border) สีเดียวกับตัวหนังสือ
                        border: Border.all(
                          color: isAvailable
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFF44336),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // เพิ่มไอคอนวงกลมติ๊กถูก / กากบาท
                          Icon(
                            isAvailable ? Icons.check_circle : Icons.cancel,
                            color: isAvailable
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFF44336),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayStatus, // แสดงผลเป็นภาษาไทยเสมอ
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              // สีตัวหนังสือปรับให้เข้มขึ้นเพื่อให้ตัดกับสีพื้นหลัง
                              color: isAvailable
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$rating ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange,
                          size: 14,
                        );
                      }),
                    ),
                    Text(
                      comments == 0
                          ? '  ยังไม่มีรีวิว'
                          : '  $comments คอมเมนต์',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'พื้นที่ให้บริการ: $location',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'ยี่ห้อรถ: $carDetail',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
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
                  child: SizedBox(
                    height: 28,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
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
                      child: const Text(
                        'ดูรายละเอียด',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
