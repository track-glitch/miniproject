import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/models/request_model.dart';
import 'package:miniproject/services/function_service.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:miniproject/views/relative/relative_home_page.dart';
import 'package:miniproject/views/relative/track_status_notification_page.dart';
import 'package:miniproject/views/relative/view_request_detail_page.dart';
import 'package:miniproject/views/login_page.dart';
// 🌟 Import หน้า Review เข้ามาเพื่อให้กดจากหน้า List ได้เลย
import 'package:miniproject/views/relative/review_caretaker_page.dart';

class ListRequestPage extends StatefulWidget {
  final String? loggedUid;

  const ListRequestPage({super.key, this.loggedUid});

  @override
  State<ListRequestPage> createState() => _ListRequestPageState();
}

class _ListRequestPageState extends State<ListRequestPage> {
  int _currentTabIndex =
      0; // 0=รอตอบรับ, 1=ตอบรับแล้ว, 2=เสร็จสิ้น, 3=ยกเลิก/ปฏิเสธ
  bool _isLoading = true;

  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color primaryPurple = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);

  // 🌟 เก็บข้อมูลทั้งหมดไว้หลังบ้าน
  List<RequestCardData> _requestsPendingAll = [];
  List<RequestCardData> _requestsAcceptedAll = [];
  List<RequestCardData> _requestsCompletedAll = [];
  List<RequestCardData> _requestsCancelledAll = [];

  // 🌟 ระบบ Pagination
  final ScrollController _scrollController = ScrollController();
  final int _perPage = 10;
  int _pendingPage = 1;
  int _acceptedPage = 1;
  int _completedPage = 1;
  int _cancelledPage = 1;

  String _userName = '';
  String _userProfilePhoto = '';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchMyRequests();

    // 🌟 ดักจับการเลื่อนจอ ถ้าเลื่อนสุดให้โหลดข้อมูลเพิ่ม
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

  // 🌟 ฟังก์ชันดึงข้อมูลมาแสดงผล (เอามาแค่เท่าที่คำนวณหน้าไว้ ทีละ 20)
  List<RequestCardData> _getCurrentTabRequestsDisplay() {
    if (_currentTabIndex == 0)
      return _requestsPendingAll.take(_pendingPage * _perPage).toList();
    if (_currentTabIndex == 1)
      return _requestsAcceptedAll.take(_acceptedPage * _perPage).toList();
    if (_currentTabIndex == 2)
      return _requestsCompletedAll.take(_completedPage * _perPage).toList();
    return _requestsCancelledAll.take(_cancelledPage * _perPage).toList();
  }

  // 🌟 เช็คว่ายังมีข้อมูลเหลือให้โหลดอีกไหม เพื่อโชว์หลอดหมุนๆ ด้านล่างสุด
  bool _hasMoreInCurrentTab() {
    if (_currentTabIndex == 0)
      return (_pendingPage * _perPage) < _requestsPendingAll.length;
    if (_currentTabIndex == 1)
      return (_acceptedPage * _perPage) < _requestsAcceptedAll.length;
    if (_currentTabIndex == 2)
      return (_completedPage * _perPage) < _requestsCompletedAll.length;
    return (_cancelledPage * _perPage) < _requestsCancelledAll.length;
  }

  Future<void> _fetchUserName() async {
    String currentUid =
        widget.loggedUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.isEmpty) return;

    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login').get();
      if (snapshot.exists && snapshot.value is Map) {
        final allUsers = Map<String, dynamic>.from(snapshot.value as Map);

        for (var key in allUsers.keys) {
          bool isMatch = false;
          if (key == currentUid) {
            isMatch = true;
          } else {
            var childData = allUsers[key];
            if (childData is Map) {
              var relNode = childData['Relative'];
              if (childData['uid'] == currentUid ||
                  (relNode is Map && relNode['relativeId'] == currentUid)) {
                isMatch = true;
              }
            }
          }

          if (isMatch) {
            var childData = allUsers[key];
            if (childData is Map && childData.containsKey('Relative')) {
              var relNode = Map<String, dynamic>.from(
                childData['Relative'] as Map,
              );
              setState(() {
                _userName =
                    "${relNode['firstname'] ?? ''} ${relNode['lastname'] ?? ''}"
                        .trim();

              String rawPhoto = relNode['profilephoto']?.toString() ??
                                  relNode['Patient']?['patientphoto']?.toString() ?? '';
                _userProfilePhoto = rawPhoto
                    .replaceAll('\n', '')
                    .replaceAll('\r', '')
                    .replaceAll(' ', '')
                    .trim();
                int pad = _userProfilePhoto.length % 4;
                if (pad > 0) _userProfilePhoto += '=' * (4 - pad);

              });
            }
            break;
          }
        }
      }
    } catch (e) {
      print("Error fetching username: $e");
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

      List<RequestCardData> pendingList = [];
      List<RequestCardData> acceptedList = [];
      List<RequestCardData> completedList = [];
      List<RequestCardData> cancelledList = [];

      if (snapshot.exists && snapshot.value is Map) {
        final Map<dynamic, dynamic> requestsMap =
            snapshot.value as Map<dynamic, dynamic>;
        final allUsersSnapshot = await FirebaseDatabase.instance
            .ref('Login')
            .get();

        Map<String, Map<String, dynamic>> caretakerDataMap = {};
        if (allUsersSnapshot.exists && allUsersSnapshot.value is Map) {
          final allUsers = allUsersSnapshot.value as Map<dynamic, dynamic>;
          allUsers.forEach((key, value) {
            if (value['Caretaker'] != null) {
              String cId = value['Caretaker']['caretakerId']?.toString() ?? '';
              if (cId.isNotEmpty) {
                caretakerDataMap[cId] = Map<String, dynamic>.from(
                  value['Caretaker'],
                );
              }
            }
          });
        }

        requestsMap.forEach((reqId, reqData) {
          try {
            RequestModel req = RequestModel.fromJson(
              Map<String, dynamic>.from(reqData),
            );
            String statusType = (req.requeststatus ?? 'pending').toLowerCase();

            String caretakerFullName = 'รอผู้ดูแลตอบรับ';
            String caretakerImage = ''; // 🌟 เก็บรูปลงโมเดลเพื่อใช้ในหน้ารีวิว

            if (req.caretakerId != null &&
                caretakerDataMap.containsKey(req.caretakerId)) {
              final cData = caretakerDataMap[req.caretakerId]!;
              String fName = cData['firstname']?.toString() ?? '';
              String lName = cData['lastname']?.toString() ?? '';
              String gender = cData['gender']?.toString() ?? '';
              String bdStr = cData['birthdate']?.toString() ?? '';
              caretakerImage = cData['profilephoto']?.toString() ?? '';

              String prefix = '';
              if (bdStr.isNotEmpty) {
                try {
                  DateTime bd = DateTime.parse(bdStr);
                  int age = DateTime.now().year - bd.year;
                  if (DateTime.now().month < bd.month ||
                      (DateTime.now().month == bd.month &&
                          DateTime.now().day < bd.day)) {
                    age--;
                  }
                  if (gender == 'ชาย') {
                    prefix = age < 15 ? 'ด.ช. ' : 'นาย ';
                  } else if (gender == 'หญิง') {
                    prefix = age < 15 ? 'ด.ญ. ' : 'นางสาว ';
                  }
                } catch (e) {
                  if (gender == 'ชาย') prefix = 'นาย ';
                  if (gender == 'หญิง') prefix = 'นางสาว ';
                }
              } else {
                if (gender == 'ชาย') prefix = 'นาย ';
                if (gender == 'หญิง') prefix = 'นางสาว ';
              }
              caretakerFullName = "$prefix$fName $lName".trim();
            }

            // 🌟 ตรวจสอบว่าถูกรีวิวไปหรือยัง
            bool isRev = false;
            if (reqData['Review'] != null ||
                reqData['review'] != null ||
                req.review != null) {
              isRev = true;
            }

            RequestCardData card = RequestCardData(
              id: req.requestId ?? 'Unknow',
              serviceName: req.hospitalname ?? 'ไม่ระบุสถานที่',
              statusType: statusType,
              date: _formatThaiDateExact(
                req.appointmentdate,
                req.appointmenttime,
              ),
              submitDate: _formatThaiDateExact(
                req.requestdate,
                req.requestdate,
              ),
              category: req.departmentname ?? 'ทั่วไป',
              caregiverName: caretakerFullName,
              caretakerImage: caretakerImage,
              isReviewed: isRev,
              requestModel: req,
            );

            if (statusType == 'pending') {
              pendingList.add(card);
            } else if (statusType == 'accepted' ||
                statusType == 'pending_advice') {
              acceptedList.add(card);
            } else if (statusType == 'completed') {
              completedList.add(card);
            } else {
              cancelledList.add(card);
            }
          } catch (innerError) {
            print("❌ Error parsing Request ID: $reqId | $innerError");
          }
        });

        int sortDate(RequestCardData a, RequestCardData b) {
          DateTime dateA = a.requestModel.requestdate ?? DateTime.now();
          DateTime dateB = b.requestModel.requestdate ?? DateTime.now();
          return dateB.compareTo(dateA);
        }

        pendingList.sort(sortDate);
        acceptedList.sort(sortDate);
        completedList.sort(sortDate);
        cancelledList.sort(sortDate);
      }

      if (!mounted) return;
      setState(() {
        _requestsPendingAll = pendingList;
        _requestsAcceptedAll = acceptedList;
        _requestsCompletedAll = completedList;
        _requestsCancelledAll = cancelledList;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching requests: $e");
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    final displayList = _getCurrentTabRequestsDisplay();

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
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        backgroundImage: _userProfilePhoto.isNotEmpty
                            ? MemoryImage(base64Decode(_userProfilePhoto))
                            : null,
                        child: _userProfilePhoto.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 11)
                            : null,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _userName.isNotEmpty ? _userName : 'ผู้ใช้บริการ',
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
              'รายการคำขอใช้บริการ',
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
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
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
                  ),
                  _buildTabItem(
                    Icons.check_circle_outline_rounded,
                    'ตอบรับแล้ว',
                    _requestsAcceptedAll.length,
                  ),
                  // 🌟 แก้ไขชื่อ Tab ให้เป็น เสร็จสิ้น และ ยกเลิก/ปฏิเสธ
                  _buildTabItem(
                    Icons.star_border_rounded,
                    'ให้รีวิว',
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
            child: displayList.isEmpty
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
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount:
                        displayList.length + (_hasMoreInCurrentTab() ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == displayList.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: primaryPurple,
                            ),
                          ),
                        );
                      }
                      return _buildRequestCard(displayList[index]);
                    },
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
              true,
              onTap: () {},
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
                if (currentUid.isEmpty) return;

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
                      Navigator.pushReplacement(
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
                        const SnackBar(content: Text('ไม่พบข้อมูลประวัติ')),
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

  Widget _buildTabItem(IconData icon, String label, int count) {
    return Tab(
      height: 65,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Text('($count)', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RequestCardData request) {
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

    int notificationCount = request.requestModel.notifications?.length ?? 0;

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
                Text(
                  'REQ-${request.id.length > 6 ? request.id.substring(request.id.length - 6) : request.id}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
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

                // 🌟 แก้ไขให้ชื่อผู้ให้บริการกลับมาเป็น Text ธรรมดา เพราะย้ายปุ่มรีวิวออกไปแล้ว
                Text(
                  'ผู้ให้บริการ: ${request.caregiverName}',
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
                const SizedBox(height: 6),

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

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (request.statusType == 'accepted' ||
                        request.statusType == 'pending_advice')
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrackStatusNotificationPage(
                                loggedUid: widget.loggedUid,
                                requestModel: request.requestModel,
                                caretakerName: request.caregiverName,
                              ),
                            ),
                          ).then((_) => _fetchMyRequests());
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: notificationCount > 0
                                ? primaryPurple.withOpacity(0.08)
                                : Colors.white,
                            border: Border.all(
                              color: notificationCount > 0
                                  ? primaryPurple
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                notificationCount > 0
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_none_rounded,
                                size: 18,
                                color: notificationCount > 0
                                    ? primaryPurple
                                    : Colors.grey.shade600,
                              ),
                              if (notificationCount > 0) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    notificationCount > 9
                                        ? '9+'
                                        : '$notificationCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                    // 🌟 ย้ายปุ่มรีวิวและป้ายรีวิวแล้ว มาวางไว้ตรงนี้
                    if (request.statusType == 'completed') ...[
                      if (request.isReviewed)
                        Container(
                          height: 30, // ปรับความสูงให้เท่ากับปุ่มรายละเอียด
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border.all(color: Colors.orange.shade200),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star, size: 14, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(
                                'รีวิวแล้ว',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          height: 30,
                          margin: const EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReviewCaretakerPage(
                                    requestId: request.id,
                                    relativeUid:
                                        widget.loggedUid ??
                                        FirebaseAuth.instance.currentUser!.uid,
                                    caretakerUid:
                                        request.requestModel.caretakerId ?? '',
                                    caretakerName: request.caregiverName,
                                    hospitalName: request.serviceName,
                                    appointmentDateStr: request.date,
                                    caretakerImage: request.caretakerImage,
                                  ),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  _fetchMyRequests();
                                }
                              });
                            },
                            child: const Text(
                              'ให้รีวิว',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],

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
  final String submitDate;
  final String category;
  final String caregiverName;
  // 🌟 เพิ่มตัวแปรสำหรับเก็บภาพไปหน้ารีวิวและสถานะการรีวิว
  final String caretakerImage;
  final bool isReviewed;
  final RequestModel requestModel;

  RequestCardData({
    required this.id,
    required this.serviceName,
    required this.statusType,
    required this.date,
    required this.submitDate,
    required this.category,
    required this.caregiverName,
    required this.caretakerImage,
    required this.isReviewed,
    required this.requestModel,
  });
}
