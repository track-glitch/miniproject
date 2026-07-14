import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String uid;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.uid,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _unreadCount = 0;
  DatabaseReference? _dbRef;

  @override
  void initState() {
    super.initState();
    _startListeningToRequests(); // 🌟 เปลี่ยนมาใช้ระบบดักฟัง (Real-time)
  }

  void _startListeningToRequests() async {
    // 🌟 3. ใช้ UID ที่รับมาจาก Parameter แทน FirebaseAuth
    String uid = widget.uid;
    if (uid.isEmpty) return;

    // 1. ดึง caretakerId ของผู้ดูแลคนนี้ออกมาก่อน
    final caretakerSnap = await FirebaseDatabase.instance
        .ref('Login/$uid/Caretaker')
        .get();
    if (!caretakerSnap.exists) return;
    String myCaretakerId =
        (caretakerSnap.value as Map)['caretakerId']?.toString() ?? '';

    // 2. ตั้งค่าดักฟัง (Listener) กวาดหา Request ทั้งหมด
    _dbRef = FirebaseDatabase.instance.ref('Login');
    _dbRef!.onValue.listen((event) {
      if (!mounted) return;
      int count = 0;
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        data.forEach((userUid, userEntry) {
          if (userEntry['Relative'] != null &&
              userEntry['Relative']['Request'] != null) {
            final requestsMap =
                userEntry['Relative']['Request'] as Map<dynamic, dynamic>;

            requestsMap.forEach((reqId, reqData) {
              if (reqData['caretakerId'] == myCaretakerId) {
                bool isRead = reqData['isReadCaretaker'] ?? false;
                String status = (reqData['requeststatus'] ?? '')
                    .toString()
                    .toLowerCase();

                // ==========================================
                // 🌟 ลอจิกใหม่: ปลุกแจ้งเตือน (Badge) เมื่อถึงเวลาบริการ
                // ==========================================
                if (status == 'accepted') {
                  String? dateStr = reqData['appointmentdate'];
                  // ใช้ตัวแปรนี้เช็คว่าเราเคยยิงเตือนรอบสองไปหรือยัง
                  bool hasTriggeredAlert =
                      reqData['hasTriggeredTimeAlert'] ?? false;

                  if (dateStr != null && !hasTriggeredAlert) {
                    DateTime? apptDate = DateTime.tryParse(dateStr);

                    // ถ้าเวลาปัจจุบัน เลยเวลานัดไปแล้ว
                    if (apptDate != null && DateTime.now().isAfter(apptDate)) {
                      // อัปเดตกลับไปที่ Firebase ให้เป็น Unread อีกครั้ง
                      FirebaseDatabase.instance
                          .ref('Login/$userUid/Relative/Request/$reqId')
                          .update({
                            'isReadCaretaker': false,
                            'hasTriggeredTimeAlert':
                                true, // มาร์คไว้ว่าปลุกแจ้งเตือนรอบสองไปแล้วนะ
                          });

                      // อัปเดตตัวแปรสำหรับนับ count ของ Badge ให้เด้งโชว์ทันที
                      isRead = false;
                    }
                  }
                }
                // ==========================================

                if ((status == 'pending' || status == 'accepted') && !isRead) {
                  count++;
                }
              }
            });
          }
        });
      }

      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      backgroundColor: const Color(0xFF8E6FF0),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 12,
      ),
      items: [
        // 🌟 แท็บที่มีการแจ้งเตือน (ตกแต่ง Badge แบบในรูปเป๊ะๆ)
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: _unreadCount > 0, // ซ่อนถ้าเป็น 0
            backgroundColor: const Color(0xFFF44336), // สีแดงสดแจ้งเตือน
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ), // เพิ่มความอ้วนให้วงกลม
            label: Text(
              _unreadCount > 99 ? '99+' : _unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            child: const Icon(Icons.support_agent, size: 28),
          ),
          label: 'ขอใช้บริการ',
        ),

        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline, size: 28),
          label: 'ผู้ดูแล',
        ),
      ],
    );
  }
}
