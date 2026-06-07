import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔐 ฟังก์ชันสมัครสมาชิก (สอดคล้องกับ registerMemberในไดอะแกรม)
  Future<UserCredential?> registerMember(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการสมัครสมาชิก: $e");
      return null;
    }
  }

  // 🔑 ฟังก์ชันเข้าสู่ระบบ (สอดคล้องกับ loginMember ในไดอะแกรม)
  Future<UserCredential?> loginMember(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเข้าสู่ระบบ: $e");
      return null;
    }
  }
}