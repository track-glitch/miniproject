import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart';
import 'package:miniproject/models/request_model.dart';

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

  // 🌟 ฟังก์ชันสำหรับดึงคำขอ (Requests) ของผู้ดูแลคนนี้โดยเฉพาะ
  // 🌟 ฟังก์ชันสำหรับดึงคำขอ (Requests) โดยแปลง UID เป็น caretakerId ก่อน
  Future<List<Map<String, dynamic>>> getRequestsForCaretaker(String uid) async {
    try {
      // 🕵️‍♂️ จังหวะที่ 1: เอา uid ไปสืบหา caretakerId (เลขบัตร ปชช.) ของคนๆ นี้ก่อน
      final myProfileSnapshot = await _dbRef
          .child('Login')
          .child(uid)
          .child('Caretaker')
          .get();

      // ถ้าไม่พบข้อมูลโปรไฟล์ ให้คืนค่าลิสต์ว่างกลับไปเลย
      if (!myProfileSnapshot.exists || myProfileSnapshot.value == null)
        return [];

      // ดึงเลขบัตร ปชช. ออกมาเก็บไว้ในตัวแปร myCaretakerId
      final myProfile = myProfileSnapshot.value as Map<dynamic, dynamic>;
      final String myCaretakerId = myProfile['caretakerId']?.toString() ?? '';

      if (myCaretakerId.isEmpty) return [];

      // ---------------------------------------------------------

      // 🔍 จังหวะที่ 2: เริ่มกวาดหา Request ทั้งหมดในระบบ
      DataSnapshot snapshot = await _dbRef.child('Login').get();
      if (!snapshot.exists || snapshot.value == null) return [];

      List<Map<String, dynamic>> allRequests = [];
      final Map<String, dynamic> data = jsonDecode(jsonEncode(snapshot.value));

      data.forEach((userUid, userEntry) {
        if (userEntry['Relative'] != null) {
          final relativeData = userEntry['Relative'] as Map<String, dynamic>;
          final patientData = relativeData['Patient'] as Map<String, dynamic>?;

          if (relativeData['Request'] != null) {
            final requestsMap = relativeData['Request'] as Map<String, dynamic>;

            // 🌟 ในไฟล์ caretaker_service.dart ปรับปรุงฟังก์ชัน getRequestsForCaretaker

            requestsMap.forEach((reqId, reqData) {
              // 🌟 จุดสำคัญ: เทียบ caretakerId ในคำขอ กับ myCaretakerId ที่เราสืบมาได้!
              if (reqData['caretakerId'] == myCaretakerId) {
                // =========================================================
                // 💥 เพิ่มลอจิกเช็คเวลาตรงนี้ เพื่อแก้ไขข้อมูลให้เสร็จก่อนส่งไปหน้าจอ List
                // =========================================================
                String status = (reqData['requeststatus'] ?? '')
                    .toString()
                    .toLowerCase();
                if (status == 'accepted') {
                  String? dateStr = reqData['appointmentdate'];
                  bool hasTriggeredAlert =
                      reqData['hasTriggeredTimeAlert'] ?? false;

                  if (dateStr != null && !hasTriggeredAlert) {
                    DateTime? apptDate = DateTime.tryParse(dateStr);

                    // ถ้าเวลาปัจจุบัน เลยเวลานัดหมายไปแล้ว
                    if (apptDate != null && DateTime.now().isAfter(apptDate)) {
                      // 1. อัปเดตลง Firebase เผื่อไว้เบื้องหลัง
                      _dbRef
                          .child('Login')
                          .child(userUid)
                          .child('Relative')
                          .child('Request')
                          .child(reqId)
                          .update({
                            'isReadCaretaker': false,
                            'hasTriggeredTimeAlert': true,
                          });

                      // 2. ปรับค่าในตัวแปรจำลอง (Local Map) ณ ตอนนี้ทันที!
                      // เพื่อให้ RequestModel รับรู้ค่าใหม่และแสดงคำว่า "NEW" บนหน้าจอทันทีโดยไม่ต้องรอรีเฟรช
                      reqData['isReadCaretaker'] = false;
                      reqData['hasTriggeredTimeAlert'] = true;
                    }
                  }
                }
                // =========================================================

                allRequests.add({
                  'requestModel': RequestModel.fromJson(
                    reqData,
                  ), // ค่านี่จะกลายเป็นผลลัพธ์ล่าสุดทันที
                  'relativeData': relativeData,
                  'patientData': patientData ?? {},
                  'relativeUid': userUid,
                  'isReadCaretaker': reqData['isReadCaretaker'] ?? false,
                  'rawData': reqData,
                });
              }
            });
          }
        }
      });

      // ⏱️ เรียงลำดับคำขอจากวันที่สร้างล่าสุด (ใหม่ไปเก่า)
      allRequests.sort((a, b) {
        DateTime? dateA = (a['requestModel'] as RequestModel).requestdate;
        DateTime? dateB = (b['requestModel'] as RequestModel).requestdate;
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      return allRequests;
    } catch (e) {
      print("Error fetching requests: $e");
      return [];
    }
  }

  Future<void> updateRequestStatus(
    String relativeUid,
    String requestId,
    String status,
  ) async {
    try {
      await _dbRef
          .child('Login')
          .child(relativeUid) // อ้างอิง UID ของญาติ
          .child('Relative')
          .child('Request')
          .child(requestId)
          .update({'requeststatus': status});
    } catch (e) {
      print("Error updating request status: $e");
    }
  }

  // 🌟 ฟังก์ชันดึงรีวิวล่าสุด (ใช้ของเดิมที่มีอยู่แล้วมาต่อยอด)
  Future<List<Map<String, dynamic>>> getRecentReviews(
    String uid, {
    int limit = 2,
  }) async {
    try {
      // 💡 1. เรียกใช้ฟังก์ชันเดิมของคุณ ที่ไปกวาด Request ทั้งหมดของอาสาคนนี้มา
      // (ฟังก์ชันเดียวกับที่คุณใช้ในหน้า List)
      final allRequests = await getRequestsForCaretaker(uid);

      List<Map<String, dynamic>> reviews = [];

      // 💡 2. วนลูปดูทีละ Request เพื่อหาว่าอันไหนมี Review ซ่อนอยู่
      for (var item in allRequests) {
        RequestModel req = item['requestModel'];
        Map<String, dynamic>? relData = item['relativeData'];
        String reviewerImg = '';
        // ถ้าคำขอนี้มีการเขียน Review เอาไว้
        if (req.review != null) {
          // เอาชื่อญาติมาเป็นชื่อคนรีวิว
          String reviewerName = 'ไม่ระบุชื่อ';
          if (relData != null) {
            reviewerName =
                "${relData['firstname'] ?? ''} ${relData['lastname'] ?? ''}"
                    .trim();
            reviewerImg = relData['Patient']['patientphoto'] ?? '';
          }

          reviews.add({
            'reviewerName': reviewerName.isEmpty ? 'ไม่ระบุชื่อ' : reviewerName,

            // ⚠️ ปรับ .rating และ .comment ให้ตรงกับตัวแปรใน ReviewModel ของคุณ
            'rating': req.review!.rating ?? 5.0,
            'comment': req.review!.comment ?? 'ไม่มีข้อความ',

            // ใช้เวลาของคำขอมาจัดเรียง (ถ้าใน ReviewModel มีเวลา ก็เปลี่ยนไปใช้ของ Review แทนได้ครับ)
            'timestamp': req.requestdate?.toIso8601String() ?? '',
            'timeAgo': _formatSimpleDate(req.requestdate?.toIso8601String()),
            'reviewerImage': reviewerImg,
          });
        }
      }

      // 💡 3. เรียงลำดับจาก ใหม่ -> เก่า
      reviews.sort(
        (a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''),
      );

      // 💡 4. ตัดเอาไปโชว์แค่จำนวนจำกัด (เช่น 2 อัน)
      print(reviews.take(limit).toList());
      return reviews.take(limit).toList();
    } catch (e) {
      print('Error fetching nested reviews: $e');
      return [];
    }
  }

  // ฟังก์ชันช่วยแปลงวันที่ให้ดูง่ายขึ้น
  String _formatSimpleDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year + 543}'; // แสดงเป็น วว/ดด/ปปปป
    } catch (e) {
      return '';
    }
  }

  // ==========================================
  // 🌟 ฟังก์ชันดึงรีวิวทั้งหมด (สำหรับหน้าดูรีวิวทั้งหมด)
  // ==========================================
  Future<List<Map<String, dynamic>>> getAllReviews(String uid) async {
    try {
      final allRequests = await getRequestsForCaretaker(uid);
      List<Map<String, dynamic>> reviews = [];

      for (var item in allRequests) {
        RequestModel req = item['requestModel'];
        Map<String, dynamic>? relData = item['relativeData'];

        // ถ้าคำขอนี้มีการรีวิว
        if (req.review != null) {
          String reviewerName = 'ไม่ระบุชื่อ';
          String reviewerImg = '';

          if (relData != null) {
            reviewerName =
                "${relData['firstname'] ?? ''} ${relData['lastname'] ?? ''}"
                    .trim();
            reviewerImg =
                relData['Patient']['patientphoto'] ?? relData['image'] ?? '';
          }

          reviews.add({
            'reviewerName': reviewerName.isEmpty ? 'ไม่ระบุชื่อ' : reviewerName,
            'rating': req.review!.rating ?? 5.0,
            'comment': req.review!.comment ?? 'ไม่มีข้อความ',
            'timestamp': req.requestdate?.toIso8601String() ?? '',
            'timeAgo': _formatSimpleDate(req.requestdate?.toIso8601String()),
            'reviewerImage': reviewerImg,
          });
        }
      }

      // เรียงจากใหม่ไปเก่า (Reverse)
      reviews.sort(
        (a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''),
      );

      // 🌟 รีเทิร์นค่ากลับไปทั้งหมดเลย ไม่ต้องจำกัด Row
      return reviews;
    } catch (e) {
      print('Error fetching all reviews: $e');
      return [];
    }
  }

  // ==========================================
  // 🌟 ฟังก์ชันสำหรับระบบ Tracking และแจ้งเตือน
  // ==========================================

  // 1. ดึงประวัติการแจ้งเตือน (เพื่อดูว่าเคยส่งสถานะไหนไปแล้วบ้าง)
  Future<List<Map<dynamic, dynamic>>> getNotifications(
    String relativeUid,
    String requestId,
  ) async {
    try {
      final snapshot = await _dbRef
          .child('Login')
          .child(relativeUid)
          .child('Relative')
          .child('Request')
          .child(requestId)
          .child('Notification')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> list = data.values
            .map((e) => e as Map<dynamic, dynamic>)
            .toList();
        // เรียงลำดับตามเวลาที่ส่ง
        list.sort(
          (a, b) => (a['timestamp'] ?? '').compareTo(b['timestamp'] ?? ''),
        );
        return list;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> addStatusNotification({
    required String relativeUid,
    required String requestId,
    required String status,
    required String detail, // 🌟 1. เพิ่มตัวรับ detail เข้ามา
  }) async {
    try {
      // เพิ่มประวัติแจ้งเตือน
      final ref = _dbRef
          .child('Login')
          .child(relativeUid)
          .child('Relative')
          .child('Request')
          .child(requestId)
          .child('Notification')
          .push();

      // 🌟 2. เปลี่ยน Key ให้ตรงกับ NotificationModel เพื่อให้ตอนดึงข้อมูลไม่พัง
      await ref.set({
        'notifyId': ref.key,
        'notifystatus': status,
        'notifydetail': detail,
        'notifydate': DateTime.now().toIso8601String(),
      });

      // ถ้ามีพิกัด ให้เซฟพิกัดล่าสุดแยกไว้ เพื่อให้ญาติดูแบบ Real-time ง่ายๆ
    } catch (e) {
      print("Error adding notification: $e");
    }
  }

  // 3. อัปเดตเฉพาะพิกัดแบบ Real-time (ยิงตลอดเวลาที่รถวิ่ง)
  Future<void> updateRealtimeLocation(
    String relativeUid,
    String requestId,
    double lat,
    double lng,
  ) async {
    try {
      await _dbRef
          .child('Login')
          .child(relativeUid)
          .child('Relative')
          .child('Request')
          .child(requestId)
          .child('currentLocation')
          .set({
            'latitude': lat,
            'longitude': lng,
            'timestamp': DateTime.now().toIso8601String(),
          });
    } catch (e) {}
  }

  // 🌟 ฟังก์ชันอัปเดตสถานะว่า "ผู้ดูแลกดเข้าไปดูคำขอนี้แล้ว"
  Future<void> markRequestAsRead(String relativeUid, String requestId) async {
    try {
      await _dbRef
          .child('Login')
          .child(relativeUid)
          .child('Relative')
          .child('Request')
          .child(requestId)
          .update({'isReadCaretaker': true});
    } catch (e) {
      print("Error marking request as read: $e");
    }
  }

  Future<void> saveDoctorAdvice({
    required String relativeUid,
    required String requestId,
    required String advicedetail,
    required String medicalphoto,
    required String doctorname,
    required String hospitalname,
    required String departmentname,
    required String appointmentdate,
    required String appointmenttime,
  }) async {
    try {
      // 🌟 นำข้อมูลมาจัดรูปแบบให้ตรงกับ DoctorAdviceModel
      Map<String, dynamic> adviceData = {
        'advicedetail': advicedetail,
        'medicalphoto': medicalphoto,
        'doctorname': doctorname,
        'hospitalname': hospitalname,
        'departmentname': departmentname,
        'appointmentdate': appointmentdate,
        'appointmenttime': appointmenttime,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _dbRef
          .child('Login')
          .child(relativeUid)
          .child('Relative')
          .child('Request')
          .child(requestId)
          .child('DoctorAdvice') // 🌟 เซฟภายใต้ชื่อ DoctorAdvice
          .set(adviceData);
    } catch (e) {
      print("Error saving doctor advice: $e");
    }
  }
}
