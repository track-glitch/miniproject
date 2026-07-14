import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:miniproject/views/login_page.dart';
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

  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  // สำหรับจุดรับ
  int _pickupOption = 1;
  final TextEditingController _pickupAddressController =
      TextEditingController();
  LatLng _pickupLocation = const LatLng(13.7563, 100.5018);
  bool _pickupHasPinned = false;

  // สำหรับจุดส่ง (🌟 ปรับใหม่ ไม่มี Option แล้ว บังคับปักหมุดเลย)
  final TextEditingController _dropoffAddressController =
      TextEditingController();
  LatLng _dropoffLocation = const LatLng(13.7563, 100.5018);
  bool _dropoffHasPinned = false;

  // 🌟 สถานะหุบ/ขยายของแผนที่จุดรับและจุดส่ง
  bool _pickupMapExpanded = false;
  bool _dropoffMapExpanded = false;

  // ข้อมูลที่อยู่จากโปรไฟล์
  Map<String, dynamic>? _relativeLocationProfile;
  List<DateTime> _caretakerBusyDates = [];

  @override
  void initState() {
    super.initState();
    _selectedDate =
        widget.initialSelectedDate ??
        DateTime.now().add(const Duration(days: 1));
    _fetchProfileLocation();
    _fetchCaretakerBusyDates();
  }

  Future<void> _fetchProfileLocation() async {
    String uid = widget.loggedUid ?? FirebaseAuth.instance.currentUser!.uid;
    try {
      // 🌟 แก้ path: ที่อยู่จริงๆ อยู่ใต้ Relative/Patient/location
      // (ดูจาก RelativeModel.toJson() -> 'Patient', PatientModel.toJson() -> 'location')
      final snapshot = await FirebaseDatabase.instance
          .ref('Login/$uid/Relative/Patient/location')
          .get();
      if (snapshot.exists && snapshot.value != null) {
        setState(() {
          _relativeLocationProfile = Map<String, dynamic>.from(
            snapshot.value as Map,
          );
        });
      }
    } catch (e) {
      print("Error fetch profile location: $e");
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
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('วันที่นัดหมาย', style: _labelStyle()),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatThaiDate(_selectedDate),
                          style: const TextStyle(fontSize: 14),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: primaryColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // การ์ดผู้ดูแล
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                    color: Colors.white,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: lightPurple,
                        backgroundImage:
                            widget.caretakerData['profilephoto'] != null &&
                                widget.caretakerData['profilephoto']
                                    .toString()
                                    .isNotEmpty
                            ? MemoryImage(
                                base64Decode(
                                  widget.caretakerData['profilephoto']
                                      .toString()
                                      .replaceAll('\n', '')
                                      .trim(),
                                ),
                              )
                            : null,
                        child:
                            widget.caretakerData['profilephoto'] == null ||
                                widget.caretakerData['profilephoto']
                                    .toString()
                                    .isEmpty
                            ? Icon(Icons.person, color: primaryColor, size: 35)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ผู้ดูแล',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'นาย ${widget.caretakerData['firstname'] ?? ''} ${widget.caretakerData['lastname'] ?? ''}'
                                  .trim(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
                                const SizedBox(width: 4),
                                const Text(
                                  '4.9 - 87 รีวิว',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'เบอร์โทร ${widget.caretakerData['phonenumber'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text('ระบุรายละเอียดคำขอ', style: _labelStyle()),
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
                const SizedBox(height: 20),

                // ── 🌟 ส่วนของจุดรับ ──
                Text('ระบุสถานที่จุดรับ (Pick-up)', style: _labelStyle()),
                RadioListTile(
                  title: const Text(
                    'ใช้ที่อยู่ปัจจุบันตามโปรไฟล์',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: 1,
                  groupValue: _pickupOption,
                  activeColor: primaryColor,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  onChanged: (val) =>
                      setState(() => _pickupOption = val as int),
                ),
                RadioListTile(
                  title: const Text(
                    'ปักหมุดสถานที่รับใหม่',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: 2,
                  groupValue: _pickupOption,
                  activeColor: primaryColor,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  onChanged: (val) =>
                      setState(() => _pickupOption = val as int),
                ),
                if (_pickupOption == 2) ...[
                  const SizedBox(height: 4),
                  _buildMapToggleHeader(
                    hasPinned: _pickupHasPinned,
                    addressText: _pickupAddressController.text,
                    placeholder: 'แตะเพื่อปักหมุดสถานที่จุดรับ',
                    isExpanded: _pickupMapExpanded,
                    onTap: () => setState(
                      () => _pickupMapExpanded = !_pickupMapExpanded,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _pickupMapExpanded
                        ? Container(
                            margin: const EdgeInsets.only(top: 8),
                            height: 400,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // 🌟 ตัดขอบแผนที่ไม่ให้ทะลุกรอบ
                              child: LocationPickerWidget(
                                initialLocation: _pickupLocation,
                                initialAddress: _pickupAddressController.text,
                                onLocationChanged: (loc, addr) {
                                  setState(() {
                                    _pickupLocation = loc;
                                    _pickupAddressController.text = addr;
                                    _pickupHasPinned = true;
                                  });
                                },
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
                const SizedBox(height: 20),

                // ── 🌟 ส่วนของจุดส่ง (Drop-off) ──
                Text('ระบุสถานที่จุดส่ง (Drop-off)', style: _labelStyle()),
                const SizedBox(height: 8),
                _buildMapToggleHeader(
                  hasPinned: _dropoffHasPinned,
                  addressText: _dropoffAddressController.text,
                  placeholder: 'แตะเพื่อปักหมุดสถานที่จุดส่ง',
                  isExpanded: _dropoffMapExpanded,
                  onTap: () => setState(
                    () => _dropoffMapExpanded = !_dropoffMapExpanded,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _dropoffMapExpanded
                      ? Container(
                          margin: const EdgeInsets.only(top: 8),
                          height: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // 🌟 ตัดขอบแผนที่
                            child: LocationPickerWidget(
                              initialLocation: _dropoffLocation,
                              initialAddress: _dropoffAddressController.text,
                              onLocationChanged: (loc, addr) {
                                setState(() {
                                  _dropoffLocation = loc;
                                  _dropoffAddressController.text = addr;
                                  _dropoffHasPinned = true;
                                });
                              },
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),

                Text('ระบุโรงพยาบาล', style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hospitalController,
                  style: const TextStyle(fontSize: 14),
                  decoration: _inputDecoration('ชื่อโรงพยาบาล'),
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาระบุโรงพยาบาล' : null,
                ),
                const SizedBox(height: 16),

                Text('ระบุแผนกในโรงพยาบาล', style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _departmentController,
                  style: const TextStyle(fontSize: 14),
                  decoration: _inputDecoration('ชื่อแผนก'),
                  validator: (value) => value!.isEmpty ? 'กรุณาระบุแผนก' : null,
                ),
                const SizedBox(height: 20),

                Text('ระบุเวลานัดหมาย', style: _labelStyle()),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTime == null
                              ? '--:-- น.'
                              : '${_selectedTime!.format(context)} น.',
                          style: TextStyle(
                            color: _selectedTime == null
                                ? Colors.grey
                                : Colors.black,
                            fontSize: 14,
                            fontWeight: _selectedTime == null
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.access_time, color: primaryColor, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ปุ่มยืนยัน/ยกเลิก
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 4,
                          shadowColor: primaryColor.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          // Validation สำหรับจุดรับและจุดส่ง
                          if (_pickupOption == 2 && !_pickupHasPinned) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "กรุณาปักหมุดสถานที่จุดรับ (Pick-up)",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (!_dropoffHasPinned) {
                            // บังคับเช็คว่าปักหมุดจุดส่งหรือยัง
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "กรุณาปักหมุดสถานที่จุดส่ง (Drop-off) บนแผนที่",
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
                                .push();
                            String requestId = requestRef.key!;

                            DateTime apptDT = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute,
                            );

                            Map<String, dynamic> pickupNode = {};
                            if (_pickupOption == 1) {
                              pickupNode = {
                                'address':
                                    _relativeLocationProfile?['address'] ??
                                    'ไม่พบที่อยู่ในโปรไฟล์',
                                'latitude':
                                    _relativeLocationProfile?['latitude'] ??
                                    0.0,
                                'longitude':
                                    _relativeLocationProfile?['longitude'] ??
                                    0.0,
                              };
                            } else {
                              pickupNode = {
                                'address': _pickupAddressController.text,
                                'latitude': _pickupLocation.latitude,
                                'longitude': _pickupLocation.longitude,
                              };
                            }

                            // สำหรับจุดส่ง บันทึกพิกัดที่ปักหมุดเสมอ
                            Map<String, dynamic> dropoffNode = {
                              'address': _dropoffAddressController.text,
                              'latitude': _dropoffLocation.latitude,
                              'longitude': _dropoffLocation.longitude,
                            };

                            await requestRef.set({
                              "requestId": requestId,
                              "caretakerId": widget.caretakerId,
                              "requestdetail": _detailController.text.trim(),
                              "PickupLocation": pickupNode,
                              "DropoffLocation": dropoffNode,
                              "hospitalname": _hospitalController.text.trim(),
                              "departmentname": _departmentController.text
                                  .trim(),
                              "appointmentdate": _selectedDate
                                  .toIso8601String(),
                              "appointmenttime": apptDT.toIso8601String(),
                              "requestdate": DateTime.now().toIso8601String(),
                              "requeststatus": "Pending",
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        backgroundColor: darkPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
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

  // 🌟 Helper สำหรับหัวข้อแบบแตะเพื่อหุบ/ขยายแผนที่
  Widget _buildMapToggleHeader({
    required bool hasPinned,
    required String addressText,
    required String placeholder,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    final bool showAddress = hasPinned && addressText.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              showAddress ? Icons.location_on : Icons.location_on_outlined,
              color: showAddress ? primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                showAddress ? addressText : placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: showAddress ? Colors.black87 : Colors.grey,
                  fontWeight: showAddress ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 8),
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

  // Helper สำหรับทำ Style ของ Label
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
