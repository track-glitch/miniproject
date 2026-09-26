import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/caretaker_model.dart';
import '../../models/document_model.dart';
import '../../services/admin_service.dart';

class ViewCaretakerRegistrationPage extends StatefulWidget {
  final CaretakerModel caretaker;
  const ViewCaretakerRegistrationPage({super.key, required this.caretaker});

  @override
  State<ViewCaretakerRegistrationPage> createState() =>
      _ViewCaretakerRegistrationPageState();
}

class _ViewCaretakerRegistrationPageState
    extends State<ViewCaretakerRegistrationPage> {
  final AdminService _adminService = AdminService();
  final TextEditingController _reasonController = TextEditingController();

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color backgroundColor = const Color(0xFFF9F9F9);
  final Color borderColor = Colors.black87;

  // เก็บสถานะผ่าน(true)/ไม่ผ่าน(false) ของเอกสารแต่ละอัน (Key = index)
  final Map<int, bool> _documentStatuses = {};

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // Helper: การจัดการรูปภาพ
  // ---------------------------------------------------------
  ImageProvider? _getImageProvider(String? data, {String folder = 'Profile'}) {
    if (data == null || data.trim().isEmpty) return null;
    if (data.startsWith('http')) return NetworkImage(data);
    if (data.contains('.')) return AssetImage('assets/images/$folder/$data');
    try {
      return MemoryImage(base64Decode(data));
    } catch (e) {
      return null;
    }
  }

  Widget _buildImageWidget(
    String? data, {
    String folder = 'Document',
    double height = 200,
    BoxFit fit = BoxFit.cover,
  }) {
    if (data == null || data.trim().isEmpty) {
      return Container(
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
      );
    }
    if (data.startsWith('http')) {
      return Image.network(
        data,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
        ),
      );
    }
    if (data.contains('.')) {
      return Image.asset(
        'assets/images/$folder/$data',
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
        ),
      );
    }
    try {
      return Image.memory(
        base64Decode(data),
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
        ),
      );
    } catch (e) {
      return Container(
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
      );
    }
  }

  void _showFullScreenImage(String? data, String folder) {
    if (data == null || data.isEmpty) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: false,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: _buildImageWidget(
                  data,
                  folder: folder,
                  height: MediaQuery.of(context).size.height * 0.7,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white, size: 35),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return '-';
    int age = DateTime.now().year - birthDate.year;
    return '$age ปี';
  }

  // ---------------------------------------------------------
  // Logic: ตรวจสอบและบันทึก
  // ---------------------------------------------------------
  void _handleSubmitReview() {
    // 🌟 1. สร้างลิสต์เอกสารที่ต้องบังคับตรวจสอบ (ตัด Resume และ Certificate ออก)
    final requiredDocs =
        widget.caretaker.documents?.where((doc) {
          String docId = doc.documentId ?? '';
          String docType = doc.documenttype ?? '';
          return !(docId == 'doc_resume' ||
              docType == 'ประวัติการทำงาน (Resume)' ||
              docType == 'resume' ||
              docId.startsWith('doc_certificate') ||
              docType.contains('ใบประกาศนียบัตร') ||
              docType == 'first_aid_certificate');
        }).toList() ??
        [];

    int requiredDocsCount = requiredDocs.length;

    // 🌟 2. นับว่ามีการกดผ่าน/ไม่ผ่านไปกี่อัน (นับเฉพาะเอกสารบังคับ)
    int checkedCount = 0;
    final docs = widget.caretaker.documents ?? [];
    for (int i = 0; i < docs.length; i++) {
      String docId = docs[i].documentId ?? '';
      String docType = docs[i].documenttype ?? '';
      bool isOptional =
          (docId == 'doc_resume' ||
          docType == 'ประวัติการทำงาน (Resume)' ||
          docType == 'resume' ||
          docId.startsWith('doc_certificate') ||
          docType.contains('ใบประกาศนียบัตร') ||
          docType == 'first_aid_certificate');

      if (!isOptional && _documentStatuses.containsKey(i)) {
        checkedCount++;
      }
    }

    if (checkedCount < requiredDocsCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาตรวจสอบและเลือกสถานะเอกสารสำคัญให้ครบทุกรายการ'),
        ),
      );
      return;
    }

    // 🌟 3. เช็กว่ามีเอกสารอันไหนที่โดนกด 'ไม่ผ่าน' บ้าง
    bool hasRejectedDoc = _documentStatuses.values.contains(false);

    if (hasRejectedDoc) {
      _showRejectDialog();
    } else {
      _showApproveDialog();
    }
  }

  void _showApproveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ยืนยันการอนุมัติ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'เอกสารผ่านทั้งหมด คุณต้องการอนุมัติ ${widget.caretaker.firstname} ${widget.caretaker.lastname} ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await _adminService.approveCaretaker(
                widget.caretaker.caretakerId!,
                widget.caretaker.documents ?? [],
              );
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('อนุมัติสำเร็จ')));
              }
            },
            child: const Text('อนุมัติ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'เอกสารไม่ผ่าน / ไม่อนุมัติ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'พบเอกสารที่ไม่ผ่านเกณฑ์ กรุณาระบุสิ่งที่ต้องแก้ไข:',
              style: TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'เช่น เอกสารใบขับขี่ไม่ชัดเจน กรุณาถ่ายใหม่...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (_reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาระบุสิ่งที่ต้องแก้ไขก่อนส่งกลับ'),
                  ),
                );
                return;
              }
              await _adminService.rejectCaretaker(
                widget.caretaker.caretakerId!,
                _reasonController.text.trim(),
                widget.caretaker.documents ?? [],
                _documentStatuses,
              );
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ส่งข้อมูลกลับให้ผู้ใช้งานแก้ไขเรียบร้อยแล้ว',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'ส่งกลับให้แก้ไข',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // UI: Components สำหรับแสดงข้อมูลเชื่อมโยงกับเอกสาร
  // ---------------------------------------------------------

  Widget _buildIdCardInfo() {
    String dobString = '-';
    if (widget.caretaker.birthdate != null) {
      final date = widget.caretaker.birthdate!;
      dobString =
          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year + 543}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () =>
                _showFullScreenImage(widget.caretaker.profilephoto, 'Profile'),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: primaryColor.withOpacity(0.2),
              backgroundImage: _getImageProvider(widget.caretaker.profilephoto),
              child: (widget.caretaker.profilephoto?.isEmpty ?? true)
                  ? const Icon(Icons.person, size: 35, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เลขบัตร: ${widget.caretaker.caretakerId ?? "-"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'ชื่อ: ${widget.caretaker.firstname} ${widget.caretaker.lastname}',
                ),
                Text(
                  'วันเกิด: $dobString (อายุ ${_calculateAge(widget.caretaker.birthdate)})',
                ),
                Text(
                  'ที่อยู่: ${widget.caretaker.location?.address ?? "-"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfo() {
    final v = widget.caretaker.vehicle;
    if (v == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🚗 ข้อมูลรถ: ${v.brand ?? "-"} ${v.model ?? "-"}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            'ทะเบียน: ${v.licenseplate ?? "-"} ${v.province ?? "-"}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.red,
            ),
          ),
          Text('ประเภท: ${v.vehicletype ?? "-"} | สี: ${v.color ?? "-"}'),
          const SizedBox(height: 8),
          if (v.vehiclephotos != null && v.vehiclephotos!.isNotEmpty)
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: v.vehiclephotos!.length,
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(
                      v.vehiclephotos![i].photo,
                      'Vehicle',
                    ),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageWidget(
                          v.vehiclephotos![i].photo,
                          folder: 'Vehicle',
                          fit: BoxFit.cover,
                          height: 70,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverLicenseInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ตรวจสอบชื่อผู้ถือบัตร: ${widget.caretaker.firstname} ${widget.caretaker.lastname}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ตรวจสอบชื่อในใบรับรอง/ใบประกาศ: ${widget.caretaker.firstname} ${widget.caretaker.lastname}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // UI: หน้าจอหลัก
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final docs = widget.caretaker.documents ?? [];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'ตรวจสอบข้อมูลและเอกสาร',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // พื้นที่ Scroll หลัก (ข้อมูลเรียงตามเอกสาร)
          Expanded(
            child: docs.isEmpty
                ? const Center(
                    child: Text(
                      'ไม่มีเอกสารแนบมา',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      bool? currentStatus = _documentStatuses[index];

                      String docId = doc.documentId ?? '';
                      String docType = doc.documenttype ?? '';
                      String title = 'เอกสารอื่นๆ';
                      Widget? infoWidget;

                      // จับคู่ Data (Text) กับ Document (Image)
                      if (docId == 'doc_idcard' ||
                          docType == 'สำเนาบัตรประชาชน' ||
                          docType == 'id_card') {
                        title = 'สำเนาบัตรประชาชน';
                        infoWidget = _buildIdCardInfo();
                      } else if (docId == 'doc_vehicle_reg' ||
                          docType == 'สำเนาทะเบียนรถ' ||
                          docType == 'vehicle_registration') {
                        title = 'สำเนาทะเบียนรถ';
                        infoWidget = _buildVehicleInfo();
                      } else if (docId == 'doc_driver_license' ||
                          docType == 'สำเนาใบขับขี่' ||
                          docType == 'driver_license') {
                        title = 'สำเนาใบขับขี่';
                        infoWidget = _buildDriverLicenseInfo();
                      } else if (docId == 'doc_insurance' ||
                          docType == 'สำเนาประกันภัยรถยนต์' ||
                          docType == 'car_insurance') {
                        title = 'สำเนาประกันภัยรถยนต์';
                        infoWidget = _buildVehicleInfo();
                      } else if (docId == 'doc_resume' ||
                          docType == 'ประวัติการทำงาน (Resume)' ||
                          docType == 'resume') {
                        title = 'ประวัติการทำงาน (Resume)';
                        infoWidget = Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'ประสบการณ์: ${widget.caretaker.experience?.isNotEmpty == true ? widget.caretaker.experience : "-"}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      } else if (docId.startsWith('doc_certificate') ||
                          docType.contains('ใบประกาศนียบัตร') ||
                          docType == 'first_aid_certificate') {
                        title = docType.isNotEmpty
                            ? docType
                            : 'ใบประกาศนียบัตร (Certificate)';
                        infoWidget = _buildCertificateInfo();
                      } else {
                        title = docType.isNotEmpty ? docType : docId;
                      }

                      // 🌟 1. เช็กว่าเป็นเอกสารเสริม (ไม่ต้องมีปุ่มผ่าน/ไม่ผ่าน) หรือไม่
                      bool isOptional =
                          (docId == 'doc_resume' ||
                          docType == 'ประวัติการทำงาน (Resume)' ||
                          docType == 'resume' ||
                          docId.startsWith('doc_certificate') ||
                          docType.contains('ใบประกาศนียบัตร') ||
                          docType == 'first_aid_certificate');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isOptional
                              ? Colors.white
                              : (currentStatus == true
                                    ? Colors.green.shade50
                                    : currentStatus == false
                                    ? Colors.red.shade50
                                    : Colors.white),
                          border: Border.all(
                            color: isOptional
                                ? Colors.grey.shade300
                                : (currentStatus == true
                                      ? Colors.green.shade300
                                      : currentStatus == false
                                      ? Colors.red.shade300
                                      : Colors.grey.shade300),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. $title',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // แปะข้อมูล Text ไว้เหนือรูปเอกสาร
                            if (infoWidget != null) infoWidget,

                            // รูปเอกสาร
                            GestureDetector(
                              onTap: () => _showFullScreenImage(
                                doc.filepath,
                                'Document',
                              ),
                              child: Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buildImageWidget(
                                    doc.filepath,
                                    folder: 'Document',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 🌟 2. ถ้าไม่ใช่เอกสารเสริม ถึงจะแสดงปุ่ม ผ่าน / ไม่ผ่าน
                            if (!isOptional)
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => setState(
                                        () => _documentStatuses[index] = true,
                                      ),
                                      icon: const Icon(
                                        Icons.check_circle,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'ผ่าน',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: currentStatus == true
                                            ? Colors.green
                                            : Colors.grey.shade200,
                                        foregroundColor: currentStatus == true
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        elevation: currentStatus == true
                                            ? 2
                                            : 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => setState(
                                        () => _documentStatuses[index] = false,
                                      ),
                                      icon: const Icon(Icons.cancel, size: 20),
                                      label: const Text(
                                        'ไม่ผ่าน',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: currentStatus == false
                                            ? Colors.red
                                            : Colors.grey.shade200,
                                        foregroundColor: currentStatus == false
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        elevation: currentStatus == false
                                            ? 2
                                            : 0,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Center(
                                child: Text(
                                  '(เอกสารอ้างอิง ไม่จำเป็นต้องตรวจสอบสถานะ)',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ปุ่ม Submit ติดอยู่ด้านล่างตลอดเวลา
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _handleSubmitReview,
                child: const Text(
                  'ส่งผลการตรวจสอบ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
