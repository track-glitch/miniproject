import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/models/request_model.dart';
import 'package:miniproject/services/function_service.dart';
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

  final Color bgColor = const Color(0xFFF9F9F9);
  final Color primaryPurple = const Color(0xFF8763E6);
  final Color darkPurple = const Color(0xFF7D3C98);

  List<RequestCardData> requestsInProgress = [];
  List<RequestCardData> requestsCompleted = [];
  List<RequestCardData> requestsCancelled = [];

  @override
  void initState() {
    super.initState();
    _fetchMyRequests();
  }

  @override
  void dispose() {
    super.dispose();
  }

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

  String _formatThaiDateShort(DateTime? date) {
    if (date == null) return '-';
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
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
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
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const CustomHeader(
        title: 'ประวัติคำขอใช้บริการ',
        showBackButton: true,
      ),

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
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(text: 'ดำเนินการ', height: 55),
                  Tab(text: 'สิ้นสุด', height: 55),
                  Tab(text: 'ยกเลิก', height: 55),
                ],
              ),
            ),
          ),
          Container(height: 6, color: bgColor),
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
                    separatorBuilder: (context, index) => Container(
                      height: 8,
                      color: bgColor,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                          height: 1,
                          color: Colors.black.withOpacity(0.18),
                        ),
                      ),
                    ),
                    itemBuilder: (context, index) =>
                        _buildRequestCard(_getCurrentTabRequests()[index]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: primaryPurple,
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withValues(alpha: 0.27),
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
              true,
              onTap: () {},
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
    Color mainColor;
    Color statusBgColor;
    Color statusTextColor;
    String statusText;

    switch (request.statusType) {
      case 'pending':
        mainColor = const Color(0xFF757BFF); // สีส้ม
        statusBgColor = const Color(0xFFB4BEFF);
        statusTextColor = const Color(0xFF757BFF);
        statusText = 'รอตอบรับ';
        break;
      case 'accepted':
        mainColor = primaryPurple; // สีม่วง
        statusBgColor = const Color(0xFFF3E5F5);
        statusTextColor = primaryPurple;
        statusText = 'ตอบรับแล้ว';
        break;
      case 'completed':
        mainColor = const Color(0xFF00B14F); // สีเขียว
        statusBgColor = const Color(0xFFE8F5E9);
        statusTextColor = const Color(0xFF00B14F);
        statusText = 'สิ้นสุดบริการ';
        break;
      case 'cancelled':
        mainColor = const Color(0xFFF44336); // สีแดง
        statusBgColor = const Color(0xFFFFEBEE);
        statusTextColor = const Color(0xFFF44336);
        statusText = 'ยกเลิกบริการ';
        break;
      default:
        mainColor = Colors.grey;
        statusBgColor = Colors.grey.shade100;
        statusTextColor = Colors.grey;
        statusText = 'ไม่ทราบสถานะ';
    }

    bool isInProgressTab = _currentTabIndex == 0;

    // 🌟 ดึงจำนวน Notification มาจาก Model ของคุณโดยตรง
    int notificationCount = request.requestModel.notifications?.length ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.15), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: mainColor, width: 6)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '# ${request.id}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'ส่งเมื่อ: ${_formatThaiDateShort(request.requestModel.requestdate)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Text(
                request.serviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: mainColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'วัน-เวลานัดหมาย',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        request.date,
                        style: TextStyle(
                          fontSize: 13,
                          color: mainColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: isInProgressTab
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                children: [
                  if (isInProgressTab)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // 🌟 ส่ง RequestModel เข้าไปหน้าแสดงสถานะด้วย
                            builder: (context) => TrackStatusNotificationPage(
                              loggedUid: widget.loggedUid,
                              requestModel: request.requestModel,
                              caretakerName: request.caregiverName,
                            ),
                          ),
                        ).then((_) {
                          // พอปิดหน้าต่าง ให้รีเฟรชยอดอัปเดตแจ้งเตือน
                          _fetchMyRequests();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications,
                              color: Color(0xFFF44336),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            // 🌟 ใส่จำนวน (notificationCount) ตรงนี้
                            Text(
                              'ติดตามสถานะแจ้งเตือน ($notificationCount)',
                              style: const TextStyle(
                                color: Color(0xFFF44336),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFF44336),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () async {
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
                      'ดูรายละเอียด',
                      style: TextStyle(
                        color: Color(0xFF9B59B6),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF9B59B6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
