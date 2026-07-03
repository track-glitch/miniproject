import 'package:firebase_database/firebase_database.dart';
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/request_model.dart';
import '../models/caretaker_model.dart';
import '../models/vehicle_model.dart';
import '../models/document_model.dart';
import '../models/login_model.dart';
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
            admincomment: caretakerData['admincomment'] ?? '',
            servicestatus: caretakerData['servicestatus'] ?? '',
            accountstatus: caretakerData['accountstatus'] ?? '',

            // 🌟 ดึงข้อมูล Location มาแปลง
            location: caretakerData['Location'] != null
                ? LocationModel.fromJson(
                    Map<String, dynamic>.from(caretakerData['Location']),
                  )
                : null,

            // 🔐 3. ผูกข้อมูลล็อกอิน (ใช้ username เป็น PK ตามที่คุณออกแบบไว้เลยครับ ไม่ต้องมี uid)
            login: LoginModel(
              username: userData['username'] ?? '',
              password: userData['password'] ?? '',
              usertype: userData['usertype'] ?? '',
            ),

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
    DateTime appointmentdate = DateTime.parse("2026-06-20T00:00:00.000");
    DateTime appointmenttime = DateTime.parse("2026-06-20T09:00:00.000");
    DateTime requestdate = DateTime.parse("2026-06-18T08:30:00.000");

    RequestModel req1 = RequestModel(
      requestId: "REQ-20260618-001",
      requestdetail: "พาผู้ป่วยไปตรวจสุขภาพประจำปี",
      // 🌟 จุดรับ (บ้านผู้ป่วย)
      pickuplocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "123 หมู่ 4 ต.พระบาท อ.เมือง จ.ลำปาง",
        latitude: 18.2744,
        longitude: 99.5100,
      ),
      // 🌟 จุดส่ง (โรงพยาบาล) - พิกัดคนละจุดกัน
      dropofflocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "โรงพยาบาลลำปาง",
        latitude: 18.2905,
        longitude: 99.5028,
      ),
      hospitalname: "โรงพยาบาลลำปาง",
      departmentname: "แผนกอายุรกรรม",
      appointmentdate: appointmentdate,
      appointmenttime: appointmenttime,
      requestdate: requestdate,
      requeststatus: "Pending",
      caretakerId: '1111111111119',
      review: null,
      doctoradvice: null,
      report: null,
      notifications: null,
    );

    // ========================================================
    // Request 2: สถานะตอบรับแล้ว (Accepted)
    // ========================================================
    DateTime req2AppointmentDate = DateTime.parse("2026-06-21T00:00:00.000");
    DateTime req2AppointmentTime = DateTime.parse("2026-06-21T13:00:00.000");
    DateTime req2RequestDate = DateTime.parse("2026-06-18T09:00:00.000");

    RequestModel req2 = RequestModel(
      requestId: "REQ-20260618-002",
      requestdetail: "รับยาตามนัดและพาทำกายภาพบำบัด",
      // 🌟 จุดรับ (บ้านผู้ป่วย)
      pickuplocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "45/2 ซอยสุขสวัสดิ์ ต.หัวเวียง จ.ลำปาง",
        latitude: 18.2912,
        longitude: 99.4900,
      ),
      // 🌟 จุดส่ง (คลินิก)
      dropofflocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "คลินิกกายภาพบำบัด",
        latitude: 18.2965,
        longitude: 99.5080,
      ),
      hospitalname: "โรงพยาบาลศูนย์",
      departmentname: "เวชศาสตร์ฟื้นฟู",
      appointmentdate: req2AppointmentDate,
      appointmenttime: req2AppointmentTime,
      requestdate: req2RequestDate,
      requeststatus: "Accepted",
      caretakerId: '1111111111119',
      review: null,
      doctoradvice: null,
      report: null,
      notifications: null,
    );

    // ========================================================
    // Request 3: สถานะเสร็จสิ้นแบบทั่วไป (Completed)
    // ========================================================
    DateTime req3AppointmentDate = DateTime.parse("2026-06-10T00:00:00.000");
    DateTime req3AppointmentTime = DateTime.parse("2026-06-10T08:00:00.000");
    DateTime req3RequestDate = DateTime.parse("2026-06-08T10:00:00.000");

    DateTime req3ReviewDate = DateTime.parse("2026-06-11T09:00:00.000");
    DateTime req3DocApptDate = DateTime.parse("2026-09-10T00:00:00.000");
    DateTime req3DocApptTime = DateTime.parse("2026-09-10T08:00:00.000");

    RequestModel req3 = RequestModel(
      requestId: "REQ-20260618-003",
      requestdetail: "พาผู้ป่วยเจาะเลือดและฟังผล",
      // 🌟 จุดรับ (บ้านผู้ป่วย)
      pickuplocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "หมู่บ้านสวนสิริ ต.พิชัย จ.ลำปาง",
        latitude: 18.3200,
        longitude: 99.5150,
      ),
      // 🌟 จุดส่ง (โรงพยาบาล)
      dropofflocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "โรงพยาบาลเขลางค์นคร-ราม",
        latitude: 18.2855,
        longitude: 99.4975,
      ),
      hospitalname: "โรงพยาบาลเขลางค์นคร-ราม",
      departmentname: "แผนกอายุรกรรม",
      appointmentdate: req3AppointmentDate,
      appointmenttime: req3AppointmentTime,
      requestdate: req3RequestDate,
      requeststatus: "Completed",
      caretakerId: '1111111111119',
      review: ReviewModel(
        reviewId: "REV-001",
        ratingscore: "5",
        comment: "บริการดีเยี่ยม ดูแลคุณพ่อดีมากครับ",
        reviewdate: req3ReviewDate,
      ),
      doctoradvice: DoctorAdviceModel(
        doctoradviceId: "DOC-001",
        doctorname: "นพ. สมเกียรติ ใจดี",
        advicedetail:
            "ผลเลือดปกติ แนะนำให้ลดอาหารเค็มและมัน นัดติดตามผลอีก 3 เดือน",
        departmentname: "อายุรกรรม",
        hospitalname: "โรงพยาบาลเขลางค์นคร-ราม",
        appointmentdate: req3DocApptDate,
        appointmenttime: req3DocApptTime,
        medicalphoto: "base64_or_image_name_here.jpg",
      ),
      report: null,
      notifications: null,
    );

    // ========================================================
    // Request 4: สถานะเสร็จสิ้นแบบมี Report (Completed)
    // ========================================================
    DateTime req4AppointmentDate = DateTime.parse("2026-06-15T00:00:00.000");
    DateTime req4AppointmentTime = DateTime.parse("2026-06-15T08:00:00.000");
    DateTime req4RequestDate = DateTime.parse("2026-06-14T15:00:00.000");

    DateTime req4ReviewDate = DateTime.parse("2026-06-16T10:00:00.000");
    DateTime req4ReportDate = DateTime.parse("2026-06-15T20:30:00.000");

    RequestModel req4 = RequestModel(
      requestId: "REQ-20260618-004",
      requestdetail: "ไปรับที่บ้านเพื่อเฝ้าไข้ที่โรงพยาบาล",
      // 🌟 จุดรับ (บ้านผู้ป่วย)
      pickuplocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "99/9 หมู่ 2 ต.บ่อแฮ้ว จ.ลำปาง",
        latitude: 18.3001,
        longitude: 99.4800,
      ),
      // 🌟 จุดส่ง (โรงพยาบาลตึกผู้ป่วยใน)
      dropofflocation: LocationModel(
        locationId: "LOC-${_dbRef.push().key}",
        address: "โรงพยาบาลลำปาง ตึกผู้ป่วยใน",
        latitude: 18.2905,
        longitude: 99.5028,
      ),
      hospitalname: "โรงพยาบาลลำปาง",
      departmentname: "กุมารเวชกรรม",
      appointmentdate: req4AppointmentDate,
      appointmenttime: req4AppointmentTime,
      requestdate: req4RequestDate,
      requeststatus: "Completed",
      caretakerId: '1111111111119',
      review: ReviewModel(
        reviewId: "REV-002",
        ratingscore: "4",
        comment: "น้องงอแงนิดหน่อย แต่คนดูแลใจเย็นมากค่ะ",
        reviewdate: req4ReviewDate,
      ),
      doctoradvice: DoctorAdviceModel(
        doctoradviceId: "DOC-002",
        doctorname: "พญ. สมศรี พัฒนา",
        advicedetail:
            "เฝ้าระวังไข้สูง ให้จิบน้ำเกลือแร่บ่อยๆ ถ้าไข้เกิน 38 ให้เช็ดตัวทันที",
        departmentname: "กุมารเวชกรรม",
        hospitalname: "โรงพยาบาลลำปาง",
        appointmentdate: null,
        appointmenttime: null,
        medicalphoto: null,
      ),
      report: ReportModel(
        reportId: "REP-001",
        reporttype: "เฝ้าไข้",
        reportdetail:
            "เช็ดตัวลดไข้ทุก 2 ชม. น้องทานข้าวได้ครึ่งชาม ขับถ่ายปกติ 1 ครั้ง อุณหภูมิ 37.5",
        reportphoto: "report_base64_or_image.jpg",
        reportdate: req4ReportDate,
      ),
      notifications: null,
    );

    List<RequestModel> allRequests = [req1, req2, req3, req4];

    // 2. วนลูปบันทึกทีละตัว
    for (var req in allRequests) {
      await _dbRef
          .child('Login')
          .child("23yM1I0mQMOusy74CQsu4t6FaPs1")
          .child('Relative')
          .child('Request')
          .child(req.requestId!) // ใช้รหัส REQ-... เป็นชื่อโฟลเดอร์เลย
          .set(req.toJson());
    }

    print(
      "✅ บันทึกข้อมูล Request จำลองทั้ง ${allRequests.length} รายการสำเร็จแล้ว!",
    );
  }
}
