import 'package:firebase_database/firebase_database.dart';
// --- เปลี่ยน Path ให้ตรงกับโฟลเดอร์ในโปรเจกต์ของคุณ ---
import '../models/caretaker_model.dart';
import '../models/patient_model.dart';
import '../models/relative_model.dart';

class DatabaseService {
  // 🛠️ เปลี่ยนจาก FirebaseFirestore มาเป็นคำสั่งอ้างอิงของ Realtime Database
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  // 📝 บันทึกข้อมูลผู้ดูแล (Caretaker) เพิ่มเติมหรือแก้ไขประวัติ
  Future<bool> saveCaretakerData(CaretakerModel caretaker) async {
    try {
      // บันทึกข้อมูลลงปม 'Caretakers' -> รหัสไอดีผู้ดูแล
      await _dbRef.child('Login').child('caretaker').child(caretaker.caretakerId).set(caretaker.toMap());
      return true;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการบันทึกผู้ดูแลลง Realtime DB: $e");
      return false;
    }
  }

  // 📝 บันทึกข้อมูลญาติและผู้ป่วย (Relative & Patient) เพิ่มเติมหรือแก้ไขประวัติ
  Future<bool> saveRelativeAndPatientData(RelativeModel relative, PatientModel patient) async {
    try {
      // บันทึกข้อมูลญาติ
      await _dbRef.child('Login').child('relative').child(relative.relativeId).set(relative.toMap());
      // บันทึกข้อมูลผู้ป่วย แปะพ่วงไว้ใต้ห้องญาติคนนั้นๆ หรือแยกห้องตามต้องการได้เลยครับ
      await _dbRef.child('Login').child('relative').child(relative.relativeId).child('Patient').set(patient.toMap());
      return true;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการบันทึกญาติและผู้ป่วยลง Realtime DB: $e");
      return false;
    }
  }
}