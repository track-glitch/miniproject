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
  int _bottomNavIndex = 1;
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
    if (index == 0) {
      // ไปหน้าแรก (บ้าน)
    } else if (index == 2) {
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

      if (statusType == 'pending' || statusType == 'accepted') {
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
    Color titleColor;
    Color statusBgColor;
    Color statusTextColor;
    String statusText;

    switch (request.statusType) {
      case 'pending':
        titleColor = const Color(0xFFFF8C00);
        statusBgColor = const Color(0xFFFFE0B2);
        statusTextColor = const Color(0xFFFF8C00);
        statusText = 'รอตอบรับ';
        break;
      case 'accepted':
        titleColor = const Color(0xFF00B14F);
        statusBgColor = const Color(0xFFB9F6CA);
        statusTextColor = const Color(0xFF00B14F);
        statusText = 'ตอบรับแล้ว';
        break;
      case 'pending_advice':
        titleColor = const Color(0xFFE67E22);
        statusBgColor = const Color(0xFFFDEBD0);
        statusTextColor = const Color(0xFFE67E22);
        statusText = 'รอเพิ่มคำแนะนำ';
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
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 1. ส่วนหัวการ์ด (รหัสงาน + ชื่อโรงพยาบาลสีๆ + ป้ายสถานะ)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '# ${request.id}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ป้าย NEW แดงๆ ถืองานเพิ่งเข้าหรือมีสถานะค้างและยังไม่ได้อ่าน
                        if (!request.isRead && isInProgressTab)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
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
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.serviceName, // ชื่อโรงพยาบาลกลับมาแล้ว!
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor, // สีตามสถานะ
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusTextColor, width: 1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🌟 2. ส่วนแสดงรายละเอียดตรงกลาง
          _buildDetailRow(
            icon: Icons.calendar_today,
            iconColor: const Color(0xFFA052BE),
            bgColor: const Color(0xFFF4EDFB),
            label: 'วัน-เวลานัดหมาย',
            value: request.date,
            valueColor: const Color(0xFFA052BE),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.hub,
            iconColor: const Color(0xFF2196F3),
            bgColor: const Color(0xFFE3F2FD),
            label: 'แผนก',
            value: request.category,
            valueColor: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.person_outline,
            iconColor: const Color(0xFFFF8C00),
            bgColor: const Color(0xFFFFF3E0),
            label: _currentTabIndex == 1 ? 'ถึง' : 'ผู้ป่วย',
            value: request.patient,
            valueColor: const Color(0xFFFF8C00),
          ),
          const SizedBox(height: 16),

          // 🌟 3. ส่วนปุ่มกดด้านล่าง (รวมลอจิก pending_advice)
          Row(
            mainAxisAlignment: isInProgressTab
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.end,
            children: [
              if (isInProgressTab)
                GestureDetector(
                  onTap: request.hasAlert
                      ? () {
                          // ดักเช็คสถานะ! ถ้าเป็น pending_advice ให้ดีดไปหน้า AddDoctor
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
                            // ถ้าเป็น accepted ไปหน้าแผนที่ปกติ
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddStatusNotificationPage(
                                  requestData: request,
                                  uid: widget.uid,
                                ),
                              ),
                            ).then((_) => _fetchRequests());
                          }
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: request.hasAlert
                          ? const Color(0xFFFFEBEE)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          request.statusType == 'pending_advice'
                              ? Icons.note_add_rounded
                              : Icons.notifications,
                          color: request.hasAlert
                              ? const Color(0xFFF44336)
                              : Colors.grey.shade500,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          request.statusType == 'pending_advice'
                              ? 'เพิ่มคำแนะนำแพทย์'
                              : 'ส่งการแจ้งเตือน',
                          style: TextStyle(
                            color: request.hasAlert
                                ? const Color(0xFFF44336)
                                : Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: request.hasAlert
                                ? const Color(0xFFF44336)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              TextButton(
                onPressed: () async {
                  if (!request.isRead) {
                    await _service.markRequestAsRead(
                      request.relativeUid,
                      request.id,
                    );
                  }

                  // ดัก "View More" ถ้าเป็น pending_advice
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
                  'View More',
                  style: TextStyle(
                    color: Color(0xFF7D3C98),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
