import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:miniproject/views/caretaker/add_doctor_advice_page.dart';
import 'dart:async';
import 'package:intl/intl.dart'; // 🌟 เพิ่ม package สำหรับจัดการเวลา

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
  bool _hasStarted = false;
  int _currentStepIndex = 0;

  // 🌟 เก็บประวัติการแจ้งเตือนจาก Firebase เพื่อเอาเวลามาโชว์
  List<Map<dynamic, dynamic>> _notificationHistory = [];

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _trackingTimer;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // 🌟 ดึงข้อมูลประวัติเพื่อนำมาสร้าง Timeline
    _notificationHistory = await _service.getNotifications(
      widget.requestData.relativeUid,
      widget.requestData.id,
    );

    _currentStepIndex = _notificationHistory.length;

    if (_currentStepIndex > 0) {
      _hasStarted = true;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _trackingTimer?.cancel();
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

  void _submitStatus() async {
    if (_isLoading || _currentStepIndex >= _statusList.length) return;

    setState(() => _isLoading = true);

    try {
      // 🌟 ดึงสถานะปัจจุบันที่จะส่ง จาก Index โดยตรง ไม่ต้องพึ่ง Dropdown
      String statusToSubmit = _statusList[_currentStepIndex];

      await _service.addStatusNotification(
        relativeUid: widget.requestData.relativeUid,
        requestId: widget.requestData.id,
        status: statusToSubmit,
      );

      // 🌟 ดึงประวัติใหม่ เพื่อเอา Timestamp ล่าสุดมาโชว์บนจอ
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

      setState(() {
        _hasStarted = true;
        _currentStepIndex = _notificationHistory.length; // อัปเดต Step ถัดไป
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งสถานะสำเร็จแล้ว!'),
            backgroundColor: Colors.green,
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
    // 🌟 1. ดึงและจัดการรูปแบบวันที่/เวลา (เพิ่มเข้ามาใหม่)
    List<String> dateParts = widget.requestData.date.split('·');
    String dateOnly = dateParts[0].trim();
    String timeOnly = dateParts.length > 1 ? dateParts[1].trim() : '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomHeader(
        title: 'ส่งสถานะการแจ้งเตือน',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7D3C98)),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🌟 2. ส่วนกล่อง "ข้อมูลบริการปัจจุบัน" (เพิ่มเข้ามาใหม่)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ข้อมูลบริการปัจจุบัน',
                              style: TextStyle(
                                color: Color(0xFF9B59B6), // สีม่วง
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              widget.requestData.id,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'ผู้ป่วย:',
                          widget.requestData.patient,
                          isBold: true,
                        ),
                        _buildInfoRow('วัน/เวลา:', '$dateOnly  $timeOnly'),
                        _buildInfoRow(
                          'สถานที่:',
                          widget.requestData.serviceName,
                        ),
                        _buildInfoRow('แผนก:', widget.requestData.category),

                        const SizedBox(height: 32), // ระยะห่างก่อนขึ้นส่วนถัดไป
                        // ----------------------------------------------------
                        const Text(
                          'รายละเอียดของการแจ้งเตือน',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Timeline รายละเอียดสถานะ
                        _buildTimeline(),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                // ส่วนปุ่มแจ้งเตือนด้านล่าง
                _buildBottomAction(),
              ],
            ),
    );
  }

  // 🌟 ฟังก์ชันวาด Timeline ทั้งหมด
  Widget _buildTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _statusList.length,
      itemBuilder: (context, index) {
        bool isCompleted = index < _currentStepIndex;
        bool isCurrent = index == _currentStepIndex;
        bool isLast = index == _statusList.length - 1;

        return _buildTimelineTile(
          index: index,
          title: _statusList[index],
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isLast: isLast,
        );
      },
    );
  }

  // 🌟 ฟังก์ชันวาดเส้นประ
  Widget _buildDashedLine() {
    return Column(
      children: List.generate(
        5,
        (index) => Container(
          width: 2,
          height: 4,
          color: Colors.grey.shade300,
          margin: const EdgeInsets.symmetric(vertical: 3),
        ),
      ),
    );
  }

  // 🌟 ฟังก์ชันวาดแต่ละแถวของสถานะ
  Widget _buildTimelineTile({
    required int index,
    required String title,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    String timeText = '';

    // พยายามดึงเวลาออกมาจากประวัติ ถ้าดึงสำเร็จให้แสดง ถ้าไม่มีให้ปล่อยว่าง
    if (isCompleted && index < _notificationHistory.length) {
      var data = _notificationHistory[index];
      if (data['timestamp'] != null) {
        try {
          // จำลองการจัด Format เวลา (ถ้า Firebase เป็น String ให้ใช้แบบนี้ได้เลย หรือปรับตามฟิลด์จริง)
          DateTime dt = DateTime.parse(data['timestamp'].toString()).toLocal();
          timeText = DateFormat('HH:mm น.').format(dt);
        } catch (e) {
          timeText = ""; // กรณี parse ไม่สำเร็จ
        }
      }
    } else if (isCurrent) {
      timeText = DateFormat('HH:mm น.').format(DateTime.now());
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // คอลัมน์ซ้าย: วงกลมสัญลักษณ์ และเส้นประ
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF6A1B9A) // สีม่วงเข้ม
                    : (isCurrent ? Colors.white : const Color(0xFFF0F0F0)),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF6A1B9A)
                      : (isCurrent
                            ? const Color(0xFFFFCA28)
                            : Colors.grey.shade300),
                  width: isCurrent ? 3 : 1,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFCA28).withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : (isCurrent
                        ? Center(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFCA28), // สีเหลือง
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null),
            ),
            if (!isLast) _buildDashedLine(),
          ],
        ),
        const SizedBox(width: 16),
        // คอลัมน์ขวา: ข้อความและป้ายกำกับ
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: (isCompleted || isCurrent)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: (isCompleted || isCurrent)
                            ? Colors.black87
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCompleted
                          ? "${timeText.isNotEmpty ? '$timeText — ' : ''}เสร็จสิ้น"
                          : (isCurrent
                                ? "$timeText — กำลังดำเนินการ"
                                : "รอดำเนินการ"),
                      style: TextStyle(
                        fontSize: 13,
                        color: isCompleted
                            ? Colors.grey.shade500
                            : (isCurrent
                                  ? const Color(0xFFF57F17)
                                  : Colors.grey.shade300),
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (isCompleted || isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFF3E5F5)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCompleted ? "เสร็จสิ้น" : "กำลังดำเนิน",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? const Color(0xFF6A1B9A)
                            : const Color(0xFFF57F17),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🌟 ฟังก์ชันวาดแต่ละแถวของข้อมูลบริการปัจจุบัน
  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 ส่วนปุ่มด้านล่างจอ
  Widget _buildBottomAction() {
    bool isAllDone = _currentStepIndex >= _statusList.length;

    return Container(
      padding: const EdgeInsets.all(24.0),
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
            backgroundColor: isAllDone
                ? Colors.grey.shade400
                : const Color(0xFF9B59B6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: isAllDone ? null : _submitStatus,
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'แจ้งเตือน',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
