import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // 🛠️ เปลี่ยนมานำเข้าตัว Realtime Database
import '../models/relative_model.dart';
import '../models/patient_model.dart';
import '../models/caretaker_model.dart';
import '../models/vehicle_model.dart';
import '../models/document_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🛠️ สร้างตัวแปรอ้างอิงไปยังถังข้อมูลของ Realtime Database
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

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
          );

      String uid = userCredential.user!.uid;

      // 1. บันทึกข้อมูลบัญชีหลัก
      await _dbRef.child('Login').child(uid).set({
        'username': username,
        'password': password,
        'usertype': usertype,
      });

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

      return userCredential;
    } catch (e) {
      print("เกิดข้อผิดพลาดหลังบ้าน: $e");
      return null;
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
          );

      String uid = userCredential.user!.uid;

      // บันทึกข้อมูลบัญชีหลัก
      await _dbRef.child('Login').child(uid).set({
        'username': username,
        'password': password,
        'usertype': usertype,
      });

      // บันทึกรายละเอียดผู้ดูแล
      Map<String, dynamic> caretakerMap = caretaker.toJson();
      caretakerMap['caretakerId'] = uid;
      await _dbRef
          .child('Login')
          .child(uid)
          .child('Caretaker')
          .set(caretakerMap);

      // บันทึกข้อมูลยานพาหนะ
      await _dbRef
          .child('Login')
          .child(uid)
          .child('Caretaker')
          .child('Vehicle')
          .set(vehicle.toJson());

      // 3. เพิ่มการบันทึกข้อมูลเอกสาร (ลูปตามจำนวนไฟล์ที่ส่งมา)
      for (var doc in documents) {
        await _dbRef
            .child('Login')
            .child(uid)
            .child('Caretaker')
            .child('Document')
            .child(doc.documentId!) // ใช้ ID เอกสารเป็นชื่อปมย่อย
            .set(doc.toJson());
      }

      return userCredential;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการสมัครสมาชิกผู้ดูแล: $e");
      return null;
    }
  }

  // 🔐 3. ฟังก์ชันเข้าสู่ระบบด้วย Username (ค้นหาจาก Realtime Database)
  // 🔐 3. ฟังก์ชันเข้าสู่ระบบด้วย Username
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
          .once();

      if (event.snapshot.exists) {
        Map<dynamic, dynamic> users =
            event.snapshot.value as Map<dynamic, dynamic>;
        String uid = users.keys.first;
        Map<dynamic, dynamic> userData = users[uid];

        // 2. เช็กว่ารหัสผ่านตรงไหม
        if (userData['password'] == password) {

          if (userData['usertype'] == 'caretaker') {
            
            String status = userData['Caretaker']['accountstatus'] ?? '';
            String reason = userData['Caretaker']['admincomment'] ?? '';

            return {
              'success': true,
              'uid': uid,
              'usertype': userData['usertype'],
              'accountstatus': status,
              'admincomment': reason,
            };
          }
          // ถ้าเป็นญาติ หรือ เป็นผู้ดูแลที่ Approved แล้ว ให้ผ่านได้ปกติ
          return {
            'success': true,
            'uid': uid,
            'usertype': userData['usertype'],
          };
        } else {
          return {'success': false, 'message': 'รหัสผ่านไม่ถูกต้อง'};
        }
      } else {
        return {'success': false, 'message': 'ไม่พบชื่อผู้ใช้นี้ในระบบ'};
      }
    } catch (e) {
      print("Login Error: $e");
      return {'success': false, 'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ'};
    }
  }
}
