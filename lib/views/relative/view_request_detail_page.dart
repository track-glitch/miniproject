import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miniproject/views/relative/view_doctor_advice_page.dart';

import '../../widgets/custom_header_nav.dart';
import '../../services/caretaker_service.dart';
import 'package:miniproject/models/request_model.dart';
import 'review_caretaker_page.dart';

enum RequestStatus {
  pending,
  acceptedEarly,
  acceptedReady,
  completed,
  cancelled,
}

class ViewRequestDetailPage extends StatefulWidget {
  final RequestModel requestModel;
  final String caretakerName;
  final String loggedUid;

  const ViewRequestDetailPage({
    super.key,
    required this.requestModel,
    required this.caretakerName,
    required this.loggedUid,
  });

  @override
  State<ViewRequestDetailPage> createState() => _ViewRequestDetailPageState();
}

class _ViewRequestDetailPageState extends State<ViewRequestDetailPage> {
  // ── 🎨 ชุดสีหลักของธีม ─────────────────────────────────────────
  final Color primaryColor = const Color(0xFF8763E6);
  final Color darkPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color lightPurple = const Color(0xFFECE2FE);
  final Color accentTeal = const Color(0xFF0F766E);
  final Color accentPink = const Color(0xFFBE185D);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color greyBorder = const Color(0xFFD3C2F0);

  // ── 🌟 ชุดสีเสริมสำหรับกรอบและสถานะ ───────────────────────────
  final Color sectionBgColor = const Color(0xFFF8F5FF);
  final Color cardBgColor = Colors.white;
  final Color labelColor = const Color(0xFF241C2B);

  late RequestStatus currentStatus;
  bool _isLoading = true;

  Map<String, dynamic>? patientData;
  Map<String, dynamic>? relativeData;
  Map<String, dynamic>? caretakerData;
  double caretakerRating = 0.0;
  int caretakerReviewCount = 0;

  bool isReviewed = false;
  bool isReported = false;

  Map<dynamic, dynamic>? doctorAdviceData;
  String? caretakerUidForReview;

  @override
  void initState() {
    super.initState();
    isReviewed = widget.requestModel.review != null;
    isReported = widget.requestModel.report != null;
    _setInitialStatus();
    _fetchDetailData();
  }

  void _setInitialStatus() {
    String statusStr = (widget.requestModel.requeststatus ?? 'pending')
        .toLowerCase();
    switch (statusStr) {
      case 'pending':
        currentStatus = RequestStatus.pending;
        break;
      case 'accepted':
        currentStatus = RequestStatus.acceptedEarly;
        break;
      case 'completed':
        currentStatus = RequestStatus.completed;
        break;
      case 'cancelled':
        currentStatus = RequestStatus.cancelled;
        break;
      default:
        currentStatus = RequestStatus.pending;
    }
  }

