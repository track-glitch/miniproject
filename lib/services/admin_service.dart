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
            // ... (ข้อมูลอื่นๆ)
            accountstatus: caretakerData['accountstatus'] ?? '',

            // 🌟 ดึงข้อมูล Location มาแปลง
            location: caretakerData['location'] != null
                ? LocationModel.fromJson(
                    Map<String, dynamic>.from(caretakerData['location']),
                  )
                : null,
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

  Future<void> addRequest() async {
    DateTime appointmentdate = DateTime.parse("2026-06-20T00:00:00.000");
    DateTime appointmenttime = DateTime.parse("2026-06-20T09:00:00.000");
    DateTime requestdate = DateTime.parse("2026-06-18T08:30:00.000");

    RequestModel req1 = RequestModel(
      requestId: "REQ-20260618-001",
      requestdetail: "พาผู้ป่วยไปตรวจสุขภาพประจำปี",
      // 🌟 ใช้ LocationModel แทน String และลบ latitude/longitude แบบเดิมออก
      pickuplocation: LocationModel(
        address: "123 หมู่ 4 ต.เมือง อ.เมือง จ.ลำปาง",
        latitude: 18.2881,
        longitude: 99.4921,
      ),
      dropofflocation: LocationModel(
        address: "โรงพยาบาลลำปาง",
        latitude: 18.2881, // สมมติพิกัดให้เหมือนจุดรับก่อนได้ครับ
        longitude: 99.4921,
      ),
      hospitalname: "โรงพยาบาลลำปาง",
      departmentname: "แผนกอายุรกรรม",
      appointmentdate: appointmentdate,
      appointmenttime: appointmenttime,
      requestdate: requestdate,
      requeststatus: "Pending",
      caretakerId: 'E7TZ3fTabuY8jEgzH81wDAE5LSS2',
      review: null,
      doctoradvice: null,
      report: null,
      notifications: null,
    );

    // ========================================================
    // Request 2: สถานะตอบรับแล้ว (Accepted) - ข้อมูลอัปเดตงานยังเป็น null
    // ========================================================
    DateTime req2AppointmentDate = DateTime.parse("2026-06-21T00:00:00.000");
    DateTime req2AppointmentTime = DateTime.parse("2026-06-21T13:00:00.000");
    DateTime req2RequestDate = DateTime.parse("2026-06-18T09:00:00.000");

    RequestModel req2 = RequestModel(
      requestId: "REQ-20260618-002",
      requestdetail: "รับยาตามนัดและพาทำกายภาพบำบัด",
      // 🌟 ใช้ LocationModel
      pickuplocation: LocationModel(
        address: "45/2 ซอยสุขสวัสดิ์ จ.ลำปาง",
        latitude: 18.2900,
        longitude: 99.5000,
      ),
      dropofflocation: LocationModel(
        address: "คลินิกกายภาพบำบัด",
        latitude: 18.2900,
        longitude: 99.5000,
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
    // Request 3: สถานะเสร็จสิ้นแบบทั่วไป (Completed) - มีคำแนะนำแพทย์และรีวิว (แต่ไม่มี Report)
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
      // 🌟 ใช้ LocationModel
      pickuplocation: LocationModel(
        address: "หมู่บ้านสวนสิริ จ.ลำปาง",
        latitude: 18.2800,
        longitude: 99.4800,
      ),
      dropofflocation: LocationModel(
        address: "โรงพยาบาลเขลางค์นคร-ราม",
        latitude: 18.2800,
        longitude: 99.4800,
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
      report: null, // ไม่มีข้อมูลการเขียนรายงาน
      notifications: null,
    );

    // ========================================================
    // Request 4: สถานะเสร็จสิ้นแบบมี Report (Completed) - มีครบทุกอย่าง
    // ========================================================
    DateTime req4AppointmentDate = DateTime.parse("2026-06-15T00:00:00.000");
    DateTime req4AppointmentTime = DateTime.parse("2026-06-15T08:00:00.000");
    DateTime req4RequestDate = DateTime.parse("2026-06-14T15:00:00.000");

    DateTime req4ReviewDate = DateTime.parse("2026-06-16T10:00:00.000");
    DateTime req4ReportDate = DateTime.parse("2026-06-15T20:30:00.000");

    RequestModel req4 = RequestModel(
      requestId: "REQ-20260618-004",
      requestdetail: "เฝ้าไข้ที่โรงพยาบาลและเช็ดตัวลดไข้",
      // 🌟 ใช้ LocationModel
      pickuplocation: LocationModel(
        address: "โรงพยาบาลลำปาง ตึกผู้ป่วยใน",
        latitude: 18.2881,
        longitude: 99.4921,
      ),
      dropofflocation: LocationModel(
        address: "โรงพยาบาลลำปาง ตึกผู้ป่วยใน",
        latitude: 18.2881,
        longitude: 99.4921,
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
        appointmentdate: null, // กรณีแพทย์ไม่ได้นัดหมายต่อ
        appointmenttime: null, // กรณีแพทย์ไม่ได้นัดหมายต่อ
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

    String? requestId = _dbRef
        .child('Login')
        .child('1666666666666')
        .child('Request')
        .push()
        .key;
    final snapshot = _dbRef
        .child('Login')
        .child('1666666666666')
        .child('Relative')
        .child('Request')
        .child(requestId!);
    snapshot.set(req3.toJson());
  }
}
