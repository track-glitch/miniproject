import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:miniproject/views/relative/list_request_page.dart';
import 'package:miniproject/views/relative/view_caretaker_profile_page.dart';
import 'package:miniproject/views/login_page.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class RelativeHomePage extends StatefulWidget {
  final String? loggedUid;
  const RelativeHomePage({super.key, this.loggedUid});

  @override
  State<RelativeHomePage> createState() => _RelativeHomePageState();
}

class _RelativeHomePageState extends State<RelativeHomePage> {
  final TextEditingController _searchController = TextEditingController();

  // ── 🎨 ชุดสีหลักของธีม ──────────
  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF9B59B6);
  final Color lightPurple = const Color(0xFFECE2FE);
  final Color accentTeal = const Color(0xFF0F766E);
  final Color accentPink = const Color(0xFFBE185D);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color greyBorder = const Color(0xFFD3C2F0);

  final Color headingColor = const Color(0xFF241C2B);
  final Color successColor = const Color(0xFF15803D);
  final Color dangerColor = const Color(0xFFB91C1C);

  String _userName = '';
  String _userProfilePhoto = '';
  DateTime? _selectedFilterDate;

  // 🌟 พิกัดตำแหน่งของผู้ป่วย (ใช้คำนวณระยะห่าง)
  double? _patientLat;
  double? _patientLng;

  List<dynamic> provinceData = [];
  List<dynamic> districtData = [];
  List<dynamic> subdistrictsData = [];
  List<String> _myBookedDates = [];

  final Geocoding geocoding = Geocoding();

  // 🌟 ระบบ Pagination
  final ScrollController _scrollController = ScrollController();
  final int _perPage = 5;
  int _currentPage = 1;
  int _currentFilteredLength = 0;

  late Stream<DatabaseEvent> _loginStream;

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

  // 🌟 ฟังก์ชันรวมคำนำหน้า + ชื่อ + นามสกุล พร้อมเว้นวรรค 1 เคาะหลังคำนำหน้า
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

  // 🌟 ฟังก์ชันช่วยดึงพิกัดจาก Map รองรับหลายคีย์
  double? _extractCoordinate(Map? map, List<String> keys) {
    if (map == null) return null;
    for (var k in keys) {
      if (map[k] != null) {
        var val = double.tryParse(map[k].toString());
        if (val != null) return val;
      }
    }
    if (map['Location'] is Map) {
      for (var k in keys) {
        if (map['Location'][k] != null) {
          var val = double.tryParse(map['Location'][k].toString());
          if (val != null) return val;
        }
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loginStream = FirebaseDatabase.instance.ref('Login').onValue;

    _searchController.addListener(() {
      setState(() {
        _currentPage = 1;
      });
    });

    _loadUserNameAndLocation();
    loadThailandData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        if ((_currentPage * _perPage) < _currentFilteredLength) {
          setState(() {
            _currentPage++;
          });
        }
      }
    });
  }

  Future<void> _loadUserNameAndLocation() async {
    String currentUid = widget.loggedUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
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
              var relNode = Map<String, dynamic>.from(childData['Relative'] as Map);

              // 🌟 เช็ค activePatientNode ว่าเลือกผู้ป่วยคนไหนอยู่
              String activeNode = relNode['activePatientNode']?.toString() ?? 'Patient';
              var patientNode = relNode[activeNode] ?? relNode['Patient'];

              setState(() {
                if (patientNode != null && patientNode is Map) {
                  _userName = formatFullNameWithTitle(
                    gender: patientNode['gender']?.toString(),
                    firstname: patientNode['firstname']?.toString(),
                    lastname: patientNode['lastname']?.toString(),
                  );
                } else {
                  _userName = formatFullNameWithTitle(
                    gender: relNode['gender']?.toString(),
                    firstname: relNode['firstname']?.toString(),
                    lastname: relNode['lastname']?.toString(),
                  );
                }

                String rawPhoto = '';
                if (patientNode != null && patientNode['patientphoto'] != null) {
                  rawPhoto = patientNode['patientphoto'].toString();
                } else {
                  rawPhoto = relNode['profilephoto']?.toString() ?? '';
                }

                _userProfilePhoto = rawPhoto
                    .replaceAll('\n', '')
                    .replaceAll('\r', '')
                    .replaceAll(' ', '')
                    .trim();
                int pad = _userProfilePhoto.length % 4;
                if (pad > 0) _userProfilePhoto += '=' * (4 - pad);
              });

              // 🌟 ค้นหาพิกัดตำแหน่งของผู้ป่วย (คนที่เลือกอยู่)
              double? pLat = _extractCoordinate(patientNode is Map ? patientNode : null, ['latitude', 'lat']) ??
                  _extractCoordinate(relNode, ['latitude', 'lat']);
              double? pLng = _extractCoordinate(patientNode is Map ? patientNode : null, ['longitude', 'lng', 'long']) ??
                  _extractCoordinate(relNode, ['longitude', 'lng', 'long']);

              if (pLat == null || pLng == null) {
                String pAddress = (patientNode is Map ? patientNode['address'] : null)?.toString() ??
                    relNode['address']?.toString() ??
                    '';
                if (pAddress.trim().isNotEmpty) {
                  try {
                    List<Location> locs = await geocoding.locationFromAddress(pAddress);
                    if (locs.isNotEmpty) {
                      pLat = locs.first.latitude;
                      pLng = locs.first.longitude;
                    }
                  } catch (_) {}
                }
              }

              if (pLat == null || pLng == null) {
                try {
                  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                  if (serviceEnabled) {
                    LocationPermission permission = await Geolocator.checkPermission();
                    if (permission == LocationPermission.whileInUse ||
                        permission == LocationPermission.always) {
                      Position pos = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.medium,
                      );
                      pLat = pos.latitude;
                      pLng = pos.longitude;
                    }
                  }
                } catch (_) {}
              }

              setState(() {
                _patientLat = pLat;
                _patientLng = pLng;
              });

              _myBookedDates.clear();
              if (relNode.containsKey('Request')) {
                var requests = relNode['Request'];
                if (requests is Map) {
                  requests.forEach((reqId, reqData) {
                    if (reqData is Map) {
                      String status = (reqData['requeststatus'] ?? '').toString().toLowerCase();
                      if (status == 'pending' || status == 'accepted' || status == 'pending_advice') {
                        String dateStr = reqData['appointmentdate'] ?? '';
                        if (dateStr.isNotEmpty) {
                          try {
                            DateTime d = DateTime.parse(dateStr);
                            String formattedDate =
                                "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                            _myBookedDates.add(formattedDate);
                          } catch (_) {}
                        }
                      }
                    }
                  });
                }
              }
            }
            break;
          }
        }
      }
    } catch (e) {
      print("Error fetching username or location: $e");
    }
  }

  // 🌟 ข้อ 5: ห้ามเลือกวันที่ปัจจุบัน (firstDate เริ่มต้นจากวันพรุ่งนี้เป็นต้นไป)
  void _openFilterCalendar() async {
    DateTime now = DateTime.now();
    DateTime tomorrow = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 2)); // 🌟 วันพรุ่งนี้

    DateTime initial = _selectedFilterDate ?? tomorrow;
    if (initial.isBefore(tomorrow)) {
      initial = tomorrow;
    }

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: tomorrow, // 🌟 ห้ามเลือกวันที่ปัจจุบัน
      lastDate: DateTime(now.year + 2, 12, 31),
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

    if (selectedDate != null) {
      setState(() {
        _selectedFilterDate = selectedDate;
        _currentPage = 1;
      });
    }
  }

  Future<void> loadThailandData() async {
    String jsonString = await rootBundle.loadString(
      'assets/data/provinces.json',
    );
    provinceData = jsonDecode(jsonString) as List<dynamic>;

    jsonString = await rootBundle.loadString('assets/data/districts.json');
    districtData = jsonDecode(jsonString) as List<dynamic>;

    jsonString = await rootBundle.loadString('assets/data/subdistricts.json');
    subdistrictsData = jsonDecode(jsonString) as List<dynamic>;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showPricingDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'รายละเอียดค่าใช้จ่าย',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: headingColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),
                Row(
                  children: [
                    Icon(Icons.style, size: 18, color: darkPurple),
                    const SizedBox(width: 6),
                    Text(
                      'อัตราค่าบริการแพ็กเกจ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '• ครึ่งวัน (4 ชั่วโมง): 600 บาท/ครั้ง',
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• เต็มวัน (8 ชั่วโมง): 1,000 บาท/ครั้ง',
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• เกินเวลาที่กำหนด: คิดเพิ่มชั่วโมงละ 150 บาท',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• ค่าบริการคิดตามแพ็กเกจที่เลือกในการจอง 1 ครั้ง',
                        style: TextStyle(fontSize: 12.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 18,
                      color: darkPurple,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ค่าเดินทางเพิ่มเติม',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text(
                    'หากจุดรับส่งหรือพื้นที่ใช้บริการอยู่นอกเหนือเขตอำเภอที่ผู้ดูแลกำหนด จะคิดค่าเดินทางเพิ่มเติม กิโลเมตรละ 10 บาท โดยคำนวณตามระยะทางจริงจากระบบแอปพลิเคชัน',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'เข้าใจแล้ว',
                      style: TextStyle(
                        fontSize: 14,
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

  void _showServiceStepsModal() {
    final List<Map<String, dynamic>> serviceSteps = [
      {
        'step': '1',
        'title': 'รับผู้ป่วยจากที่พัก',
        'desc': 'ผู้ดูแลเดินทางไปรับถึงบ้าน ช่วยพยุงและพาขึ้นรถอย่างปลอดภัย',
        'icon': Icons.home_filled,
      },
      {
        'step': '2',
        'title': 'เดินทางไปโรงพยาบาล',
        'desc': 'ขับรถพาผู้ป่วยไปโรงพยาบาล และช่วยพาเข้าจุดบริการ',
        'icon': Icons.directions_car_filled,
      },
      {
        'step': '3',
        'title': 'ดูแลตลอดการพบแพทย์',
        'desc':
            'ช่วยลงทะเบียน อยู่เป็นเพื่อนหน้าห้องตรวจ เดินเรื่องชำระเงิน และรับยา',
        'icon': Icons.local_hospital,
      },
      {
        'step': '4',
        'title': 'ส่งกลับถึงที่พักอย่างปลอดภัย',
        'desc': 'พาผู้ป่วยเดินทางกลับ ส่งถึงบ้านโดยสวัสดิภาพ และจบงานบริการ',
        'icon': Icons.check_circle,
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.volunteer_activism_rounded,
                    color: primaryColor,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ขั้นตอนการให้บริการ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'ผู้ดูแลจะคอยดูแลและช่วยเหลือตลอดการเดินทาง',
                style: TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
              const Divider(height: 24),
              ...serviceSteps.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: lightPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${item['step']}. ${item['title']}",
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item['desc'] as String,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'เข้าใจแล้ว',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, authSnapshot) {
              final User? currentUser = authSnapshot.data;
              final String effectiveUid =
                  widget.loggedUid ?? currentUser?.uid ?? '';
              final bool isLoggedIn = effectiveUid.isNotEmpty;

              if (!isLoggedIn) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white38, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.account_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_userName.isNotEmpty)
                    Padding(
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
                            CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              backgroundImage: _userProfilePhoto.isNotEmpty
                                  ? MemoryImage(base64Decode(_userProfilePhoto))
                                  : null,
                              child: _userProfilePhoto.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
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
                            content: const Text(
                              'คุณต้องการออกจากระบบใช่หรือไม่?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'ยกเลิก',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
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
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                children: [
                  Text(
                    'ค้นหาผู้ดูแล',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🌟 ข้อ 1: แยกกล่องเลือกวันที่ออกมาโดยเฉพาะ
                  InkWell(
                    onTap: _openFilterCalendar,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedFilterDate != null
                              ? primaryColor
                              : greyBorder,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: _selectedFilterDate != null
                                ? primaryColor
                                : Colors.grey.shade600,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'วันที่ต้องการรับบริการ (นัดหมาย)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedFilterDate != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(_selectedFilterDate!)
                                      : 'แตะเพื่อเลือกวันที่ (เลือกได้ตั้งแต่พรุ่งนี้)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _selectedFilterDate != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _selectedFilterDate != null
                                        ? primaryColor
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedFilterDate != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFilterDate = null;
                                  _currentPage = 1;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🌟 ช่องค้นหา (แยกออกมาเดี่ยวๆ สามารถพิมพ์ค้นหาได้ทันที)
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: greyBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.08),
                          blurRadius: 6,
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
                              hintText: 'ค้นหาด้วยชื่อผู้ดูแล หรือ ที่อยู่...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.info_outline, color: Colors.red, size: 15),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'แนะนำให้ส่งคำขอล่วงหน้าก่อน 3 วันเพื่อให้ผู้ดูแลมีเวลาเตรียมตัว',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🌟 ข้อ 3: เอาปุ่มค้นหาใกล้ฉันออก เหลือเฉพาะปุ่มข้อมูลที่เป็นประโยชน์
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: _showServiceStepsModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 9,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(
                                    0xFF22C55E,
                                  ).withOpacity(0.5),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF22C55E,
                                    ).withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.format_list_bulleted_rounded,
                                    color: Color(0xFF16A34A),
                                    size: 15,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'ขั้นตอนการทำงาน',
                                      style: TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: _showPricingDetailsDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 9,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(
                                    0xFFF59E0B,
                                  ).withOpacity(0.5),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.payments_outlined,
                                    color: Color(0xFFD97706),
                                    size: 15,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'รายละเอียดค่าใช้จ่าย',
                                      style: TextStyle(
                                        color: Color(0xFFD97706),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _loginStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
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
                  Map<String, List<Map<String, dynamic>>> caregiverReviewsMap =
                      {};
                  Map<String, List<String>> busyDatesMap = {};
                  Map<String, int> completedServicesMap = {};

                  if (rootValue is Map) {
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
                                String cId = reqData['caretakerId'].toString();
                                String status = (reqData['requeststatus'] ?? '')
                                    .toString()
                                    .toLowerCase();

                                if (status == 'pending' ||
                                    status == 'accepted' ||
                                    status == 'pending_advice') {
                                  String apptDateStr =
                                      reqData['appointmentdate'] ?? '';
                                  if (apptDateStr.isNotEmpty) {
                                    try {
                                      DateTime d = DateTime.parse(apptDateStr);
                                      String formattedDate =
                                          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                                      if (!busyDatesMap.containsKey(cId))
                                        busyDatesMap[cId] = [];
                                      busyDatesMap[cId]!.add(formattedDate);
                                    } catch (e) {}
                                  }
                                }

                                if (status == 'completed' ||
                                    status == 'success' ||
                                    status == 'pending_advice' ||
                                    reqData['Review'] != null) {
                                  completedServicesMap[cId] =
                                      (completedServicesMap[cId] ?? 0) + 1;
                                }

                                var reviewData =
                                    reqData['Review'] ?? reqData['review'];
                                if (reviewData != null && reviewData is Map) {
                                  double ratingScore = 0.0;
                                  var rawRating =
                                      reviewData['rating'] ??
                                      reviewData['ratingscore'];
                                  if (rawRating != null)
                                    ratingScore =
                                        double.tryParse(rawRating.toString()) ??
                                        0.0;

                                  String commentStr =
                                      reviewData['comment']?.toString() ?? '';
                                  String reviewDateStr =
                                      reviewData['reviewdate']?.toString() ??
                                      DateTime.now().toIso8601String();

                                  String reviewerGender =
                                      (relativeNode['Patient']?['gender'] ??
                                              relativeNode['gender'] ??
                                              '')
                                          .toString();
                                  String rFirstname =
                                      (relativeNode['firstname'] ?? '')
                                          .toString();
                                  String rLastname =
                                      (relativeNode['lastname'] ?? '')
                                          .toString();

                                  String reviewerName = formatFullNameWithTitle(
                                    gender: reviewerGender,
                                    firstname: rFirstname,
                                    lastname: rLastname,
                                  );

                                  if (reviewerName.isEmpty ||
                                      reviewerName == 'ไม่ระบุ') {
                                    reviewerName = 'ผู้ใช้บริการ';
                                  }

                                  String reviewerImage =
                                      relativeNode['profilephoto']
                                          ?.toString() ??
                                      relativeNode['Patient']?['patientphoto']
                                          ?.toString() ??
                                      '';

                                  if (!caregiverReviewsMap.containsKey(cId))
                                    caregiverReviewsMap[cId] = [];

                                  caregiverReviewsMap[cId]!.add({
                                    'ratingscore': ratingScore,
                                    'comment': commentStr,
                                    'reviewdate': reviewDateStr,
                                    'reviewerName': reviewerName,
                                    'reviewerImage': reviewerImage,
                                  });
                                }
                              }
                            });
                          }
                        }
                      }
                    });

                    rootValue.forEach((userUidKey, userNodeValue) {
                      if (userNodeValue is Map &&
                          userNodeValue.containsKey('Caretaker')) {
                        String accountStatus = (userNodeValue['Caretaker']
                                    ['accountstatus']
                                ?.toString() ??
                            '')
                            .trim()
                            .toLowerCase();

                        if (accountStatus == 'suspended') {
                          return;
                        }

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

                          String idCard = data['caretakerId']?.toString() ?? '';
                          List<Map<String, dynamic>> reviewList =
                              caregiverReviewsMap[idCard] ?? [];

                          data['serviceCount'] =
                              completedServicesMap[idCard] ?? 0;
                          data['reviewsList'] = reviewList;

                          if (reviewList.isEmpty) {
                            data['rating'] = 0.0;
                            data['comments'] = 0;
                          } else {
                            double sum = reviewList.fold(
                              0.0,
                              (prev, item) =>
                                  prev + (item['ratingscore'] as double),
                            );
                            data['rating'] = sum / reviewList.length;
                            data['comments'] = reviewList.length;
                          }

                          // 🌟 ข้อ 2: คำนวณระยะห่างระหว่างผู้ป่วยและผู้ดูแล
                          double? cLat = _extractCoordinate(
                                  data, ['latitude', 'lat']) ??
                              _extractCoordinate(
                                  userNodeValue, ['latitude', 'lat']);
                          double? cLng = _extractCoordinate(
                                  data, ['longitude', 'lng', 'long']) ??
                              _extractCoordinate(
                                  userNodeValue, ['longitude', 'lng', 'long']);

                          if (cLat != null &&
                              cLng != null &&
                              _patientLat != null &&
                              _patientLng != null) {
                            double distInMeters = Geolocator.distanceBetween(
                              _patientLat!,
                              _patientLng!,
                              cLat,
                              cLng,
                            );
                            data['distanceKm'] = distInMeters / 1000.0;
                          } else {
                            data['distanceKm'] = null;
                          }

                          caretakersList.add(data);
                        }
                      }
                    });
                  }

                  if (caretakersList.isEmpty)
                    return const Center(
                      child: Text('ไม่พบข้อมูลผู้ดูแลในคลังข้อมูล'),
                    );

                  final searchQuery = _searchController.text
                      .toLowerCase()
                      .trim();

                  String cleanQuery = searchQuery
                      .replaceAll('อำเภอ', '')
                      .replaceAll('จังหวัด', '')
                      .replaceAll('ตำบล', '')
                      .replaceAll('ต.', '')
                      .replaceAll('อ.', '')
                      .replaceAll('จ.', '')
                      .replaceAll('เมือง', '')
                      .trim();

                  final searchTerms = cleanQuery.split(RegExp(r'\s+'));

                  final filteredList = caretakersList.where((data) {
                    String rawStatus =
                        (data['servicestatus']?.toString() ??
                                'ไม่พร้อมให้บริการ')
                            .trim();
                    bool isAvailable =
                        rawStatus.toLowerCase() == 'online' ||
                        rawStatus.toLowerCase() == 'on' ||
                        rawStatus == 'พร้อมให้บริการ';

                    if (!isAvailable) return false;

                    if (_selectedFilterDate != null) {
                      String filterDateStr =
                          "${_selectedFilterDate!.year}-${_selectedFilterDate!.month.toString().padLeft(2, '0')}-${_selectedFilterDate!.day.toString().padLeft(2, '0')}";
                      String idCard = data['caretakerId']?.toString() ?? '';
                      List<String> busyDates = busyDatesMap[idCard] ?? [];
                      if (busyDates.contains(filterDateStr)) return false;
                    }

                    final name =
                        "${data['firstname'] ?? ''} ${data['lastname'] ?? ''}"
                            .toLowerCase();

                    var address = '';
                    if (data['address'] != null) {
                      address = data['address'].toString().toLowerCase();
                    } else if (data['Location'] != null &&
                        data['Location']['address'] != null) {
                      address = data['Location']['address']
                          .toString()
                          .toLowerCase();
                    }

                    if (cleanQuery.isEmpty) return true;

                    bool isMatch = true;
                    for (String term in searchTerms) {
                      if (term.isEmpty) continue;
                      if (!name.contains(term) && !address.contains(term)) {
                        isMatch = false;
                        break;
                      }
                    }
                    return isMatch;
                  }).toList();

                  // 🌟 ข้อ 4: เรียงลำดับจากระยะห่างที่ใกล้ที่สุดไปไกลที่สุด และตามด้วยคะแนนรีวิว
                  filteredList.sort((a, b) {
                    double? distA = a['distanceKm'] as double?;
                    double? distB = b['distanceKm'] as double?;
                    double ratingA = (a['rating'] as double?) ?? 0.0;
                    double ratingB = (b['rating'] as double?) ?? 0.0;

                    // เปรียบเทียบระยะทางก่อน
                    if (distA != null && distB != null) {
                      int distComp = distA.compareTo(distB);
                      if (distComp != 0) return distComp; // ใกล้สุดมาก่อน
                    } else if (distA != null && distB == null) {
                      return -1; // คนที่รู้ระยะทางอยู่ก่อน
                    } else if (distA == null && distB != null) {
                      return 1;
                    }

                    // ถ้าระยะทางเท่ากัน หรือไม่มีระยะทาง ให้เรียงตามเรตติ้งรีวิวจากมากไปน้อย
                    int ratingComp = ratingB.compareTo(ratingA);
                    if (ratingComp != 0) return ratingComp;

                    int commentsA = (a['comments'] as int?) ?? 0;
                    int commentsB = (b['comments'] as int?) ?? 0;
                    return commentsB.compareTo(commentsA);
                  });

                  if (filteredList.isEmpty)
                    return const Center(child: Text('ไม่พบผลลัพธ์การค้นหา'));

                  _currentFilteredLength = filteredList.length;
                  final displayList = filteredList
                      .take(_currentPage * _perPage)
                      .toList();
                  bool hasMore =
                      (_currentPage * _perPage) < filteredList.length;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayList.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == displayList.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ),
                        );
                      }
                      return _buildCaretakerCard(
                        displayList[index],
                        displayList[index]['id'],
                      );
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
            _buildBottomNavItem(
              Icons.home_outlined,
              'บ้าน',
              true,
              onTap: () {},
            ),
            _buildBottomNavItem(
              Icons.support_agent,
              'รายการคำขอ',
              false,
              onTap: () {
                String currentUid =
                    widget.loggedUid ??
                    FirebaseAuth.instance.currentUser?.uid ??
                    '';
                if (currentUid.isEmpty) {
                  _showLoginRequiredDialog();
                  return;
                }

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
                    String activeNode = relativeMap['activePatientNode']?.toString() ?? 'Patient';
                    var targetPatientNode = relativeMap[activeNode] ?? relativeMap['Patient'];

                    if (targetPatientNode != null) {
                      final pData = Map<String, dynamic>.from(targetPatientNode as Map);
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

  Widget _buildCaretakerCard(Map<String, dynamic> data, String docId) {
    String fullName = formatFullNameWithTitle(
      gender: data['gender']?.toString(),
      firstname: data['firstname']?.toString(),
      lastname: data['lastname']?.toString(),
    );

    String location = '';
    if (data['address'] != null) {
      location = data['address'];
    } else if (data['Location'] != null &&
        data['Location']['address'] != null) {
      location = data['Location']['address'];
    } else {
      location = 'ไม่พบข้อมูล';
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

    double rating = data['rating'] != null
        ? (data['rating'] as num).toDouble()
        : 0.0;
    int comments = data['comments'] ?? 0;
    List<Map<String, dynamic>> reviewsList =
        (data['reviewsList'] as List<Map<String, dynamic>>?) ?? [];

    int serviceCount = data['serviceCount'] ?? 0;
    double? distKm = data['distanceKm'] as double?;

    String rawProfilePhoto = data['profilephoto']?.toString() ?? '';
    String cleanedBase64 = rawProfilePhoto
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '')
        .trim();
    int pad = cleanedBase64.length % 4;
    if (pad > 0) cleanedBase64 += '=' * (4 - pad);
    bool hasProfileImage = cleanedBase64.isNotEmpty;

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
              backgroundImage: hasProfileImage
                  ? MemoryImage(base64Decode(cleanedBase64))
                  : null,
              child: !hasProfileImage
                  ? Icon(Icons.person, size: 32, color: primaryColor)
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
                          maxLines: 1,
                          softWrap: false,
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
                        '${rating.toStringAsFixed(1)}/5',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < rating.floor() ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFBBF24),
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        comments == 0 ? 'ยังไม่มีรีวิว' : '($comments รีวิว)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (serviceCount > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ให้บริการไปแล้ว $serviceCount ครั้ง',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ให้บริการไปแล้ว 0 ครั้ง',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 🌟 ข้อ 2: แสดงระยะห่างระหว่างผู้ป่วยกับผู้ให้บริการ
                  Row(
                    children: [
                      Icon(Icons.near_me_outlined,
                          size: 13, color: primaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          distKm != null
                              ? 'ระยะห่าง: ${distKm.toStringAsFixed(1)} กม.'
                              : 'ระยะห่าง: กรุณาเข้าสู่ระบบเพื่อดูระยะห่าง',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: distKm != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: distKm != null ? accentTeal : Colors.black54,
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
                      Icon(Icons.directions_car,
                          size: 13, color: primaryColor),
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
                                loggedUid: widget.loggedUid ??
                                    FirebaseAuth.instance.currentUser?.uid,
                                selectedDate: _selectedFilterDate,
                                reviews: reviewsList,
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