import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'dart:convert';
import 'package:miniproject/widgets/location_picker_widget.dart';
import '../../models/hospital_model.dart';
import '../../models/department_model.dart';

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
  final Color primaryColor = const Color(0xFF7D3C98);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFECE2FE);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;
  final Color borderColor = const Color(0xFFD3C2F0);
  final Color labelColor = const Color(0xFF241C2B);

  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  late String _generatedRequestId;

  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  // 🌟 สำหรับจุดรับ (Pickup)
  int _pickupOption = 1; // 1 = ตามหน้าโปรไฟล์, 2 = ระบุที่อยู่ใหม่
  final TextEditingController _pickupAddressController =
      TextEditingController();
  LatLng _pickupLocation = const LatLng(13.7563, 100.5018);
  bool _pickupHasPinned = false;
  bool _pickupMapExpanded = false;

  // 🌟 เพิ่มตัวแปรสำหรับโรงพยาบาล
  List<HospitalModel> _hospitals = [];
  HospitalModel? _selectedHospital;

  // 🌟 เพิ่มตัวแปรสำหรับจัดการลิสต์ผู้ป่วย
  String? _activePatientId;

  LatLng _dropoffLocation = const LatLng(18.789735, 98.974654);
  bool _dropoffHasPinned = false;
  bool _dropoffMapExpanded = false;

  // ข้อมูลจากโปรไฟล์
  Map<String, dynamic>? _relativeData;
  Map<String, dynamic>? _patientData;
  List<String> _caretakerBusyDates = [];

  // 🌟 เพิ่มตัวแปรสำหรับเก็บ Key ผู้ป่วยที่กำลังทำงานอยู่ (สำคัญมาก)
  String _activePatientKey = 'Patient';

  // ตัวแปรเก็บที่อยู่เดิมจากโปรไฟล์
  String _profileAddress = '';
  double _profileLat = 0.0;
  double _profileLng = 0.0;

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
    DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedDate = widget.initialSelectedDate ?? tomorrow;

    _generatedRequestId = _generateCustomRequestId();
    _loadHospitalData();
    _fetchProfileData();
    _fetchCaretakerBusyDates();
  }

  // 🌟 ฟังก์ชันโหลดข้อมูลโรงพยาบาลจากไฟล์ assets/hospitals.json
  Future<void> _loadHospitalData() async {
    try {
      // 🌟 ระบุ Path ให้ตรงกับโฟลเดอร์ที่เก็บไฟล์ไว้ (เช่น assets/data/hospitals.json หรือ assets/hospitals.json)
      String jsonString = await rootBundle.loadString(
        'assets/data/hospitals.json',
      );
      List<dynamic> jsonResponse = jsonDecode(jsonString);

      if (mounted) {
        setState(() {
          _hospitals = jsonResponse.map((data) {
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
      print("Error loading hospital data: $e");
    }
  }

  String _generateCustomRequestId() {
    final random = Random();
    int randomNumber = 100000 + random.nextInt(900000);
    return "REQ-PEND1-$randomNumber";
  }

  Future<void> _fetchProfileData() async {
    String uid = widget.loggedUid ?? FirebaseAuth.instance.currentUser!.uid;
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('Login/$uid/Relative')
          .get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // 🌟 1. ดึง ID ของผู้ป่วยที่ Active อยู่
        String activeId = data['activePatientNode']?.toString() ?? '';
        Map<String, dynamic>? currentPatient;

        // 🌟 2. เข้าไปดึงข้อมูลผู้ป่วยเฉพาะคนที่มี ID ตรงกับ activeId
        if (activeId.isNotEmpty && data['Patient'] != null) {
          final patientNode = data['Patient'] as Map;
          if (patientNode[activeId] != null) {
            currentPatient = Map<String, dynamic>.from(patientNode[activeId]);
          }
        }

        // 🌟 3. อัปเดตพิกัดจุดรับให้ตรงกับผู้ป่วยที่ Active
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

  // 🌟 ฟังก์ชันอัปเดตที่อยู่จุดรับเมื่อเลือกผู้ป่วย
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

        // ดึง UID ของญาติที่กำลังใช้งานอยู่ตอนนี้
        String myUid =
            widget.loggedUid ?? FirebaseAuth.instance.currentUser!.uid;

        // 🌟 ดึงเลขบัตรประชาชนของผู้ดูแล จากก้อนข้อมูล Profile ที่ส่งมา
        String realCaretakerIdCard =
            widget.caretakerData['caretakerId']?.toString() ?? '';

        allUsers.forEach((key, val) {
          if (val is Map &&
              val['Relative'] != null &&
              val['Relative']['Request'] != null) {
            final reqs = val['Relative']['Request'] as Map;
            reqs.forEach((reqId, reqData) {
              // 🌟 เช็กว่างานนี้เป็นของผู้ดูแลคนนี้ไหม โดยใช้ "เลขบัตรประชาชน" เทียบ
              bool isThisCaretaker =
                  reqData['caretakerId']?.toString() == realCaretakerIdCard;

              bool isMyRequest = key == myUid;

              // ถ้าตรงกับเงื่อนไขใดเงื่อนไขหนึ่ง ให้นำมาตรวจสอบสถานะ
              if (isThisCaretaker || isMyRequest) {
                String status = (reqData['requeststatus'] ?? '')
                    .toString()
                    .toLowerCase();
                // ล็อกวันไว้ถ้ายังติดพันกับคำขอนี้
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

  // 🌟 ฟังก์ชันใหม่: ตรวจสอบและปัดวันเริ่มต้นให้ถูกต้องเสมอ
  // 🌟 ฟังก์ชันใหม่: ตรวจสอบและปัดวันเริ่มต้นให้ถูกต้องเสมอ
  void _adjustSelectedDate() {
    DateTime now = DateTime.now();
    // 🌟 คำนวณเป็น "วันพรุ่งนี้" แทน
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

    // 🌟 ถ้าวันที่เลือกไว้เป็นก่อนวันพรุ่งนี้ ให้ปัดไปเป็นวันพรุ่งนี้
    if (validDateOnly.isBefore(tomorrow)) {
      validDate = tomorrow;
    }

    while (true) {
      String checkFormat =
          "${validDate.year}-${validDate.month.toString().padLeft(2, '0')}-${validDate.day.toString().padLeft(2, '0')}";
      if (!_caretakerBusyDates.contains(checkFormat)) {
        break;
      }
      validDate = validDate.add(const Duration(days: 1));
    }

    if (validDate != _selectedDate) {
      setState(() {
        _selectedDate = validDate;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    // 🌟 วันที่น้อยที่สุดที่กดเลือกได้ในปฏิทิน คือ "พรุ่งนี้"
    DateTime tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(tomorrow) ? tomorrow : _selectedDate,
      firstDate: tomorrow, // 🌟 บังคับไม่ให้เลือกวันที่ผ่านมาแล้ว หรือ วันนี้
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
      // 🌟 เพิ่มบรรทัดนี้: บังคับให้เปิดมาเป็นแบบกล่องพิมพ์ตัวเลข (ไม่ต้องหมุนเข็มนาฬิกา)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: darkPurple,
        elevation: 2,
        shadowColor: const Color.fromARGB(255, 153, 116, 255),
        centerTitle: true,
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
                // ── รหัสคำขอบริการ ──
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
                  child: Row(
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
                ),
                const SizedBox(height: 20),
                Text('ผู้ดูแลที่ให้บริการ', style: _labelStyle()),
                const SizedBox(height: 8),
                _buildCaretakerCard(),
                // ── ข้อมูลบุคคล ──
                Text('ข้อมูลผู้นัดหมาย', style: _labelStyle()),
                const SizedBox(height: 8),
                // 🌟 แสดงการ์ดผู้ป่วยที่กำลัง Active อยู่ได้เลย (ข้อมูลจะดึงจาก _patientData อัตโนมัติ)
                _buildPatientCard(),

                // 🌟 แสดงการ์ดญาติ
                _buildRelativeCard(),

                // ── โรงพยาบาลและรายละเอียด ──
                // ── ข้อมูลนัดหมาย ──
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
                                        // 🌟 เปลี่ยนมาดึง hour และ minute มาเติม 0 ด้านหน้าให้ครบ 2 หลักแทน
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
                const SizedBox(height: 8),
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

                // 🌟 เปลี่ยนเป็น Autocomplete สำหรับเลือกโรงพยาบาล
                Autocomplete<HospitalModel>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _hospitals; // แสดงทั้งหมดถ้ายังไม่พิมพ์
                    }
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
                            // รีเซ็ตถ้ามีการลบ/พิมพ์ใหม่ แล้วไม่ตรงกับตัวเลือก
                            if (_selectedHospital != null &&
                                val != _selectedHospital!.hospitalname) {
                              _selectedHospital = null;
                              _dropoffHasPinned = false;
                            }
                          },
                        );
                      },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
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
                  ],
                ),

                const SizedBox(height: 8),
                TextFormField(
                  controller: _departmentController,
                  style: const TextStyle(fontSize: 14),
                  decoration: _inputDecoration('ชื่อแผนก'),
                  validator: (value) => value!.isEmpty ? 'กรุณาระบุแผนก' : null,
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 28),
                // ── ปุ่มยืนยัน/ยกเลิก ──
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
                          if (_pickupOption == 2 && !_pickupHasPinned) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("กรุณาปักหมุดพิกัดจุดรับ"),
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
                            String uid =
                                widget.loggedUid ??
                                FirebaseAuth.instance.currentUser!.uid;

                            DatabaseReference requestRef = FirebaseDatabase
                                .instance
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
                              departmentId:
                                  "DEP-${DateTime.now().millisecondsSinceEpoch}",
                              departmentname: _departmentController.text.trim(),
                              hospital: _selectedHospital,
                            );

                            String realCaretakerIdCard =
                                widget.caretakerData['caretakerId']
                                    ?.toString() ??
                                widget.caretakerId;

                            // 🌟 บันทึกลง Firebase
                            await requestRef.set({
                              "requestId": _generatedRequestId,
                              "caretakerId": realCaretakerIdCard,
                              "patientId":
                                  _activePatientId, // 🌟 ใช้ ID จาก Active Node
                              "pickupaddress": _profileAddress,
                              "requestdetail": _detailController.text.trim(),
                              "Department": departmentNode.toJson(),
                              "appointmentdate": _selectedDate
                                  .toIso8601String(),
                              "appointmenttime": apptDT.toIso8601String(),
                              "requestdate": DateTime.now().toIso8601String(),
                              "requeststatus": "pending",
                              "longitude": _profileLng,
                              "latitude": _profileLat,
                            });

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("ส่งคำขอสำเร็จ"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
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
                          'ยืนยัน',
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

  // ---------------- Helper Widgets พื้นฐาน ----------------

  Widget _buildPatientCard() {
    if (_patientData == null) return const SizedBox();
    return _buildInfoCard(
      title: 'ผู้ป่วย',
      gender: _patientData!['gender']?.toString(),
      firstName: _patientData!['firstname'] ?? '',
      lastName: _patientData!['lastname'] ?? '',
      phone: _patientData!['phonenumber'] ?? '-',
      photoBase64: _patientData!['patientphoto'],
      extraInfo:
          'โรคประจำตัว: ${_patientData!['disease'] ?? '-'} | การเดิน: ${_patientData!['mobility'] ?? '-'}',
    );
  }

  Widget _buildRelativeCard() {
    if (_relativeData == null) return const SizedBox();
    return _buildInfoCard(
      title: 'ญาติ (ผู้ติดต่อ)',
      gender: _relativeData!['gender']?.toString(),
      firstName: 'คุณ ${_relativeData!['firstname'] ?? ''}'.trim(),
      lastName: _relativeData!['lastname'] ?? '',
      phone: _relativeData!['phonenumber'] ?? '-',
      extraInfo: 'ความสัมพันธ์: ${_relativeData!['relationship'] ?? '-'}',
      showAvatar: false,
    );
  }

  Widget _buildCaretakerCard() {
    return _buildInfoCard(
      title: 'ผู้ดูแล',
      gender: widget.caretakerData['gender']?.toString(),
      firstName: widget.caretakerData['firstname'] ?? '',
      lastName: widget.caretakerData['lastname'] ?? '',
      phone: widget.caretakerData['phonenumber'] ?? '-',
      photoBase64: widget.caretakerData['profilephoto'],
      isCaretaker: true,
    );
  }

  Widget _buildInfoCard({
    required String title,
    String? gender,
    required String firstName,
    required String lastName,
    required String phone,
    String? photoBase64,
    String? extraInfo,
    bool isCaretaker = false,
    bool showAvatar = true,
  }) {
    // 🌟 จัดรูปแบบชื่อพร้อม นาย / นาง (เว้นวรรค 1 เคาะ)
    String fullName = formatFullNameWithTitle(
      gender: gender,
      firstname: firstName,
      lastname: lastName,
    );

    ImageProvider? imageProvider;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        String cleanBase64 = photoBase64;
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        cleanBase64 = cleanBase64
            .replaceAll('\n', '')
            .replaceAll('\r', '')
            .replaceAll(' ', '')
            .trim();
        int pad = cleanBase64.length % 4;
        if (pad > 0) cleanBase64 += '=' * (4 - pad);

        imageProvider = MemoryImage(base64Decode(cleanBase64));
      } catch (e) {
        imageProvider = null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            CircleAvatar(
              radius: 28,
              backgroundColor: lightPurple,
              backgroundImage: photoBase64 != null && photoBase64.isNotEmpty
                  ? MemoryImage(
                      base64Decode(photoBase64.replaceAll('\n', '').trim()),
                    )
                  : null,
              child: (photoBase64 == null || photoBase64.isEmpty)
                  ? Icon(Icons.person, color: primaryColor, size: 35)
                  : null,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCaretaker) ...[
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (extraInfo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    extraInfo,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      'เบอร์โทร $phone',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
}
