import 'dart:async';
import 'dart:convert';

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

  final Color bgColor = const Color(0xFFF5F5F5);
  final Color primaryPurple = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF9B59B6);

  // 🌟 เก็บข้อมูลทั้งหมดไว้หลังบ้าน
  List<RequestCard> _requestsPendingAll = [];
  List<RequestCard> _requestsAcceptedAll = [];
  List<RequestCard> _requestsCompletedAll = [];
  List<RequestCard> _requestsCancelledAll = [];

  // 🌟 ระบบ Pagination
  final ScrollController _scrollController = ScrollController();
  final int _perPage = 10;
  int _pendingPage = 1;
  int _acceptedPage = 1;
  int _completedPage = 1;
  int _cancelledPage = 1;

  String _userName = '';
  String _userProfilePhoto = '';

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
    _fetchRequests(); // เรียกใช้ตอนเปิดหน้า
    // 🌟 ดักจับการเลื่อนจอ
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        _loadMoreCurrentTab();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreCurrentTab() {
    setState(() {
      if (_currentTabIndex == 0 &&
          (_pendingPage * _perPage) < _requestsPendingAll.length) {
        _pendingPage++;
      } else if (_currentTabIndex == 1 &&
          (_acceptedPage * _perPage) < _requestsAcceptedAll.length) {
        _acceptedPage++;
      } else if (_currentTabIndex == 2 &&
          (_completedPage * _perPage) < _requestsCompletedAll.length) {
        _completedPage++;
      } else if (_currentTabIndex == 3 &&
          (_cancelledPage * _perPage) < _requestsCancelledAll.length) {
        _cancelledPage++;
      }
    });
  }

  // 🌟 ดึงข้อมูลมาแสดงตามหน้าจอ
  List<RequestCard> _getCurrentTabRequestsDisplay() {
    if (_currentTabIndex == 0)
      return _requestsPendingAll.take(_pendingPage * _perPage).toList();
    if (_currentTabIndex == 1)
      return _requestsAcceptedAll.take(_acceptedPage * _perPage).toList();
    if (_currentTabIndex == 2)
      return _requestsCompletedAll.take(_completedPage * _perPage).toList();
    return _requestsCancelledAll.take(_cancelledPage * _perPage).toList();
  }

  bool _hasMoreInCurrentTab() {
    if (_currentTabIndex == 0)
      return (_pendingPage * _perPage) < _requestsPendingAll.length;
    if (_currentTabIndex == 1)
      return (_acceptedPage * _perPage) < _requestsAcceptedAll.length;
    if (_currentTabIndex == 2)
      return (_completedPage * _perPage) < _requestsCompletedAll.length;
    return (_cancelledPage * _perPage) < _requestsCancelledAll.length;
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

          String rawPhoto = data['profilephoto']?.toString() ?? '';
          _userProfilePhoto = rawPhoto
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .replaceAll(' ', '')
              .trim();
          int pad = _userProfilePhoto.length % 4;
          if (pad > 0) _userProfilePhoto += '=' * (4 - pad);
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
      _requestsPendingAll = pendingList;
      _requestsAcceptedAll = acceptedList;
      _requestsCompletedAll = completedList;
      _requestsCancelledAll = cancelledList;
      _isLoading = false;
    });
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

    final displayList = _getCurrentTabRequestsDisplay();
    int unreadPending = _requestsPendingAll.where((r) => !r.isRead).length;
    int unreadAccepted = _requestsAcceptedAll.where((r) => !r.isRead).length;

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
                    vertical: 4,
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
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage: _userProfilePhoto.isNotEmpty
                            ? MemoryImage(base64Decode(_userProfilePhoto))
                            : null,
                        child: _userProfilePhoto.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 11,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _userName.isNotEmpty ? _userName : 'ผู้ดูแล',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
          Container(
            color: Colors.white,
            child: DefaultTabController(
              length: 4,
              initialIndex: _currentTabIndex,
              child: TabBar(
                isScrollable: false,
                onTap: (index) {
                  setState(() {
                    _currentTabIndex = index;
                    if (_scrollController.hasClients)
                      _scrollController.jumpTo(0);
                  });
                },
                labelColor: darkPurple,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: darkPurple,
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                tabs: [
                  _buildTabItem(
                    Icons.access_time_rounded,
                    'คำขอใช้บริการ',
                    _requestsPendingAll.length,
                    showBadge: unreadPending > 0,
                  ),
                  _buildTabItem(
                    Icons.check_circle_outline_rounded,
                    'ตอบรับแล้ว',
                    _requestsAcceptedAll.length,
                    showBadge: unreadAccepted > 0,
                  ),
                  _buildTabItem(
                    Icons.star_border_rounded,
                    'เสร็จสิ้น',
                    _requestsCompletedAll.length,
                  ),
                  _buildTabItem(
                    Icons.cancel_outlined,
                    'ยกเลิก/ปฏิเสธ',
                    _requestsCancelledAll.length,
                  ),
                ],
              ),
            ),
          ),
          Container(height: 6, color: bgColor),

          Expanded(
            child: RefreshIndicator(
              color: primaryPurple, // สีของวงล้อโหลด
              onRefresh: () async {
                // เมื่อดึงหน้าจอลง จะเรียกฟังก์ชันดึงข้อมูลใหม่
                await _fetchRequests();
              },
              child: displayList.isEmpty
                  // กรณีไม่มีข้อมูล ต้องครอบ SingleChildScrollView เพื่อให้ดึงหน้าจอลงได้
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        alignment: Alignment.center,
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
                      ),
                    )
                  // กรณีมีข้อมูล
                  : ListView.builder(
                      // เพิ่ม Physics เพื่อบังคับให้ดึงรีเฟรชได้เสมอแม้ยาวไม่เต็มจอ
                      physics: const AlwaysScrollableScrollPhysics(),
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount:
                          displayList.length + (_hasMoreInCurrentTab() ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == displayList.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildRequestCard(displayList[index]);
                      },
                    ),
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

  Widget _buildRequestCard(RequestCard request) {
    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    switch (request.statusType) {
      case 'pending':
        statusColor = const Color(0xFFE65100);
        statusBgColor = const Color(0xFFFFF3E0);
        statusText = 'รอตอบรับ';
        statusIcon = Icons.access_time_rounded;
        break;
      case 'accepted':
      case 'pending_advice':
        statusColor = const Color(0xFF2ECC71);
        statusBgColor = const Color(0xFFE9F7EF);
        statusText = 'ตอบรับแล้ว';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'completed':
        statusColor = const Color(0xFF3498DB);
        statusBgColor = const Color(0xFFEBF5FB);
        statusText = 'เสร็จสิ้น';
        statusIcon = Icons.star_border_rounded;
        break;
      case 'cancelled':
        statusColor = const Color(0xFFE74C3C);
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
            ],
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      request.id,
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
                Text(
                  'ผู้ป่วย: ${request.patient}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  'วันที่ส่งคำขอ: ${request.submitDate}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'วันนัดบริการ: ${request.date}',
                  style: TextStyle(
                    fontSize: 12,
                    color: darkPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // 🌟 ย้ายกรอบบอกสถานะมาไว้ใต้ วันนัดบริการ
                Row(
                  children: [
                    const Text(
                      'สถานะ: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentTabIndex == 1)
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
                                    : 'อัปเดตสถานะ',
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
                          if (!request.isRead)
                            await _service.markRequestAsRead(
                              request.relativeUid,
                              request.id,
                            );
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
