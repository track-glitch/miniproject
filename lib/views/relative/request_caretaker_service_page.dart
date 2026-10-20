import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'dart:convert';
import '../../models/hospital_model.dart';
import '../../models/department_model.dart';
import '../../models/hospital_model.dart';
import '../../models/department_model.dart';
import 'package:miniproject/widgets/location_picker_widget.dart'; // 🌟 เพิ่มบรรทัดนี้

class ServiceRequestPage extends StatefulWidget {
  final Map<String, dynamic> caretakerData;
  final String caretakerId;
  final String? loggedUid;
  final DateTime? initialSelectedDate;

  const ServiceRequestPage({
    super.key,
    required this.caretakerData,
    required this.caretakerId,
    this.loggedUid,
    this.initialSelectedDate,
  });

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  // ==========================================
  // 1. VARIABLES & STATE (ตัวแปร)
  // ==========================================
  final Color primaryColor = const Color(0xFF7D3C98);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFECE2FE);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;
  final Color borderColor = const Color(0xFFD3C2F0);
  final Color labelColor = const Color(0xFF241C2B);
  final Color greyBorder = const Color(0xFFD3C2F0);

  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  late String _generatedRequestId;

  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  // สำหรับจุดรับ (Pickup)
  int _pickupOption =
      1; // 🌟 เอา final ออก (1 = ตามหน้าโปรไฟล์, 2 = ระบุที่อยู่ใหม่)
  final TextEditingController _pickupAddressController =
      TextEditingController();
  LatLng _pickupLocation = const LatLng(
    13.7563,
    100.5018,
  ); // 🌟 เอา final ออก (หรือตั้งเป็นพิกัดเชียงใหม่ LatLng(18.7883, 98.9853))
  bool _pickupHasPinned = false; // 🌟 เอา final ออก
  final bool _pickupMapExpanded = false;

  // สำหรับโรงพยาบาลและจุดส่ง (Dropoff)
  List<HospitalModel> _hospitals = [];
  HospitalModel? _selectedHospital;
  LatLng _dropoffLocation = const LatLng(18.789735, 98.974654);
  bool _dropoffHasPinned = false;
  final bool _dropoffMapExpanded = false;

  // 🌟 เพิ่มตัวแปรจัดการแผนก (Departments)
  List<dynamic> _allDepartments = [];
  List<String> _availableDepartments = [];
  String? _selectedDepartment;
  Key _deptAutocompleteKey = UniqueKey();

  // ข้อมูลจากโปรไฟล์
  String? _activePatientId;
  Map<String, dynamic>? _relativeData;
  Map<String, dynamic>? _patientData;
  List<String> _caretakerBusyDates = [];
  final String _activePatientKey = 'Patient';

  // ตัวแปรเก็บที่อยู่เดิมจากโปรไฟล์
  String _profileAddress = '';
  double _profileLat = 0.0;
  double _profileLng = 0.0;

  // 🌟 เพิ่มตัวแปรเก็บคะแนนรีวิว
  double _caretakerRating = 0.0;
  int _caretakerReviewCount = 0;

  // ==========================================
  // 2. LIFECYCLE (การเริ่มต้นหน้าจอ)
  // ==========================================
  @override
  void initState() {
    super.initState();
    DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedDate = widget.initialSelectedDate ?? tomorrow;

    _generatedRequestId = _generateCustomRequestId();
    _loadHospitalData();
    _fetchProfileData();
    _fetchCaretakerBusyDates();
    _fetchCaretakerReviews(); // 🌟 เพิ่มบรรทัดนี้เพื่อดึงรีวิวตอนเปิดหน้า
  }

  // ==========================================
  // 3. LOGIC & FUNCTIONS (ฟังก์ชันการทำงานต่างๆ)
  // ==========================================

  String getPrefix(String? gender) {
    if (gender == null) return '';
    final g = gender.trim();
    if (g == 'ชาย' || g.toLowerCase() == 'male') return 'นาย';
    if (g == 'หญิง' || g.toLowerCase() == 'female') return 'นาง';
    return '';
  }

  // 🌟 ฟังก์ชันคำนวณอายุ
  String _calculateAge(String? birthdate) {
    if (birthdate == null || birthdate.trim().isEmpty) return '-';
    DateTime? birth;
    if (birthdate.contains('/')) {
      final parts = birthdate.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        int? year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          if (year > 2400) year -= 543;
          birth = DateTime(year, month, day);
        }
      }
    } else {
      birth = DateTime.tryParse(birthdate);
      if (birth != null && birth.year > 2400) {
        birth = DateTime(birth.year - 543, birth.month, birth.day);
      }
    }
    if (birth == null) return '-';
    DateTime today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return '$age ปี';
  }

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

  // 🌟 ฟังก์ชันโหลดข้อมูลโรงพยาบาลและแผนก
  Future<void> _loadHospitalData() async {
    try {
      // 1. โหลดข้อมูลโรงพยาบาล
      String hospitalString = await rootBundle.loadString(
        'assets/data/hospitals.json',
      );
      List<dynamic> hospitalJson = jsonDecode(hospitalString);

      // 2. โหลดข้อมูลแผนก
      String deptString = await rootBundle.loadString(
        'assets/data/departments.json',
      );
      List<dynamic> deptJson = jsonDecode(deptString);

      if (mounted) {
        setState(() {
          _allDepartments = deptJson; // เก็บแผนกทั้งหมดไว้กรองทีหลัง

          _hospitals = hospitalJson.map((data) {
            return HospitalModel(
              hospitalId: data['id'].toString(),
              hospitalname: data['hospital_name'],
              latitude: data['latitude'] != null
                  ? (data['latitude'] as num).toDouble()
                  : null,
              longitude: data['longitude'] != null
                  ? (data['longitude'] as num).toDouble()
                  : null,
            );
          }).toList();
        });
      }
    } catch (e) {
      print("Error loading hospital and department data: $e");
    }
  }

  String _generateCustomRequestId() {
    final random = Random();
    int randomNumber = 100000 + random.nextInt(900000);
    return "REQ-PEND1-$randomNumber";
  }

  // 🌟 ฟังก์ชันใหม่: ดึงรีวิวของผู้ดูแลคนนี้มาคำนวณดาว
  Future<void> _fetchCaretakerReviews() async {
    String realCaretakerIdCard =
        widget.caretakerData['caretakerId']?.toString() ?? widget.caretakerId;
    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login').get();
      if (snapshot.exists && snapshot.value is Map) {
        final allUsers = Map<String, dynamic>.from(snapshot.value as Map);
        int count = 0;
        double sumScore = 0.0;

        allUsers.forEach((key, val) {
          if (val is Map &&
              val['Relative'] != null &&
              val['Relative']['Request'] != null) {
            final reqs = val['Relative']['Request'] as Map;
            reqs.forEach((reqId, reqData) {
              if (reqData is Map &&
                  reqData['caretakerId']?.toString() == realCaretakerIdCard) {
                var rev = reqData['Review'] ?? reqData['review'];
                if (rev != null && rev is Map) {
                  double score =
                      double.tryParse(
                        (rev['rating'] ?? rev['ratingscore'] ?? 0).toString(),
                      ) ??
                      0.0;
                  sumScore += score;
                  count++;
                }
              }
            });
          }
        });

        if (mounted) {
          setState(() {
            _caretakerReviewCount = count;
            _caretakerRating = count > 0 ? (sumScore / count) : 0.0;
          });
        }
      }
    } catch (e) {
      print("Error fetching reviews: $e");
    }
  }

  Future<void> _fetchProfileData() async {
    String uid = widget.loggedUid ?? FirebaseAuth.instance.currentUser!.uid;
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('Login/$uid/Relative')
          .get();
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

        if (currentPatient != null && currentPatient['Location'] != null) {
          final locData = currentPatient['Location'];
          _profileAddress = locData['address'] ?? '';
          _profileLat = (locData['latitude'] as num?)?.toDouble() ?? 0.0;
          _profileLng = (locData['longitude'] as num?)?.toDouble() ?? 0.0;
        }

        setState(() {
          _relativeData = data;
          _patientData = currentPatient;
          _activePatientId = activeId;
        });
      }
    } catch (e) {
      print("Error fetch profile data: $e");
    }
  }

  void _updatePatientLocation(Map<String, dynamic> patient) {
    if (patient['Location'] != null) {
      final locData = patient['Location'];
      _profileAddress = locData['address'] ?? '';
      _profileLat = (locData['latitude'] as num?)?.toDouble() ?? 0.0;
      _profileLng = (locData['longitude'] as num?)?.toDouble() ?? 0.0;
    } else {
      _profileAddress = '';
      _profileLat = 0.0;
      _profileLng = 0.0;
    }
  }

  Future<void> _fetchCaretakerBusyDates() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login').get();
      if (snapshot.exists && snapshot.value is Map) {
        final allUsers = snapshot.value as Map;
        List<String> busy = [];
        String myUid =
            widget.loggedUid ?? FirebaseAuth.instance.currentUser!.uid;
        String realCaretakerIdCard =
            widget.caretakerData['caretakerId']?.toString() ?? '';

        allUsers.forEach((key, val) {
          if (val is Map &&
              val['Relative'] != null &&
              val['Relative']['Request'] != null) {
            final reqs = val['Relative']['Request'] as Map;
            reqs.forEach((reqId, reqData) {
              bool isThisCaretaker =
                  reqData['caretakerId']?.toString() == realCaretakerIdCard;
              bool isMyRequest = key == myUid;

              if (isThisCaretaker || isMyRequest) {
                String status = (reqData['requeststatus'] ?? '')
                    .toString()
                    .toLowerCase();
                if (status == 'pending' ||
                    status == 'accepted' ||
                    status == 'pending_advice') {
                  String dateStr = reqData['appointmentdate'] ?? '';
                  if (dateStr.isNotEmpty) {
                    try {
                      DateTime d = DateTime.parse(dateStr);
                      String formattedDate =
                          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                      busy.add(formattedDate);
                    } catch (e) {}
                  }
                }
              }
            });
          }
        });
        setState(() {
          _caretakerBusyDates = busy.toSet().toList();
        });
        _adjustSelectedDate();
      }
    } catch (e) {
      print("Error fetching busy dates: $e");
    }
  }

  void _adjustSelectedDate() {
    DateTime now = DateTime.now();
    DateTime tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    DateTime validDate = _selectedDate;
    DateTime validDateOnly = DateTime(
      validDate.year,
      validDate.month,
      validDate.day,
    );

    if (validDateOnly.isBefore(tomorrow)) {
      validDate = tomorrow;
    }
    while (true) {
      String checkFormat =
          "${validDate.year}-${validDate.month.toString().padLeft(2, '0')}-${validDate.day.toString().padLeft(2, '0')}";
      if (!_caretakerBusyDates.contains(checkFormat)) break;
      validDate = validDate.add(const Duration(days: 1));
    }
    if (validDate != _selectedDate) {
      setState(() => _selectedDate = validDate);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(tomorrow) ? tomorrow : _selectedDate,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'กรุณาส่งคำขอก่อนวันนัด 1 วัน',
      selectableDayPredicate: (DateTime val) {
        String formatVal =
            "${val.year}-${val.month.toString().padLeft(2, '0')}-${val.day.toString().padLeft(2, '0')}";
        return !_caretakerBusyDates.contains(formatVal);
      },
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
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                onSurface: darkPurple,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatThaiDate(DateTime date) {
    final thaiMonths = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
  }

  Future<void> _submitRequestToFirebase() async {
    String uid = widget.loggedUid ?? FirebaseAuth.instance.currentUser!.uid;
    DatabaseReference requestRef = FirebaseDatabase.instance
        .ref()
        .child("Login")
        .child(uid)
        .child("Relative")
        .child("Request")
        .child(_generatedRequestId);

    DateTime apptDT = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    DepartmentModel departmentNode = DepartmentModel(
      departmentId: "DEP-${DateTime.now().millisecondsSinceEpoch}",
      departmentname: _departmentController.text.trim(),
      hospital: _selectedHospital,
    );

    String realCaretakerIdCard =
        widget.caretakerData['caretakerId']?.toString() ?? widget.caretakerId;

    // 🌟 เช็กว่าใช้ที่อยู่จากโปรไฟล์ หรือ ที่อยู่ปักหมุดใหม่
    String finalPickupAddress = _pickupOption == 1
        ? _profileAddress
        : _pickupAddressController.text.trim();
    double finalLat = _pickupOption == 1
        ? _profileLat
        : _pickupLocation.latitude;
    double finalLng = _pickupOption == 1
        ? _profileLng
        : _pickupLocation.longitude;

    await requestRef.set({
      "requestId": _generatedRequestId,
      "caretakerId": realCaretakerIdCard,
      "patientId": _activePatientId,
      "pickupaddress": finalPickupAddress, // 🌟 ใช้ตัวแปรที่เช็กแล้ว
      "requestdetail": _detailController.text.trim(),
      "Department": departmentNode.toJson(),
      "appointmentdate": _selectedDate.toIso8601String(),
      "appointmenttime": apptDT.toIso8601String(),
      "requestdate": DateTime.now().toIso8601String(),
      "requeststatus": "pending",
      "longitude": finalLng, // 🌟 ใช้ตัวแปรที่เช็กแล้ว
      "latitude": finalLat, // 🌟 ใช้ตัวแปรที่เช็กแล้ว
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("ส่งคำขอสำเร็จ"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  // ==========================================
  // 4. UI WIDGETS & BUILDERS (จัดการหน้าตาแอป)
  // ==========================================

  void _showPreviewConfirmation() {
    String patientName = formatFullNameWithTitle(
      gender: _patientData?['gender']?.toString(),
      firstname: _patientData?['firstname']?.toString(),
      lastname: _patientData?['lastname']?.toString(),
    );

    String relativeName = formatFullNameWithTitle(
      gender: _relativeData?['gender']?.toString(),
      firstname: _relativeData?['firstname']?.toString(),
      lastname: _relativeData?['lastname']?.toString(),
    );

    // 🌟 เพิ่มตัวแปรดึงที่อยู่จุดรับตาม Option ที่เลือก (1 = โปรไฟล์, 2 = ปักหมุดใหม่)
    String previewPickupAddress = _pickupOption == 1
        ? _profileAddress
        : _pickupAddressController.text.trim();
    String pickupTypeLabel = _pickupOption == 1
        ? '(ใช้ที่อยู่ตามหน้าโปรไฟล์)'
        : '(ระบุจุดรับ-ส่งกลับใหม่)';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: greyBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ตรวจสอบใบคำขอรับบริการ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#$_generatedRequestId',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: labelColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1.5),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreviewSectionWrapper(
                          title: 'ข้อมูลการนัดหมาย',
                          icon: Icons.calendar_month_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPreviewDocField(
                                      'วันที่ส่งคำขอ',
                                      _formatThaiDate(DateTime.now()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildPreviewDocField(
                                      'โรงพยาบาล',
                                      _selectedHospital?.hospitalname ?? '-',
                                      maxLines: 2,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: _buildPreviewDocField(
                                      'แผนก',
                                      _departmentController.text.trim(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPreviewDocField(
                                      'วันที่นัดหมาย',
                                      _formatThaiDate(_selectedDate),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildPreviewDocField(
                                      'เวลานัดหมาย',
                                      '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')} น.',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildPreviewDocField(
                                'รายละเอียดคำขอ',
                                maxLines: 50,
                                _detailController.text.trim().isEmpty
                                    ? '-'
                                    : _detailController.text.trim(),
                              ),
                            ],
                          ),
                        ),

                        // 🌟 เพิ่มกล่องแสดงจุดรับ-ส่ง ตรงนี้ครับ!
                        _buildPreviewSectionWrapper(
                          title: 'ข้อมูลจุดรับส่ง',
                          icon: Icons.location_on_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPreviewDocField(
                                'จุดรับและส่ง (บ้าน)',
                                previewPickupAddress.isEmpty
                                    ? '-'
                                    : previewPickupAddress,
                                maxLines: 4,
                              ),
                              const SizedBox(height: 16),
                              _buildPreviewDocField(
                                'จุดหมายปลายทาง (โรงพยาบาล)',
                                _selectedHospital?.hospitalname ?? '-',
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: primaryColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'กลับไปแก้ไข',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            _submitRequestToFirebase();
                          },
                          child: const Text(
                            'ยืนยันส่งคำขอ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
      },
    );
  }

  Widget _buildPreviewSectionWrapper({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.trim().isEmpty ? '-' : value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPreviewDocField(String label, String value, {maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF241C2B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // 🌟 2. การ์ดข้อมูลผู้นัดหมาย (ผู้ป่วย + ญาติ) (ดีไซน์ใหม่)
  Widget _buildCombinedBookerCard() {
    // ข้อมูลผู้ป่วย
    String patientName = formatFullNameWithTitle(
      gender: _patientData?['gender']?.toString(),
      firstname: _patientData?['firstname']?.toString(),
      lastname: _patientData?['lastname']?.toString(),
    );
    String pAge = _calculateAge(_patientData?['birthdate']?.toString());
    String pGender = _patientData?['gender']?.toString() ?? '-';
    String pDisease = _patientData?['disease']?.toString() ?? '-';
    String pMobility = _patientData?['mobility']?.toString() ?? '-';
    String pPhone = _patientData?['phonenumber']?.toString() ?? '-';
    String pPhoto = _patientData?['patientphoto']?.toString() ?? '';

    // ข้อมูลญาติ
    String relativeName = formatFullNameWithTitle(
      gender: _relativeData?['gender']?.toString(),
      firstname: _relativeData?['firstname']?.toString(),
      lastname: _relativeData?['lastname']?.toString(),
    );
    String rPhone = _relativeData?['phonenumber']?.toString() ?? '-';
    String rRelation = _relativeData?['relationship']?.toString() ?? '-';
    String rlineId = _relativeData?['lineId']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF), // สีม่วงอ่อนตามเรฟเฟอเรนซ์
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวการ์ด
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                color: Color(0xFF7D3C98),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'ข้อมูลผู้นัดหมาย',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF241C2B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── ส่วนของผู้ป่วย ──
          Row(
            children: [
              _buildAvatar(pPhoto, Icons.person, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ชื่อ - นามสกุล',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF241C2B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDetailColumn('อายุ', pAge)),
              Expanded(child: _buildDetailColumn('เพศ', pGender)),
              Expanded(child: _buildDetailColumn('เบอร์โทร', pPhone)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDetailColumn('โรคประจำตัว', pDisease)),
              Expanded(
                flex: 2,
                child: _buildDetailColumn('สภาพร่างกาย', pMobility),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1),
          ),

          // ── ส่วนของญาติ ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ชื่อ - นามสกุล',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'คุณ $relativeName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF241C2B),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildDetailColumn('ความสัมพันธ์', rRelation)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildDetailColumn('เบอร์ติดต่อ', rPhone),
              ),
              Expanded(flex: 2, child: _buildDetailColumn('LINE ID', rlineId)),
            ],
          ),
        ],
      ),
    );
  }

  // 🌟 Helper วิดเจ็ตสำหรับจัดเรียงข้อมูลย่อยๆ ให้เป็นระเบียบ (Icon + Label + Value)
  Widget _buildSubInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 🌟 Helper สร้างรูปโปรไฟล์วงกลม
  Widget _buildAvatar(
    String? base64Str,
    IconData fallbackIcon, {
    double radius = 26,
  }) {
    ImageProvider? imgProv;
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        String clean = base64Str.replaceAll(RegExp(r'\s+'), '');
        if (clean.contains(',')) clean = clean.split(',').last;
        int pad = clean.length % 4;
        if (pad > 0) clean += '=' * (4 - pad);
        imgProv = MemoryImage(base64Decode(clean));
      } catch (_) {}
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: lightPurple,
      backgroundImage: imgProv,
      child: imgProv == null
          ? Icon(fallbackIcon, color: primaryColor, size: radius * 0.8)
          : null,
    );
  }

  // 🌟 1. การ์ดผู้ดูแลที่ได้รับมอบหมาย (ดีไซน์ใหม่)
  Widget _buildCaretakerCard() {
    String fullName = formatFullNameWithTitle(
      gender: widget.caretakerData['gender']?.toString(),
      firstname: widget.caretakerData['firstname']?.toString(),
      lastname: widget.caretakerData['lastname']?.toString(),
    );

    // ดึงคะแนนจากการคำนวณในตัวแปร
    double rating = _caretakerRating;
    int reviews = _caretakerReviewCount;
    String? photoBase64 = widget.caretakerData['profilephoto'];

    String ageStr = _calculateAge(
      widget.caretakerData['birthdate']?.toString(),
    );
    String genderStr = widget.caretakerData['gender']?.toString() ?? '-';
    String phoneStr = widget.caretakerData['phonenumber']?.toString() ?? '-';
    String emailStr = widget.caretakerData['email']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF), // สีม่วงอ่อนตามเรฟเฟอเรนซ์
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวการ์ด
          Row(
            children: [
              const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF7D3C98),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'ผู้ดูแลที่ได้รับมอบหมาย',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF241C2B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // รูป + ชื่อ + ดาว
          Row(
            children: [
              _buildAvatar(photoBase64, Icons.person, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ชื่อ - นามสกุล',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF9B59B6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviews รีวิว)',
                          style: const TextStyle(
                            fontSize: 13,
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
          const SizedBox(height: 16),

          // ข้อมูลย่อยแบบ Grid
          Row(
            children: [
              Expanded(child: _buildDetailColumn('อายุ', ageStr)),
              Expanded(child: _buildDetailColumn('เพศ', genderStr)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDetailColumn('เบอร์ติดต่อ', phoneStr)),
              Expanded(child: _buildDetailColumn('อีเมล', emailStr)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDropoffSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'ข้อมูลจุดรับส่ง',
                style: _labelStyle().copyWith(fontSize: 15),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 🌟 ตัวเลือกที่ 1: ใช้ที่อยู่ตามหน้าโปรไฟล์
          RadioListTile<int>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: 1,
            groupValue: _pickupOption,
            activeColor: primaryColor,
            title: const Text(
              'ใช้ที่อยู่ตามหน้าโปรไฟล์',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onChanged: (val) {
              setState(() {
                _pickupOption = val!;
              });
            },
          ),

          // แสดงกล่องที่อยู่เดิมเมื่อเลือก Option 1
          if (_pickupOption == 1)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 12, bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: greyBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.home_rounded, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _profileAddress.isNotEmpty
                          ? _profileAddress
                          : 'ไม่พบที่อยู่ในโปรไฟล์ (กรุณาเลือกจุดรับ-ส่งกลับใหม่)',
                      style: TextStyle(
                        fontSize: 13,
                        color: _profileAddress.isNotEmpty
                            ? Colors.black87
                            : Colors.red,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 🌟 ตัวเลือกที่ 2: เลือกจุดรับ-ส่งกลับใหม่
          RadioListTile<int>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: 2,
            groupValue: _pickupOption,
            activeColor: primaryColor,
            title: const Text(
              'เลือกจุดรับส่งใหม่',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onChanged: (val) {
              setState(() {
                _pickupOption = val!;
                if (!_pickupHasPinned &&
                    _profileLat != 0.0 &&
                    _profileLng != 0.0) {
                  _pickupLocation = LatLng(_profileLat, _profileLng);
                }
              });
            },
          ),

          // แสดง LocationPickerWidget เหมือนหน้า edit_relative เมื่อเลือก Option 2
          if (_pickupOption == 2) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: greyBorder),
              ),
              child: LocationPickerWidget(
                key: const ValueKey('request_pickup_map_picker'),
                initialLocation: _pickupLocation,
                initialAddress: _pickupAddressController.text,
                onLocationChanged: (newLocation, newAddress) {
                  setState(() {
                    _pickupLocation = newLocation;
                    _pickupAddressController.text = newAddress;
                    _pickupHasPinned = true;
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _labelStyle() {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: labelColor,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  // ==========================================
  // 5. MAIN BUILD (ส่วนแสดงผลหน้าจอหลัก)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    String userName = '';
    if (_patientData != null) {
      userName = formatFullNameWithTitle(
        gender: _patientData?['gender']?.toString(),
        firstname: _patientData?['firstname']?.toString(),
        lastname: _patientData?['lastname']?.toString(),
      );
    } else if (_relativeData != null) {
      userName = formatFullNameWithTitle(
        gender: _relativeData?['gender']?.toString(),
        firstname: _relativeData?['firstname']?.toString(),
        lastname: _relativeData?['lastname']?.toString(),
      );
    }

    ImageProvider? userImageProvider;
    String rawPhoto = '';
    if (_patientData != null && _patientData?['patientphoto'] != null) {
      rawPhoto = _patientData?['patientphoto'].toString() ?? '';
    } else if (_relativeData != null &&
        _relativeData?['profilephoto'] != null) {
      rawPhoto = _relativeData?['profilephoto'].toString() ?? '';
    }

    if (rawPhoto.isNotEmpty) {
      try {
        String clean = rawPhoto.replaceAll(RegExp(r'\s+'), '');
        if (clean.contains(',')) clean = clean.split(',').last;
        int pad = clean.length % 4;
        if (pad > 0) clean += '=' * (4 - pad);
        userImageProvider = MemoryImage(base64Decode(clean));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: darkPurple,
        elevation: 2,
        shadowColor: const Color.fromARGB(255, 153, 116, 255),
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(
          'ส่งคำขอบริการ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        // 🌟 2. เพิ่ม actions สำหรับแสดงรูปและชื่อโปรไฟล์มุมบนขวา
        actions: [
          if (userName.isNotEmpty)
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
                        userName,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. รหัสคำขอบริการ และ วันที่ส่งคำขอ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: lightPurple,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'รหัสคำขอบริการ: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: labelColor,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _generatedRequestId,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'วันที่ส่งคำขอ: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            _formatThaiDate(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. ข้อมูลผู้ดูแล
                _buildCaretakerCard(),
                const SizedBox(height: 20),

                // 3. ข้อมูลผู้นัดหมาย (ผู้ป่วย+ญาติ)
                _buildCombinedBookerCard(),
                const SizedBox(height: 18),
                const Divider(thickness: 1.5),
                const SizedBox(height: 16),

                // 4. ข้อมูลวัน/เวลานัดหมาย
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('วันที่นัดหมาย', style: _labelStyle()),
                              const Text(
                                ' *',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatThaiDate(_selectedDate),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: primaryColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('เวลานัดหมาย', style: _labelStyle()),
                              const Text(
                                ' *',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedTime == null
                                        ? '--:-- น.'
                                        : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')} น.',
                                    style: TextStyle(
                                      color: _selectedTime == null
                                          ? Colors.grey
                                          : Colors.black,
                                      fontSize: 13,
                                      fontWeight: _selectedTime == null
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: primaryColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. โรงพยาบาลปลายทาง
                Row(
                  children: [
                    Text('โรงพยาบาลที่ต้องการไปพบแพทย์', style: _labelStyle()),
                    const Text(
                      ' *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Autocomplete<HospitalModel>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return _hospitals;
                    return _hospitals.where(
                      (hospital) => hospital.hospitalname!.contains(
                        textEditingValue.text,
                      ),
                    );
                  },
                  displayStringForOption: (HospitalModel option) =>
                      option.hospitalname ?? '',
                  onSelected: (HospitalModel selection) {
                    setState(() {
                      _selectedHospital = selection;
                      _hospitalController.text = selection.hospitalname ?? '';
                      _dropoffLocation = LatLng(
                        selection.latitude ?? 0.0,
                        selection.longitude ?? 0.0,
                      );
                      _dropoffHasPinned = true;

                      // 🌟 กรองแผนก และบังคับรีเซ็ตช่อง Autocomplete แผนก
                      _selectedDepartment = null;
                      _departmentController.clear();
                      _deptAutocompleteKey =
                          UniqueKey(); // 🌟 รีเซ็ต UI ช่องแผนก

                      _availableDepartments = _allDepartments
                          .where(
                            (dept) =>
                                dept['hospital_id'].toString() ==
                                selection.hospitalId,
                          )
                          .map((dept) => dept['department_name'].toString())
                          .toList();
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          style: const TextStyle(fontSize: 14),
                          decoration:
                              _inputDecoration(
                                'พิมพ์ค้นหา หรือ เลือกโรงพยาบาล...',
                              ).copyWith(
                                suffixIcon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey,
                                ),
                              ),
                          validator: (value) => _selectedHospital == null
                              ? 'กรุณาเลือกโรงพยาบาลจากรายการ'
                              : null,
                          onChanged: (val) {
                            // ถ้ายกเลิก/ลบข้อความโรงพยาบาล ให้ล้างข้อมูลแผนกด้วย
                            if (_selectedHospital != null &&
                                val != _selectedHospital!.hospitalname) {
                              setState(() {
                                _selectedHospital = null;
                                _dropoffHasPinned = false;

                                _selectedDepartment = null;
                                _availableDepartments.clear();
                                _departmentController.clear();
                                _deptAutocompleteKey =
                                    UniqueKey(); // 🌟 รีเซ็ต UI ช่องแผนก
                              });
                            }
                          },
                        );
                      },
                ),
                const SizedBox(height: 16),

                // 6. แผนกในโรงพยาบาล (เปลี่ยนเป็น Autocomplete)
                Row(
                  children: [
                    Text('ระบุแผนกในโรงพยาบาล', style: _labelStyle()),
                    const Text(
                      ' *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Autocomplete<String>(
                  key:
                      _deptAutocompleteKey, // 🌟 ใส่ Key ตรงนี้เพื่อให้มันรีเซ็ตตัวเองตอนเปลี่ยน รพ. ได้
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty)
                      return _availableDepartments;
                    return _availableDepartments.where(
                      (dept) => dept.contains(textEditingValue.text),
                    );
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _selectedDepartment = selection;
                      _departmentController.text = selection;
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          enabled:
                              _selectedHospital !=
                              null, // 🌟 ปิดไม่ให้พิมพ์ถ้ายังไม่เลือกโรงพยาบาล
                          style: const TextStyle(fontSize: 14),
                          decoration:
                              _inputDecoration(
                                _selectedHospital == null
                                    ? 'กรุณาเลือกโรงพยาบาลก่อน'
                                    : 'พิมพ์ค้นหา หรือ เลือกแผนก...',
                              ).copyWith(
                                fillColor: _selectedHospital == null
                                    ? Colors.grey.shade100
                                    : Colors.white,
                                suffixIcon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey,
                                ),
                              ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'กรุณาระบุแผนก'
                              : null,
                          onChanged: (val) {
                            _selectedDepartment = val;
                            _departmentController.text = val;
                          },
                        );
                      },
                ),
                const SizedBox(height: 16),

                // 7. รายละเอียดคำขอเพิ่มเติม
                Row(
                  children: [
                    Text('ระบุรายละเอียดคำขอ', style: _labelStyle()),
                    const Text(
                      ' *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _detailController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: _inputDecoration(
                    'อาการ หรือ สิ่งที่ต้องการให้ช่วยเหลือ...',
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาระบุรายละเอียด' : null,
                ),
                const SizedBox(height: 24),

                // 🌟 8. วางเรียกใช้งานตรงนี้ครับ! (อยู่ก่อนปุ่มตรวจสอบข้อมูล)
                _buildPickupDropoffSection(),
                const SizedBox(height: 24),

                // 9. ปุ่มยืนยัน/ยกเลิก
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 4,
                          shadowColor: primaryColor.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (_pickupOption == 1 && _profileAddress.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "ไม่พบที่อยู่บนโปรไฟล์ กรุณาเลือกระบุที่อยู่ใหม่",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (_pickupOption == 2 &&
                              (!_pickupHasPinned ||
                                  _pickupAddressController.text
                                      .trim()
                                      .isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "กรุณาปักหมุดและระบุรายละเอียดที่อยู่จุดรับ-ส่งกลับใหม่",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (!_dropoffHasPinned || _selectedHospital == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "กรุณาเลือกโรงพยาบาลปลายทางจากรายการ",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (_formKey.currentState!.validate() &&
                              _selectedTime != null &&
                              _selectedHospital != null) {
                            // กดปุ่มยืนยันแล้วจะเรียก Preview ขึ้นมาตรวจสอบก่อน
                            _showPreviewConfirmation();
                          } else if (_selectedTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("กรุณาระบุเวลานัดหมาย"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'ตรวจสอบข้อมูล',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
