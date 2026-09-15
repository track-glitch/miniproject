import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:miniproject/views/caretaker/list_relative_request_page.dart';
import '../../services/caretaker_service.dart';
import '../../widgets/custom_header_nav.dart';
import 'dart:typed_data';

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

  // ── 🎨 ชุดสีหลักควบคุมธีม ─────────────────────────────────────────
  final Color primaryPurple = const Color(0xFF7D3C98);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFECE2FE);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color borderColor = const Color(0xFF7D3C98);
  final Color sectionBgColor = const Color(0xFFF8F5FF);

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

  bool _hasNextAppointment = false;

  @override
  void initState() {
    super.initState();
    _hospitalController.text = widget.requestInfo['hospital'] ?? '';
    _deptController.text = widget.requestInfo['department'] ?? '';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryPurple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: primaryPurple)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
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

  // 🌟 Helper สร้างกรอบ Card คุมสไตล์ธีม
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: primaryPurple.withOpacity(0.12),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
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
        backgroundColor: bgColor,
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
                icon: Icons.medical_information_outlined,
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
                icon: Icons.calendar_month_outlined,
                trailing: Checkbox(
                  value: _hasNextAppointment,
                  activeColor: primaryPurple,
                  onChanged: (bool? value) {
                    setState(() {
                      _hasNextAppointment = value ?? false;
                      if (!_hasNextAppointment) {
                        _doctorController.clear();
                        _dateController.clear();
                        _timeController.clear();
                      }
                    });
                  },
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ติ๊กถูกหากมีการนัดหมายในครั้งถัดไป",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Visibility(
                      visible: _hasNextAppointment,
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _textField(
                            "แพทย์ผู้นัด (ไม่บังคับ)",
                            _doctorController,
                          ),
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
                icon: Icons.speaker_notes_outlined,
                child: Column(
                  children: [
                    TextField(
                      controller: _adviceController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryPurple,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: sectionBgColor,
                        hintText: "พิมพ์คำแนะนำหรือรายละเอียดเพิ่มเติม...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: sectionBgColor,
                          border: Border.all(
                            color: primaryPurple,
                            style: BorderStyle.solid,
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _imageFile == null
                            ? Center(
                                child: Text(
                                  "📎 เพิ่มรูปถ่ายใบนัดหมาย (ถ้ามี)",
                                  style: TextStyle(
                                    color: primaryPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Image.file(_imageFile!, height: 120),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 4,
                    shadowColor: primaryPurple.withOpacity(0.4),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
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

                          // 🌟 เปลี่ยนจาก String เป็น String? (อนุญาตให้เป็น null ได้)
                          String? finalDateToSave;
                          String? finalTimeToSave;

                          if (_hasNextAppointment) {
                            DateTime parsedDate = DateFormat(
                              'dd/MM/yyyy',
                            ).parse(_dateController.text);

                            finalDateToSave = DateFormat(
                              'yyyy-MM-dd',
                            ).format(parsedDate);

                            // 🌟 ปรับ Format ให้เป็น ISO 8601 (มีตัว T คั่น) เพื่อให้ DateTime.parse ของ Dart อ่านได้ชัวร์ 100%
                            finalTimeToSave =
                                "${finalDateToSave}T${_timeController.text}:00";
                          }

                          setState(() => _isLoading = true);

                          try {
                            await _service.saveDoctorAdvice(
                              relativeUid: widget.relativeUid,
                              requestId: widget.requestId,
                              advicedetail: _adviceController.text,
                              medicalphoto: _base64Image ?? '',
                              doctorname: _hasNextAppointment
                                  ? _doctorController.text
                                  : '',
                              hospitalname: _hasNextAppointment
                                  ? _hospitalController.text
                                  : '',
                              departmentname: _hasNextAppointment
                                  ? _deptController.text
                                  : '',
                              // 🌟 ส่งค่า finalDateToSave และ finalTimeToSave ที่เป็น null ไปแทนค่าว่าง
                              appointmentdate: finalDateToSave,
                              appointmenttime: finalTimeToSave,
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

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListRelativeRequestPage(
                                    uid: FirebaseAuth.instance.currentUser!.uid,
                                  ),
                                ),
                                (route) => false,
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
                            fontSize: 18,
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
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: primaryPurple, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: primaryPurple,
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const Divider(height: 20, thickness: 1.2, color: Color(0xFFECE2FE)),
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
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF241C2B),
              fontSize: 14,
            ),
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
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        filled: true,
        fillColor: sectionBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryPurple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    ),
  );

  Widget _datePickerField(
    String label,
    TextEditingController controller,
    BuildContext context,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(context),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        filled: true,
        fillColor: sectionBgColor,
        suffixIcon: Icon(Icons.calendar_today, color: primaryPurple, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryPurple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    ),
  );

  Widget _timePickerField(
    String label,
    TextEditingController controller,
    BuildContext context,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectTime(context),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        filled: true,
        fillColor: sectionBgColor,
        suffixIcon: Icon(Icons.access_time, color: primaryPurple, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryPurple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    ),
  );
}
