import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/models/request_model.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:miniproject/views/login_page.dart';
import 'package:miniproject/views/relative/list_request_page.dart';
import 'package:miniproject/views/relative/relative_home_page.dart';

/// หน้าจอ "สถานะการแจ้งเตือน" (Track Status Notification Page)
class TrackStatusNotificationPage extends StatefulWidget {
  final String? loggedUid;
  final RequestModel? requestModel;
  final String? caretakerName;
  final String? patientName; // 🌟 1. เพิ่มตัวรับชื่อผู้ป่วย

  const TrackStatusNotificationPage({
    super.key,
    this.loggedUid,
    this.requestModel,
    this.caretakerName,
    this.patientName,
  });

  @override
  State<TrackStatusNotificationPage> createState() =>
      _TrackStatusNotificationPageState();
}

class _TrackStatusNotificationPageState
    extends State<TrackStatusNotificationPage> {
  List<_NotificationItem> _items = [];
  bool _isLoading = true;
  String _currentPatientName = ''; // 🌟 2. ตัวแปรเก็บชื่อผู้ป่วยสำหรับแสดงผล

  static const Color primaryPurple = Color(0xFF7D3C98);
  static const Color darkPurple = Color(0xFF7D3C98);
  static const Color lightPurpleBg = Color.fromARGB(255, 225, 202, 255);

  // 🌟 ปรับเป็นสีเหลือง (Amber/Golden Yellow) เพื่อให้อ่านง่ายบนพื้นขาว
  static const Color highlightColor = Color(0xFFE69500);

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

  @override
  void initState() {
    super.initState();
    _currentPatientName = widget.patientName ?? '';
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (widget.loggedUid == null || widget.requestModel!.requestId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 🌟 3. ไปดึงข้อมูล Request มาเพิ่มเติม เพื่อดึงชื่อผู้ป่วย (กรณีที่ไม่ได้ส่งผ่านพารามิเตอร์มา)
      final reqSnap = await FirebaseDatabase.instance
          .ref(
            'Login/${widget.loggedUid}/Relative/Request/${widget.requestModel!.requestId}',
          )
          .get();

      if (reqSnap.exists && reqSnap.value is Map) {
        final reqData = reqSnap.value as Map;
        if (_currentPatientName.isEmpty) {
          _currentPatientName =
              reqData['patientName']?.toString() ?? 'ไม่ระบุชื่อผู้ป่วย';
        }
      }

      // ดึงแจ้งเตือน
      final snap = await FirebaseDatabase.instance
          .ref(
            'Login/${widget.loggedUid}/Relative/Request/${widget.requestModel!.requestId}/Notification',
          )
          .get();

      List<_NotificationItem> loadedItems = [];

      if (snap.exists && snap.value != null) {
        final data = snap.value;
        List<Map<dynamic, dynamic>> rawList = [];

        if (data is Map) {
          rawList = data.values.map((e) => e as Map<dynamic, dynamic>).toList();
        } else if (data is List) {
          rawList = data
              .where((e) => e != null)
              .map((e) => e as Map<dynamic, dynamic>)
              .toList();
        }

        // Sort เวลา ใหม่ -> เก่า (ล่าสุดอยู่บนสุด)
        rawList.sort((a, b) {
          String timeA = a['notifydate'] ?? a['timestamp'] ?? "";
          String timeB = b['notifydate'] ?? b['timestamp'] ?? "";
          return timeB.compareTo(timeA);
        });

        for (int i = 0; i < rawList.length; i++) {
          var item = rawList[i];
          bool isLatest = (i == 0); // ใหม่สุดอยู่บนสุดเสมอ

          // จัดรูปแบบเวลา
          String rawDate = item['notifydate'] ?? item['timestamp'] ?? "";
          String formattedDate = rawDate;
          if (rawDate.isNotEmpty) {
            try {
              DateTime dt = DateTime.parse(rawDate).toLocal();
              formattedDate =
                  '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year + 543} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
            } catch (_) {}
          }

          String detailText = item['notifydetail']?.toString().trim() ?? '';

          loadedItems.add(
            _NotificationItem(
              dateTime: formattedDate,
              requestId: '#${widget.requestModel!.requestId}',
              status: item['notifystatus'] ?? item['status'] ?? 'อัปเดตสถานะ',
              detailLabel: 'รายละเอียด:',
              detail: detailText,
              isLatest: isLatest,
            ),
          );
        }
      }

      setState(() {
        _items = loadedItems;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching tracking notifications: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatApptDate(DateTime? date, DateTime? time) {
    if (date == null || time == null) return '-';
    List<String> months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} น.';
  }

  // 🌟 1. ฟังก์ชันสร้างโครงสร้างไทม์ไลน์ทั้งหมด
  Widget _buildTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _statusList.length,
      itemBuilder: (context, index) {
        String currentStatusName = _statusList[index];
        bool isLastInList = index == _statusList.length - 1;

        // ค้นหาว่าสถานะนี้ถูกส่งหรือยังใน _items ที่ดึงมาจาก Firebase
        var historyItemIndex = _items.indexWhere((n) {
          return n.status == currentStatusName;
        });

        bool isCompleted = historyItemIndex != -1;
        _NotificationItem? itemData = isCompleted
            ? _items[historyItemIndex]
            : null;

        // เช็กว่าสถานะนี้คือสถานะล่าสุดใช่ไหม
        bool isLatestCompleted = isCompleted ? itemData!.isLatest : false;

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

  // 🌟 2. ฟังก์ชันวาดเส้นประเชื่อมไทม์ไลน์แบบยืดหยุ่นตามความสูง
  Widget _buildDashedLine(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 🌟 ดักบัคตรงนี้! ถ้าระบบยังคำนวณความสูงไม่เสร็จ (เป็น Infinity) ให้ข้ามไปก่อน แอปจะได้ไม่เด้ง
        if (!constraints.hasBoundedHeight) {
          return const SizedBox();
        }

        final boxHeight = constraints.constrainHeight();
        const double dashHeight = 4.0;
        const double dashSpace = 3.0;

        // 🌟 คำนวณจำนวนเส้นประอัตโนมัติจากความสูงจริง
        final int dashCount = (boxHeight / (dashHeight + dashSpace)).floor();

        return Flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => Container(width: 2, height: dashHeight, color: color),
          ),
        );
      },
    );
  }

  // 🌟 ฟังก์ชันสร้างรายการ Timeline (ใช้เทคนิค Stack แทน IntrinsicHeight เพื่อแก้บัคข้อมูลหาย)
  Widget _buildTimelineTile({
    required String statusName,
    required _NotificationItem? itemData,
    required bool isCompleted,
    required bool isLastInList,
    required bool isLatestCompleted,
  }) {
    Color historyColor = highlightColor;
    Color currentColor = highlightColor;

    Color dotColor = isLatestCompleted
        ? currentColor
        : (isCompleted ? historyColor : Colors.grey.shade300);
    Color lineColor = (isCompleted && !isLatestCompleted)
        ? historyColor
        : Colors.grey.shade300;

    IconData statusIcon = Icons.check;
    Color iconColor = isCompleted ? Colors.white : Colors.transparent;

    String detailText = itemData?.detail ?? '';
    String dateTimeText = itemData?.dateTime ?? '';

    return Stack(
      children: [
        // 🌟 1. เลเยอร์หลัง: เส้นประ (ยืดตามความสูงของเนื้อหาอัตโนมัติ)
        if (!isLastInList)
          Positioned(
            left: 13, // กึ่งกลางของวงกลมพอดี
            top: 28, // เริ่มวาดใต้จุดวงกลม
            bottom: 0, // ยืดลงไปจนสุดขอบของรายการ
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (!constraints.hasBoundedHeight ||
                    constraints.maxHeight <= 0) {
                  return const SizedBox();
                }
                // คำนวณจำนวนขีด (ขีด 4px + ช่องว่าง 3px = 7)
                final int dashCount = (constraints.maxHeight / 7).floor();
                return Flex(
                  direction: Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    dashCount,
                    (_) => Container(width: 2, height: 4, color: lineColor),
                  ),
                );
              },
            ),
          ),

        // 🌟 2. เลเยอร์หน้า: จุดวงกลม และ ข้อความ
        Padding(
          padding: const EdgeInsets.only(
            bottom: 24.0,
          ), // ดันระยะห่างไปหาสเต็ปถัดไป
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: isLatestCompleted
                      ? Border.all(
                          color: currentColor.withOpacity(0.3),
                          width: 3,
                        )
                      : null,
                ),
                child: Icon(
                  statusIcon,
                  color: iconColor,
                  size: isLatestCompleted ? 14 : 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isLatestCompleted
                            ? currentColor
                            : (isCompleted
                                  ? const Color(0xFF241C2B)
                                  : Colors.grey.shade400),
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 13,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateTimeText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (detailText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              detailText,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceInfoCard() {
    final req = widget.requestModel;
    if (req == null) return const SizedBox.shrink();

    String apptStr = _formatApptDate(req.appointmentdate, req.appointmenttime);

    String displayReqId = req.requestId ?? '';
    if (!displayReqId.toUpperCase().startsWith('REQ-') &&
        !displayReqId.toUpperCase().startsWith('RQ-')) {
      if (displayReqId.length > 6) {
        displayReqId = 'RQ-${displayReqId.substring(displayReqId.length - 6)}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ข้อมูลบริการปัจจุบัน',
                style: TextStyle(
                  color: Color(0xFF7D3C98),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EDFB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayReqId,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7D3C98),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌟 4. เพิ่มชื่อผู้ป่วย
                    _buildCompactInfo(
                      'ผู้รับบริการ',
                      _currentPatientName.isNotEmpty
                          ? _currentPatientName
                          : 'ไม่ระบุชื่อ',
                      isBold: true,
                    ),
                    const SizedBox(height: 12),
                    _buildCompactInfo(
                      'ผู้ให้บริการ',
                      widget.caretakerName ?? 'รอผู้ดูแลตอบรับ',
                    ),
                    const SizedBox(height: 12),
                    _buildCompactInfo(
                      'สถานที่',
                      req.department?.hospital?.hospitalname ?? '-',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactInfo('วันที่นัดหมาย', apptStr),
                    const SizedBox(height: 12),
                    _buildCompactInfo(
                      'แผนก',
                      req.department?.departmentname ?? '-',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold
                ? primaryPurple
                : Colors.black87, // ให้ชื่อผู้รับบริการเด่นขึ้น
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryPurple, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person_outlined,
                  size: 75,
                  color: primaryPurple,
                ),
                const SizedBox(height: 20),
                const Text(
                  'กรุณาเข้าสู่ระบบก่อนใช้งาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'คุณต้องลงชื่อเข้าใช้งานในระบบก่อน จึงจะสามารถแก้ไขข้อมูลได้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'ไปหน้าเข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurpleBg,
      appBar: AppBar(
        backgroundColor: primaryPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สถานะการแจ้งเตือน',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryPurple))
          : RefreshIndicator(
              color: primaryPurple,
              onRefresh: () async {
                await _fetchNotifications();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  _buildServiceInfoCard(),

                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ยังไม่มีการแจ้งเตือนสถานะ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // 🌟 กล่องครอบ Timeline
                    Container(
                      padding: const EdgeInsets.only(
                        top: 20,
                        left: 16,
                        right: 16,
                        bottom: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                color: primaryPurple,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'ประวัติไทม์ไลน์',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryPurple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 🌟 เปลี่ยนมาเรียกใช้ _buildTimeline() ตรงนี้ครับ
                          _buildTimeline(),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: primaryPurple,
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.27),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(
              Icons.home_outlined,
              'บ้าน',
              false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RelativeHomePage(loggedUid: widget.loggedUid),
                  ),
                );
              },
            ),
            _buildBottomNavItem(
              Icons.support_agent,
              'รายการคำขอ',
              false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ListRequestPage(loggedUid: widget.loggedUid),
                  ),
                );
              },
            ),
            _buildBottomNavItem(
              Icons.person_outline,
              'ญาติ',
              false,
              onTap: () async {
                String currentUid =
                    widget.loggedUid ??
                    FirebaseAuth.instance.currentUser?.uid ??
                    '';
                if (currentUid.isEmpty) {
                  _showLoginRequiredDialog();
                  return;
                }
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  final snapshot = await FirebaseDatabase.instance
                      .ref('Login')
                      .get();
                  if (context.mounted) Navigator.pop(context);
                  String targetRelativeId = '';
                  Map<String, dynamic> targetUserData = {};
                  bool isFound = false;

                  if (snapshot.exists && snapshot.value is Map) {
                    final allUsers = Map<String, dynamic>.from(
                      snapshot.value as Map,
                    );
                    for (var key in allUsers.keys) {
                      if (key == currentUid) {
                        targetRelativeId = key;
                        targetUserData = Map<String, dynamic>.from(
                          allUsers[key] as Map,
                        );
                        isFound = true;
                        break;
                      }
                      var childData = allUsers[key];
                      if (childData is Map) {
                        var relNode = childData['Relative'];
                        if (childData['uid'] == currentUid ||
                            (relNode is Map &&
                                relNode['relativeId'] == currentUid)) {
                          targetRelativeId = key;
                          targetUserData = Map<String, dynamic>.from(childData);
                          isFound = true;
                          break;
                        }
                      }
                    }
                  }
                  if (isFound && targetRelativeId.isNotEmpty) {
                    RelativeModel relative;
                    Map<String, dynamic> relativeMap = {};
                    if (targetUserData.containsKey('Relative')) {
                      relativeMap = Map<String, dynamic>.from(
                        targetUserData['Relative'] as Map,
                      );
                      relative = RelativeModel(
                        relativeId:
                            relativeMap['relativeId'] ?? targetRelativeId,
                        firstname: relativeMap['firstname'] ?? '',
                        lastname: relativeMap['lastname'] ?? '',
                        phonenumber: relativeMap['phonenumber'] ?? '',
                        relationship: relativeMap['relationship'] ?? '',
                        email: relativeMap['email'] ?? '',
                      );
                    } else {
                      relative = RelativeModel(
                        relativeId: targetRelativeId,
                        firstname: '',
                        lastname: '',
                        phonenumber: '',
                        relationship: '',
                        email: '',
                      );
                    }
                    PatientModel patient;
                    if (relativeMap.containsKey('Patient')) {
                      final pData = Map<String, dynamic>.from(
                        relativeMap['Patient'] as Map,
                      );
                      patient = PatientModel(
                        patientId: pData['patientId'] ?? '',
                        patientphoto: pData['patientphoto'] ?? '',
                        firstname: pData['firstname'] ?? '',
                        lastname: pData['lastname'] ?? '',
                        phonenumber: pData['phonenumber'] ?? '',
                        gender: pData['gender'] ?? '',
                        birthdate: pData['birthdate'] != null
                            ? DateTime.tryParse(pData['birthdate'].toString())
                            : null,
                        disease: pData['disease'] ?? '',
                        mobility: pData['mobility'] ?? '',
                      );
                    } else {
                      patient = PatientModel(
                        patientId: '',
                        patientphoto: '',
                        firstname: '',
                        lastname: '',
                        phonenumber: '',
                        gender: '',
                      );
                    }
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditRelativeInfoPage(
                            currentPatient: patient,
                            currentRelative: relative,
                            loggedUid: targetRelativeId,
                          ),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ไม่พบข้อมูลประวัติ (กรุณาลองเข้าสู่ระบบใหม่อีกครั้ง)',
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('เกิดข้อผิดพลาด: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestDivider() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: highlightColor, thickness: 1.5)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: highlightColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.stars_rounded, color: highlightColor, size: 16),
                SizedBox(width: 6),
                Text(
                  'สถานะล่าสุด',
                  style: TextStyle(
                    color: highlightColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: Divider(color: highlightColor, thickness: 1.5)),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final String dateTime;
  final String requestId;
  final String status;
  final String detailLabel;
  final String detail;
  final bool isLatest;

  const _NotificationItem({
    required this.dateTime,
    required this.requestId,
    required this.status,
    required this.detailLabel,
    required this.detail,
    required this.isLatest,
  });
}

// 🌟 ปรับสีสถานะล่าสุดเป็นสีเหลือง และข้อความเก่าเป็นสีเทา
class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool latest = item.isLatest;

    // แยกวันที่กับเวลา
    String dateStr = item.dateTime;
    String timeStr = '';
    final parts = item.dateTime.split(' ');
    if (parts.length >= 2) {
      dateStr = parts[0];
      timeStr = parts.sublist(1).join(' ');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // ขอบ: สีเหลืองสำหรับสถานะล่าสุด และสีเทาสำหรับการ์ดเก่า
        border: Border.all(
          color: latest
              ? _TrackStatusNotificationPageState.highlightColor
              : Colors.grey.shade300,
          width: latest ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: latest
                ? _TrackStatusNotificationPageState.highlightColor.withOpacity(
                    0.2,
                  )
                : Colors.black.withOpacity(0.04),
            blurRadius: latest ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ฝั่งซ้าย: แสดงวันที่และเวลา
            Container(
              width: 95,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: latest
                    ? _TrackStatusNotificationPageState.highlightColor
                          .withOpacity(0.08)
                    : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: latest
                          ? Colors.grey.shade800
                          : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (timeStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: latest
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            // เส้นคั่นกลาง
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.grey.shade200,
            ),

            // ฝั่งขวา: แสดงสถานะและรายละเอียด
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // หัวข้อสถานะ: ล่าสุดเป็นสีเหลือง ข้อความเก่าเป็นสีเทา
                    Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: latest
                            ? _TrackStatusNotificationPageState.highlightColor
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (item.detail.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      // รายละเอียด: ข้อความเก่าปรับเป็นสีเทาจางลง
                      Text(
                        item.detail,
                        style: TextStyle(
                          fontSize: 13,
                          color: latest ? Colors.black87 : Colors.grey.shade500,
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
