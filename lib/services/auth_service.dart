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

  Future<Map<String, dynamic>?> loginWithIdCard(
    String idCard,
    String password,
  ) async {
    try {
      String? email;
      String? role;
      Map<dynamic, dynamic>? userData;
      String? uid;

      // 1. 🔍 ลองค้นหาในโหนด Caretaker ก่อน
      DatabaseEvent caretakerEvent = await _dbRef
          .child('Login')
          .orderByChild('Caretaker/caretakerId')
          .equalTo(idCard)
          .once();

      if (caretakerEvent.snapshot.exists) {
        Map<dynamic, dynamic> users =
            caretakerEvent.snapshot.value as Map<dynamic, dynamic>;
        uid = users.keys.first.toString();
        userData = Map<dynamic, dynamic>.from(users[uid] as Map);

        email = userData['Caretaker']['email'];
        role = 'caretaker';
      } else {
        // 2. 🔍 ถ้าไม่เจอผู้ดูแล ให้ลองค้นหาในโหนด Relative (ญาติ)
        DatabaseEvent relativeEvent = await _dbRef
            .child('Login')
            .orderByChild('Relative/relativeId')
            .equalTo(idCard)
            .once();

        if (relativeEvent.snapshot.exists) {
          Map<dynamic, dynamic> users =
              relativeEvent.snapshot.value as Map<dynamic, dynamic>;
          uid = users.keys.first.toString();
          userData = Map<dynamic, dynamic>.from(users[uid] as Map);

          email = userData['Relative']['email'];
          role = 'relative';
        }
      }

      // 3. ถ้าหาไม่เจอทั้งคู่ แปลว่าไม่มีเลขบัตรนี้ในระบบ
      if (email == null || role == null) {
        return {
          'success': false,
          'message': 'ไม่พบหมายเลขบัตรประชาชนนี้ในระบบ',
        };
      }

      // 4. ล็อกอินด้วย Firebase Auth จริงๆ
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 5. จัดเตรียมข้อมูลส่งกลับให้หน้า Login แยกตามประเภทผู้ใช้
      if (role == 'caretaker') {
        String status = userData!['Caretaker']['accountstatus'] ?? 'Pending';
        String reason = userData['Caretaker']['admincomment'] ?? '';
        bool hasVehicle = false;
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
          'usertype': 'caretaker',
          'accountstatus': status,
          'admincomment': reason,
          'hasVehicle': hasVehicle,
        };
      } else {
        // กรณีเป็นญาติ (Relative)
        return {
          'success': true,
          'uid': userCredential.user!.uid,
          'usertype': 'relative',
        };
      }
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

  Future<bool> updateVehicleAndServiceStatus({
    required String uid,
    required VehicleModel vehicle,
  }) async {
    try {
      // ใช้ .update() เพื่อแก้ไขและเพิ่มข้อมูลเฉพาะส่วน โดยไม่กระทบข้อมูลอื่น
      await _dbRef.child('Login').child(uid).child('Caretaker').update({
        'Vehicle': vehicle.toJson(), // อัปเดตข้อมูลรถ
        'servicestatus': 'Available', // เปลี่ยนสถานะเป็นพร้อมรับงาน
      });
      return true;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการอัปเดตรถยนต์: $e");
      return false;
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
