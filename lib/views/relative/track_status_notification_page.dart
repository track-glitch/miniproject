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

  static const Color primaryPurple = Color(0xFF8E5DB8);
  static const Color lightPurpleBg = Color(0xFFE9DCF3);
  static const Color redAccent = Color(0xFFE53935);
  final Color darkPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color searchPrimaryColor = const Color(0xFF8763E6);

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // 🌟 ฟังก์ชันดึงข้อมูลจาก Firebase
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

        // 🌟 1. Sort เวลา ใหม่ -> เก่า (ล่าสุดอยู่บนสุด)[cite: 17]
        rawList.sort((a, b) {
          String timeA = a['notifydate'] ?? a['timestamp'] ?? "";
          String timeB = b['notifydate'] ?? b['timestamp'] ?? "";
          return timeB.compareTo(timeA);
        });

        for (int i = 0; i < rawList.length; i++) {
          var item = rawList[i];
          // 🌟 เมื่อใหม่สุดอยู่บนสุด ดังนั้น index 0 คืออันล่าสุดเสมอ
          bool isLatest = (i == 0);

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

          // 🌟 2. ดึงเฉพาะรายละเอียด ไม่เอาชื่อผู้ดูแลมาต่อท้ายแล้ว[cite: 17]
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
              border: Border.all(color: searchPrimaryColor, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_outlined, size: 75, color: darkPurple),
                const SizedBox(height: 20),
                Text(
                  'กรุณาเข้าสู่ระบบก่อนใช้งาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPurple,
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
                      backgroundColor: searchPrimaryColor,
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
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                for (int i = 0; i < _items.length; i++) ...[
                  if (_items[i].isLatest) _buildLatestDivider(),
                  _NotificationCard(item: _items[i]),
                  const SizedBox(height: 14),
                ],
              ],
            ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: darkPurple,
          boxShadow: [
            BoxShadow(
              color: darkPurple.withOpacity(0.27),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const Expanded(child: Divider(color: redAccent, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'สถานะล่าสุด',
              style: TextStyle(
                color: redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(color: redAccent, thickness: 1)),
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
        borderRadius: BorderRadius.circular(12),
        border: latest
            ? const Border(left: BorderSide(color: Color(0xFFE53935), width: 4))
            : null,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.dateTime,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                item.requestId,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: latest ? FontWeight.bold : FontWeight.w500,
                  color: latest ? const Color(0xFFE53935) : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.status,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: latest ? const Color(0xFFE53935) : Colors.black87,
            ),
          ),
          // 🌟 3. เช็คเงื่อนไข ถ้าข้อมูล detail ว่าง จะไม่สร้าง Text ขึ้นมาเลย[cite: 17]
          if (item.detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.detailLabel,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              item.detail,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
