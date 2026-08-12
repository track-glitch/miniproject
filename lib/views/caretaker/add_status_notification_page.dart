import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:miniproject/views/caretaker/add_doctor_advice_page.dart';
import 'dart:async';
import 'package:intl/intl.dart';

import '../../widgets/custom_header_nav.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../caretaker/edit_profile_page.dart';
import '../../views/caretaker/list_relative_request_page.dart';
import '../../services/caretaker_service.dart';

class AddStatusNotificationPage extends StatefulWidget {
  final RequestCard requestData;
  final String uid;

  const AddStatusNotificationPage({
    super.key,
    required this.requestData,
    required this.uid,
  });

  @override
  State<AddStatusNotificationPage> createState() =>
      _AddStatusNotificationPageState();
}

class _AddStatusNotificationPageState extends State<AddStatusNotificationPage> {
  int _bottomNavIndex = 1;
  final CaretakerService _service = CaretakerService();

  final List<String> _statusList = [
    'กำลังเดินทางไปรับ',
    'ถึงจุดรับผู้ป่วย',
    'กำลังเดินทางไปโรงพยาบาล',
    'ถึงโรงพยาบาล',
    'รอคิวพบแพทย์',
    'กำลังรักษา',
    'ตรวจรักษาเสร็จสิ้น',
    'กำลังเดินทางกลับ',
    'ถึงจุดหมายปลายทาง',
    'เสร็จสิ้นการให้บริการ',
  ];

  bool _isLoading = true;
  List<Map<dynamic, dynamic>> _notificationHistory = [];
  List<String> _availableStatusList = []; // 🌟 เก็บสถานะที่ยังไม่ได้ส่ง

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _trackingTimer;

  String? _selectedStatus;
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _cancelRemarkController =
      TextEditingController(); // 🌟 สำหรับกรอกหมายเหตุยกเลิก
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  // ── 🎨 ชุดสีหลักควบคุมธีม ─────────────────────────────────────────
  final Color primaryPurple = const Color(0xFF8763E6);
  final Color darkPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color lightPurple = const Color(0xFFECE2FE);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color borderColor = const Color(0xFFD3C2F0);
  final Color sectionBgColor = const Color(0xFFF8F5FF);
  final Color historyColor = Colors.green; // 🌟 เปลี่ยนประวัติเป็นสีเขียว

