import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // 🌟 เพิ่ม package สำหรับจัดการรูปแบบวันที่
import 'package:miniproject/views/caretaker/list_relative_request_page.dart';
import '../../services/caretaker_service.dart';
import '../../widgets/custom_header_nav.dart';

class AddDoctorAdvicePage extends StatefulWidget {
  final String relativeUid;
  final String requestId;
  final Map<String, dynamic> requestInfo;

  const AddDoctorAdvicePage({
    super.key,
    required this.relativeUid,
    required this.requestId,
    required this.requestInfo,
  });

  @override
  State<AddDoctorAdvicePage> createState() => _AddDoctorAdvicePageState();
}

class _AddDoctorAdvicePageState extends State<AddDoctorAdvicePage> {
  final CaretakerService _service = CaretakerService();

  // Controllers
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _adviceController = TextEditingController();

  File? _imageFile;
  String? _base64Image;
  bool _isLoading = false;

  // 🌟 1. เพิ่มตัวแปรสำหรับควบคุม Checkbox
  bool _hasNextAppointment = false;

  @override
  void initState() {
    super.initState();
    // 🌟 2. Autofill ข้อมูลโรงพยาบาลและแผนก จากข้อมูลปัจจุบัน
    _hospitalController.text = widget.requestInfo['hospital'] ?? '';
    _deptController.text = widget.requestInfo['department'] ?? '';
  }

