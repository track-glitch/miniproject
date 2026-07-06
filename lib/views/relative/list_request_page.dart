import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/models/request_model.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:miniproject/views/login_page.dart';
import 'package:miniproject/views/relative/relative_home_page.dart';
import 'package:miniproject/views/relative/track_status_notification_page.dart';
import 'package:miniproject/views/relative/view_request_detail_page.dart';
import '../../widgets/custom_header_nav.dart';

class ListRequestPage extends StatefulWidget {
  final String? loggedUid;

  const ListRequestPage({super.key, this.loggedUid});

  @override
  State<ListRequestPage> createState() => _ListRequestPageState();
}

class _ListRequestPageState extends State<ListRequestPage> {
  int _currentTabIndex = 0; // 0 = กำลังดำเนินการ, 1 = สิ้นสุด, 2 = ยกเลิก
  bool _isLoading = true;

  final Color primaryPurple = const Color(0xFF8763E6);
  final Color darkPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color lightPurpleBg = const Color(0xFFF4EDFB);

  List<RequestCardData> requestsInProgress = [];
  List<RequestCardData> requestsCompleted = [];
  List<RequestCardData> requestsCancelled = [];

  @override
  void initState() {
    super.initState();
    _fetchMyRequests();
  }

  // 🌟 ดึงข้อมูลคำขอเฉพาะของตัวเองจาก Firebase
  Future<void> _fetchMyRequests() async {
    String uid =
        widget.loggedUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('Login/$uid/Relative/Request')
          .get();

      List<RequestCardData> inProgress = [];
      List<RequestCardData> completed = [];
      List<RequestCardData> cancelled = [];

      if (snapshot.exists && snapshot.value is Map) {
        final Map<dynamic, dynamic> requestsMap =
            snapshot.value as Map<dynamic, dynamic>;

        // ดึงรายชื่อ Caretaker ทั้งหมดมาเตรียมไว้แมปชื่อ
        final allUsersSnapshot = await FirebaseDatabase.instance
            .ref('Login')
            .get();
        Map<String, String> caretakerNameMap = {};
        if (allUsersSnapshot.exists && allUsersSnapshot.value is Map) {
          final allUsers = allUsersSnapshot.value as Map<dynamic, dynamic>;
          allUsers.forEach((key, value) {
            if (value['Caretaker'] != null) {
              String cId = value['Caretaker']['caretakerId']?.toString() ?? '';
              String cName =
                  "${value['Caretaker']['firstname'] ?? ''} ${value['Caretaker']['lastname'] ?? ''}"
                      .trim();
              if (cId.isNotEmpty) caretakerNameMap[cId] = cName;
            }
          });
        }

        requestsMap.forEach((reqId, reqData) {
          try {
            RequestModel req = RequestModel.fromJson(
              Map<String, dynamic>.from(reqData),
            );
            String statusType = (req.requeststatus ?? 'pending').toLowerCase();

            String caretakerName = 'รอผู้ดูแลตอบรับ';
            if (req.caretakerId != null &&
                caretakerNameMap.containsKey(req.caretakerId)) {
              caretakerName = caretakerNameMap[req.caretakerId]!;
            }

            RequestCardData card = RequestCardData(
              id: req.requestId ?? 'Unknow',
              serviceName: req.hospitalname ?? 'ไม่ระบุสถานที่',
              statusType: statusType,
              date: _formatThaiDate(req.appointmentdate, req.appointmenttime),
              category: req.departmentname ?? 'ทั่วไป',
              caregiverName: caretakerName,
              requestModel: req,
            );

            if (statusType == 'pending' || statusType == 'accepted') {
              inProgress.add(card);
            } else if (statusType == 'completed') {
              completed.add(card);
            } else {
              cancelled.add(card);
            }
          } catch (innerError) {
            print(
              "❌ แปลงข้อมูล Request พังที่ ID: $reqId | สาเหตุ: $innerError",
            );
          }
        });

        // เรียงลำดับจากใหม่ไปเก่า
        int sortDate(RequestCardData a, RequestCardData b) {
          DateTime dateA = a.requestModel.requestdate ?? DateTime.now();
          DateTime dateB = b.requestModel.requestdate ?? DateTime.now();
          return dateB.compareTo(dateA);
        }

        inProgress.sort(sortDate);
        completed.sort(sortDate);
        cancelled.sort(sortDate);
      }

      if (!mounted) return;

      setState(() {
        requestsInProgress = inProgress;
        requestsCompleted = completed;
        requestsCancelled = cancelled;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching requests: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatThaiDate(DateTime? date, DateTime? time) {
    if (date == null || time == null) return 'ไม่ระบุวัน-เวลา';
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
    List<String> days = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
    ];

    // ตรงกับรูป: วันศุกร์ 16 ม.ค. 2568 · 08:00 น.
    return 'วัน${days[date.weekday % 7]} ${date.day} ${months[date.month - 1]} ${date.year + 543} · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} น.';
  }

  List<RequestCardData> _getCurrentTabRequests() {
    if (_currentTabIndex == 0) return requestsInProgress;
    if (_currentTabIndex == 1) return requestsCompleted;
    return requestsCancelled;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8763E6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightPurpleBg,
      appBar: const CustomHeader(title: 'รายการคำขอ', showBackButton: true),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: DefaultTabController(
              length: 3,
              initialIndex: _currentTabIndex,
              child: TabBar(
                onTap: (index) => setState(() => _currentTabIndex = index),
                labelColor: primaryPurple,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: primaryPurple,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'กำลังดำเนินการ'),
                  Tab(text: 'สิ้นสุด'),
                  Tab(text: 'ยกเลิก'),
                ],
              ),
            ),
          ),
          Container(height: 6, color: lightPurpleBg),
          Expanded(
            child: _getCurrentTabRequests().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่พบข้อมูลรายการ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _getCurrentTabRequests().length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      return _buildRequestCard(_getCurrentTabRequests()[index]);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: darkPurple,
          boxShadow: [
            BoxShadow(
              color: darkPurple.withOpacity(0.27),
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
              onTap: () => {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        (RelativeHomePage(loggedUid: widget.loggedUid)),
                  ),
                ),
              },
            ),
            _buildBottomNavItem(
              Icons.support_agent,
              'ขอใช้บริการ',
              true,
              onTap: () {},
            ),
            _buildBottomNavItem(
              Icons.notifications_none,
              'แจ้งเตือน',
              false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackStatusNotificationPage(
                      loggedUid: widget.loggedUid,
                    ),
                  ),
                );
              },
            ),
            _buildBottomNavItem(
              Icons.person_outline,
              'ญาติ',
              false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(RequestCardData request) {
    Color titleColor;
    Color statusBgColor;
    Color statusTextColor;
    String statusText;

    switch (request.statusType) {
      case 'pending':
        titleColor = const Color(0xFFFF8C00);
        statusBgColor = const Color(0xFFFFE0B2);
        statusTextColor = const Color(0xFFFF8C00);
        statusText = 'อยู่ระหว่างรอ'; // แก้ข้อความให้ตรงกับดีไซน์
        break;
      case 'accepted':
        titleColor = const Color(0xFF00B14F);
        statusBgColor = const Color(0xFFB9F6CA);
        statusTextColor = const Color(0xFF00B14F);
        statusText = 'ตอบรับแล้ว';
        break;
      case 'completed':
        titleColor = const Color(0xFF00B14F);
        statusBgColor = const Color(0xFFB9F6CA);
        statusTextColor = const Color(0xFF00B14F);
        statusText = 'สิ้นสุดบริการ';
        break;
      case 'cancelled':
        titleColor = const Color(0xFFF44336);
        statusBgColor = const Color(0xFFFFEBEE);
        statusTextColor = const Color(0xFFF44336);
        statusText = 'ยกเลิกบริการ';
        break;
      default:
        titleColor = Colors.grey;
        statusBgColor = Colors.grey.shade200;
        statusTextColor = Colors.grey;
        statusText = 'ไม่ทราบสถานะ';
    }

    bool isInProgressTab = _currentTabIndex == 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '# ${request.id}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusTextColor,
                    width: 1.2,
                  ), // เพิ่มเส้นขอบเหมือนในดีไซน์
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.serviceName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),

          _buildDetailRow(
            icon: Icons.calendar_today,
            iconColor: primaryPurple,
            bgColor: const Color(0xFFEFE0F7),
            label: 'วัน-เวลานัดหมาย',
            value: request.date,
            valueColor: primaryPurple,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.hub_outlined,
            iconColor: Colors.blue,
            bgColor: const Color(0xFFE3F0FF),
            label: 'แผนก',
            value: request.category,
            valueColor: Colors.blue,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.person_outline,
            iconColor: Colors.orange,
            bgColor: const Color(0xFFFFEFE0),
            label: 'ถึง',
            value: request.caregiverName,
            valueColor: Colors.orange,
          ),
          const SizedBox(height: 14),

          // 🌟 โซนปุ่มด้านล่าง (แก้ไขให้ตรงตามรูปภาพ)
          Row(
            mainAxisAlignment: isInProgressTab
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.end,
            children: [
              // ถ้าอยู่แท็บกำลังดำเนินการ ให้แสดงปุ่ม "ติดตามสถานะบริการ"
              if (isInProgressTab)
                GestureDetector(
                  onTap: () {
                    // กดปุ่มแล้วเด้งไปหน้าแจ้งเตือน (Tracking)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackStatusNotificationPage(
                          loggedUid: widget.loggedUid,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE), // สีพื้นแดงอ่อน
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications,
                          color: Color(0xFFF44336),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ติดตามสถานะบริการ',
                          style: TextStyle(
                            color: Color(0xFFF44336),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFF44336),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewRequestDetailPage(
                        requestModel: request.requestModel,
                        caretakerName: request.caregiverName,
                        loggedUid:
                            widget.loggedUid ??
                            FirebaseAuth.instance.currentUser!.uid,
                      ),
                    ),
                  );
                  _fetchMyRequests();
                },
                child: const Text(
                  'View More',
                  style: TextStyle(
                    color: Color(0xFF8763E6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ), // ปรับไอคอนเป็นสี่เหลี่ยมขอบมนเหมือนรูป
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
}

class RequestCardData {
  final String id;
  final String serviceName;
  final String statusType;
  final String date;
  final String category;
  final String caregiverName;
  final RequestModel requestModel;

  RequestCardData({
    required this.id,
    required this.serviceName,
    required this.statusType,
    required this.date,
    required this.category,
    required this.caregiverName,
    required this.requestModel,
  });
}