  Future<void> _fetchDetailData() async {
    try {
      final relSnap = await FirebaseDatabase.instance
          .ref('Login/${widget.loggedUid}/Relative')
          .get();
      if (relSnap.exists && relSnap.value is Map) {
        relativeData = Map<String, dynamic>.from(relSnap.value as Map);
      }

      final patSnap = await FirebaseDatabase.instance
          .ref('Login/${widget.loggedUid}/Relative/Patient')
          .get();
      if (patSnap.exists && patSnap.value is Map) {
        patientData = Map<String, dynamic>.from(patSnap.value as Map);
      }

      final requestSnap = await FirebaseDatabase.instance
          .ref(
            'Login/${widget.loggedUid}/Relative/Request/${widget.requestModel.requestId}',
          )
          .get();
      if (requestSnap.exists && requestSnap.value is Map) {
        final reqData = requestSnap.value as Map;
        setState(() {
          doctorAdviceData = reqData['DoctorAdvice'];
        });
      }

      String? targetId = widget.requestModel.caretakerId;
      if (targetId != null && targetId.isNotEmpty) {
        final usersSnap = await FirebaseDatabase.instance.ref('Login').get();
        if (usersSnap.exists && usersSnap.value is Map) {
          final users = usersSnap.value as Map<dynamic, dynamic>;

          users.forEach((key, value) {
            if (value['Caretaker'] != null &&
                value['Caretaker']['caretakerId'] == targetId) {
              caretakerUidForReview = key.toString();
              caretakerData = Map<String, dynamic>.from(value['Caretaker']);
              if (value['email'] != null) {
                caretakerData!['email'] = value['email'];
              }
            }
          });
          if (caretakerUidForReview != null) {
            final reviews = await CaretakerService().getAllReviews(
              caretakerUidForReview!,
            );
            caretakerReviewCount = reviews.length;

            if (reviews.isNotEmpty) {
              double sum = reviews
                  .map((r) => r['rating'] as double)
                  .reduce((a, b) => a + b);
              caretakerRating = sum / reviews.length;
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching details: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showReviewPage() {
    if (caretakerUidForReview == null) return;

    String dateStr = _formatThaiDateFull(widget.requestModel.appointmentdate);
    String timeStr = _formatTime(widget.requestModel.appointmenttime);
    String fullDateTime = '$dateStr เวลา $timeStr';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewCaretakerPage(
          requestId: widget.requestModel.requestId!,
          relativeUid: widget.loggedUid,
          caretakerUid: caretakerUidForReview!,
          caretakerName: widget.caretakerName,
          hospitalName: widget.requestModel.hospitalname ?? 'ไม่ระบุโรงพยาบาล',
          appointmentDateStr: fullDateTime,
          caretakerImage: caretakerData?['profilephoto'],
        ),
      ),
    ).then((value) {
      if (value == true) {
        setState(() {
          isReviewed = true;
        });
      }
    });
  }

  void _navigateToDoctorAdvicePage() {
    if (doctorAdviceData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewDoctorAdvicePage(loggedUid: widget.loggedUid),
      ),
    );
  }

  void _showReportDialog() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String? selectedType;
    final TextEditingController detailController = TextEditingController();

    bool hasImage = false;
    File? imageFile;
    String? imageBase64;
    bool isSubmitting = false;

    final List<String> reportTypes = [
      'ผู้ดูแลมาสาย / ไม่มาตามนัด',
      'พฤติกรรมไม่เหมาะสม / ไม่สุภาพ',
      'ขับรถประมาท / ไม่ปลอดภัย',
      'เรียกเก็บเงินเพิ่มเกินจริง',
      'อื่นๆ',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
              );

              if (image != null) {
                final bytes = await image.readAsBytes();
                setDialogState(() {
                  imageFile = File(image.path);
                  imageBase64 = base64Encode(bytes);
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 32),
                            Text(
                              'รายงาน',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: accentPink,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.red,
                                size: 28,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                if (!isSubmitting) Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'ประเภทรายงาน',
                          style: TextStyle(fontSize: 14, color: labelColor),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: InputDecoration(
                            hintText: 'เลือกประเภทรายงาน',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: greyBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: greyBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                          items: reportTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setDialogState(() => selectedType = val);
                          },
                          validator: (val) =>
                              val == null ? 'กรุณาเลือกประเภทรายงาน' : null,
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'รายละเอียด',
                          style: TextStyle(fontSize: 14, color: labelColor),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: detailController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'อธิบายรายละเอียด...',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: greyBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: greyBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'กรุณาระบุรายละเอียด'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Checkbox(
                              value: hasImage,
                              activeColor: primaryColor,
                              onChanged: (val) {
                                setDialogState(() {
                                  hasImage = val ?? false;
                                  if (!hasImage) {
                                    imageFile = null;
                                    imageBase64 = null;
                                  }
                                });
                              },
                            ),
                            const Text(
                              'มีรูปภาพประกอบ (ถ้ามี)',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),

                        if (hasImage) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: pickImage,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: sectionBgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: greyBorder),
                              ),
                              child: imageFile != null
                                  ? Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            imageFile!,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'เปลี่ยนรูปภาพ',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: lightPurple,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.arrow_upward,
                                            color: primaryColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'อัพโหลดรูปภาพ',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Text(
                                          'PNG, JPG (สูงสุด 5MB)',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentPink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      if (hasImage && imageBase64 == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'กรุณาอัปโหลดรูปภาพ หรือนำเครื่องหมายติ๊กถูกออก',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      setDialogState(() => isSubmitting = true);
                                      try {
                                        String reportId =
                                            'REP-${DateTime.now().millisecondsSinceEpoch}';

                                        final newReport = {
                                          'reportId': reportId,
                                          'reporttype': selectedType,
                                          'reportdetail': detailController.text,
                                          'reportphoto': imageBase64 ?? "",
                                          'reportdate': DateTime.now()
                                              .toIso8601String(),
                                        };

                                        await FirebaseDatabase.instance
                                            .ref(
                                              'Login/${widget.loggedUid}/Relative/Request/${widget.requestModel.requestId}/Report',
                                            )
                                            .set(newReport);

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('ส่งรายงานสำเร็จ'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          setState(() {
                                            isReported = true;
                                          });
                                        }
                                      } catch (e) {
                                        setDialogState(
                                          () => isSubmitting = false,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'เกิดข้อผิดพลาด: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'ส่งรายงาน',
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
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _cancelRequest() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ยกเลิกคำขอ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildAvatar(
                  caretakerData?['profilephoto'] ??
                      patientData?['patientphoto'],
                  radius: 35,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.caretakerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'คุณต้องการยกเลิกคำขอไหม?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade500,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          setState(() => _isLoading = true);
                          try {
                            await FirebaseDatabase.instance
                                .ref(
                                  'Login/${widget.loggedUid}/Relative/Request/${widget.requestModel.requestId}',
                                )
                                .update({'requeststatus': 'cancelled'});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ยกเลิกคำขอสำเร็จ'),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            setState(() => _isLoading = false);
                          }
                        },
                        child: const Text(
                          'ตกลง',
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
        );
      },
    );
  }

  String _formatThaiDateFull(DateTime? date) {
    if (date == null) return '-';
    List<String> months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '-';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} น.';
  }

  String _calculateAge(String? birthdate) {
    if (birthdate == null || birthdate.trim().isEmpty) return '-';
    DateTime? birth = DateTime.tryParse(birthdate);
    if (birth == null && birthdate.contains('/')) {
      final parts = birthdate.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          birth = DateTime(year, month, day);
        }
      }
    }
    if (birth == null) return '-';
    return '${DateTime.now().year - birth.year}';
  }

  // 🌟 Helper สร้างกรอบคลุมแต่ละ Section ให้สวยงามตรงตามชุดสี
  Widget _buildSectionWrapper({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionBgColor,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomHeader(
          title: 'รายละเอียดคำขอ',
          showBackButton: true,
        ),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    var req = widget.requestModel;
    String statusText = 'รอตอบรับ';
    Color statusColor = const Color(0xFF757BFF);
    Color statusBgColor = const Color(0xFFE8EAFF);

    if (currentStatus == RequestStatus.acceptedEarly ||
        currentStatus == RequestStatus.acceptedReady) {
      statusText = 'ตอบรับแล้ว';
      statusColor = primaryColor;
      statusBgColor = lightPurple;
    } else if (currentStatus == RequestStatus.completed) {
      statusText = 'สิ้นสุดบริการ';
      statusColor = const Color(0xFF00B14F);
      statusBgColor = const Color(0xFFE8F5E9);
    } else if (currentStatus == RequestStatus.cancelled) {
      statusText = 'ยกเลิกบริการ';
      statusColor = const Color(0xFFF44336);
      statusBgColor = const Color(0xFFFFEBEE);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const CustomHeader(title: 'รายละเอียดคำขอ', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: greyBorder, width: 1.5),
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
                  // --- ส่วนหัวคำขอ ---
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ใบคำขอรับบริการ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '#${req.requestId}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: labelColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ส่งคำขอเมื่อ: ${_formatThaiDateFull(req.requestdate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 🌟 Section 1: ข้อมูลการนัดหมาย ──
                  _buildSectionWrapper(
                    title: 'ข้อมูลการนัดหมาย',
                    icon: Icons.calendar_month_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDocField(
                                'โรงพยาบาล',
                                req.hospitalname ?? 'ไม่ระบุสถานที่',
                              ),
                            ),
                            Expanded(
                              child: _buildDocField(
                                'แผนก',
                                req.departmentname ?? '-',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDocField(
                                'วันที่นัดหมาย',
                                _formatThaiDateFull(req.appointmentdate),
                              ),
                            ),
                            Expanded(
                              child: _buildDocField(
                                'เวลานัดหมาย',
                                _formatTime(req.appointmenttime),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDocField(
                          'รายละเอียดคำขอ',
                          (req.requestdetail?.isEmpty ?? true)
                              ? '-'
                              : req.requestdetail!,
                        ),
                      ],
                    ),
                  ),

                  // ── 🌟 Section 2: ผู้ดูแลที่ได้รับมอบหมาย ──
                  if (caretakerData != null &&
                      widget.caretakerName != 'รอผู้ดูแลตอบรับ')
                    _buildSectionWrapper(
                      title: 'ผู้ดูแลที่ได้รับมอบหมาย',
                      icon: Icons.support_agent_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildAvatar(
                                caretakerData?['profilephoto'],
                                radius: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.caretakerName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.orange,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${caretakerRating.toStringAsFixed(1)} ($caretakerReviewCount รีวิว)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
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
                          Row(
                            children: [
                              Expanded(
                                child: _buildDocField(
                                  'อายุ',
                                  '${_calculateAge(caretakerData?['birthdate'])} ปี',
                                ),
                              ),
                              Expanded(
                                child: _buildDocField(
                                  'เพศ',
                                  caretakerData?['gender'] ?? '-',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDocField(
                                  'เบอร์ติดต่อ',
                                  caretakerData?['phonenumber'] ?? '-',
                                ),
                              ),
                              Expanded(
                                child: _buildDocField(
                                  'อีเมล',
                                  caretakerData?['email'] ?? '-',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // ── 🌟 Section 3: ข้อมูลผู้ป่วย ──
                  _buildSectionWrapper(
                    title: 'ข้อมูลผู้ป่วย',
                    icon: Icons.person_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildAvatar(
                              patientData?['patientphoto'],
                              radius: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDocField(
                                'ชื่อ - นามสกุล',
                                '${patientData?['firstname'] ?? '-'} ${patientData?['lastname'] ?? ''}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDocField(
                                'อายุ',
                                '${_calculateAge(patientData?['birthdate'])} ปี',
                              ),
                            ),
                            Expanded(
                              child: _buildDocField(
                                'เพศ',
                                patientData?['gender'] ?? '-',
                              ),
                            ),
                            Expanded(
                              child: _buildDocField(
                                'เบอร์โทร',
                                patientData?['phonenumber'] ?? '-',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildBottomActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDocField(
    String label,
    String value, {
    Color? color,
  }) {
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
          value,
          style: TextStyle(
            fontSize: 14,
            color: color ?? labelColor,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    if (currentStatus == RequestStatus.cancelled) {
      return const SizedBox.shrink();
    }

    if (currentStatus == RequestStatus.completed) {
      return Column(
        children: [
          if (doctorAdviceData != null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _navigateToDoctorAdvicePage,
                label: const Text(
                  'ดูคำแนะนำและนัดหมายถัดไป',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          if (doctorAdviceData != null && !isReviewed)
            const SizedBox(height: 12),

          if (!isReviewed)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showReviewPage,
                label: const Text(
                  'ให้คะแนนบริการ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          if (!isReported)
            GestureDetector(
              onTap: _showReportDialog,
              child: Text(
                'รายงานผู้ดูแล',
                style: TextStyle(
                  color: accentPink,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: accentPink,
                ),
              ),
            )
          else
            const Text(
              'คุณได้ส่งรายงานปัญหาสำหรับบริการนี้แล้ว',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      );
    }

    if (currentStatus == RequestStatus.pending) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFF44336), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _cancelRequest,
          icon: const Icon(Icons.close, color: Color(0xFFF44336), size: 18),
          label: const Text(
            'ยกเลิกคำขอ',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFFF44336),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildAvatar(dynamic imageString, {double radius = 26}) {
    ImageProvider? imgProv;
    if (imageString != null && imageString.toString().isNotEmpty) {
      try {
        String clean = imageString.toString().replaceAll('\n', '').trim();
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
          ? Icon(Icons.person, color: primaryColor, size: radius + 5)
          : null,
    );
  }
}