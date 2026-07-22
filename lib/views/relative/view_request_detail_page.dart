import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../widgets/custom_header_nav.dart';
import '../../services/caretaker_service.dart';
import 'package:miniproject/models/request_model.dart';

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

  final Color primaryPurple = const Color(0xFF8763E6);
  // 🌟 ปรับสีพื้นหลังให้เป็นสีม่วงอ่อนๆ เข้ากับธีมของแอป ดูไม่จืด
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
      if (relSnap.exists && relSnap.value is Map)
        relativeData = Map<String, dynamic>.from(relSnap.value as Map);

      final patSnap = await FirebaseDatabase.instance
          .ref('Login/${widget.loggedUid}/Relative/Patient')
          .get();
      if (patSnap.exists && patSnap.value is Map)
        patientData = Map<String, dynamic>.from(patSnap.value as Map);

      String? targetId = widget.requestModel.caretakerId;
      if (targetId != null && targetId.isNotEmpty) {
        final usersSnap = await FirebaseDatabase.instance.ref('Login').get();
        if (usersSnap.exists && usersSnap.value is Map) {
          final users = usersSnap.value as Map<dynamic, dynamic>;
          String? foundCaretakerUid;

          users.forEach((key, value) {
            if (value['Caretaker'] != null &&
                value['Caretaker']['caretakerId'] == targetId) {
              foundCaretakerUid = key.toString();
              caretakerData = Map<String, dynamic>.from(value['Caretaker']);
              // 🌟 ดึง Email มาด้วยเผื่อมันเก็บอยู่ที่ root ของ user
              if (value['email'] != null) {
                caretakerData!['email'] = value['email'];
              }
            }
          });

          if (foundCaretakerUid != null) {
            final reviews = await CaretakerService().getAllReviews(
              foundCaretakerUid!,
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
    if (birthdate == null || birthdate.isEmpty) return '-';
    final birth = DateTime.tryParse(birthdate);
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
    Color statusColor = const Color(0xFF757BFF); // สีน้ำเงิน
    Color statusBgColor = const Color(0xFFE8EAFF); // พื้นหลังสีฟ้าอ่อน

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
                // 🌟 เพิ่มเงาให้การ์ดดูมีมิติเล็กน้อย
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
                  // --- ส่วนหัว Header ---
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

                  // --- ข้อมูลสถานพยาบาลและนัดหมาย ---
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

                  _buildSectionDivider('ข้อมูลผู้ป่วย'),

                  // --- ข้อมูลผู้ป่วย ---
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDocField(
                                'สภาพร่างกาย',
                                patientData?['mobility'] ?? '-',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDocField(
                          'โรคประจำตัว',
                          (patientData?['disease']?.toString().isEmpty ?? true)
                              ? '-'
                              : patientData!['disease'],
                        ),
                      ],
                    ),
                  ),

                  _buildSectionDivider('ข้อมูลญาติ (ผู้ติดต่อ)'),

                  // --- ข้อมูลญาติ ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDocField(
                                'ชื่อ - นามสกุล',
                                '${relativeData?['firstname'] ?? '-'} ${relativeData?['lastname'] ?? ''}',
                              ),
                            ),
                            Expanded(
                              child: _buildDocField(
                                'ความสัมพันธ์',
                                relativeData?['relationship'] ?? '-',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDocField(
                                'เบอร์โทรศัพท์',
                                relativeData?['phonenumber'] ?? '-',
                              ),
                            ),
                            Expanded(
                              child: _buildDocField(
                                'LINE ID',
                                relativeData?['lineId'] ?? '-',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _buildSectionDivider('การเดินทาง'),

                  // --- จุดรับและจุดส่ง ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildDocField(
                                'จุดรับ',
                                req.pickuplocation?.address ?? 'ไม่ระบุ',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildDocField(
                                'จุดส่ง',
                                req.dropofflocation?.address ?? 'ไม่ระบุ',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 🌟 --- ส่วนข้อมูลผู้ดูแลที่ถูกปรับปรุงใหม่ ---
                  if (caretakerData != null &&
                      widget.caretakerName != 'รอผู้ดูแลตอบรับ') ...[
                    _buildSectionDivider('ผู้ดูแลที่ได้รับมอบหมาย'),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 20,
                      ),
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
                                    // 🌟 นำคะแนนรีวิวมาแสดง
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
                          // 🌟 เพิ่มฟิลด์ อายุ และ เพศ
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
                          // 🌟 เพิ่มฟิลด์ เบอร์ติดต่อ และ อีเมล
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
                  ] else ...[
                    const SizedBox(height: 20),
                  ],
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
          // 🌟 ทำให้ขีดด้านซ้ายสั้นลง เพื่อผลักข้อความไปทางซ้าย
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

  Widget _buildBottomActionButtons() {
    if (currentStatus == RequestStatus.cancelled)
      return const SizedBox.shrink();

    if (currentStatus == RequestStatus.completed) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {},
              child: const Text(
                'ดูวันนัดหมายและคำแนะนำ',
                style: TextStyle(
                  fontSize: 15,
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
