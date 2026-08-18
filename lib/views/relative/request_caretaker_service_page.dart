import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'dart:convert';
import 'package:miniproject/widgets/location_picker_widget.dart';

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
  final Color primaryColor = const Color(0xFF8763E6);
  final Color darkPurple = const Color.fromARGB(255, 153, 116, 255);
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

  // 🌟 สำหรับจุดส่ง (Dropoff)
  LatLng _dropoffLocation = const LatLng(13.7563, 100.5018);
  bool _dropoffHasPinned = false;
  bool _dropoffMapExpanded = false;

  // ข้อมูลจากโปรไฟล์
  Map<String, dynamic>? _relativeData;
  Map<String, dynamic>? _patientData;
  List<DateTime> _caretakerBusyDates = [];

  // ตัวแปรเก็บที่อยู่เดิมจากโปรไฟล์
  String _profileAddress = '';
  double _profileLat = 0.0;
  double _profileLng = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedDate =
        widget.initialSelectedDate ??
        DateTime.now().add(const Duration(days: 1));

    _generatedRequestId = _generateCustomRequestId();

    _fetchProfileData();
    _fetchCaretakerBusyDates();
  }

  String _generateCustomRequestId() {
    final random = Random();
    int randomNumber = 100000 + random.nextInt(900000);
    return "REQ-PEND1-$randomNumber";
  }

  // 🌟 อัปเดตฟังก์ชันดึงข้อมูลให้ทะลุเข้าไปใน Patient -> Location
  Future<void> _fetchProfileData() async {
    String uid = widget.loggedUid ?? FirebaseAuth.instance.currentUser!.uid;
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('Login/$uid/Relative')
          .get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // 🌟 ดึงข้อมูลที่อยู่จากหน้าโปรไฟล์ของผู้ป่วย
        if (data['Patient'] != null && data['Patient']['Location'] != null) {
          final locData = data['Patient']['Location'];
          _profileAddress = locData['address'] ?? '';
          _profileLat = (locData['latitude'] as num?)?.toDouble() ?? 0.0;
          _profileLng = (locData['longitude'] as num?)?.toDouble() ?? 0.0;
        }

        setState(() {
          _relativeData = data;
          if (data['Patient'] != null) {
            _patientData = Map<String, dynamic>.from(data['Patient'] as Map);
          }
        });
      }
    } catch (e) {
      print("Error fetch profile data: $e");
    }
  }

  Future<void> _fetchCaretakerBusyDates() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login').get();
      if (snapshot.exists && snapshot.value is Map) {
        final allUsers = snapshot.value as Map;
        List<DateTime> busy = [];

        allUsers.forEach((key, val) {
          if (val is Map &&
              val['Relative'] != null &&
              val['Relative']['Request'] != null) {
            final reqs = val['Relative']['Request'] as Map;
            reqs.forEach((reqId, reqData) {
              if (reqData['caretakerId'] == widget.caretakerId) {
                String status = (reqData['requeststatus'] ?? '')
                    .toString()
                    .toLowerCase();
                if (status == 'pending' ||
                    status == 'accepted' ||
                    status == 'pending_advice') {
                  String dateStr = reqData['appointmentdate'] ?? '';
                  if (dateStr.isNotEmpty) {
                    DateTime d = DateTime.parse(dateStr);
                    busy.add(DateTime(d.year, d.month, d.day));
                  }
                }
              }
            });
          }
        });
        setState(() {
          _caretakerBusyDates = busy;
        });
      }
    } catch (e) {
      print("Error fetching busy dates: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.utc(2030, 12, 31),
      selectableDayPredicate: (DateTime val) {
        DateTime checkDate = DateTime(val.year, val.month, val.day);
        return !_caretakerBusyDates.contains(checkDate);
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
                                        : '${_selectedTime!.format(context)} น.',
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
                const SizedBox(height: 24),

                // ── ข้อมูลบุคคล ──
                Text('ข้อมูลผู้ป่วยและญาติ', style: _labelStyle()),
                const SizedBox(height: 8),
                _buildPatientCard(),
                _buildRelativeCard(),
                const SizedBox(height: 12),

                Text('ผู้ดูแลที่ให้บริการ', style: _labelStyle()),
                const SizedBox(height: 8),
                _buildCaretakerCard(),
                const SizedBox(height: 20),

                // ── โรงพยาบาลและรายละเอียด ──
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
                TextFormField(
                  controller: _hospitalController,
                  style: const TextStyle(fontSize: 14),
                  decoration: _inputDecoration('ชื่อโรงพยาบาล'),
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาระบุโรงพยาบาล' : null,
                ),
                const SizedBox(height: 16),
                _buildAddressAndPinFields(
                  addressController: null,
                  location: _dropoffLocation,
                  hasPinned: _dropoffHasPinned,
                  isExpanded: _dropoffMapExpanded,
                  showAddressField: false,
                  pinButtonText: 'ระบุพิกัดสถานที่ไป',
                  onToggleMap: () => setState(
                    () => _dropoffMapExpanded = !_dropoffMapExpanded,
                  ),
                  onLocationChanged: (loc, addr) {
                    setState(() {
                      _dropoffLocation = loc;
                      _dropoffHasPinned = true;
                    });
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
                const Divider(thickness: 1.5),
                const SizedBox(height: 12),

                // ── ข้อมูลการเดินทาง (จุดรับ และ จุดส่ง) ──
                Text(
                  'ข้อมูลการเดินทาง',
                  style: _labelStyle().copyWith(fontSize: 16),
                ),
                const SizedBox(height: 16),

                _buildPickupDropoffSection(),

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
                          // 🌟 ตรวจสอบว่าเลือก Profile แล้วมีที่อยู่ไหม
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
                          // 🌟 ตรวจสอบว่าเลือกระบุที่อยู่ใหม่แล้วปักหมุดหรือยัง
                          if (_pickupOption == 2 && !_pickupHasPinned) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("กรุณาปักหมุดพิกัดจุดรับ"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          // 🌟 ตรวจสอบว่าปักหมุดจุดส่งหรือยัง
                          if (!_dropoffHasPinned) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "กรุณาปักหมุดพิกัดจุดส่ง (โรงพยาบาล)",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (_formKey.currentState!.validate() &&
                              _selectedTime != null) {
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

                            // 🌟 จัดเตรียมข้อมูล Pickup ให้โครงสร้างตรงกับ LocationModel
                            Map<String, dynamic> pickupNode = {};
                            if (_pickupOption == 1) {
                              pickupNode = {
                                'locationId': 'pickup_loc',
                                'address': _profileAddress,
                                'latitude': _profileLat,
                                'longitude': _profileLng,
                              };
                            } else {
                              pickupNode = {
                                'locationId': 'pickup_loc',
                                'address': _pickupAddressController.text.trim(),
                                'latitude': _pickupLocation.latitude,
                                'longitude': _pickupLocation.longitude,
                              };
                            }

                            // 🌟 จัดเตรียมข้อมูล Dropoff ให้โครงสร้างตรงกับ LocationModel
                            Map<String, dynamic> dropoffNode = {
                              'locationId': 'dropoff_loc',
                              'address': _hospitalController.text
                                  .trim(), // อ้างอิงชื่อ รพ. เพื่อให้แสดงผลใน Location ได้
                              'latitude': _dropoffLocation.latitude,
                              'longitude': _dropoffLocation.longitude,
                            };

                            await requestRef.set({
                              "requestId": _generatedRequestId,
                              "caretakerId": widget.caretakerId,
                              "requestdetail": _detailController.text.trim(),
                              "PickupLocation":
                                  pickupNode, // โครงสร้างตาม LocationModel
                              "DropoffLocation":
                                  dropoffNode, // โครงสร้างตาม LocationModel
                              "hospitalname": _hospitalController.text.trim(),
                              "departmentname": _departmentController.text
                                  .trim(),
                              "appointmentdate": _selectedDate
                                  .toIso8601String(),
                              "appointmenttime": apptDT.toIso8601String(),
                              "requestdate": DateTime.now().toIso8601String(),
                              "requeststatus": "pending",
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

  // ---------------- วิดเจ็ตแยกสำหรับ จุดรับ-จุดส่ง ----------------
  Widget _buildPickupDropoffSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 1. จุดนัดหมายรับ
          Row(
            children: [
              Text(
                '1. จุดนัดหมายรับส่งผู้ป่วย',
                style: _labelStyle().copyWith(fontSize: 14),
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

          // ตัวเลือก Checkbox (Radio)
          RadioListTile(
            title: Text(
              'เลือกจุดรับตามหน้าโปรไฟล์\n(${_profileAddress.isNotEmpty ? _profileAddress : 'ไม่พบข้อมูลที่อยู่'})',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            value: 1,
            groupValue: _pickupOption,
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _pickupOption = val as int),
          ),
          RadioListTile(
            title: const Text(
              'เลือกระบุพิกัดและจุดรับใหม่',
              style: TextStyle(fontSize: 13),
            ),
            value: 2,
            groupValue: _pickupOption,
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _pickupOption = val as int),
          ),

          if (_pickupOption == 2)
            _buildAddressAndPinFields(
              addressController: _pickupAddressController,
              location: _pickupLocation,
              hasPinned: _pickupHasPinned,
              isExpanded: _pickupMapExpanded,
              showAddressField: true,
              pinButtonText: 'กดเพื่อปักหมุดจุดรับ',
              onToggleMap: () =>
                  setState(() => _pickupMapExpanded = !_pickupMapExpanded),
              onLocationChanged: (loc, addr) {
                setState(() {
                  _pickupLocation = loc;
                  _pickupHasPinned = true;
                });
              },
            ),
        ],
      ),
    );
  }

  // ---------------- วิดเจ็ตรวม: สร้างช่องกรอกที่อยู่ (เปิด/ปิดได้) + ปุ่มแผนที่ ----------------
  Widget _buildAddressAndPinFields({
    TextEditingController? addressController,
    required LatLng location,
    required bool hasPinned,
    required bool isExpanded,
    required bool showAddressField,
    required String pinButtonText,
    required VoidCallback onToggleMap,
    required Function(LatLng, String) onLocationChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAddressField && addressController != null) ...[
          TextFormField(
            controller: addressController,
            maxLines: 2,
            style: const TextStyle(fontSize: 14),
            decoration: _inputDecoration(
              'บ้านเลขที่ ถนน ตำบล อำเภอ จังหวัด เลขไปรษณีย์',
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? 'กรุณาระบุรายละเอียดที่อยู่'
                : null,
          ),
          const SizedBox(height: 12),
        ],

        _buildPinButton(
          hasPinned: hasPinned,
          isExpanded: isExpanded,
          defaultText: pinButtonText,
          onTap: onToggleMap,
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LocationPickerWidget(
                      initialLocation: location,
                      initialAddress: addressController?.text ?? '',
                      showAddressTextField:
                          false, // 🌟 ปิดช่องกรอกที่อยู่ในแผนที่เสมอ ตามที่คุณต้องการ
                      onLocationChanged: onLocationChanged,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPinButton({
    required bool hasPinned,
    required bool isExpanded,
    required String defaultText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasPinned ? lightPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPinned ? primaryColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.map_outlined,
              color: hasPinned ? primaryColor : Colors.grey.shade700,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasPinned ? 'เลือกพิกัดแล้ว (แตะเพื่อแก้ไข)' : defaultText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasPinned ? FontWeight.w600 : FontWeight.normal,
                  color: hasPinned ? primaryColor : Colors.grey.shade700,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down, color: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Helper Widgets พื้นฐาน ----------------

  Widget _buildPatientCard() {
    if (_patientData == null) return const SizedBox();
    return _buildInfoCard(
      title: 'ผู้ป่วย',
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
      firstName: _relativeData!['firstname'] ?? '',
      lastName: _relativeData!['lastname'] ?? '',
      phone: _relativeData!['phonenumber'] ?? '-',
      extraInfo: 'ความสัมพันธ์: ${_relativeData!['relationship'] ?? '-'}',
      showAvatar: false,
    );
  }

  Widget _buildCaretakerCard() {
    return _buildInfoCard(
      title: 'ผู้ดูแล',
      firstName: widget.caretakerData['firstname'] ?? '',
      lastName: widget.caretakerData['lastname'] ?? '',
      phone: widget.caretakerData['phonenumber'] ?? '-',
      photoBase64: widget.caretakerData['profilephoto'],
      isCaretaker: true,
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String firstName,
    required String lastName,
    required String phone,
    String? photoBase64,
    String? extraInfo,
    bool isCaretaker = false,
    bool showAvatar = true,
  }) {
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
                  'คุณ $firstName $lastName'.trim(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
