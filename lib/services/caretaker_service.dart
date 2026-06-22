import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart';

class CaretakerService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<List<Map<dynamic, dynamic>>> getAppointmentDateFromRelative(
    String uid,
  ) async {
    DataSnapshot snapshot = await _dbRef.child('Login').get();

    if (!snapshot.exists)
      return []; // 💡 เช็กความปลอดภัยก่อนเผื่อฐานข้อมูลว่างเปล่า

    final data = snapshot.value as Map<dynamic, dynamic>;
    List<Map<dynamic, dynamic>> result = [];

    // 💡 จุดแก้ที่ 1: ใช้ .entries แทน เพื่อให้ได้ทั้งชื่อ UID (key) และข้อมูลด้านใน (value)
    // และเปลี่ยนจาก DataSnapshot เป็น var หรือ MapEntry เพื่อไม่ให้ประเภทชนกันพัง
    for (var userEntry in data.entries) {
      String userUid = userEntry.key.toString(); // ดึง UID ของแต่ละคนออกมาสวย ๆ
      print(userUid);
      final mapDB = userEntry.value as Map<dynamic, dynamic>?;

      if (mapDB != null) {
        String usertype = mapDB['usertype'] as String? ?? '';

        if (usertype == 'Relative') {
          // เจาะพิกัดตรง ๆ ไปที่โหนด Request ของ UID คนนี้เลยครับ
          snapshot = await _dbRef
              .child('Login')
              .child(userUid)
              .child('Relative')
              .child('Request')
              .get();

          if (snapshot.exists && snapshot.value != null) {
            final data1 = snapshot.value as Map<dynamic, dynamic>;

            // 💡 จุดแก้ที่ 2: วนลูปเอาค่าข้อมูลด้านในออกมาตรง ๆ
            // และใช้คำว่า var แทนเพื่อรองรับข้อมูลประเภท Map ที่ส่งมาจาก data1.values
            for (var requestValue in data1.values) {
              final requestMap = requestValue as Map<dynamic, dynamic>?;

              if (requestMap != null) {
                String appointmentDate =
                    requestMap['appointmentdate'] as String? ?? '';

                if (appointmentDate.isNotEmpty) {
                  DateTime parseDate = DateTime.parse(appointmentDate);

                  // 💡 ยัดวันที่ที่แปลงสำเร็จแล้วใส่ Map ใหม่ลงในผลลัพธ์
                  result.add({'appointmentdate': parseDate});
                }
              }
            }
          }
        }
      }
    }
    return result;
  }

  // 🌟 ฟังก์ชันดึงข้อมูลโปรไฟล์ผู้ดูแลมาโชว์ในหน้าแก้ไข
  Future<Map<dynamic, dynamic>?> getCaretakerProfile(String uid) async {
    try {
      DataSnapshot snapshot = await _dbRef
          .child('Login')
          .child(uid)
          .child('Caretaker')
          .get();
      if (snapshot.exists) {
        return snapshot.value as Map<dynamic, dynamic>;
      }
      return null;
    } catch (e) {
      print("ดึงข้อมูลโปรไฟล์ผิดพลาด: $e");
      return null;
    }
  }

  // 🌟 ฟังก์ชันอัปเดตข้อมูลทั้งหมดตอนกดบันทึก
  Future<void> updateCaretakerProfile(
    String uid,
    Map<String, dynamic> updateData,
  ) async {
    await _dbRef
        .child('Login')
        .child(uid)
        .child('Caretaker')
        .update(updateData);
  }

  // 🌟 ฟังก์ชันอัปเดตสถานะรับงาน (Real-time)
  Future<void> updateServiceStatus(String uid, String status) async {
    await _dbRef.child('Login').child(uid).child('Caretaker').update({
      'servicestatus': status,
    });
  }
}
