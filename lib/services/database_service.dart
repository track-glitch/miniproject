import 'package:cloud_firestore/cloud_firestore.dart';
// อย่าลืม import ไฟล์โมเดลของคุณให้ครบนะครับ
import '../models/caretaker_model.dart';
import '../models/patient_model.dart';
import '../models/relative_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📝 บันทึกข้อมูลผู้ดูแล (Caretaker)
  Future<bool> saveCaretakerData(CaretakerModel caretaker) async {
    try {
      // ใช้ caretakerId (ที่ได้จาก UID ของ Auth) เป็นชื่อ Document
      await _firestore.collection('caretakers').doc(caretaker.caretakerId).set(caretaker.toMap());
      return true;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการบันทึกผู้ดูแล: $e");
      return false;
    }
  }

  // 📝 บันทึกข้อมูลญาติและผู้ป่วย (Relative & Patient)
  Future<bool> saveRelativeAndPatientData(RelativeModel relative, PatientModel patient) async {
    try {
      // บันทึกข้อมูลญาติ
      await _firestore.collection('relatives').doc(relative.relativeId).set(relative.toMap());
      // บันทึกข้อมูลผู้ป่วย
      await _firestore.collection('patients').doc(patient.patientId).set(patient.toMap());
      return true;
    } catch (e) {
      print("เกิดข้อผิดพลาดในการบันทึกญาติและผู้ป่วย: $e");
      return false;
    }
  }
}