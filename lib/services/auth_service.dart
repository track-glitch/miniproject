import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // 🛠️ เปลี่ยนมานำเข้าตัว Realtime Database
import '../models/relative_model.dart';
import '../models/patient_model.dart';
import '../models/caretaker_model.dart';
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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: relative.email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // 1. บันทึกข้อมูลบัญชีหลัก
      await _dbRef.child('Login').child(uid).set({
        'username': username,
        'email': relative.email, // 🛠️ ต้องเก็บ email ไว้ในนี้ด้วยนะน้า เอาไว้ค้นหาตอน login ครับ!
        'usertype': usertype,
      });

      // 2. บันทึกข้อมูลญาติ
      await _dbRef.child('Login').child(usertype).child(uid).set(relative.toMap()); // 🛠️ แปลงเป็น toMap()

      // 3. บันทึกข้อมูลผู้ป่วย
      await _dbRef.child('Login').child(usertype).child(uid).child('Patient').set(patient.toMap()); // 🛠️ แปลงเป็น toMap() และขยับปมให้สมเหตุสมผล

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
  }) async {
    try {
      // สเต็ป A: ส่งอีเมลจริง + รหัสผ่าน ไปขอบัญชีหลักและเอา UID ป้ายแดงมาจาก Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: caretaker.email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // สเต็ป B: บันทึกคู่แฝด "username" และ "email" ลงตู้ Realtime Database ทันทีเพื่อเอาไว้สืบค้นตอนล็อกอิน
      // โครงสร้าง JSON จะถูกเก็บไว้ที่ปม: users -> uid -> ข้อมูลส่วนตัว
      await _dbRef.child('Login').child(uid).set({
        'username': username,
        'password': password,
        'usertype': usertype, // เก็บตำแหน่งเพื่อแยกหน้าจอแอป
      });

      await _dbRef.child('Login').child(usertype).child(uid).set({
        'caretakerId': caretaker.caretakerId,
        'profilephoto': caretaker.profilephoto,
        'firstname': caretaker.firstname,
        'lastname': caretaker.lastname,
        'gender': caretaker.gender,
        'birthdate': caretaker.birthdate.toIso8601String(),
        'phonenumber': caretaker.phonenumber,
        'email': caretaker.email,
        'aboutme': caretaker.aboutme,
        'equipmentdetails': caretaker.equipmentdetails,
        'address': caretaker.address,
        'admincomment': caretaker.admincomment,
        'servicestatus': caretaker.servicestatus,
        'accountstatus': caretaker.accountstatus,
        'latitude': caretaker.latitude,
        'longitude': caretaker.longitude,
      });

      return userCredential;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการสมัครสมาชิก: $e");
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