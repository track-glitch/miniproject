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
    required String username,
    required String password,
    required String usertype,
    required RelativeModel relative,
    required PatientModel patient,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: relative.email!,
            password: password,
          ); //

      String uid = userCredential.user!.uid; //

      // 1. บันทึกข้อมูลบัญชีหลัก
      await _dbRef.child('Login').child(uid).set({
        'username': username,
        'password': password,
        'usertype': usertype,
      }); //

      // 2. บันทึกข้อมูลญาติ
      await _dbRef
          .child('Login')
          .child(uid)
          .child('Relative')
          .set(relative.toJson()); // 🛠️ แปลงเป็น toJson()

      // 3. บันทึกข้อมูลผู้ป่วย
      await _dbRef
          .child('Login')
          .child(uid)
          .child('Relative')
          .child('Patient')
          .set(
            patient.toJson(),
          ); // 🛠️ แปลงเป็น toJson() และขยับปมให้สมเหตุสมผล

      return userCredential; //
    } catch (e) {
      print("เกิดข้อผิดพลาดหลังบ้าน: $e"); //
      return null; //
    }
  }

  Future<UserCredential?> registerCaretaker({
    required String username,
    required String password,
    required String usertype,
    required CaretakerModel caretaker,
    required VehicleModel vehicle,
    required List<DocumentModel> documents, // 2. เพิ่มการรับ List ของเอกสาร
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: caretaker.email!,
            password: password,
          ); //

      String uid = userCredential.user!.uid; //

      // บันทึกข้อมูลบัญชีหลัก
      await _dbRef.child('Login').child(uid).set({
        'username': username,
        'password': password,
        'usertype': usertype,
      }); //

      // บันทึกรายละเอียดผู้ดูแล
      Map<String, dynamic> caretakerMap = caretaker.toJson(); //
      caretakerMap['caretakerId'] = uid; //
      await _dbRef
          .child('Login')
          .child(uid)
          .child('Caretaker')
          .set(caretakerMap); //

      // บันทึกข้อมูลยานพาหนะ
      await _dbRef
          .child('Login')
          .child(uid)
          .child('Caretaker')
          .child('Vehicle')
          .set(vehicle.toJson()); //

      // 3. เพิ่มการบันทึกข้อมูลเอกสาร (ลูปตามจำนวนไฟล์ที่ส่งมา)
      for (var doc in documents) {
        await _dbRef
            .child('Login')
            .child(uid)
            .child('Caretaker')
            .child('Document')
            .child(doc.documentId!) // ใช้ ID เอกสารเป็นชื่อปมย่อย
            .set(doc.toJson()); //
      }

      return userCredential; //
    } catch (e) {
      print("เกิดข้อผิดพลาดในการสมัครสมาชิกผู้ดูแล: $e"); //
      return null; //
    }
  }

  // 🔐 3. ฟังก์ชันเข้าสู่ระบบด้วย Username (เวอร์ชันอัปเดตแก้อาการสิทธิ์ซ้ำซ้อนพัง)
  Future<Map<String, dynamic>?> loginWithUsername(
    String username,
    String password,
  ) async {
    try {
      // 1. ค้นหาในโหนด 'Login' ว่ามีใครใช้ username นี้ไหม
      DatabaseEvent event = await _dbRef
          .child('Login')
          .orderByChild('username')
          .equalTo(username)
          .once(); //

      if (event.snapshot.exists) {
        Map<dynamic, dynamic> users =
            event.snapshot.value as Map<dynamic, dynamic>; //
        String uid = users.keys.first.toString(); //
        Map<dynamic, dynamic> userData = Map<dynamic, dynamic>.from(users[uid] as Map); //

        // 2. เช็กว่ารหัสผ่านใน Realtime Database ตรงกันไหม
        if (userData['password'] == password) {
          
          // 🎯 แก้ไขจุดสำคัญ: สั่งเข้าสู่ระบบแบบ Anonymous แทนเพื่อผูก Token จำสถานะผู้ใช้ในเครื่อง
          // โดยไม่ใช้วิธีเดิมที่ส่งผลให้เกิด Error [firebase_auth/invalid-credential]
          if (_auth.currentUser == null) {
            await _auth.signInAnonymously();
          }

          // 3. ส่งข้อมูลกลับไปตามเงื่อนไขประเภทผู้ใช้
          if (userData['usertype'] == 'caretaker' && userData['Caretaker'] != null) { //
            String status = userData['Caretaker']['accountstatus'] ?? ''; //
            String reason = userData['Caretaker']['admincomment'] ?? ''; //

            return {
              'success': true,
              'uid': uid,
              'usertype': userData['usertype'],
              'accountstatus': status,
              'admincomment': reason,
            }; //
          }
          
          return {
            'success': true,
            'uid': uid,
            'usertype': userData['usertype'],
          }; //
        } else {
          return {'success': false, 'message': 'รหัสผ่านไม่ถูกต้อง'}; //
        }
      } else {
        return {'success': false, 'message': 'ไม่พบชื่อผู้ใช้นี้ในระบบ'}; //
      }
    } catch (e) {
      print("Login Error: $e"); //
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'}; //
    }
  }

  Future<User?> loginWithEmail(String email, String password) async { //
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Email Login Error: $e");
      return null;
    }
  }

  // 🎯 ดึงตำแหน่งสิทธิ์ของผู้ใช้งาน (Role)
  Future<String?> getUserRole(dynamic uid) async { //
    try {
      final snapshot = await _dbRef.child('Login/$uid').get(); //
      if (snapshot.exists && snapshot.value is Map) { //
        final userData = Map<String, dynamic>.from(snapshot.value as Map); //
        return userData['usertype']?.toString(); // คืนค่า 'relative', 'caretaker', 'admin'
      }
      return null; //
    } catch (e) {
      print("Error getting user role: $e"); //
      return null; //
    }
  }

  // 🎯 ดึงสถานะการอนุมัติบัญชี (accountstatus) จากระบบฐานข้อมูลจริงของคุณ
  Future<String?> getUserStatus(dynamic uid) async { //
    try {
      final snapshot = await _dbRef.child('Login/$uid').get(); //
      if (snapshot.exists && snapshot.value is Map) { //
        final userData = Map<String, dynamic>.from(snapshot.value as Map); //
        
        // เช็คที่คีย์ระดับรากหลักก่อน
        if (userData.containsKey('accountstatus')) {
          return userData['accountstatus']?.toString(); //
        }

        // เช็คในโหนดชั้นในของ Relative
        if (userData.containsKey('Relative') && userData['Relative'] != null) { //
          final relativeData = Map<String, dynamic>.from(userData['Relative'] as Map); //
          if (relativeData.containsKey('accountstatus')) { //
            return relativeData['accountstatus']?.toString(); //
          }
        }
        
        // เช็คในโหนดชั้นในของ Caretaker
        if (userData.containsKey('Caretaker') && userData['Caretaker'] != null) { //
          final caretakerData = Map<String, dynamic>.from(userData['Caretaker'] as Map); //
          if (caretakerData.containsKey('accountstatus')) { //
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