import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:miniproject/models/request_model.dart';
import 'package:miniproject/services/caretaker_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../caretaker/view_relative_request_page.dart';
import '../caretaker/add_status_notification_page.dart';
import '../caretaker/edit_profile_page.dart';
import '../caretaker/add_doctor_advice_page.dart';
import '../login_page.dart';

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
  int _unreadCount = 0;
  String _userName = ''; // 🌟 เพิ่มตัวแปรเก็บชื่อผู้ใช้

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
    _fetchUserData(); // 🌟 โหลดชื่อผู้ใช้ก่อน
    _fetchRequests();
  }

  // 🌟 ฟังก์ชันดึงชื่อผู้ใช้มาแสดงบน AppBar
  Future<void> _fetchUserData() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('Login/${widget.uid}/Caretaker')
          .get();

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _userName = "${data['firstname'] ?? ''} ${data['lastname'] ?? ''}"
              .trim();
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // 🌟 ฟังก์ชันแสดง Pop-up ยืนยันออกจากระบบ
  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'ออกจากระบบ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'ตกลง',
                style: TextStyle(
                  color: Colors.red,
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
    int unread = 0;

    for (var item in data) {
      RequestModel req = item['requestModel'];
      Map<String, dynamic> pat = item['patientData'];
      Map<String, dynamic> rel = item['relativeData'];
      bool isRead = req.isReadCaretaker ?? false;

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
        submitDate: _formatThaiDate(req.requestdate, req.requestdate),
        category: req.departmentname ?? 'ทั่วไป',
        patient: patientName.isEmpty ? 'ไม่ระบุชื่อผู้ป่วย' : patientName,
        hasAlert: hasAlert,
        requestModel: req,
        patientData: pat,
        relativeData: rel,
        relativeUid: item['relativeUid'] ?? '',
        isRead: isRead,
      );

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
      _unreadCount = unread;
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
        appBar: AppBar(
          backgroundColor: const Color(0xFF8763E6),
          title: const Text(
            'รายการคำขอของฉัน',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF8763E6),
        elevation: 0,
        // 🌟 1. ตั้งค่าให้อยู่ตรงกลาง และเขียนข้อความยาวติดกันเลย
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'ยินดีต้อนรับ คุณ${_userName.isNotEmpty ? _userName : 'ผู้ให้บริการ'}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18, // ปรับขนาดให้พอดีกับแถบ AppBar
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'ออกจากระบบ',
            onPressed: _showLogoutConfirmDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 2. ลดขนาดตัวอักษรและลดระยะห่างของแถบรายการคำขอ
          Container(
            width: double.infinity,
            color: const Color(0xFF8763E6),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ), // ลด padding บน-ล่าง
            child: Center(
              child: const Text(
                'รายการคำขอ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22, // ลดจาก 28 เหลือ 22
                ),
              ),
            ),
          ),

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
                    separatorBuilder: (context, index) => Container(
                      height: 8,
                      color: const Color(0xFFF4EDFB),
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

    switch (request.statusType) {
      case 'pending':
        mainColor = const Color(0xFF757BFF);
        statusBgColor = const Color(0xFFB4BEFF).withOpacity(0.8);
        statusText = 'รอตอบรับ';
        break;
      case 'accepted':
        mainColor = const Color(0xFF9B59B6);
        statusBgColor = const Color(0xFFF4EDFB);
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
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 221, 221, 221),
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
              Text(
                'ส่งคำขอเมื่อ: ${request.submitDate}',
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
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              request.statusType == 'pending_advice'
                                  ? 'เพิ่มคำแนะนำ'
                                  : 'แก้ไขสถานะ',
                              style: TextStyle(
                                color: (request.hasAlert && isInProgressTab)
                                    ? const Color(0xFFF44336)
                                    : Colors.grey.shade500,
                                fontSize: 12,
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
}

class RequestCard {
  final String id;
  final String serviceName;
  final String statusType;
  final String date;
  final String submitDate;
  final String category;
  final String patient;
  final bool hasAlert;
  final RequestModel requestModel;
  final Map<String, dynamic> patientData;
  final Map<String, dynamic> relativeData;
  final String relativeUid;
  final bool isRead;

  RequestCard({
    required this.id,
    required this.serviceName,
    required this.statusType,
    required this.date,
    required this.submitDate,
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
