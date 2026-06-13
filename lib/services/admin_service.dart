import 'package:firebase_database/firebase_database.dart';
import '../models/caretaker_model.dart';
import '../models/vehicle_model.dart';
import '../models/document_model.dart';
import '../models/login_model.dart';
import 'dart:convert'; // 📌 ต้องมีตัวนี้เพื่อใช้เครื่องมือแปลงข้อมูล
class AdminService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();


  Future<List<CaretakerModel>> getCaretakersByStatus(String status) async {
      try {
        final snapshot = await _dbRef.child('Login').get();

        if (!snapshot.exists || snapshot.value == null) return [];

        // 🌟 ท่าไม้ตาย: แปลงข้อมูลทั้งหมดจาก Firebase ให้เป็น Map<String, dynamic> 100%
        final Map<String, dynamic> data = jsonDecode(jsonEncode(snapshot.value));

        List<CaretakerModel> caretakers = [];

        data.forEach((uid, userData) {
          // ถ้าบัญชีนี้ไม่มีโหนด Caretaker ให้ข้ามไป
          if (userData['Caretaker'] == null) return;

          // ข้อมูลตอนนี้รับประกันว่าเป็น Map<String, dynamic> แน่นอน
          final caretakerData = userData['Caretaker'] as Map<String, dynamic>;

          // กรองเอาเฉพาะ accountstatus ที่ตรงกับแท็บที่เลือก
          if (caretakerData['accountstatus'] != status) return;

          // 🚗 1. ดึงข้อมูลยานพาหนะ (ถ้ามี)
          VehicleModel? vehicle;
          if (caretakerData['Vehicle'] != null) {
            vehicle = VehicleModel.fromJson(caretakerData['Vehicle'] as Map<String, dynamic>);
          }

          // 📂 2. ดึงข้อมูลรายการเอกสาร (ถ้ามี)
          List<DocumentModel>? documents;
          if (caretakerData['Document'] != null) {
            final docMap = caretakerData['Document'] as Map<String, dynamic>;
            documents = docMap.values.map((e) {
              return DocumentModel.fromJson(e as Map<String, dynamic>);
            }).toList();
          }

          caretakers.add(
            CaretakerModel(
              caretakerId: caretakerData['caretakerId'] ?? '',
              profilephoto: caretakerData['profilephoto'] ?? '',
              firstname: caretakerData['firstname'] ?? '',
              lastname: caretakerData['lastname'] ?? '',
              gender: caretakerData['gender'] ?? '',
              birthdate: caretakerData['birthdate'] != null 
                  ? DateTime.parse(caretakerData['birthdate']) 
                  : null,
              phonenumber: caretakerData['phonenumber'] ?? '',
              email: caretakerData['email'] ?? '',
              aboutme: caretakerData['aboutme'] ?? '',
              equipmentdetails: caretakerData['equipmentdetails'] ?? '',
              address: caretakerData['address'] ?? '',
              admincomment: caretakerData['admincomment'] ?? '',
              servicestatus: caretakerData['servicestatus'] ?? '',
              accountstatus: caretakerData['accountstatus'] ?? '',
              latitude: (caretakerData['latitude'] ?? 0).toDouble(),
              longitude: (caretakerData['longitude'] ?? 0).toDouble(),
              
              // 🔐 3. ผูกข้อมูลล็อกอินหลักเข้ามาด้วย
              login: LoginModel(
                username: userData['username'] ?? '',
                password: userData['password'] ?? '',
                usertype: userData['usertype'] ?? '',
              ),
              // ผูกข้อมูลรถและเอกสารเข้าก้อน Model หลัก
              vehicle: vehicle,
              documents: documents,
            ),
          );
        });

        return caretakers;
      } catch (e) {
        print('Error fetching caretakers: $e');
        return [];
      }
    }

  Future<String>  getAdminName(String uid) async {
      try {
          // 1. ดึงข้อมูล
          final snapshot = await _dbRef.child('Login').child(uid).get();

          // 2. เช็กก่อนว่ามีข้อมูลจริงๆ ไหม
          if (snapshot.exists && snapshot.value != null) {
            Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
            
            // 3. ป้องกันกรณีไม่มี key 'username' ให้ส่งค่า default กลับไปแทน
            return data['username']?.toString() ?? 'unknow'; 
          } else {
            return 'ไม่พบผู้ใช้ในระบบ'; // กรณีหา uid ไม่เจอ
          }
          
        } catch (e) {
          // 4. ดักจับ Error เผื่อเน็ตหลุด หรือดึงข้อมูลพลาด
          print("Error getting admin name: $e");
          return 'เกิดข้อผิดพลาด'; 
        }
  }

  Future<void> approveCaretaker(String caretakerId) async {
    await _dbRef.child('Login').child(caretakerId).child('Caretaker').update({
      'accountstatus': 'Approved',
    });
  }

  Future<void> suspendCaretaker(String caretakerId) async {
    await _dbRef.child('Login').child(caretakerId).child('Caretaker').update({
      'accountstatus': 'Suspended', // หรืออาจจะใช้ 'Rejected' ตามโครงสร้าง DB ของคุณ
    });
  }

  // ไม่อนุมัติผู้ดูแล (เปลี่ยนเป็น Failed และเก็บเหตุผล)
  Future<void> rejectCaretaker(String caretakerId, String reason) async {
    await _dbRef.child('Login').child(caretakerId).child('Caretaker').update({
      'accountstatus': 'Failed', 
      'admincomment': reason, // เก็บหมายเหตุว่าทำไมถึงไม่อนุมัติ
    });
  }


}