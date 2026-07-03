import 'package:flutter/material.dart';
import 'package:miniproject/models/request_model.dart';
import 'package:miniproject/services/caretaker_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/custom_header_nav.dart';
import '../caretaker/view_relative_request_page.dart';
import '../caretaker/add_status_notification_page.dart';
import '../caretaker/edit_profile_page.dart';

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
  bool _isLoading = true; // 🌟 ตัวแปรโหลดข้อมูล
  final CaretakerService _service = CaretakerService();

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });

    // เช็คเลขให้ตรงกับลำดับใหม่
    if (index == 0) {
      // ไปหน้าแรก (บ้าน)
    } else if (index == 1) {
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => const ListRelativeRequestPage(),
      //   ),
      // );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfilePage(uid: widget.uid),
        ),
      );
    }
  }

  List<RequestCard> requestsInProgress = [];
  List<RequestCard> requestsCompleted = [];
  List<RequestCard> requestsCancelled = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests(); // 🌟 ดึงข้อมูลจริงตอนเปิดหน้า
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

  // ดึงข้อมูลและจัดกลุ่มตามแท็บสถานะ
  Future<void> _fetchRequests() async {
    final data = await _service.getRequestsForCaretaker(widget.uid);

    List<RequestCard> inProgress = [];
    List<RequestCard> completed = [];
    List<RequestCard> cancelled = [];

    for (var item in data) {
      RequestModel req = item['requestModel'];
      Map<String, dynamic> pat = item['patientData'];
      Map<String, dynamic> rel = item['relativeData'];

      String statusType = (req.requeststatus ?? 'pending').toLowerCase();
      bool hasAlert = (statusType == 'accepted');

      String patGender = pat['gender'] ?? '';
      String prefix = patGender == 'ชาย'
          ? 'นาย '
          : (patGender == 'หญิง' ? 'นาง ' : 'คุณ ');

      // 🌟 2. เอาคำนำหน้ามารวมกับชื่อ
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
        relativeUid: '',
      );

      // จัดกลุ่มการ์ดลงกล่องตามสถานะ
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
          showBackButton: false, // หน้าหลักไม่ต้องมีปุ่ม back
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(
                  0xFF9B59B6,
                ), // 🌟 เปลี่ยนสีหลอดโหลดเป็นสีม่วงให้เข้ากับธีมแอป
              ),
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
                onTap: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                },
                labelColor: const Color(0xFF7D3C98),
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: const Color(0xFF7D3C98),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'กำลังดำเนินการ'),
                  Tab(text: 'สิ้นสุด'),
                  Tab(text: 'ยกเลิก'),
                ],
              ),
            ),
          ),
          Container(height: 6, color: const Color(0xFFF4EDFB)),
          Expanded(
            child: _getCurrentTabRequests().isEmpty
                // ถ้าไม่มีข้อมูล ให้แสดงหน้า Empty State
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
                // ถ้ามีข้อมูล ก็แสดง ListView ของการ์ดตามปกติ
                : ListView.separated(
                    itemCount: _getCurrentTabRequests().length,
                    separatorBuilder: (context, index) =>
                        Container(height: 8, color: const Color(0xFFF4EDFB)),
                    itemBuilder: (context, index) {
                      final request = _getCurrentTabRequests()[index];
                      return _buildRequestCard(request);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
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

    // 🌟 เช็คว่าเป็น Tab กำลังดำเนินการหรือไม่
    bool isInProgressTab = _currentTabIndex == 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '# ${request.id}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.serviceName,
                      maxLines: 1, // 🌟 ป้องกันชื่อโรงพยาบาลล้นจอ
                      overflow: TextOverflow.ellipsis, // ถ้าเกินให้แสดงเป็น ...
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
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

          Row(
            mainAxisAlignment: isInProgressTab
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.end,
            children: [
              // 🌟 โชว์ปุ่มเสมอถ้าอยู่ Tab 0 (แต่ปรับสี เทา/แดง ตาม request.hasAlert)
              if (isInProgressTab)
                GestureDetector(
                  // 🌟 ถ้า hasAlert เป็น true ให้เด้งไปหน้า SendNotification ถ้า false เป็น null (กดไม่ได้)
                  onTap: request.hasAlert
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddStatusNotificationPage(
                                requestData: request,
                                uid: widget.uid,
                              ),
                            ),
                          );
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
                          Icons.notifications,
                          color: request.hasAlert
                              ? const Color(0xFFF44336)
                              : Colors.grey.shade500,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ส่งการแจ้งเตือน',
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewRelativeRequestPage(
                        requestData: request,
                        uid: widget.uid,
                      ),
                    ),
                  );
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
                maxLines: 1, // 🌟 ป้องกันข้อมูลแถวอื่นๆ ล้นจอ
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
  final RequestModel requestModel; // 🌟 เก็บก้อนข้อมูล Request จริง
  final Map<String, dynamic> patientData; // 🌟 เก็บข้อมูลคนไข้จริง
  final Map<String, dynamic> relativeData; // 🌟 เก็บข้อมูลญาติจริง
  final String relativeUid;

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
  });
}
