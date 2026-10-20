import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:miniproject/views/caretaker/add_doctor_advice_page.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart'; // 🌟 เพิ่ม import นี้เพื่อใช้คำสั่งลบ

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
    'กำลังลงทะเบียน',
    'รอพบแพทย์',
    'กำลังตรวจรักษา',
    'รอดำเนินการหลังตรวจ',
    'รอชำระเงิน',
    'รอรับยา',
    'กำลังเดินทางกลับ',
    'ถึงจุดหมายปลายทาง',
    'เสร็จสิ้นการให้บริการ',
  ];

  bool _isLoading = true;
  List<Map<dynamic, dynamic>> _notificationHistory = [];
  List<String> _availableStatusList = [];

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _trackingTimer;

  String? _selectedStatus;
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _emergencyRemarkController =
      TextEditingController();

  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  final Color primaryPurple = const Color(0xFF9B59B6);
  final Color darkPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color lightPurple = const Color(0xFFECE2FE);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color borderColor = const Color(0xFFD3C2F0);
  final Color sectionBgColor = const Color(0xFFF8F5FF);
  final Color historyColor = Colors.green;

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

  void _updateAvailableStatuses() {
    _availableStatusList.clear();

    // 🌟 หาลำดับสูงสุดของสถานะที่เคยส่งไปแล้ว เพื่อปิดไม่ให้เลือกสถานะข้างหลัง
    int maxSentIndex = -1;
    for (var n in _notificationHistory) {
      String title = n['notifystatus'] ?? n['status'] ?? '';
      int idx = _statusList.indexOf(title);
      if (idx > maxSentIndex) {
        maxSentIndex = idx;
      }
    }

    // 🌟 ดึงสถานะที่เหลือทั้งหมดมาใส่ลิสต์ (ตั้งแต่ตัวถัดไปจนจบ)
    for (int i = maxSentIndex + 1; i < _statusList.length; i++) {
      _availableStatusList.add(_statusList[i]);
    }

    if (_availableStatusList.isNotEmpty) {
      _selectedStatus = _availableStatusList.first;
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
    _emergencyRemarkController.dispose();
    super.dispose();
  }

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

      // 🌟 บันทึกสถานะปัจจุบันลง Firebase ทันที (ไม่ต้องมีลูปเช็กการข้ามสเต็ปแล้ว)
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
      _updateAvailableStatuses();
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

  // 🌟 ฟังก์ชันแสดง Pop-up ยืนยันการลบสถานะล่าสุด
  void _showCancelDialog(String notifId, String oldStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'ยกเลิกสถานะล่าสุด',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          content: Text(
            'คุณต้องการลบสถานะ\n"$oldStatus" ใช่หรือไม่?\n(เมื่อลบแล้วระบบจะย้อนกลับไปสถานะก่อนหน้า)',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ปิด', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                _deleteLatestNotification(notifId);
              },
              child: const Text(
                'ยืนยันการลบ',
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

  // 🌟 ฟังก์ชันลบการแจ้งเตือนออกจาก Firebase โดยตรง
  Future<void> _deleteLatestNotification(String notifId) async {
    setState(() => _isLoading = true);
    try {
      final DatabaseReference notifRef = FirebaseDatabase.instance.ref(
        'Login/${widget.requestData.relativeUid}/Relative/Request/${widget.requestData.id}/Notification/$notifId',
      );

      await notifRef.remove(); // ลบทิ้งออกจาก Firebase

      _notificationHistory = await _service.getNotifications(
        widget.requestData.relativeUid,
        widget.requestData.id,
      );
      _updateAvailableStatuses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ยกเลิกและย้อนกลับสถานะสำเร็จ'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Error deleting status: $e");
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🌟 กล่อง Dropdown แบบจำกัดการข้าม
                                    // 🌟 กล่อง Dropdown แบบห้ามเลือกข้ามสถานะ (บังคับตามลำดับ)
                                    DropdownButtonFormField<String>(
                                      value: _selectedStatus,
                                      items: _availableStatusList.asMap().entries.map((
                                        entry,
                                      ) {
                                        int index = entry.key;
                                        String value = entry.value;

                                        // 🌟 เปลี่ยนเป็น index == 0 เพื่อบังคับให้เลือกได้เฉพาะสถานะถัดไปเท่านั้น (ห้ามข้าม)
                                        bool isEnabled = index == 0;

                                        return DropdownMenuItem<String>(
                                          value: value,
                                          enabled:
                                              isEnabled, // ปิดการเลือกสถานะอื่นที่ยังไม่ถึงคิว
                                          child: Text(
                                            value,
                                            style: TextStyle(
                                              color: isEnabled
                                                  ? primaryPurple
                                                  : Colors.grey.shade400,
                                              fontWeight: isEnabled
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedStatus = newValue;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'อัปเดตสถานะถัดไป',
                                        labelStyle: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: primaryPurple.withOpacity(
                                              0.5,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: primaryPurple.withOpacity(
                                              0.5,
                                            ),
                                            width: 1.5,
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
                                    const SizedBox(height: 12),

                                    // 🌟 ช่องกรอกรายละเอียดเพิ่มเติม (เก็บไว้เหมือนเดิม)
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
                                    'สถานะการแจ้งเตือนปัจุบัน', // 🌟 แก้ชื่อหัวข้อตรงนี้
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
                _buildBottomAction(),
              ],
            ),
    );
  }

  // 🌟 กลับมาโชว์ Timeline ทุกสถานะ อันไหนยังไม่ส่งหรือข้ามไปให้เป็นสีเทา
  Widget _buildTimeline() {
    // 🌟 1. หา Index ที่อยู่ล่างสุด (ไกลสุด) ของสถานะที่เคยส่งไปแล้ว
    int maxCompletedIndex = -1;
    for (int i = 0; i < _statusList.length; i++) {
      bool exists = _notificationHistory.any((n) {
        String title = n['notifystatus'] ?? n['status'] ?? '';
        return title == _statusList[i];
      });
      if (exists) {
        maxCompletedIndex = i; // จะเก็บค่า Index ที่ลึกที่สุดเสมอ
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _statusList.length,
      itemBuilder: (context, index) {
        String currentStatusName = _statusList[index];
        bool isLastInList = index == _statusList.length - 1;

        // ค้นหาข้อมูลของสถานะนี้ในประวัติ
        var historyItemIndex = _notificationHistory.indexWhere((n) {
          String title = n['notifystatus'] ?? n['status'] ?? '';
          return title == currentStatusName;
        });

        bool isCompleted = historyItemIndex != -1;
        Map<dynamic, dynamic>? itemData = isCompleted
            ? _notificationHistory[historyItemIndex]
            : null;

        // 🌟 2. เช็กว่ามันคือสถานะล่าสุด (ล่างสุด) ที่ส่งไปหรือยัง
        bool isLatestCompleted = index == maxCompletedIndex;

        return _buildTimelineTile(
          statusName: currentStatusName,
          itemData: itemData,
          isCompleted: isCompleted,
          isLastInList: isLastInList,
          isLatestCompleted: isLatestCompleted,
        );
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

  // 🌟 ฟังก์ชันสร้างรายการ Timeline ทีละจุด (สีเขียว/สีเทา)
  Widget _buildTimelineTile({
    required String statusName,
    required Map<dynamic, dynamic>? itemData,
    required bool isCompleted,
    required bool isLastInList,
    required bool isLatestCompleted,
  }) {
    Color currentStatusColor = isCompleted
        ? historyColor
        : Colors.grey.shade300;
    IconData statusIcon = Icons.check;
    Color iconColor = isCompleted ? Colors.white : Colors.transparent;

    String detailText = '';
    String dateText = '';
    String timeText = '';
    String notifId = '';

    if (isCompleted && itemData != null) {
      detailText = itemData['notifydetail']?.toString() ?? '';
      notifId = itemData['id'] ?? itemData['notifyId'] ?? itemData['key'] ?? '';

      String? rawDate = itemData['notifydate'] ?? itemData['timestamp'];
      if (rawDate != null) {
        try {
          DateTime dt = DateTime.parse(rawDate).toLocal();
          dateText = DateFormat('dd/MM/yyyy').format(dt);
          timeText = DateFormat('HH:mm น.').format(dt);
        } catch (e) {}
      }
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
              ),
              child: Icon(statusIcon, color: iconColor, size: 16),
            ),
            if (!isLastInList) _buildDashedLine(currentStatusColor),
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
                        statusName,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? const Color(0xFF241C2B)
                              : Colors.grey.shade400,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 2),
                        Text(
                          "${dateText.isNotEmpty ? '$dateText ' : ''}${timeText.isNotEmpty ? '$timeText' : ''}",
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
                    ],
                  ),
                ),
                // 🌟 แสดงปุ่มลบเฉพาะสถานะที่เป็นสถานะล่าสุดในประวัติ (เพื่อย้อนกลับทีละสเต็ป)
                if (isLatestCompleted && notifId.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
                    tooltip: 'ยกเลิกสถานะนี้เพื่อย้อนกลับ',
                    onPressed: () => _showCancelDialog(notifId, statusName),
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
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 4,
                shadowColor: primaryPurple.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: (_isLoading || _selectedStatus == null)
                  ? null
                  : _showConfirmationDialog,
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
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
