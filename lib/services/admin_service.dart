import 'package:firebase_database/firebase_database.dart';
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/request_model.dart';
import '../models/caretaker_model.dart';
import '../models/vehicle_model.dart';
import '../models/document_model.dart';
import '../models/review_model.dart';
import '../models/doctor_advice_model.dart';
import '../models/report_model.dart';
import '../models/relative_model.dart';
import '../models/location_model.dart';
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
          vehicle = VehicleModel.fromJson(
            caretakerData['Vehicle'] as Map<String, dynamic>,
          );
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
            password: caretakerData['password'] ?? '',
            usertype: caretakerData['usertype'] ?? '',
            profilephoto: caretakerData['profilephoto'] ?? '',
            firstname: caretakerData['firstname'] ?? '',
            lastname: caretakerData['lastname'] ?? '',
            gender: caretakerData['gender'] ?? '',
            birthdate: caretakerData['birthdate'] != null
                ? DateTime.parse(caretakerData['birthdate'])
                : null,
            phonenumber: caretakerData['phonenumber'] ?? '',
            email: caretakerData['email'] ?? '',
            experience: caretakerData['experience'] ?? '',
            admincomment: caretakerData['admincomment'] ?? '',
            servicestatus: caretakerData['servicestatus'] ?? '',
            accountstatus: caretakerData['accountstatus'] ?? '',

            // 🌟 ดึงข้อมูล Location มาแปลง
            location: caretakerData['Location'] != null
                ? LocationModel.fromJson(
                    Map<String, dynamic>.from(caretakerData['Location']),
                  )
                : null,

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

  Future<String?> _findUidByCaretakerId(String caretakerId) async {
    DatabaseEvent event = await _dbRef
        .child('Login')
        .orderByChild('Caretaker/caretakerId')
        .equalTo(caretakerId)
        .once();

    if (event.snapshot.exists) {
      Map<dynamic, dynamic> users =
          event.snapshot.value as Map<dynamic, dynamic>;
      return users.keys.first.toString(); // ได้ UID รหัสยาวๆ กลับไป
    }
    return null;
  }

  Future<String> getAdminName(String uid) async {
    try {
      final snapshot = await _dbRef.child('Login').child(uid).get();
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        return data['username']?.toString() ?? 'unknow';
      } else {
        return 'ไม่พบผู้ใช้ในระบบ';
      }
    } catch (e) {
      return 'เกิดข้อผิดพลาด';
    }
  }

  // =======================================================
  // 🌟 3. ฟังก์ชันอัปเดตสถานะ (ดัดแปลงให้หา UID ก่อนอัปเดต)
  // =======================================================
  Future<void> approveCaretaker(String caretakerId) async {
    String? uid = await _findUidByCaretakerId(
      caretakerId,
    ); // 🔎 ให้ลูกมือไปหา UID ให้
    if (uid != null) {
      await _dbRef.child('Login').child(uid).child('Caretaker').update({
        'accountstatus': 'Approved',
      });
    }
  }

  Future<void> suspendCaretaker(String caretakerId) async {
    String? uid = await _findUidByCaretakerId(
      caretakerId,
    ); // 🔎 ให้ลูกมือไปหา UID ให้
    if (uid != null) {
      await _dbRef.child('Login').child(uid).child('Caretaker').update({
        'accountstatus': 'Suspended',
      });
    }
  }

  Future<void> rejectCaretaker(String caretakerId, String reason) async {
    String? uid = await _findUidByCaretakerId(
      caretakerId,
    ); // 🔎 ให้ลูกมือไปหา UID ให้
    if (uid != null) {
      await _dbRef.child('Login').child(uid).child('Caretaker').update({
        'accountstatus': 'Rejected',
        'admincomment': reason,
      });
    }
  }

  // 🌟 ฟังก์ชันสร้างข้อมูลจำลองสำหรับญาติ (Mock Relative & Patient)
  Future<void> addMockRelative() async {
    String uid = "23yM1I0mQMOusy74CQsu4t6FaPs1"; // UID ที่คุณต้องการใช้งาน

    try {
      // 1. สร้างพิกัดจำลองด้วย LocationModel ให้ผู้ป่วย
      LocationModel patientLocation = LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "99/9 หมู่ 2 ต.บ่อแฮ้ว จ.ลำปาง", // ที่อยู่สมมติ
        latitude: 18.3001,
        longitude: 99.4800,
      );

      // 2. สร้างข้อมูลผู้ป่วย (PatientModel)
      PatientModel mockPatient = PatientModel(
        patientId: "1234567890123", // สมมติเลขบัตร ปชช. ผู้ป่วย
        patientphoto: "", // ปล่อยว่าง หรือใส่ Base64 รูปภาพ
        firstname: "สมหมาย",
        lastname: "ใจดี",
        phonenumber: "089-999-9999",
        gender: "ชาย",
        birthdate: DateTime.parse("1955-05-15T00:00:00.000"),
        disease: "ความดันโลหิตสูง, เบาหวาน",
        mobility: "เดินได้โดยใช้ไม้เท้า",
        location: patientLocation, // 🌟 ใช้ LocationModel ที่เพิ่งสร้าง
      );

      // 3. สร้างข้อมูลญาติ (RelativeModel)
      RelativeModel mockRelative = RelativeModel(
        relativeId: "1987654321098", // สมมติเลขบัตร ปชช. ญาติ
        firstname: "มารตี",
        lastname: "ใจดี",
        email: "maratee@example.com",
        phonenumber: "081-111-2222",
        lineId: "maratee_love",
        relationship: "บุตรสาว",
      );

      // ==========================================
      // 🌟 กระบวนการบันทึกลง Firebase Realtime Database
      // ==========================================

      // 1. บันทึกข้อมูลบัญชีหลัก (Login Node)
      await _dbRef.child('Login').child(uid).set({
        'username': 'relative_user',
        'password': 'password123',
        'usertype': 'relative',
      });

      // 2. บันทึกข้อมูลญาติ ไว้ใต้ UID
      await _dbRef
          .child('Login')
          .child(uid)
          .child('Relative')
          .set(mockRelative.toJson());

      // 3. บันทึกข้อมูลผู้ป่วย ไว้ใต้ Relative
      await _dbRef
          .child('Login')
          .child(uid)
          .child('Relative')
          .child('Patient')
          .set(mockPatient.toJson());

      print("✅ สร้างข้อมูลญาติและผู้ป่วยสำเร็จ! UID: $uid");
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดในการสร้างข้อมูลญาติ: $e");
    }
  }

  Future<void> addRequest() async {
    DateTime currentTime = DateTime.now();

    // ===============================================
    // 🌟 1. Mockup: สถานะ "อยู่ระหว่างรอ(ตอบรับ)" -> Pending
    // งานเพิ่งเด้งเข้ามา อาสายังไม่ได้กดตกลงหรือปฏิเสธ
    // ===============================================
    RequestModel reqPending = RequestModel(
      requestId:
          "REQ-PEND-${currentTime.millisecondsSinceEpoch.toString().substring(7)}",
      requestdetail: "พาผู้ป่วยไปทำกายภาพบำบัดและรอรับกลับ",
      pickuplocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "บ้านพัก ต.พระบาท จ.ลำปาง",
        latitude: 18.2750,
        longitude: 99.5050,
      ),
      dropofflocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "โรงพยาบาลเขลางค์นคร-ราม",
        latitude: 18.2865,
        longitude: 99.4855,
      ),
      hospitalname: "โรงพยาบาลเขลางค์นคร-ราม",
      departmentname: "แผนกเวชศาสตร์ฟื้นฟู",
      appointmentdate: currentTime.add(
        const Duration(days: 3),
      ), // นัดหมายในอีก 3 วันข้างหน้า
      appointmenttime: currentTime.add(const Duration(days: 3)),
      requestdate: currentTime, // ส่งคำขอวันนี้
      requeststatus: "Pending", // 🌟 สถานะ รอตอบรับ
      caretakerId: '1111111111119',
      isReadCaretaker: false, // ยังไม่ได้เปิดอ่าน (จุดแดงเด้ง)
    );

    // ===============================================
    // 🌟 2. Mockup: สถานะ "อยู่ระหว่างรอ(ถึงเวลานัด)" -> Accepted
    // อาสากดตอบรับแล้ว แต่วันนัดหมายยังมาไม่ถึง
    // ===============================================
    RequestModel reqAccepted = RequestModel(
      requestId:
          "REQ-WAIT-${currentTime.millisecondsSinceEpoch.toString().substring(7)}",
      requestdetail: "พาผู้ป่วยไปพบแพทย์เพื่อติดตามอาการเบาหวาน",
      pickuplocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "หมู่บ้านค่ายพระร่วง ต.หัวเวียง จ.ลำปาง",
        latitude: 18.2905,
        longitude: 99.5010,
      ),
      dropofflocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "โรงพยาบาลศูนย์ลำปาง",
        latitude: 18.2900,
        longitude: 99.5000,
      ),
      hospitalname: "โรงพยาบาลศูนย์ลำปาง",
      departmentname: "อายุรกรรม",
      appointmentdate: currentTime.add(
        const Duration(days: 1),
      ), // นัดหมายในวันพรุ่งนี้
      appointmenttime: currentTime.add(const Duration(days: 1)),
      requestdate: currentTime.subtract(
        const Duration(days: 1),
      ), // ส่งคำขอตั้งแต่เมื่อวาน
      requeststatus: "accepted", // 🌟 สถานะ ตอบรับแล้ว
      caretakerId: '1111111111119',
      isReadCaretaker: true, // เปิดอ่านรายละเอียดตอนกดรับงานไปแล้ว
    );

    // นำคำขอใส่ใน List เพื่อเตรียมส่งขึ้น Firebase
    List<RequestModel> allRequests = [reqPending, reqAccepted];

    // วนลูปบันทึกทีละตัว
    for (var req in allRequests) {
      await _dbRef
          .child('Login')
          .child(
            "23yM1I0mQMOusy74CQsu4t6FaPs1",
          ) // เปลี่ยน UID ญาติตามที่คุณใช้เทสต์[cite: 17]
          .child('Relative')
          .child('Request')
          .child(req.requestId!)
          .set(req.toJson());
    }
  }
}
