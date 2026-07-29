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
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _trackingTimer;

  String? _selectedStatus;
  final TextEditingController _detailController = TextEditingController();
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  final Color bgColor = const Color(0xFFF3E5FF);
  final Color primaryPurple = const Color(0xFF7D3C98);
  final Color completePurple = const Color(0xFF6A1B9A);
  final Color warningYellow = const Color(0xFFFFCA28);

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

    // Default สถานะใน Dropdown เป็นขั้นตอนถัดไปที่ยังไม่เคยส่ง
    for (String s in _statusList) {
      bool exists = _notificationHistory.any(
        (n) => n['notifystatus'] == s || n['status'] == s,
      );
      if (!exists) {
        _selectedStatus = s;
        break;
      }
    }
    _selectedStatus ??= _statusList.last;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _trackingTimer?.cancel();
    _clockTimer?.cancel();
    _detailController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() => _bottomNavIndex = index);
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfilePage(uid: widget.uid),
        ),
      );
    }
  }

  // 🌟 ฟังก์ชันแสดงป๊อปอัพยืนยัน
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
              onPressed: () {
                Navigator.of(context).pop(); // ปิดป๊อปอัพโดยไม่ทำอะไร
              },
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
                Navigator.of(context).pop(); // ปิดป๊อปอัพก่อน
                _submitStatus(); // 🌟 ค่อยเรียกฟังก์ชันส่งข้อมูลจริง
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

      int currentIndex = _statusList.indexOf(statusToSubmit);
      if (currentIndex != -1 && currentIndex < _statusList.length - 1) {
        _selectedStatus = _statusList[currentIndex + 1];
      }
      _detailController.clear();

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🌟 1. กล่องข้อมูลบริการ (UI แบบ Card)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPurple.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ข้อมูลบริการปัจจุบัน',
                                    style: TextStyle(
                                      color: primaryPurple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    widget.requestData.id,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, thickness: 1),
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

                        // 🌟 2. กล่องฟอร์มสำหรับเลือกและส่งการแจ้งเตือน
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPurple.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'อัปเดตสถานะการบริการ',
                                    style: TextStyle(
                                      color: primaryPurple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
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
                              DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: InputDecoration(
                                  labelText: 'สถานะปัจจุบัน',
                                  filled: true,
                                  fillColor: const Color(0xFFF9F9F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: primaryPurple,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                items: _statusList
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s,
                                          style: const TextStyle(fontSize: 14),
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
                                  labelText: 'รายละเอียดเพิ่มเติม (ถ้ามี)',
                                  hintText:
                                      'เช่น ถึงก่อนเวลา 10 นาที, ผู้ป่วยขึ้นรถเรียบร้อย',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF9F9F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: primaryPurple,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🌟 3. กล่องแสดงประวัติสถานะที่ส่งไปแล้ว (Timeline ประวัติ)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryPurple.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ประวัติการส่งสถานะ',
                                style: TextStyle(
                                  color: primaryPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
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
                _buildBottomAction(),
              ],
            ),
    );
  }

  // 🌟 นำข้อมูลจาก _notificationHistory มาแสดงเป็น Timeline เท่านั้น
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

    // จัดเรียงตามเวลาเก่าไปใหม่
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

  Widget _buildDashedLine() {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          width: 2,
          height: 4,
          color: Colors.grey.shade300,
          margin: const EdgeInsets.symmetric(vertical: 2.5),
        ),
      ),
    );
  }

  // 🌟 สร้าง UI สำหรับประวัติที่สำเร็จแล้วเท่านั้น
  Widget _buildTimelineTile({
    required Map<dynamic, dynamic> item,
    required bool isLast,
  }) {
    String title = item['notifystatus'] ?? item['status'] ?? 'ไม่ทราบสถานะ';
    String detailText = item['notifydetail']?.toString() ?? '';
    String timeText = '';

    String? rawDate = item['notifydate'] ?? item['timestamp'];
    if (rawDate != null) {
      try {
        DateTime dt = DateTime.parse(rawDate).toLocal();
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
                color: completePurple,
                border: Border.all(color: completePurple, width: 1),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            if (!isLast) _buildDashedLine(),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${timeText.isNotEmpty ? '$timeText — ' : ''}ส่งแล้ว",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (detailText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            detailText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                color: Colors.black87,
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
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          // 🌟 แก้ไขตรงนี้ จาก _submitStatus เป็น _showConfirmationDialog
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
