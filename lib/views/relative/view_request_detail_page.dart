import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

import '../../widgets/custom_header_nav.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../caretaker/add_status_notification_page.dart';
import '../../views/caretaker/list_relative_request_page.dart';
import '../caretaker/edit_profile_page.dart';
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

  final Color primaryPurple = const Color(0xFF9B59B6);
  final Color bgPurple = const Color.fromARGB(255, 225, 202, 255);
  final Color orangeAccent = const Color(0xFFFF8C00);

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
      // 🌟 ดึงข้อมูลญาติ
      final relSnap = await FirebaseDatabase.instance
          .ref('Login/${widget.loggedUid}/Relative')
          .get();
      if (relSnap.exists && relSnap.value is Map) {
        relativeData = Map<String, dynamic>.from(relSnap.value as Map);
      }

      // 🌟 ดึงข้อมูลผู้ป่วย
      final patSnap = await FirebaseDatabase.instance
          .ref('Login/${widget.loggedUid}/Relative/Patient')
          .get();
      if (patSnap.exists && patSnap.value is Map) {
        patientData = Map<String, dynamic>.from(patSnap.value as Map);
      }

      // 🌟 ดึงข้อมูล Caretaker
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316), // สีส้ม
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                              );
                            }
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
    if (date == null) return 'ไม่ระบุวันที่';
    List<String> days = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
    ];
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
    return 'วัน${days[date.weekday % 7]}ที่ ${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'ไม่ระบุเวลา';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} น.';
  }

  String _calculateAge(String? birthdate) {
    if (birthdate == null || birthdate.isEmpty) return 'ไม่ระบุ';
    final birth = DateTime.tryParse(birthdate);
    if (birth == null) return 'ไม่ระบุ';
    int age = DateTime.now().year - birth.year;
    return '$age';
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

    // ตั้งค่าสีสถานะ
    String statusText = 'อยู่ระหว่างรอ';
    Color statusColor = orangeAccent;
    Color statusBgColor = const Color(0xFFFFF3E0);

    if (currentStatus == RequestStatus.acceptedEarly ||
        currentStatus == RequestStatus.acceptedReady) {
      statusText = 'ผู้ดูแลตอบรับแล้ว';
      statusColor = const Color(0xFF00B14F);
      statusBgColor = const Color(0xFFB9F6CA);
    } else if (currentStatus == RequestStatus.completed) {
      statusText = 'สิ้นสุดบริการ';
      statusColor = const Color(0xFF00B14F);
      statusBgColor = const Color(0xFFB9F6CA);
    } else if (currentStatus == RequestStatus.cancelled) {
      statusText = 'ยกเลิกบริการ';
      statusColor = const Color(0xFFF44336);
      statusBgColor = const Color(0xFFFFEBEE);
    }

    String countdownText = '';
    if (req.appointmentdate != null) {
      final difference = req.appointmentdate!.difference(DateTime.now()).inDays;
      if (difference > 0) {
        countdownText = 'อีก $difference วัน';
      } else if (difference == 0) {
        countdownText = 'วันนี้';
      } else {
        countdownText = 'ผ่านมาแล้ว';
      }
    }

    return Scaffold(
      backgroundColor: bgPurple,
      appBar: const CustomHeader(title: 'รายละเอียดคำขอ', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. การ์ดหัวข้อ (Header) ตามรูป ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.hospitalname ?? 'ไม่ระบุสถานที่',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: orangeAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            req.departmentname ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor, width: 1.2),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '# ${req.requestId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── ข้อมูลผู้ป่วย (Patient Data) ──
            _buildSectionTitle('ข้อมูลผู้ป่วย'),
            _buildCard(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(patientData?['patientphoto'], radius: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${patientData?['firstname'] ?? 'ไม่ระบุ'} ${patientData?['lastname'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'อายุ ${_calculateAge(patientData?['birthdate'])} ปี · เพศ${patientData?['gender'] ?? '-'}  ${patientData?['mobility'] ?? ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (patientData?['disease'] != null &&
                                patientData!['disease'].toString().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.favorite,
                                      color: Colors.orange,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        patientData!['disease'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ),
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'เบอร์ผู้ป่วย',
                    value: patientData?['phonenumber'] ?? '-',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── ข้อมูลญาติ (Relative Data) ──
            _buildSectionTitle('ญาติ'),
            _buildCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${relativeData?['firstname'] ?? 'ไม่ระบุ'} ${relativeData?['lastname'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          relativeData?['relationship'] ?? 'ญาติ',
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ),
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'เบอร์โทร',
                    value: relativeData?['phonenumber'] ?? '-',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.chat_bubble_outline,
                    label: 'LINE ID',
                    value: relativeData?['lineId'] ?? '-',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── วันและเวลานัดหมาย ──
            _buildSectionTitle('วันและเวลานัดหมาย'),
            _buildCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: primaryPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatThaiDateFull(req.appointmentdate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'เวลา ${_formatTime(req.appointmenttime)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (countdownText.isNotEmpty &&
                      currentStatus != RequestStatus.completed &&
                      currentStatus != RequestStatus.cancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0B2), // ส้มอ่อน
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Colors.orange,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            countdownText,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── จุดรับจุดส่ง (Timeline) ──
            _buildSectionTitle('จุดรับจุดส่ง'),
            _buildCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      _buildHollowCircle(primaryPurple),
                      ...List.generate(
                        5,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          width: 2,
                          height: 4,
                          color: Colors.grey.shade400, // สีเทาไข่ปลา
                        ),
                      ),
                      _buildHollowCircle(Colors.black),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'จุดรับ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          req.pickuplocation?.address ?? 'ไม่ระบุ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'จุดส่ง',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          req.dropofflocation?.address ?? 'ไม่ระบุ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── ผู้ดูแลที่ได้รับมอบหมาย (ถ้ามี) ──
            if (caretakerData != null &&
                widget.caretakerName != 'รอผู้ดูแลตอบรับ') ...[
              _buildSectionTitle('ผู้ดูแลที่ได้รับมอบหมาย'),
              _buildCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildAvatar(caretakerData?['profilephoto']),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.caretakerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < caretakerRating.floor()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: const Color(0xFFFFC107),
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${caretakerRating.toStringAsFixed(1)} • $caretakerReviewCount รีวิว',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ),
                    _buildInfoRow(
                      icon: Icons.phone,
                      label: 'เบอร์โทร',
                      value: caretakerData?['phonenumber'] ?? '-',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── รายละเอียดคำร้อง ──
            _buildSectionTitle('รายละเอียดคำร้อง'),
            _buildCard(
              child: Text(
                req.requestdetail ?? 'ไม่มีรายละเอียด',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildBottomActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 🌟 ฟังก์ชันจัดการปุ่มด้านล่างตามสถานะ
  Widget _buildBottomActionButtons() {
    // ถ้ายกเลิกคำขอแล้ว ให้ซ่อนปุ่มไปเลย
    if (currentStatus == RequestStatus.cancelled) {
      return const SizedBox.shrink();
    }

    // 🌟 ถ้าสถานะ เสร็จสิ้น (Completed) ให้โชว์ปุ่มดูวันนัดและรายงาน
    if (currentStatus == RequestStatus.completed) {
      return Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // TODO: นำทางไปหน้า "ดูวันนัดหมายและคำแนะนำของแพทย์"
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลังเปิดหน้าดูวันนัดหมาย...')),
                );
              },
              child: const Text(
                'ดูวันนัดหมายและคำแนะนำ',
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
            onTap: () {
              // TODO: นำทางไปหน้า "รายงานผู้ดูแล"
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('กำลังเปิดหน้ารายงาน...')),
              );
            },
            child: const Center(
              child: Text(
                'รายงานผู้ดูแล',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.red,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 🌟 ถ้าสถานะ รอตอบรับ (Pending) ให้โชว์ปุ่มยกเลิกคำขอ
    if (currentStatus == RequestStatus.pending) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFEBEE),
              elevation: 0,
              side: const BorderSide(color: Color(0xFFF44336), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: _cancelRequest,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close, color: Color(0xFFF44336), size: 20),
                SizedBox(width: 8),
                Text(
                  'ยกเลิกคำขอ',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFF44336),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // สถานะอื่นๆ (Accepted) ไม่ต้องแสดงปุ่มอะไรเพิ่มเติม
    return const SizedBox.shrink();
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 4, right: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15, // ปรับขนาดตัวอักษรนิดหน่อยให้พอดี
              fontWeight: FontWeight.bold,
              color: primaryPurple,
            ),
          ),
          const SizedBox(width: 12), // ระยะห่างระหว่างข้อความกับเส้น
          Expanded(
            child: Divider(
              color: primaryPurple.withOpacity(0.25), // สีเส้นขีดบางๆ โทนม่วง
              thickness: 2, // ความหนาของเส้น
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHollowCircle(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3.5),
      ),
    );
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
      backgroundColor: const Color(0xFFE8D5FF),
      backgroundImage: imgProv,
      child: imgProv == null
          ? Icon(Icons.person, color: Colors.black54, size: radius + 2)
          : null,
    );
  }

  // ฟังก์ชันช่วยจัดเรียงข้อมูลแบบแถวให้ตรงกัน (Grid-like)
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 12),
        // กำหนดความกว้างคงที่ให้ Label เพื่อให้ Value ด้านหลังเรียงตรงกัน
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
