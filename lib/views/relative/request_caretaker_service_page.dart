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

  const ServiceRequestPage({
    super.key,
    required this.caretakerData,
    required this.caretakerId,
    this.loggedUid,
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

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;

  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _customLocationController =
      TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  int _locationOption = 1; // 1 = ที่อยู่ปัจจุบัน, 2 = ระบุสถานที่รับ

  // สำหรับแผนที่
  LatLng _selectedLocation = const LatLng(13.7563, 100.5018);
  bool _hasPinned = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.utc(2030, 12, 31),
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
<<<<<<< HEAD
                  color: primaryColor.withValues(alpha: 0.15), // 🌟 แก้สีเงากล่องให้เป็นโทนม่วง
=======
                  color: primaryColor.withValues(
                    alpha: 0.15,
                  ), // 🌟 แก้สีเงากล่องให้เป็นโทนม่วง
>>>>>>> b519ff17f9516aff75d567b820e13ebaa86f3b88
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'วันที่นัดหมาย',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: labelColor,
                  ),
                ),
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
                        Icon(Icons.calendar_today, color: primaryColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
<<<<<<< HEAD
                        backgroundColor: lightPurple, // 🌟 เปลี่ยนพื้นหลังเป็นม่วงอ่อน
=======
                        backgroundColor:
                            lightPurple, // 🌟 เปลี่ยนพื้นหลังเป็นม่วงอ่อน
>>>>>>> b519ff17f9516aff75d567b820e13ebaa86f3b88
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
                            ? Icon(
                                Icons.person,
<<<<<<< HEAD
                                color: primaryColor, // 🌟 เปลี่ยนสีไอคอนคนเป็นสีม่วง
=======
                                color:
                                    primaryColor, // 🌟 เปลี่ยนสีไอคอนคนเป็นสีม่วง
>>>>>>> b519ff17f9516aff75d567b820e13ebaa86f3b88
                                size: 35,
                              )
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
                            const SizedBox(height: 6),
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

                Text(
                  'ระบุรายละเอียดคำขอ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _detailController,
                  maxLines: 3,
                  decoration: _inputDecoration(''),
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาระบุรายละเอียด' : null,
                ),
                const SizedBox(height: 16),

                Text(
                  'ระบุสถานที่จุดรับ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: labelColor,
                  ),
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'ใช้ที่อยู่ปัจจุบันตามที่ระบุในโปรไฟล์',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: 1,
                  groupValue: _locationOption,
                  activeColor: primaryColor,
                  onChanged: (val) => setState(() {
                    _locationOption = val as int;
                    // ล้างค่าที่อยู่ค้นหาเก่าเผื่อเปลี่ยนใจ
                    FocusScope.of(context).unfocus();
                  }),
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'สถานที่จุดรับ',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: 2,
                  groupValue: _locationOption,
                  activeColor: primaryColor,
                  onChanged: (val) =>
                      setState(() => _locationOption = val as int),
                ),

                // 🌟 ลบ TextFormField (บ้านเลขที่ ถนน ตำบล) ออกไปแล้ว
                // 🌟 และใช้ if ควบคุมให้โชว์ LocationPickerWidget เฉพาะเมื่อกดสถานที่จุดรับ
                if (_locationOption == 2)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: darkPurple,
                        width: 2,
                      ), // เพิ่มสีขอบให้เด่นขึ้น
                      boxShadow: [
                        BoxShadow(
<<<<<<< HEAD
                          color: darkPurple.withValues(alpha: 0.2), // 🌟 ปรับสีเงากล่องแผนที่ให้อ่อนลง
=======
                          color: darkPurple.withValues(
                            alpha: 0.2,
                          ), // 🌟 ปรับสีเงากล่องแผนที่ให้อ่อนลง
>>>>>>> b519ff17f9516aff75d567b820e13ebaa86f3b88
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LocationPickerWidget(
                      initialLocation: _selectedLocation,
                      initialAddress: _customLocationController.text,
                      onLocationChanged: (newLocation, newAddress) {
                        setState(() {
                          _selectedLocation = newLocation;
                          _customLocationController.text = newAddress;
                          _hasPinned = true;
                        });
                      },
                    ),
                  ),

                Text(
                  'ระบุโรงพยาบาล',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hospitalController,
                  decoration: _inputDecoration('ชื่อโรงพยาบาล'),
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาระบุโรงพยาบาล' : null,
                ),
                const SizedBox(height: 16),

                Text(
                  'ระบุแผนกในโรงพยาบาล',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _departmentController,
                  decoration: _inputDecoration('ชื่อแผนก'),
                  validator: (value) => value!.isEmpty ? 'กรุณาระบุแผนก' : null,
                ),
                const SizedBox(height: 16),

                Text(
                  'ระบุเวลานัดหมาย',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: labelColor,
                  ),
                ),
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
                              ? '--:-- --'
                              : _selectedTime!.format(context),
                          style: TextStyle(
                            color: _selectedTime == null
                                ? Colors.grey
                                : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.access_time, color: primaryColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 4,
<<<<<<< HEAD
                          shadowColor: primaryColor.withValues(alpha: 0.4), // 🌟 ปรับสีเงาปุ่มให้เป็นโทนม่วง
=======
                          shadowColor: primaryColor.withValues(
                            alpha: 0.4,
                          ), // 🌟 ปรับสีเงาปุ่มให้เป็นโทนม่วง
>>>>>>> b519ff17f9516aff75d567b820e13ebaa86f3b88
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          // 🌟 เพิ่ม Validation ให้กับสถานที่จุดรับ ในกรณีที่ไม่ได้กรอกเข้ามา
                          if (_locationOption == 2 &&
                              _customLocationController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "กรุณาค้นหาสถานที่หรือปักหมุดจุดรับ",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return; // หยุดการทำงานถ้าไม่ได้กรอกสถานที่จุดรับ
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

                            DateTime appointmentDateTime = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute,
                            );

                            await requestRef.set({
                              "requestId": requestId,
                              "caretakerId": widget.caretakerId,
                              "requestdetail": _detailController.text.trim(),
                              "pickuplocation": _locationOption == 1
                                  ? "ที่อยู่จากโปรไฟล์ผู้ป่วย"
                                  : _customLocationController.text.trim(),
                              "dropofflocation": _hospitalController.text
                                  .trim(),
                              "hospitalname": _hospitalController.text.trim(),
                              "departmentname": _departmentController.text
                                  .trim(),
                              "appointmentdate": _selectedDate
                                  .toIso8601String(),
                              "appointmenttime": appointmentDateTime
                                  .toIso8601String(),
                              "requestdate": DateTime.now().toIso8601String(),
                              "requeststatus": "Pending",
                              "latitude": _locationOption == 2 && _hasPinned
                                  ? _selectedLocation.latitude
                                  : 0.0,
                              "longitude": _locationOption == 2 && _hasPinned
                                  ? _selectedLocation.longitude
                                  : 0.0,
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
                          backgroundColor: Colors.grey,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
