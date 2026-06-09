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
            email: relative.email,
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
          .set(relative.toMap()); // 🛠️ แปลงเป็น toMap()

      // 3. บันทึกข้อมูลผู้ป่วย
      await _dbRef
          .child('Login')
          .child(uid)
          .child('Relative')
          .child('Patient')
          .set(patient.toMap()); // 🛠️ แปลงเป็น toMap() และขยับปมให้สมเหตุสมผล

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
            email: caretaker.email,
            password: password,
          );

      String uid = userCredential.user!.uid;

      // บันทึกข้อมูลบัญชีหลัก
      await _dbRef.child('Login').child(uid).set({
        'username': username,
        'password': password,
        'usertype': usertype,
        'email': caretaker.email,
      });

      // บันทึกรายละเอียดผู้ดูแล
      Map<String, dynamic> caretakerMap = caretaker.toMap();
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
          .set(vehicle.toMap());

      // 3. เพิ่มการบันทึกข้อมูลเอกสาร (ลูปตามจำนวนไฟล์ที่ส่งมา)
      for (var doc in documents) {
        await _dbRef
            .child('Login')
            .child(uid)
            .child('Caretaker')
            .child('Document')
            .child(doc.documentId) // ใช้ ID เอกสารเป็นชื่อปมย่อย
            .set(doc.toMap());
      }

      return userCredential;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการสมัครสมาชิกผู้ดูแล: $e");
      return null;
    }
  }

  // 🔑 2. ฟังก์ชันเข้าสู่ระบบด้วย Username + Password
  Future<UserCredential?> loginMember({
    required String username,
    required String password,
  }) async {
    try {
      // สเต็ป A: วิ่งไปส่องต้นไม้ JSON เพื่อค้นหาว่ามีใครใช้ username นี้ไหม
      // สั่งค้นหาปมใน 'users' ที่มีฟิลด์ 'username' ตรงกับที่กรอกเข้ามา
      DataSnapshot snapshot = await _dbRef
          .child('Login')
          .orderByChild('username')
          .equalTo(username)
          .get();

      // ถ้าไม่เจอชื่อผู้ใช้นี้เลยในฐานข้อมูล
      if (!snapshot.exists || snapshot.value == null) {
        print("ไม่พบชื่อผู้ใช้นี้ในระบบ");
        return null;
      }

      // เนื่องจาก Realtime DB จะคืนค่ากลับมาเป็น Map เราต้องแกะเอาอีเมลจริงที่ซ่อนอยู่ข้างในออกมา
      Map<dynamic, dynamic> usersMap = snapshot.value as Map<dynamic, dynamic>;
      String realEmail = "";

      for (var entry in usersMap.values) {
        realEmail = entry['email'] ?? "";
      }

      if (realEmail.isEmpty) return null;

      // สเต็ป B: ได้อีเมลจริงมาแล้ว! เอาอีเมลจริง + พาสเวิร์ด ส่งไปล็อกอินกับ Firebase Auth ตามสูตรสากลครับ
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: realEmail,
        password: password,
      );

      return userCredential;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเข้าสู่ระบบ: $e");
      return null;
    }
  }
}
