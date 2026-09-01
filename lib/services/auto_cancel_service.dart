import 'package:firebase_database/firebase_database.dart';

class AutoCancelService {
  static Future<void> checkAndCancelExpiredRequests() async {
    try {
      final dbRef = FirebaseDatabase.instance.ref('Login');
      final snapshot = await dbRef.get();

      if (!snapshot.exists || snapshot.value == null) return;

      final allUsers = Map<String, dynamic>.from(snapshot.value as Map);

      // ดึงเวลา ณ ปัจจุบัน (เซ็ตเวลาเป็น 00:00:00 ของวันนี้ เพื่อเทียบแค่วันที่)
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      allUsers.forEach((uid, userData) {
        if (userData is Map && userData['Relative'] != null) {
          var relativeData = userData['Relative'];

          if (relativeData is Map && relativeData['Request'] != null) {
            var requests = Map<String, dynamic>.from(
              relativeData['Request'] as Map,
            );

            requests.forEach((reqId, reqData) {
              if (reqData is Map) {
                String status = (reqData['requeststatus'] ?? '')
                    .toString()
                    .toLowerCase();

                // 🌟 เช็กเฉพาะงานที่ยังค้างอยู่ (รอตอบรับ, ตอบรับแล้ว, รอคำแนะนำ)
                if (status == 'pending' ||
                    status == 'accepted' ||
                    status == 'pending_advice') {
                  String apptDateStr = reqData['appointmentdate'] ?? '';

                  if (apptDateStr.isNotEmpty) {
                    try {
                      DateTime apptDate = DateTime.parse(apptDateStr);
                      DateTime apptDayOnly = DateTime(
                        apptDate.year,
                        apptDate.month,
                        apptDate.day,
                      );

                      // 🌟 ถ้า "วันนี้" มาถึงช้ากว่า "วันนัดหมาย" (แปลว่าเลยวันนัดมาแล้วอย่างน้อย 1 วัน)
                      if (today.isAfter(apptDayOnly)) {
                        // ทำการอัปเดตสถานะเป็น ยกเลิก (cancelled) อัตโนมัติ
                        dbRef.child('$uid/Relative/Request/$reqId').update({
                          'requeststatus': 'cancelled',
                          'cancelReason':
                              'ระบบยกเลิกอัตโนมัติ (เลยกำหนดวันนัดหมาย)',
                        });

                        print('✅ ยกเลิกคำขอ $reqId อัตโนมัติสำเร็จ');
                      }
                    } catch (e) {
                      print('Error parsing date for $reqId: $e');
                    }
                  }
                }
              }
            });
          }
        }
      });
    } catch (e) {
      print('Auto cancel service error: $e');
    }
  }
}
