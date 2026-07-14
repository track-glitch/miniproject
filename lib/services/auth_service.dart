import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // 🛠️ นำเข้าตัว Realtime Database
import '../models/relative_model.dart'; //
import '../models/patient_model.dart'; //
import '../models/caretaker_model.dart'; //
import '../models/vehicle_model.dart'; //
import '../models/document_model.dart'; //

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance; //

  // 🛠️ สร้างตัวแปรอ้างอิงไปยังถังข้อมูลของ Realtime Database
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(); //

  // 🔐 1. ฟังก์ชันสมัครสมาชิก (กรอก Username, Email จริง, และ Password)
  Future<UserCredential?> registerRelative({
    required String password,
    required RelativeModel
    relative, // 🌟 รับแค่ก้อนนี้ก้อนเดียว เพราะ Patient อยู่ข้างในแล้ว
  }) async {
    try {
      // 1. สร้างบัญชี Firebase Auth ด้วย Email
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: relative.email!,
            password: password,
          );

      String uid = userCredential.user!.uid;

      // 2. บันทึกข้อมูลลง Realtime Database
      // ใช้ relative.toJson() มันจะแปลง PatientModel ที่ซ้อนอยู่ให้เป็น JSON อัตโนมัติ
      await _dbRef.child('Login').child(uid).set({
        'Relative': relative.toJson(),
      });

      return userCredential;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการสมัครสมาชิกญาติ: $e");
      return null;
    }
  }

  // ==========================================
  // File: lib/services/auth_service.dart (อัปเดตฟังก์ชันสมัคร Caretaker)
  // ==========================================

  // ==========================================
  // แก้ไขในไฟล์: lib/services/auth_service.dart
  // ==========================================

  Future<UserCredential?> registerCaretaker({
    required String password,
    // ไม่ต้องรับ usertype แยกแล้ว เพราะมีอยู่ใน caretaker.usertype แล้ว
    required CaretakerModel caretaker,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: caretaker.email!,
            password: password,
          );

      String uid = userCredential.user!.uid;

      // บันทึกข้อมูลลง Realtime Database
      // โครงสร้าง: Login/uid/Caretaker (usertype และ Document ถูกจัดเก็บตาม Model แล้ว)
      await _dbRef.child('Login').child(uid).set({
        'Caretaker': caretaker.toJson(),
      });

      return userCredential;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการสมัครสมาชิกผู้ดูแล: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> loginWithCaretakerId(
    String caretakerId,
    String password,
  ) async {
    try {
      DatabaseEvent event = await _dbRef
          .child('Login')
          .orderByChild('Caretaker/caretakerId')
          .equalTo(caretakerId)
          .once();

      if (!event.snapshot.exists) {
        return {
          'success': false,
          'message': 'ไม่พบหมายเลขบัตรประชาชนนี้ในระบบ',
        };
      }

      Map<dynamic, dynamic> users =
          event.snapshot.value as Map<dynamic, dynamic>;
      String uid = users.keys.first.toString();
      Map<dynamic, dynamic> userData = Map<dynamic, dynamic>.from(
        users[uid] as Map,
      );

      // 🌟 อัปเดตการเช็ค usertype ให้เช็คจากด้านใน Caretaker
      if (userData['Caretaker'] == null ||
          userData['Caretaker']['usertype'] != 'caretaker') {
        return {'success': false, 'message': 'บัญชีนี้ไม่ใช่ผู้ให้บริการ'};
      }

      String email = userData['Caretaker']['email'];

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String status = userData['Caretaker']['accountstatus'] ?? 'Pending';
      String reason = userData['Caretaker']['admincomment'] ?? '';
      bool hasVehicle = false;

      // 🌟 อัปเดต Key เป็น 'Vehicle' (ตัว V ใหญ่) ตามที่แก้ใน Model
      if (userData['Caretaker']['Vehicle'] != null) {
        var vehicleData = userData['Caretaker']['Vehicle'];
        if (vehicleData['licenseplate'] != null &&
            vehicleData['licenseplate'] != "ยังไม่ได้ระบุ") {
          hasVehicle = true;
        }
      }

      return {
        'success': true,
        'uid': userCredential.user!.uid,
        'usertype': 'caretaker', // คืนค่า usertype กลับไปให้หน้า Login นำทางต่อ
        'accountstatus': status,
        'admincomment': reason,
        'hasVehicle': hasVehicle,
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return {'success': false, 'message': 'รหัสผ่านไม่ถูกต้อง'};
      }
      return {'success': false, 'message': 'เกิดข้อผิดพลาด Auth: ${e.message}'};
    } catch (e) {
      print("Login Error: $e");
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ'};
    }
  }

  Future<Map<String, dynamic>?> loginWithRelativeId(
    String idCard,
    String password,
  ) async {
    try {
      // 1. Query ค้นหาข้อมูลใน Database จากเลขบัตรประชาชนที่เก็บไว้ใน Relative/relativeId
      DatabaseEvent event = await _dbRef
          .child('Login')
          .orderByChild('Relative/relativeId')
          .equalTo(idCard)
          .once();

      if (!event.snapshot.exists) {
        return {
          'success': false,
          'message': 'ไม่พบหมายเลขบัตรประชาชนนี้ในระบบ',
        };
      }

      // 2. ดึงข้อมูล Email ออกมาจาก Database
      Map<dynamic, dynamic> users =
          event.snapshot.value as Map<dynamic, dynamic>;
      String uid = users.keys.first.toString();
      Map<dynamic, dynamic> userData = Map<dynamic, dynamic>.from(
        users[uid] as Map,
      );

      // เช็คให้แน่ใจว่าเป็นบัญชี Relative
      if (userData['Relative'] == null ||
          userData['Relative']['usertype'] != 'relative') {
        return {
          'success': false,
          'message': 'บัญชีนี้ไม่ใช่บัญชีสำหรับญาติหรือผู้ป่วย',
        };
      }

      String email = userData['Relative']['email']; // ได้ Email จริงมาแล้ว

      // 3. นำ Email และ Password ไปล็อกอินผ่าน Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return {
        'success': true,
        'uid': userCredential.user!.uid,
        'usertype': 'relative',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return {'success': false, 'message': 'รหัสผ่านไม่ถูกต้อง'};
      }
      return {'success': false, 'message': 'เกิดข้อผิดพลาด Auth: ${e.message}'};
    } catch (e) {
      print("Login Error: $e");
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ'};
    }
  }

  // 🎯 ดึงตำแหน่งสิทธิ์ของผู้ใช้งาน (Role)
  Future<String?> getUserRole(dynamic uid) async {
    //
    try {
      final snapshot = await _dbRef.child('Login/$uid').get(); //
      if (snapshot.exists && snapshot.value is Map) {
        //
        final userData = Map<String, dynamic>.from(snapshot.value as Map); //
        return userData['usertype']
            ?.toString(); // คืนค่า 'relative', 'caretaker', 'admin'
      }
      return null; //
    } catch (e) {
      print("Error getting user role: $e"); //
      return null; //
    }
  }

  // 🎯 ดึงสถานะการอนุมัติบัญชี (accountstatus) จากระบบฐานข้อมูลจริงของคุณ
  Future<String?> getUserStatus(dynamic uid) async {
    //
    try {
      final snapshot = await _dbRef.child('Login/$uid').get(); //
      if (snapshot.exists && snapshot.value is Map) {
        //
        final userData = Map<String, dynamic>.from(snapshot.value as Map); //

        // เช็คที่คีย์ระดับรากหลักก่อน
        if (userData.containsKey('accountstatus')) {
          return userData['accountstatus']?.toString(); //
        }

        // เช็คในโหนดชั้นในของ Relative
        if (userData.containsKey('Relative') && userData['Relative'] != null) {
          //
          final relativeData = Map<String, dynamic>.from(
            userData['Relative'] as Map,
          ); //
          if (relativeData.containsKey('accountstatus')) {
            //
            return relativeData['accountstatus']?.toString(); //
          }
        }

        // เช็คในโหนดชั้นในของ Caretaker
        if (userData.containsKey('Caretaker') &&
            userData['Caretaker'] != null) {
          //
          final caretakerData = Map<String, dynamic>.from(
            userData['Caretaker'] as Map,
          ); //
          if (caretakerData.containsKey('accountstatus')) {
            //
            return caretakerData['accountstatus']?.toString();
          }
        }
      }
      return null; //
    } catch (e) {
      print("Error getting user status: $e"); //
      return null; //
    }
  }
}