  // 🌟 3. ฟังก์ชันสำหรับเลือกวันที่ (Date Picker)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // ป้องกันการเลือกวันในอดีต
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA052BE), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // จัดรูปแบบเป็น วัน/เดือน/ปี (ค.ศ. หรือ พ.ศ. ค่อยว่ากัน)
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // 🌟 4. ฟังก์ชันสำหรับเลือกเวลา (Time Picker)
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFA052BE)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // แปลงเวลาเป็น 24 ชม. Format (เช่น 08:30)
        final now = DateTime.now();
        final dt = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        _timeController.text = DateFormat('HH:mm').format(dt);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      List<int> imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = File(pickedFile.path);
        _base64Image = base64Encode(imageBytes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ ต้องเพิ่มข้อมูลคำแนะนำของแพทย์ให้เสร็จก่อนกลับหน้าแรกค่ะ',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4EDFB),
        appBar: const CustomHeader(
          title: 'เพิ่มวันนัดและคำแนะนำ',
          showBackButton: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. ส่วน ข้อมูลบริการปัจจุบัน
              _buildSectionCard(
                title: "ข้อมูลบริการปัจจุบัน",
                child: Column(
                  children: [
                    _infoRow(
                      "ผู้ป่วย:",
                      widget.requestInfo['patientName'] ?? '-',
                    ),
                    _infoRow(
                      "วัน/เวลา:",
                      widget.requestInfo['dateTime'] ?? '-',
                    ),
                    _infoRow("สถานที่:", widget.requestInfo['hospital'] ?? '-'),
                    _infoRow("แผนก:", widget.requestInfo['department'] ?? '-'),
                  ],
                ),
              ),

              // 2. ส่วน การนัดหมายครั้งต่อไป
              _buildSectionCard(
                title: "การนัดหมายครั้งต่อไป",
                trailing: Checkbox(
                  value: _hasNextAppointment,
                  activeColor: const Color(0xFFA052BE),
                  onChanged: (bool? value) {
                    setState(() {
                      _hasNextAppointment = value ?? false;
                      // เคลียร์ข้อมูลถ้าเอาติ๊กออก (ยกเว้นรพ.และแผนกที่เป็นค่า Default)
                      if (!_hasNextAppointment) {
                        _doctorController.clear();
                        _dateController.clear();
                        _timeController.clear();
                      }
                    });
                  },
                ),
                child: Column(
                  children: [
                    const Text(
                      "ติ๊กถูกหากมีการนัดหมายในครั้งถัดไป",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    // 🌟 5. ใช้ Visibility เพื่อซ่อน/แสดง ฟอร์มตามการติ๊กถูก
                    Visibility(
                      visible: _hasNextAppointment,
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _textField(
                            "แพทย์ผู้นัด (ไม่บังคับ)",
                            _doctorController,
                          ),

                          // 🌟 เปลี่ยนเป็น Picker แทน TextField
                          _datePickerField("วันที่", _dateController, context),
                          _timePickerField("เวลา", _timeController, context),

                          _textField("สถานที่", _hospitalController),
                          _textField("แผนก", _deptController),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. ส่วน รายละเอียด/คำแนะนำ
              _buildSectionCard(
                title: "รายละเอียด/คำแนะนำเพิ่มเติม",
                child: Column(
                  children: [
                    TextField(
                      controller: _adviceController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "พิมพ์คำแนะนำหรือรายละเอียดเพิ่มเติม...",
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFA052BE),
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _imageFile == null
                            ? const Center(
                                child: Text(
                                  "📎 เพิ่มรูปถ่ายใบนัดหมาย (ถ้ามี)",
                                  style: TextStyle(color: Color(0xFFA052BE)),
                                ),
                              )
                            : Image.file(_imageFile!, height: 100),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA052BE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          // ล็อคบังคับ 1: เช็ครายละเอียดหรือรูป
                          if (_adviceController.text.trim().isEmpty &&
                              _base64Image == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '❌ กรุณากรอกรายละเอียด หรือ ถ่ายรูปใบนัดอย่างน้อยหนึ่งอย่างค่ะ',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // ล็อคบังคับ 2: ถ้าติ๊กถูกว่ามีนัดหมาย ต้องกรอกวันและเวลา
                          if (_hasNextAppointment) {
                            if (_dateController.text.isEmpty ||
                                _timeController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '❌ กรุณาเลือกวันที่และเวลาสำหรับการนัดหมายครั้งถัดไปค่ะ',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }

                          setState(() => _isLoading = true);

                          try {
                            // เก็บเฉพาะตอนที่ติ๊กเลือก
                            Map<String, dynamic> nextAppt = {};
                            if (_hasNextAppointment) {
                              nextAppt = {
                                'doctor': _doctorController.text,
                                'date': _dateController.text,
                                'time': _timeController.text,
                                'hospital': _hospitalController.text,
                                'department': _deptController.text,
                              };
                            }

                            await _service.saveDoctorAdvice(
                              relativeUid: widget.relativeUid,
                              requestId: widget.requestId,
                              adviceText: _adviceController.text,
                              base64Image: _base64Image ?? '',
                              nextAppointment:
                                  nextAppt, // ส่ง {} ไปถ้าไม่มีนัดหมาย
                            );

                            await _service.updateRequestStatus(
                              widget.relativeUid,
                              widget.requestId,
                              'completed',
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'บันทึกข้อมูลเสร็จสิ้น ขอบคุณที่ให้บริการค่ะ!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // 🌟 ลบของเก่าออก: Navigator.of(context).popUntil((route) => route.isFirst);

                              // 🌟 ใช้โค้ดใหม่นี้แทน: ล้าง Stack แล้วบังคับโหลดหน้า List ใหม่ทั้งหมด
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListRelativeRequestPage(
                                    uid: FirebaseAuth.instance.currentUser!.uid,
                                  ),
                                ),
                                (route) =>
                                    false, // false คือลบประวัติการย้อนกลับออกทั้งหมด
                              );
                            }
                          } catch (e) {
                            print("Error saving doctor advice: $e");
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "บันทึกและจบงาน",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFA052BE), // เปลี่ยนสีหัวข้อให้สวยขึ้น
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const Divider(),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  Widget _textField(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    ),
  );

  // 🌟 Widget พิเศษสำหรับกดเลือกวันที่
  Widget _datePickerField(
    String label,
    TextEditingController controller,
    BuildContext context,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      readOnly: true, // ป้องกันการพิมพ์เอง
      onTap: () => _selectDate(context),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(
          Icons.calendar_today,
          color: Color(0xFFA052BE),
          size: 20,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    ),
  );

  // 🌟 Widget พิเศษสำหรับกดเลือกเวลา
  Widget _timePickerField(
    String label,
    TextEditingController controller,
    BuildContext context,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      readOnly: true, // ป้องกันการพิมพ์เอง
      onTap: () => _selectTime(context),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(
          Icons.access_time,
          color: Color(0xFFA052BE),
          size: 20,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    ),
  );
}
