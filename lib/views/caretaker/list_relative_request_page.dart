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
  int _inProgressFilterIndex = 0;
  final CaretakerService _service = CaretakerService();

  List<RequestCard> requestsInProgress = [];
  List<RequestCard> requestsCompleted = [];
  List<RequestCard> requestsCancelled = [];
  int _unreadCount = 0;
  String _userName = '';

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
    _fetchUserData();
    _fetchRequests();
  }

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
        submitDate: _formatThaiDateShort(
          req.requestdate,
        ), // 🌟 ย่อวันที่ส่งให้สั้นลง
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
        if (_inProgressFilterIndex == 0) {
          // กรองเฉพาะงานที่รอดำเนินการตอบรับ (pending)
          return requestsInProgress
              .where((req) => req.statusType == 'pending')
              .toList();
        } else {
          // กรองเฉพาะงานที่ตอบรับแล้ว (accepted หรือ pending_advice)
          return requestsInProgress
              .where(
                (req) =>
                    req.statusType == 'accepted' ||
                    req.statusType == 'pending_advice',
              )
              .toList();
        }
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
      backgroundColor: const Color.fromARGB(255, 225, 202, 255),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8763E6),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'ยินดีต้อนรับ คุณ${_userName.isNotEmpty ? _userName : 'ผู้ให้บริการ'}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
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
          Container(
            width: double.infinity,
            color: const Color(0xFF8763E6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Center(
              child: Text(
                'รายการคำขอ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
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

          // 🌟 ใช้ ListView เลื่อนปุ่มไปด้วยกันกับการ์ดเลย!
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 0, bottom: 16),
              itemCount: _getCurrentTabRequests().isEmpty
                  ? 2
                  : _getCurrentTabRequests().length + 1,
              itemBuilder: (context, index) {
                // --- ส่วนที่ 1: แถบปุ่ม (Index 0 เลื่อนหายไปกับ List) ---
                if (index == 0) {
                  if (_currentTabIndex == 0) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),

                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.start, // เรียงปุ่มชิดซ้าย
                        children: [
                          _buildFilterButton('รอตอบรับ', 0),
                          const SizedBox(width: 10),
                          _buildFilterButton('ตอบรับแล้ว', 1),
                        ],
                      ),
                    );
                  } else {
                    return Container();
                  }
                }

                // --- ส่วนที่ 2: กรณีไม่มีข้อมูล ---
                if (_getCurrentTabRequests().isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80),
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
                  );
                }

                // --- ส่วนที่ 3: แสดงการ์ดรายการ ---
                final request = _getCurrentTabRequests()[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildRequestCard(request),
                );
              },
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

  Widget _buildFilterButton(String text, int index) {
    bool isActive = _inProgressFilterIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _inProgressFilterIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // 🌟 ปรับขนาด Padding ให้ปุ่มเล็กๆ กะทัดรัด
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8763E6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF8763E6) : Colors.grey.shade300,
            width: 1.2,
          ),
          // ไม่ใส่ boxShadow ปุ่มจะได้ราบไปกับพื้นหลัง ไม่ลอย
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(RequestCard request) {
    Color mainColor;
    Color statusBgColor;
    Color statusTextColor;
    String statusText;

    switch (request.statusType) {
      case 'pending':
        mainColor = const Color(0xFF00C853);
        statusBgColor = const Color(0xFFE8F5E9);
        statusTextColor = const Color(0xFF00C853);
        statusText = 'รอตอบรับ';
        break;
      case 'accepted':
        mainColor = const Color(0xFF00C853);
        statusBgColor = const Color(0xFFE8F5E9);
        statusTextColor = const Color(0xFF00C853);
        statusText = 'ตอบรับแล้ว';
        break;
      case 'pending_advice':
        mainColor = const Color(0xFFF2994A);
        statusBgColor = const Color(0xFFFDEBD0);
        statusTextColor = const Color(0xFFF2994A);
        statusText = 'รอคำแนะนำ';
        break;
      case 'completed':
        mainColor = const Color(0xFF00B0FF);
        statusBgColor = const Color(0xFFE1F5FE);
        statusTextColor = const Color(0xFF00B0FF);
        statusText = 'สิ้นสุดบริการ';
        break;
      case 'cancelled':
        mainColor = const Color(0xFFF44336);
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

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4, // ลดระยะห่างระหว่างการ์ดเล็กน้อย
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: mainColor, width: 6)),
          ),
          padding: const EdgeInsets.all(16),
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
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 4),
              Text(
                'ส่งคำขอเมื่อ: ${request.submitDate}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 12),

              // --- แถวที่ 2: ชื่อโรงพยาบาล ---
              Text(
                'จุดหมายปลายทาง',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                request.serviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
              ),
              const SizedBox(height: 12),

              // --- แถวที่ 3: วันและเวลา ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: mainColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'วัน-เวลานัดหมาย',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.date,
                        style: TextStyle(
                          fontSize: 14,
                          color: mainColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: (request.hasAlert && isInProgressTab)
                              ? const Color(0xFFFFEBEE)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              request.statusType == 'pending_advice'
                                  ? Icons.note_add_rounded
                                  : Icons.notifications_active,
                              color: (request.hasAlert && isInProgressTab)
                                  ? const Color(0xFFF44336)
                                  : Colors.grey.shade500,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              request.statusType == 'pending_advice'
                                  ? 'เพิ่มคำแนะนำแพทย์'
                                  : 'แก้ไขสถานะ',
                              style: TextStyle(
                                color: (request.hasAlert && isInProgressTab)
                                    ? const Color(0xFFF44336)
                                    : Colors.grey.shade500,
                                fontSize: 13,
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF8763E6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ดูรายละเอียด',
                        style: TextStyle(
                          color: Color(0xFF8763E6),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
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
