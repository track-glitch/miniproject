import 'package:firebase_database/firebase_database.dart';
// --- เปลี่ยน Path ให้ตรงกับโฟลเดอร์ในโปรเจกต์ของคุณ ---
import '../models/caretaker_model.dart';
import '../models/vehicle_model.dart';
import '../models/document_model.dart';

class AdminService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // 🛠️ เปลี่ยนเป็นฟังก์ชันที่รับพารามิเตอร์ status 
  // เช่น 'Pending', 'Approved', หรือ 'Suspended'
  Future<List<CaretakerModel>> getCaretakersByStatus(String status) async {
    try {
      final snapshot = await _dbRef.child('Login').get();

      if (!snapshot.exists) return [];

      List<CaretakerModel> caretakers = [];
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

      for (var entry in data.entries) {
        final userData = Map<dynamic, dynamic>.from(entry.value);

        if (userData['Caretaker'] == null) continue;

        final caretakerData = Map<dynamic, dynamic>.from(userData['Caretaker']);
        // กรองเอาเฉพาะ accountstatus ที่ตรงกับแท็บที่เลือก
        if (caretakerData['accountstatus'] != status) continue;

        caretakers.add(
          CaretakerModel(
            caretakerId: caretakerData['caretakerId'] ?? '',
            profilephoto: caretakerData['profilephoto'] ?? '',
            firstname: caretakerData['firstname'] ?? '',
            lastname: caretakerData['lastname'] ?? '',
            gender: caretakerData['gender'] ?? '',
            birthdate: DateTime.parse(caretakerData['birthdate']),
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
          ),
        );
      }
      return caretakers;
    } catch (e) {
      print('Error fetching caretakers: $e');
      return [];
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
}