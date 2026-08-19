import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/models/request_model.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:miniproject/views/login_page.dart';
import 'package:miniproject/views/relative/list_request_page.dart';
import 'package:miniproject/views/relative/relative_home_page.dart';

/// หน้าจอ "สถานะการแจ้งเตือน" (Track Status Notification Page)
class TrackStatusNotificationPage extends StatefulWidget {
  final String? loggedUid;
  final RequestModel? requestModel;
  final String? caretakerName;

  const TrackStatusNotificationPage({
    super.key,
    this.loggedUid,
    this.requestModel,
    this.caretakerName,
  });

  @override
  State<TrackStatusNotificationPage> createState() =>
      _TrackStatusNotificationPageState();
}

class _TrackStatusNotificationPageState
    extends State<TrackStatusNotificationPage> {
  List<_NotificationItem> _items = [];
  bool _isLoading = true;

  // 🌟 ปรับโทนสีใหม่ให้เข้ากันและโดดเด่นขึ้น
  static const Color primaryPurple = Color(0xFF8763E6);
  static const Color darkPurple = Color(0xFF7D3C98);
  static const Color lightPurpleBg = Color(0xFFF4EDFB);
  // 🌟 ใช้สีส้มทองสำหรับไฮไลต์สถานะล่าสุด (ตัดกับสีม่วงได้ดีมากและดูพรีเมียม)
  static const Color highlightColor = Color(0xFFFF8F00);

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (widget.loggedUid == null || widget.requestModel!.requestId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snap = await FirebaseDatabase.instance
          .ref(
            'Login/${widget.loggedUid}/Relative/Request/${widget.requestModel!.requestId}/Notification',
          )
          .get();

      List<_NotificationItem> loadedItems = [];

      if (snap.exists && snap.value != null) {
        final data = snap.value;
        List<Map<dynamic, dynamic>> rawList = [];

        if (data is Map) {
          rawList = data.values.map((e) => e as Map<dynamic, dynamic>).toList();
        } else if (data is List) {
          rawList = data
              .where((e) => e != null)
              .map((e) => e as Map<dynamic, dynamic>)
              .toList();
        }

        // Sort เวลา ใหม่ -> เก่า (ล่าสุดอยู่บนสุด)
        rawList.sort((a, b) {
          String timeA = a['notifydate'] ?? a['timestamp'] ?? "";
          String timeB = b['notifydate'] ?? b['timestamp'] ?? "";
          return timeB.compareTo(timeA);
        });

        for (int i = 0; i < rawList.length; i++) {
          var item = rawList[i];
          bool isLatest = (i == 0); // ใหม่สุดอยู่บนสุดเสมอ

          // จัดรูปแบบเวลา
          String rawDate = item['notifydate'] ?? item['timestamp'] ?? "";
          String formattedDate = rawDate;
          if (rawDate.isNotEmpty) {
            try {
              DateTime dt = DateTime.parse(rawDate).toLocal();
              formattedDate =
                  '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year + 543} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
            } catch (_) {}
          }

          String detailText = item['notifydetail']?.toString().trim() ?? '';

          loadedItems.add(
            _NotificationItem(
              dateTime: formattedDate,
              requestId: '#${widget.requestModel!.requestId}',
              status: item['notifystatus'] ?? item['status'] ?? 'อัปเดตสถานะ',
              detailLabel: 'รายละเอียด:',
              detail: detailText,
              isLatest: isLatest,
            ),
          );
        }
      }

      setState(() {
        _items = loadedItems;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching tracking notifications: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryPurple, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person_outlined,
                  size: 75,
                  color: primaryPurple,
                ),
                const SizedBox(height: 20),
                const Text(
                  'กรุณาเข้าสู่ระบบก่อนใช้งาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'คุณต้องลงชื่อเข้าใช้งานในระบบก่อน จึงจะสามารถแก้ไขข้อมูลได้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'ไปหน้าเข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurpleBg,
      appBar: AppBar(
        backgroundColor: primaryPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สถานะการแจ้งเตือน',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryPurple))
          : _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีการแจ้งเตือนสถานะ',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Column(
                  children: [
                    if (item.isLatest) _buildLatestDivider(),
                    _NotificationCard(item: item),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color:
              primaryPurple, // 🌟 เปลี่ยนจาก darkPurple เป็น primaryPurple ตรงนี้
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(
                0.27,
              ), // 🌟 เปลี่ยนสีเงาให้เข้ากัน
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
              false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ListRequestPage(loggedUid: widget.loggedUid),
                  ),
                );
              },
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
                if (currentUid.isEmpty) {
                  _showLoginRequiredDialog();
                  return;
                }
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
                      Navigator.push(
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
                        const SnackBar(
                          content: Text(
                            'ไม่พบข้อมูลประวัติ (กรุณาลองเข้าสู่ระบบใหม่อีกครั้ง)',
                          ),
                        ),
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

  Widget _buildLatestDivider() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: highlightColor, thickness: 1.5)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: highlightColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.stars_rounded, color: highlightColor, size: 16),
                SizedBox(width: 6),
                Text(
                  'อัปเดตล่าสุด',
                  style: TextStyle(
                    color: highlightColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: Divider(color: highlightColor, thickness: 1.5)),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final String dateTime;
  final String requestId;
  final String status;
  final String detailLabel;
  final String detail;
  final bool isLatest;

  const _NotificationItem({
    required this.dateTime,
    required this.requestId,
    required this.status,
    required this.detailLabel,
    required this.detail,
    required this.isLatest,
  });
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool latest = item.isLatest;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        // 🌟 เพิ่มความหนาของขอบและปรับเงาให้การ์ดล่าสุดดูเด้งออกมา
        border: latest
            ? const Border(
                left: BorderSide(
                  color: _TrackStatusNotificationPageState.highlightColor,
                  width: 5,
                ),
              )
            : Border.all(color: Colors.grey.shade200),
        boxShadow: latest
            ? [
                BoxShadow(
                  color: _TrackStatusNotificationPageState.highlightColor
                      .withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time_filled_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.dateTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: latest
                      ? _TrackStatusNotificationPageState.highlightColor
                            .withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.requestId,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: latest
                        ? _TrackStatusNotificationPageState.highlightColor
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.status,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: latest
                  ? _TrackStatusNotificationPageState.highlightColor
                  : _TrackStatusNotificationPageState.darkPurple,
            ),
          ),
          if (item.detail.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(thickness: 1, height: 1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.detailLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.detail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
