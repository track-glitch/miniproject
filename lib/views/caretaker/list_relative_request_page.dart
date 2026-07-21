import 'package:flutter/material.dart';
import 'package:miniproject/models/request_model.dart';
import 'package:miniproject/services/caretaker_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/custom_header_nav.dart';
import '../caretaker/view_relative_request_page.dart';
import '../caretaker/add_status_notification_page.dart';
import '../caretaker/edit_profile_page.dart';
import '../caretaker/add_doctor_advice_page.dart'; // 🌟 เพิ่มบรรทัดนี้

class ListRelativeRequestPage extends StatefulWidget {
  final String uid;
  const ListRelativeRequestPage({super.key, required this.uid});

  @override
  State<ListRelativeRequestPage> createState() =>
      _ListRelativeRequestPageState();
}

class _ListRelativeRequestPageState extends State<ListRelativeRequestPage> {
  int _currentTabIndex = 0;
  int _bottomNavIndex = 0;
  bool _isLoading = true;
  final CaretakerService _service = CaretakerService();

  List<RequestCard> requestsInProgress = [];
  List<RequestCard> requestsCompleted = [];
  List<RequestCard> requestsCancelled = [];
  int _unreadCount = 0; // 🌟 ตัวแปรเก็บจำนวนคำขอที่มาใหม่

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfilePage(uid: widget.uid),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  String _formatThaiDate(DateTime? date, DateTime? time) {
    if (date == null || time == null) return 'ไม่ระบุวัน-เวลา';
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
    return 'วัน${days[date.weekday % 7]} ${date.day} ${months[date.month - 1]} ${date.year + 543}  ·  ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} น.';
  }

  Future<void> _fetchRequests() async {
    final data = await _service.getRequestsForCaretaker(widget.uid);

    List<RequestCard> inProgress = [];
    List<RequestCard> completed = [];
    List<RequestCard> cancelled = [];
    int unread = 0; // 🌟 ตัวนับยังไม่ได้อ่าน

    for (var item in data) {
      RequestModel req = item['requestModel'];
      Map<String, dynamic> pat = item['patientData'];
      Map<String, dynamic> rel = item['relativeData'];
      bool isRead = req.isReadCaretaker ?? false; // 🌟 ดึงสถานะการอ่านมา

      String statusType = (req.requeststatus ?? 'pending').toLowerCase();
      bool hasAlert =
          (statusType == 'accepted' || statusType == 'pending_advice');

      String patGender = pat['gender'] ?? '';
      String prefix = patGender == 'ชาย'
          ? 'นาย '
          : (patGender == 'หญิง' ? 'นาง ' : 'คุณ ');
      String patientName =
          "$prefix${pat['firstname'] ?? ''} ${pat['lastname'] ?? ''}".trim();

      RequestCard card = RequestCard(
        id: req.requestId ?? 'Unknow',
        serviceName: req.hospitalname ?? 'ไม่ระบุสถานที่',
        statusType: statusType,
        date: _formatThaiDate(req.appointmentdate, req.appointmenttime),
        category: req.departmentname ?? 'ทั่วไป',
        patient: patientName.isEmpty ? 'ไม่ระบุชื่อผู้ป่วย' : patientName,
        hasAlert: hasAlert,
        requestModel: req,
        patientData: pat,
        relativeData: rel,
        relativeUid: item['relativeUid'] ?? '',
        isRead: isRead, // 🌟 ยัดใส่การ์ด
      );

      // นับเฉพาะที่อยู่แท็บกำลังดำเนินการและยังไม่ได้อ่าน
      if ((statusType == 'pending' ||
              statusType == 'accepted' ||
              statusType == 'pending_advice') &&
          !isRead) {
        unread++;
      }

      if (statusType == 'pending' ||
          statusType == 'accepted' ||
          statusType == 'pending_advice') {
        inProgress.add(card);
      } else if (statusType == 'completed') {
        completed.add(card);
      } else {
        cancelled.add(card);
      }
    }

    setState(() {
      requestsInProgress = inProgress;
      requestsCompleted = completed;
      requestsCancelled = cancelled;
      _unreadCount = unread; // 🌟 อัปเดตตัวเลขแจ้งเตือน
      _isLoading = false;
    });
  }

