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
  int _currentTabIndex = 0; // 0=รอตอบรับ, 1=ตอบรับแล้ว, 2=สิ้นสุด, 3=ยกเลิก
  int _bottomNavIndex = 0;
  bool _isLoading = true;
  final CaretakerService _service = CaretakerService();

  // 🌟 ปรับสีให้เหมือนหน้าของญาติ
  final Color bgColor = const Color(0xFFF5F5F5);
  final Color primaryPurple = const Color(0xFF8763E6);
  final Color darkPurple = const Color(0xFF7D3C98);

  // 🌟 แยก List เป็น 4 หมวดหมู่
  List<RequestCard> requestsPending = [];
  List<RequestCard> requestsAccepted = [];
  List<RequestCard> requestsCompleted = [];
  List<RequestCard> requestsCancelled = [];

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
                  Navigator.pop(context);
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

  // 🌟 ฟอร์แมตวันที่แบบกระชับ (เปลี่ยน | เป็นคำว่า "เวลา")
  String _formatThaiDateExact(DateTime? date, DateTime? time) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year + 543} เวลา ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} น.';
  }

  Future<void> _fetchRequests() async {
    final data = await _service.getRequestsForCaretaker(widget.uid);

    List<RequestCard> pendingList = [];
    List<RequestCard> acceptedList = [];
    List<RequestCard> completedList = [];
    List<RequestCard> cancelledList = [];

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
        date: _formatThaiDateExact(req.appointmentdate, req.appointmenttime),
        submitDate: _formatThaiDateExact(req.requestdate, req.requestdate),
        category: req.departmentname ?? 'ทั่วไป',
        patient: patientName.isEmpty ? 'ไม่ระบุชื่อผู้ป่วย' : patientName,
        hasAlert: hasAlert,
        requestModel: req,
        patientData: pat,
        relativeData: rel,
        relativeUid: item['relativeUid'] ?? '',
        isRead: isRead,
      );

      // 🌟 แยกเข้า 4 กล่องให้ตรงกับ Tab
      if (statusType == 'pending') {
        pendingList.add(card);
      } else if (statusType == 'accepted' || statusType == 'pending_advice') {
        acceptedList.add(card);
      } else if (statusType == 'completed') {
        completedList.add(card);
      } else {
        cancelledList.add(card);
      }
    }

    // Sort ใหม่สุดอยู่บน
    int sortDate(RequestCard a, RequestCard b) {
      DateTime dateA = a.requestModel.requestdate ?? DateTime.now();
      DateTime dateB = b.requestModel.requestdate ?? DateTime.now();
      return dateB.compareTo(dateA);
    }

    pendingList.sort(sortDate);
    acceptedList.sort(sortDate);
    completedList.sort(sortDate);
    cancelledList.sort(sortDate);

    setState(() {
      requestsPending = pendingList;
      requestsAccepted = acceptedList;
      requestsCompleted = completedList;
      requestsCancelled = cancelledList;
      _isLoading = false;
    });
  }

  List<RequestCard> _getCurrentTabRequests() {
    if (_currentTabIndex == 0) return requestsPending;
    if (_currentTabIndex == 1) return requestsAccepted;
    if (_currentTabIndex == 2) return requestsCompleted;
    return requestsCancelled;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8763E6)),
        ),
      );
    }

    // 🌟 คำนวณหาจำนวนที่ยังไม่ได้อ่าน เพื่อแปะจุดแดงบน Tab
    int unreadPending = requestsPending.where((r) => !r.isRead).length;
    int unreadAccepted = requestsAccepted.where((r) => !r.isRead).length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryPurple,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        toolbarHeight: 95,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _userName.isNotEmpty ? _userName : 'ผู้ดูแล',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'ออกจากระบบ',
                  onPressed: _showLogoutConfirmDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'รายการคำขอรับบริการ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 4 Tabs แนวนอนแบบในภาพเรฟเฟอเรนซ์
          Container(
            color: Colors.white,
            child: DefaultTabController(
              length: 4,
              initialIndex: _currentTabIndex,
              child: TabBar(
                isScrollable: false,
                onTap: (index) => setState(() => _currentTabIndex = index),
                labelColor: darkPurple,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: darkPurple,
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                tabs: [
                  _buildTabItem(
                    Icons.access_time_rounded,
                    'รอตอบรับ',
                    requestsPending.length,
                    showBadge: unreadPending > 0,
                  ),
                  _buildTabItem(
                    Icons.check_circle_outline_rounded,
                    'ตอบรับแล้ว',
                    requestsAccepted.length,
                    showBadge: unreadAccepted > 0,
                  ),
                  _buildTabItem(
                    Icons.star_border_rounded,
                    'สิ้นสุด',
                    requestsCompleted.length,
                  ),
                  _buildTabItem(
                    Icons.cancel_outlined,
                    'ยกเลิก',
                    requestsCancelled.length,
                  ),
                ],
              ),
            ),
          ),

          Container(height: 6, color: bgColor),

          // 🌟 ตัวลิสต์รายการที่ถูกจัดหน้าตาใหม่
          Expanded(
            child: _getCurrentTabRequests().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีคำขอในสถานะนี้',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _getCurrentTabRequests().length,
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

  // 🌟 สร้างหน้าตา Tab ให้มี Icon และตัวเลข (Count) พร้อมจุดแดงแจ้งเตือน
  Widget _buildTabItem(
    IconData icon,
    String label,
    int count, {
    bool showBadge = false,
  }) {
    return Tab(
      height: 65,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('($count)', style: const TextStyle(fontSize: 10)),
            ],
          ),
          if (showBadge)
            Positioned(
              top: 8,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🌟 การ์ดแบบใหม่เป๊ะตามแบบภาพเรฟเฟอเรนซ์
  Widget _buildRequestCard(RequestCard request) {
    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    switch (request.statusType) {
      case 'pending':
        statusColor = const Color(0xFFE65100); // สีส้มเข้ม
        statusBgColor = const Color(0xFFFFF3E0);
        statusText = 'รอตอบรับ';
        statusIcon = Icons.access_time_rounded;
        break;
      case 'accepted':
      case 'pending_advice':
        statusColor = const Color(0xFF2ECC71); // สีเขียว
        statusBgColor = const Color(0xFFE9F7EF);
        statusText = 'ตอบรับแล้ว';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'completed':
        statusColor = const Color(0xFF3498DB); // สีฟ้า
        statusBgColor = const Color(0xFFEBF5FB);
        statusText = 'สิ้นสุด';
        statusIcon = Icons.star_border_rounded;
        break;
      case 'cancelled':
        statusColor = const Color(0xFFE74C3C); // สีแดง
        statusBgColor = const Color(0xFFFDEDEC);
        statusText = 'ยกเลิก';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.shade100;
        statusText = 'ไม่ทราบ';
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ด้านซ้าย: กล่องไอค่อน + Badge สถานะ ---
          Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: primaryPurple, size: 26),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // --- ด้านขวา: รายละเอียด ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🌟 รหัสคำขออยู่ด้านบนสุด และโชว์ป้าย NEW ถ้ายังไม่ได้อ่าน
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'REQ-${request.id.length > 6 ? request.id.substring(request.id.length - 6) : request.id}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!request.isRead &&
                        (_currentTabIndex == 0 || _currentTabIndex == 1))
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
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // 🌟 จุดหมายปลายทาง: ชื่อโรงพยาบาล
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Kanit'),
                    children: [
                      const TextSpan(
                        text: 'จุดหมายปลายทาง: ',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      TextSpan(
                        text: request.serviceName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // 🌟 ชื่อผู้ป่วย
                Text(
                  'ผู้ป่วย: ${request.patient}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),

                // 🌟 วันที่ส่งคำขอ
                Text(
                  'วันที่ส่งคำขอ: ${request.submitDate}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),

                // 🌟 วันนัดบริการ
                Text(
                  'วันนัดบริการ: ${request.date}',
                  style: TextStyle(
                    fontSize: 12,
                    color: darkPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // 🌟 แถวปุ่มกดด้านล่าง
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // ปุ่มอัปเดตสถานะ/คำแนะนำแพทย์ (เฉพาะตอนตอบรับแล้ว)
                    if (_currentTabIndex == 1) // อยู่ในแท็บตอบรับแล้ว
                      InkWell(
                        onTap: () {
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
                                builder: (context) => AddStatusNotificationPage(
                                  requestData: request,
                                  uid: widget.uid,
                                ),
                              ),
                            ).then((_) => _fetchRequests());
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: darkPurple),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                request.statusType == 'pending_advice'
                                    ? Icons.note_add_rounded
                                    : Icons.edit_note_rounded,
                                size: 16,
                                color: darkPurple,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                request.statusType == 'pending_advice'
                                    ? 'คำแนะนำแพทย์'
                                    : 'แก้ไขสถานะ',
                                style: TextStyle(
                                  color: darkPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ปุ่มรายละเอียด (สีม่วงทึบ)
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (!request.isRead) {
                            await _service.markRequestAsRead(
                              request.relativeUid,
                              request.id,
                            );
                          }
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewRelativeRequestPage(
                                requestData: request,
                                uid: widget.uid,
                              ),
                            ),
                          );
                          _fetchRequests();
                        },
                        child: const Text(
                          'รายละเอียด',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
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
        ],
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
