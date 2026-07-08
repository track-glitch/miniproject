import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _adviceController = TextEditingController();

  File? _imageFile;
  String? _base64Image;
  bool _isLoading = false; // 🌟 เพิ่มสเตทควบคุมการปุ่มโหลด

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
      canPop:
          false, // 🌟 ล็อคบังคับ: ห้ามผู้ใช้กดย้อนกลับทางอื่นเด็ดขาด (ปุ่ม Back เครื่อง / ปัดหน้าจอ)
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // แสดงการเตือนเมื่อผู้ใช้งานพยายามหาทางออก
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
          showBackButton:
              false, // 🌟 ล็อคบังคับ: ซ่อนปุ่มกดย้อนกลับบนหัวแอปบาร์ออกไปเลย
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
                trailing: Checkbox(value: true, onChanged: (v) {}),
                child: Column(
                  children: [
                    _textField("แพทย์ผู้นัด", _doctorController),
                    _textField("วันที่", _dateController),
                    _textField("เวลา", _timeController),
                    _textField("สถานที่", _hospitalController),
                    _textField("แผนก", _deptController),
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
                                  "📎 เพิ่มรูปถ่ายใบนัดหมาย",
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
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          // 🌟 ล็อคบังคับ: เช็คว่ากรอกข้อมูลสำคัญหรือยัง (อย่างใดอย่างหนึ่ง: คำแนะนำ หรือแนบรูป)
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
                            return; // เบรกระบบไว้ ไม่ให้เซฟลง Firebase
                          }

                          setState(
                            () => _isLoading = true,
                          ); // เปิดโหมดดาวน์โหลด หมุนๆ

                          try {
                            // มัดโครงสร้างข้อมูลนัดครั้งถัดไป
                            Map<String, dynamic> nextAppt = {
                              'doctor': _doctorController.text,
                              'date': _dateController.text,
                              'time': _timeController.text,
                              'hospital': _hospitalController.text,
                              'department': _deptController.text,
                            };

                            // สั่งเซฟข้อมูลตรงไปยัง Firebase
                            await _service.saveDoctorAdvice(
                              relativeUid: widget.relativeUid,
                              requestId: widget.requestId,
                              adviceText: _adviceController.text,
                              base64Image: _base64Image ?? '',
                              nextAppointment: nextAppt,
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
                                    'บันทึกคำแนะนำแพทย์สำเร็จเสร็จสิ้น!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // 🌟 ล็อคบังคับ: พอบันทึกเสร็จเรียบร้อยแล้ว ให้เคลียร์ Stack หน้าจอดีดผู้ใช้ออกไปหน้าแรก (Home/Dashboard)
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
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
                          "บันทึก",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
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
        SizedBox(width: 80, child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _textField(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    ),
  );
}
