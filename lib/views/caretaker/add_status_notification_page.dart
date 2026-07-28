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
  bool _hasStarted = false;
  int _currentStepIndex = 0;

  List<Map<dynamic, dynamic>> _notificationHistory = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _trackingTimer;

  // 🎨 สีหลักที่ใช้ตกแต่ง (อิงจากภาพ)
  final Color bgColor = const Color(0xFFF3E5FF);
  final Color primaryPurple = const Color(0xFF7D3C98);
  final Color completePurple = const Color(0xFF6A1B9A);
  final Color warningYellow = const Color(0xFFFFCA28);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _notificationHistory = await _service.getNotifications(
      widget.requestData.relativeUid,
      widget.requestData.id,
    );

    _currentStepIndex = _notificationHistory.length;

    // 🌟 เช็คว่ามีประวัติการแจ้งเตือนหรือยัง
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
      String statusToSubmit = _statusList[_currentStepIndex];

      await _service.addStatusNotification(
        relativeUid: widget.requestData.relativeUid,
        requestId: widget.requestData.id,
        status: statusToSubmit,
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

      setState(() {
        _hasStarted = true;
        _currentStepIndex = _notificationHistory.length;
      });

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
      backgroundColor: bgColor, // 🌟 พื้นหลังสีม่วงอ่อน
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
                        // 🌟 กล่องข้อมูลบริการ (UI แบบ Card)
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

                        // 🌟 กล่อง Timeline
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
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
                          child: _buildTimeline(),
                        ),
                        const SizedBox(height: 16),
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

  Widget _buildTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _statusList.length,
      itemBuilder: (context, index) {
        bool isCompleted = index < _currentStepIndex;
        // 🌟 แก้ลอจิก: ถ้ายังไม่เคยเริ่มเลย (ไม่มีประวัติ) ให้แสดงเป็นสีเทารอดำเนินการไปก่อน
        bool isCurrent = index == _currentStepIndex && _hasStarted;
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

  // 🌟 บีบเส้นประให้สั้นลง
  Widget _buildDashedLine() {
    return Column(
      children: List.generate(
        4, // ลดจำนวนเส้นประ
        (index) => Container(
          width: 2,
          height: 4,
          color: Colors.grey.shade300,
          margin: const EdgeInsets.symmetric(vertical: 2.5),
        ),
      ),
    );
  }

  Widget _buildTimelineTile({
    required int index,
    required String title,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    String timeText = '';

    if (isCompleted && index < _notificationHistory.length) {
      var data = _notificationHistory[index];
      if (data['timestamp'] != null) {
        try {
          DateTime dt = DateTime.parse(data['timestamp'].toString()).toLocal();
          timeText = DateFormat('HH:mm น.').format(dt);
        } catch (e) {
          timeText = "";
        }
      }
    } else if (isCurrent) {
      timeText = DateFormat('HH:mm น.').format(DateTime.now());
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28, // บีบขนาดวงกลมเล็กลงนิดนึง
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? completePurple
                    : (isCurrent ? Colors.white : const Color(0xFFF0F0F0)),
                border: Border.all(
                  color: isCompleted
                      ? completePurple
                      : (isCurrent ? warningYellow : Colors.grey.shade300),
                  width: isCurrent ? 3 : 1,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: warningYellow.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : (isCurrent
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: warningYellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null),
            ),
            if (!isLast) _buildDashedLine(),
          ],
        ),
        const SizedBox(width: 12), // บีบระยะห่างข้อความกับวงกลม
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 4), // บีบความสูงแต่ละแถวลง
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
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: (isCompleted || isCurrent)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: (isCompleted || isCurrent)
                              ? Colors.black87
                              : Colors.grey.shade400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCompleted
                            ? "${timeText.isNotEmpty ? '$timeText — ' : ''}เสร็จสิ้น"
                            : (isCurrent
                                  ? "$timeText — กำลังดำเนินการ"
                                  : "รอดำเนินการ"),
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted
                              ? Colors.grey.shade500
                              : (isCurrent
                                    ? const Color(0xFFF57F17)
                                    : Colors.grey.shade400),
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted || isCurrent)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFF3E5F5)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCompleted ? "เสร็จสิ้น" : "กำลังดำเนิน",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? completePurple
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

  // 🌟 บีบระยะห่างแถวข้อมูลให้ดูแน่นขึ้นนิดหน่อย
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
    bool isAllDone = _currentStepIndex >= _statusList.length;

    return Container(
      padding: const EdgeInsets.all(16.0), // ลด Padding ปุ่มด้านล่าง
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
            backgroundColor: isAllDone ? Colors.grey.shade400 : primaryPurple,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: isAllDone ? null : _submitStatus,
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
                  'แจ้งเตือน',
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
