import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
// 🌟 อย่าลืม import ไฟล์หน้า Review ของคุณ
// import 'package:miniproject/views/relative/review_caretaker_page.dart';

class FunctionService {
  StreamSubscription<DatabaseEvent>? _requestSubscription;
  bool _isShowingReviewPopup = false;

  // ฟังก์ชันเริ่มการดักฟัง
  void startListening(BuildContext context, String loggedUid) {
    final reqRef = FirebaseDatabase.instance.ref(
      'Login/$loggedUid/Relative/Request',
    );

    _requestSubscription = reqRef.onValue.listen((event) async {
      if (!event.snapshot.exists || event.snapshot.value == null) return;

      final requests = event.snapshot.value as Map<dynamic, dynamic>;

      for (var entry in requests.entries) {
        final reqId = entry.key;
        final reqData = entry.value as Map<dynamic, dynamic>;

        final status = reqData['requeststatus']?.toString().toLowerCase();
        final isReviewed = reqData['isReviewed'] ?? false;

        if (status == 'completed' && !isReviewed && !_isShowingReviewPopup) {
          _isShowingReviewPopup = true;

          await _fetchCaretakerAndShowReview(
            context: context,
            loggedUid: loggedUid,
            reqId: reqId.toString(),
            caretakerId: reqData['caretakerId']?.toString(),
            hospitalName:
                reqData['hospitalname']?.toString() ?? 'ไม่ระบุโรงพยาบาล',
          );
          break;
        }
      }
    });
  }

  // ฟังก์ชันดึงข้อมูลผู้ดูแลและเด้ง Popup
  Future<void> _fetchCaretakerAndShowReview({
    required BuildContext context,
    required String loggedUid,
    required String reqId,
    required String? caretakerId,
    required String hospitalName,
  }) async {
    if (caretakerId == null || caretakerId.isEmpty) {
      _isShowingReviewPopup = false;
      return;
    }

    try {
      final usersSnap = await FirebaseDatabase.instance.ref('Login').get();
      String? caretakerUid;
      String caretakerName = 'ไม่ทราบชื่อ';
      String? caretakerImage;

      if (usersSnap.exists && usersSnap.value is Map) {
        final users = usersSnap.value as Map<dynamic, dynamic>;
        for (var entry in users.entries) {
          if (entry.value['Caretaker'] != null &&
              entry.value['Caretaker']['caretakerId'] == caretakerId) {
            caretakerUid = entry.key.toString();
            final ctData = entry.value['Caretaker'];
            caretakerName =
                '${ctData['firstname'] ?? ''} ${ctData['lastname'] ?? ''}'
                    .trim();
            if (caretakerName.isEmpty) caretakerName = 'ผู้ดูแลของคุณ';
            caretakerImage = ctData['profilephoto'];
            break;
          }
        }
      }

      // เช็กว่า context ยังอยู่ไหมก่อน push หน้าใหม่
      if (caretakerUid != null && context.mounted) {
        /* 🌟 ปลดคอมเมนต์เมื่อ import หน้า Review เข้ามาแล้ว
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewCaretakerPage(
              requestId: reqId,
              relativeUid: loggedUid,
              caretakerUid: caretakerUid!,
              caretakerName: caretakerName,
              hospitalName: hospitalName,
              caretakerImage: caretakerImage,
            ),
          ),
        );
        */
      }
    } catch (e) {
      print("Error showing auto-review popup: $e");
    } finally {
      _isShowingReviewPopup = false;
    }
  }

  // ฟังก์ชันสำหรับเคลียร์ Listener คืนหน่วยความจำ
  void dispose() {
    _requestSubscription?.cancel();
  }
}