  @override
  void initState() {
    super.initState();
    _initData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  Future<void> _initData() async {
    _notificationHistory = await _service.getNotifications(
      widget.requestData.relativeUid,
      widget.requestData.id,
    );

    _updateAvailableStatuses();

    setState(() {
      _isLoading = false;
    });
  }

  // 🌟 ฟังก์ชันคำนวณว่าสถานะไหนบ้างที่ยังไม่เคยส่ง
  void _updateAvailableStatuses() {
    _availableStatusList.clear();
    for (String s in _statusList) {
      // เช็กว่ามีสถานะนี้ในประวัติไหม (และต้องไม่ใช่สถานะที่ถูกยกเลิกไปแล้ว)
      bool exists = _notificationHistory.any((n) {
        String title = n['notifystatus'] ?? n['status'] ?? '';
        return title == s && !title.contains('ยกเลิก');
      });

      if (!exists) {
        _availableStatusList.add(s);
      }
    }

    if (_availableStatusList.isNotEmpty) {
      // ป้องกัน Error กรณี _selectedStatus ค้างค่าที่ไม่มีใน List
      if (_selectedStatus == null ||
          !_availableStatusList.contains(_selectedStatus)) {
        _selectedStatus = _availableStatusList.first;
      }
    } else {
      _selectedStatus = null;
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _trackingTimer?.cancel();
    _clockTimer?.cancel();
    _detailController.dispose();
    _cancelRemarkController.dispose();
    super.dispose();
  }

  // 🌟 ฟังก์ชันแสดงป๊อปอัพยืนยันการส่ง
  void _showConfirmationDialog() {
    if (_selectedStatus == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'ยืนยันการส่งสถานะ',
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryPurple),
          ),
          content: Text(
            'คุณต้องการแจ้งเตือนสถานะ\n"$_selectedStatus" ใช่หรือไม่?',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _submitStatus();
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
          ],
        );
      },
    );
  }

  void _submitStatus() async {
    if (_isLoading || _selectedStatus == null) return;
    setState(() => _isLoading = true);

    try {
      String statusToSubmit = _selectedStatus!;
      String detailToSubmit = _detailController.text.trim();

      await _service.addStatusNotification(
        relativeUid: widget.requestData.relativeUid,
        requestId: widget.requestData.id,
        status: statusToSubmit,
        detail: detailToSubmit,
      );

      _notificationHistory = await _service.getNotifications(
        widget.requestData.relativeUid,
        widget.requestData.id,
      );
      _updateAvailableStatuses(); // 🌟 อัปเดต Dropdown หลังส่งสำเร็จ
      _detailController.clear();

      if (statusToSubmit == 'เสร็จสิ้นการให้บริการ') {
        await _service.updateRequestStatus(
          widget.requestData.relativeUid,
          widget.requestData.id,
          'pending_advice',
        );
        _positionStreamSubscription?.cancel();
        _trackingTimer?.cancel();

        List<String> dateParts = widget.requestData.date.split('·');
        String dateOnly = dateParts[0].trim();
        String timeOnly = dateParts.length > 1 ? dateParts[1].trim() : '';

        Map<String, dynamic> reqInfo = {
          'patientName': widget.requestData.patient,
          'dateTime': '$dateOnly $timeOnly',
          'hospital': widget.requestData.serviceName,
          'department': widget.requestData.category,
        };

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AddDoctorAdvicePage(
                relativeUid: widget.requestData.relativeUid,
                requestId: widget.requestData.id,
                requestInfo: reqInfo,
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งสถานะสำเร็จแล้ว!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Error submitting status: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 ฟังก์ชันแสดงป๊อปอัพยกเลิกสถานะ
  void _showCancelDialog(String notifId, String oldStatus) {
    _cancelRemarkController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'ยกเลิกสถานะล่าสุด',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'คุณต้องการยกเลิกสถานะ\n"$oldStatus" ใช่หรือไม่?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _cancelRemarkController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'หมายเหตุการยกเลิก',
                  hintText: 'เช่น กดผิดสถานะ, ยังไปไม่ถึง',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ปิด', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (_cancelRemarkController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกหมายเหตุการยกเลิก')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _cancelLatestNotification(
                  notifId,
                  oldStatus,
                  _cancelRemarkController.text.trim(),
                );
              },
              child: const Text(
                'ยืนยันยกเลิก',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 🌟 ฟังก์ชันทำงานเมื่อกดยกเลิก
  Future<void> _cancelLatestNotification(
    String notifId,
    String oldStatus,
    String remark,
  ) async {
    setState(() => _isLoading = true);
    try {
      await _service.cancelNotificationStatus(
        relativeUid: widget.requestData.relativeUid,
        requestId: widget.requestData.id,
        notifId: notifId,
        cancelRemark: 'ยกเลิกสถานะ "$oldStatus" เนื่องจาก: $remark',
      );

      _notificationHistory = await _service.getNotifications(
        widget.requestData.relativeUid,
        widget.requestData.id,
      );
      _updateAvailableStatuses(); // 🌟 อัปเดต Dropdown เพื่อเอาสถานะกลับมาให้เลือกใหม่

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยกเลิกสถานะสำเร็จ'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Error cancelling status: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    List<String> dateParts = widget.requestData.date.split('·');
    String dateOnly = dateParts[0].trim();
    String timeOnly = dateParts.length > 1 ? dateParts[1].trim() : '';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const CustomHeader(
        title: 'ส่งสถานะการแจ้งเตือน',
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryPurple))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // กล่องข้อมูลบริการ
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: _cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.medical_information_outlined,
                                        color: primaryPurple,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ข้อมูลบริการปัจจุบัน',
                                        style: TextStyle(
                                          color: primaryPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    widget.requestData.id,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 20,
                                thickness: 1.2,
                                color: Color(0xFFECE2FE),
                              ),
                              _buildInfoRow(
                                'ผู้ป่วย:',
                                widget.requestData.patient,
                                isBold: true,
                              ),
                              _buildInfoRow(
                                'วัน/เวลา:',
                                '$dateOnly  $timeOnly',
                              ),
                              _buildInfoRow(
                                'สถานที่:',
                                widget.requestData.serviceName,
                              ),
                              _buildInfoRow(
                                'แผนก:',
                                widget.requestData.category,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // กล่องส่งสถานะ
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: _cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.update_rounded,
                                        color: primaryPurple,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'อัปเดตสถานะการบริการ',
                                        style: TextStyle(
                                          color: primaryPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.orange.shade800,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat(
                                          'HH:mm น.',
                                        ).format(_currentTime),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.orange.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (_availableStatusList.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'ส่งสถานะครบทุกขั้นตอนแล้ว 🎉',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: _selectedStatus,
                                      decoration: InputDecoration(
                                        labelText: 'สถานะปัจจุบัน',
                                        labelStyle: TextStyle(
                                          color: primaryPurple,
                                          fontSize: 13,
                                        ),
                                        filled: true,
                                        fillColor: sectionBgColor,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                            width: 1.2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: primaryPurple,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                      ),
                                      items: _availableStatusList
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                s,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF241C2B),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => _selectedStatus = val),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _detailController,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        labelText:
                                            'รายละเอียดเพิ่มเติม (ถ้ามี)',
                                        labelStyle: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                        hintText:
                                            'เช่น ถึงก่อนเวลา 10 นาที, ผู้ป่วยขึ้นรถเรียบร้อย',
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 13,
                                        ),
                                        filled: true,
                                        fillColor: sectionBgColor,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                            width: 1.2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: primaryPurple,
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // กล่องแสดงประวัติ Timeline
                        Container(
                          padding: const EdgeInsets.all(18),
                          width: double.infinity,
                          decoration: _cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    color: primaryPurple,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ประวัติการส่งสถานะ',
                                    style: TextStyle(
                                      color: primaryPurple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTimeline(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (_availableStatusList.isNotEmpty) _buildBottomAction(),
              ],
            ),
    );
  }

  Widget _buildTimeline() {
    if (_notificationHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            'ยังไม่มีประวัติการส่งสถานะ',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ),
      );
    }

    _notificationHistory.sort((a, b) {
      String timeA = a['notifydate'] ?? a['timestamp'] ?? "";
      String timeB = b['notifydate'] ?? b['timestamp'] ?? "";
      return timeA.compareTo(timeB);
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _notificationHistory.length,
      itemBuilder: (context, index) {
        var item = _notificationHistory[index];
        bool isLast = index == _notificationHistory.length - 1;
        return _buildTimelineTile(item: item, isLast: isLast);
      },
    );
  }

  Widget _buildDashedLine(Color color) {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          width: 2,
          height: 4,
          color: color,
          margin: const EdgeInsets.symmetric(vertical: 2.5),
        ),
      ),
    );
  }

  Widget _buildTimelineTile({
    required Map<dynamic, dynamic> item,
    required bool isLast,
  }) {
    String title = item['notifystatus'] ?? item['status'] ?? 'ไม่ทราบสถานะ';
    String detailText = item['notifydetail']?.toString() ?? '';
    // 🌟 ดึง ID ของ Notification เพื่อใช้ตอนยกเลิก (เปลี่ยนชื่อ Key ตามโครงสร้างใน Firebase ของคุณ)
    String notifId = item['id'] ?? item['notifyId'] ?? item['key'] ?? '';

    bool isCancelled = title.contains('ยกเลิก');
    Color currentStatusColor = isCancelled ? Colors.red : historyColor;
    IconData statusIcon = isCancelled ? Icons.close : Icons.check;

    String dateText = '';
    String timeText = '';

    String? rawDate = item['notifydate'] ?? item['timestamp'];
    if (rawDate != null) {
      try {
        DateTime dt = DateTime.parse(rawDate).toLocal();
        dateText = DateFormat('dd/MM/yyyy').format(dt); // 🌟 เพิ่มวันที่
        timeText = DateFormat('HH:mm น.').format(dt);
      } catch (e) {}
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentStatusColor,
                border: Border.all(color: currentStatusColor, width: 1),
              ),
              child: Icon(statusIcon, color: Colors.white, size: 16),
            ),
            if (!isLast)
              _buildDashedLine(
                isCancelled ? Colors.red.shade200 : Colors.green.shade200,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isCancelled
                              ? Colors.red
                              : const Color(0xFF241C2B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${dateText.isNotEmpty ? '$dateText ' : ''}${timeText.isNotEmpty ? '$timeText' : ''}", // 🌟 แสดงวันและเวลา
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (detailText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            detailText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // 🌟 แสดงปุ่มยกเลิกเฉพาะรายการล่าสุด และต้องยังไม่ถูกยกเลิก
                if (isLast && !isCancelled && notifId.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    tooltip: 'ยกเลิกสถานะนี้',
                    onPressed: () => _showCancelDialog(notifId, title),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 65,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF241C2B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.1),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SizedBox(
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
          onPressed: _isLoading ? null : _showConfirmationDialog,
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
                  'ส่งแจ้งเตือน',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