  List<RequestCard> _getCurrentTabRequests() {
    switch (_currentTabIndex) {
      case 0:
        return requestsInProgress;
      case 1:
        return requestsCompleted;
      case 2:
        return requestsCancelled;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: const CustomHeader(
          title: 'รายการคำขอของฉัน',
          showBackButton: false,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF9B59B6)),
              SizedBox(height: 16),
              Text(
                'กำลังโหลดข้อมูล...',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _bottomNavIndex,
          onTap: _onBottomNavTapped,
          uid: widget.uid,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4EDFB),
      appBar: const CustomHeader(title: 'รายการคำขอ', showBackButton: false),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: DefaultTabController(
              length: 3,
              initialIndex: _currentTabIndex,
              child: TabBar(
                onTap: (index) => setState(() => _currentTabIndex = index),
                labelColor: const Color(0xFF7D3C98),
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: const Color(0xFF7D3C98),
                indicatorWeight: 3,
                tabs: [
                  // 🌟 เพิ่มการแจ้งเตือนจุดแดงๆ ตรงแท็บ "กำลังดำเนินการ" ได้ด้วย!
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('กำลังดำเนินการ'),
                        if (_unreadCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'สิ้นสุด'),
                  const Tab(text: 'ยกเลิก'),
                ],
              ),
            ),
          ),
          Container(height: 6, color: const Color(0xFFF4EDFB)),
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
                        const SizedBox(height: 8),
                        Text(
                          'ยังไม่มีคำขอรับบริการในหมวดหมู่นี้',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _getCurrentTabRequests().length,
                    separatorBuilder: (context, index) =>
                        Container(height: 8, color: const Color(0xFFF4EDFB)),
                    itemBuilder: (context, index) =>
                        _buildRequestCard(_getCurrentTabRequests()[index]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
        uid: widget.uid,
      ),
    );
  }

  Widget _buildRequestCard(RequestCard request) {
    Color mainColor;
    Color statusBgColor;
    String statusText;

    // 🌟 ชุดสีเหมือนเดิม
    switch (request.statusType) {
      case 'pending':
        mainColor = const Color(0xFF757BFF);
        statusBgColor = const Color(0xFFB4BEFF).withOpacity(0.8);
        statusText = 'รอตอบรับ';
        break;
      case 'accepted':
        mainColor = const Color(0xFF00C853);
        statusBgColor = const Color(0xFFB9F6CA);
        statusText = 'ตอบรับแล้ว';
        break;
      case 'pending_advice':
        mainColor = const Color(0xFFF2994A);
        statusBgColor = const Color(0xFFFDEBD0);
        statusText = 'รอคำแนะนำ';
        break;
      case 'completed':
        mainColor = const Color(0xFF00B14F);
        statusBgColor = const Color(0xFFB9F6CA);
        statusText = 'สิ้นสุดบริการ';
        break;
      case 'cancelled':
        mainColor = const Color(0xFFFF5C5C);
        statusBgColor = const Color(0xFFFFB6B6).withOpacity(0.7);
        statusText = 'ยกเลิก';
        break;
      default:
        mainColor = Colors.grey;
        statusBgColor = Colors.grey.shade200;
        statusText = 'ไม่ทราบสถานะ';
    }

    bool isInProgressTab = _currentTabIndex == 0;

    return Container(
      // 🔽 1. ลดระยะห่างระหว่างการ์ด (Margin)
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10), // ปรับขอบให้มนน้อยลงนิดนึง
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: mainColor, width: 6),
            ), // 🔽 ลดความหนาแถบสี
          ),
          // 🔽 2. ลดระยะห่างภายในกรอบ (Padding)
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- แถวที่ 1: รหัสคำขอ + สถานะ ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '# ${request.id}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ), // 🔽 ลดฟอนต์
                      ),
                      const SizedBox(width: 6),
                      if (!request.isRead && isInProgressTab)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    // 🔽 ย่อปุ่มสถานะ
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
                        color: mainColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // 🔽 ลด SizedBox
              // --- แถวที่ 2: ชื่อโรงพยาบาล ---
              Text(
                request.serviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ), // 🔽 ลดจาก 20 เหลือ 16
              ),
              const SizedBox(height: 10), // 🔽 ลด SizedBox
              // --- แถวที่ 3: วันและเวลา ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6), // 🔽 ย่อไอคอน
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: mainColor,
                    ), // 🔽 ไอคอนเล็กลง
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
                      const SizedBox(height: 2),
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
              const SizedBox(height: 12), // 🔽 ลดช่องว่างก่อนถึงปุ่ม
              // --- แถวที่ 4: ปุ่มกด ---
              Row(
                mainAxisAlignment: isInProgressTab
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                children: [
                  if (isInProgressTab)
                    GestureDetector(
                      onTap: (request.hasAlert && isInProgressTab)
                          ? () {
                              if (request.statusType == 'pending_advice') {
                                Map<String, dynamic> reqInfo = {
                                  'patientName': request.patient,
                                  'dateTime': request.date,
                                  'hospital': request.serviceName,
                                  'department': request.category,
                                };
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddDoctorAdvicePage(
                                      relativeUid: request.relativeUid,
                                      requestId: request.id,
                                      requestInfo: reqInfo,
                                    ),
                                  ),
                                ).then((_) => _fetchRequests());
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddStatusNotificationPage(
                                          requestData: request,
                                          uid: widget.uid,
                                        ),
                                  ),
                                ).then((_) => _fetchRequests());
                              }
                            }
                          : null,
                      child: Container(
                        // 🔽 บีบปุ่มให้บางลง
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (request.hasAlert && isInProgressTab)
                              ? const Color(0xFFFFEBEE)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              request.statusType == 'pending_advice'
                                  ? Icons.note_add_rounded
                                  : Icons.notifications,
                              color: (request.hasAlert && isInProgressTab)
                                  ? const Color(0xFFF44336)
                                  : Colors.grey.shade500,
                              size: 16, // 🔽 ลดขนาด
                            ),
                            const SizedBox(width: 6),
                            Text(
                              request.statusType == 'pending_advice'
                                  ? 'เพิ่มคำแนะนำ'
                                  : 'ส่งแจ้งเตือน',
                              style: TextStyle(
                                color: (request.hasAlert && isInProgressTab)
                                    ? const Color(0xFFF44336)
                                    : Colors.grey.shade500,
                                fontSize: 12, // 🔽 ลดขนาด
                                fontWeight: FontWeight.bold,
                                decoration:
                                    (request.hasAlert && isInProgressTab)
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationColor: const Color(0xFFF44336),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  GestureDetector(
                    onTap: () async {
                      if (!request.isRead) {
                        await _service.markRequestAsRead(
                          request.relativeUid,
                          request.id,
                        );
                      }

                      if (request.statusType == 'pending_advice') {
                        Map<String, dynamic> reqInfo = {
                          'patientName': request.patient,
                          'dateTime': request.date,
                          'hospital': request.serviceName,
                          'department': request.category,
                        };
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddDoctorAdvicePage(
                              relativeUid: request.relativeUid,
                              requestId: request.id,
                              requestInfo: reqInfo,
                            ),
                          ),
                        );
                      } else {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewRelativeRequestPage(
                              requestData: request,
                              uid: widget.uid,
                            ),
                          ),
                        );
                      }
                      _fetchRequests();
                    },
                    child: const Text(
                      'ดูรายละเอียด',
                      style: TextStyle(
                        color: Color(0xFF9B59B6),
                        fontSize: 13, // 🔽 ลดขนาดตัวอักษร
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RequestCard {
  final String id;
  final String serviceName;
  final String statusType;
  final String date;
  final String category;
  final String patient;
  final bool hasAlert;
  final RequestModel requestModel;
  final Map<String, dynamic> patientData;
  final Map<String, dynamic> relativeData;
  final String relativeUid;
  final bool isRead; // 🌟 เพิ่มตัวแปรเช็คสถานะการอ่านในโมเดลการ์ด

  RequestCard({
    required this.id,
    required this.serviceName,
    required this.statusType,
    required this.date,
    required this.category,
    required this.patient,
    required this.hasAlert,
    required this.requestModel,
    required this.patientData,
    required this.relativeData,
    required this.relativeUid,
    required this.isRead,
  });
}
