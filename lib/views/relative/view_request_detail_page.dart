import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
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
  late RequestStatus currentStatus;
  bool _isLoading = true;

  Map<String, dynamic>? patientData;
  Map<String, dynamic>? relativeData;
  Map<String, dynamic>? caretakerData;
  double caretakerRating = 0.0;
  int caretakerReviewCount = 0;

  bool isReviewed = false;
  Map<dynamic, dynamic>? doctorAdviceData;
  String? caretakerUidForReview;

  final Color primaryPurple = const Color(0xFF8763E6);
  final Color bgGray = const Color(0xFFF4EDFB);

  @override
  void initState() {
    super.initState();
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
        isReviewed = reqData['isReviewed'] ?? false;
        doctorAdviceData = reqData['DoctorAdvice'];
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
          _isLoading = true;
        });
        _fetchDetailData();
      }
    });
  }

  // 🌟 ฟังก์ชันเปิดหน้าคำแนะนำจากแพทย์แบบเต็มจอ
  void _navigateToDoctorAdvicePage() {
    if (doctorAdviceData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewDoctorAdvicePage(
          loggedUid: widget.loggedUid,
          // 💡 หมายเหตุ: ตอนนี้หน้า ViewDoctorAdvicePage เป็นข้อมูลจำลอง (Mock Data)
          // ในอนาคตคุณสามารถเพิ่ม Parameter เพื่อส่ง doctorAdviceData, patientData และ req ไปแสดงผลจริงได้ครับ
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomHeader(
          title: 'รายละเอียดคำขอ',
          showBackButton: true,
        ),
        body: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    var req = widget.requestModel;
    String statusText = 'รอตอบรับ';
    Color statusColor = const Color(0xFF757BFF);
    Color statusBgColor = const Color(0xFFE8EAFF);

    if (currentStatus == RequestStatus.acceptedEarly ||
        currentStatus == RequestStatus.acceptedReady) {
      statusText = 'ตอบรับแล้ว';
      statusColor = primaryPurple;
      statusBgColor = const Color(0xFFF3E5F5);
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
      backgroundColor: bgGray,
      appBar: const CustomHeader(title: 'รายละเอียดคำขอ', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
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
                                'ใบคำขอรับบริการ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '#${req.requestId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ส่งคำขอเมื่อ: ${_formatThaiDateFull(req.requestdate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
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

                  _buildSectionDivider('ข้อมูลการนัดหมาย'),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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

                  if (caretakerData != null &&
                      widget.caretakerName != 'รอผู้ดูแลตอบรับ') ...[
                    _buildSectionDivider('ผู้ดูแลที่ได้รับมอบหมาย'),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
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
                                        color: primaryPurple,
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
                  ],

                  _buildSectionDivider('ข้อมูลผู้ป่วย'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  const SizedBox(height: 20),
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
    Color color = Colors.black87,
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
            color: color,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSectionDivider(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        children: [
          const SizedBox(
            width: 0,
            child: Divider(color: Color(0xFFE8E8E8), thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryPurple,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: Color(0xFFE8E8E8), thickness: 1),
          ),
        ],
      ),
    );
  }

  // 🌟 รวมปุ่มแยกให้ชัดเจนตรงนี้
  Widget _buildBottomActionButtons() {
    if (currentStatus == RequestStatus.cancelled)
      return const SizedBox.shrink();

    if (currentStatus == RequestStatus.completed) {
      return Column(
        children: [
          // ปุ่มที่ 1: ดูคำแนะนำจากแพทย์ (แสดงเมื่อมีข้อมูล)
          if (doctorAdviceData != null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple, // สีม่วง
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

          // ปุ่มที่ 2: ให้คะแนนบริการ (แสดงเฉพาะตอนที่ยังไม่ได้รีวิว)
          if (!isReviewed)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // สีส้ม
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

          GestureDetector(
            onTap: () {},
            child: const Text(
              'รายงานผู้ดูแล',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Colors.red,
              ),
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
              borderRadius: BorderRadius.circular(10),
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
      backgroundColor: const Color(0xFFF3E5F5),
      backgroundImage: imgProv,
      child: imgProv == null
          ? Icon(Icons.person, color: Colors.black54, size: radius + 5)
          : null,
    );
  }
}
