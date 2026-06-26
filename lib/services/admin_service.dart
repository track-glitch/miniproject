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
      pickuplocation: "123 หมู่ 4 ต.เมือง อ.เมือง จ.ลำปาง",
      dropofflocation: "โรงพยาบาลลำปาง",
      hospitalname: "โรงพยาบาลลำปาง",
      departmentname: "แผนกอายุรกรรม",
      appointmentdate: appointmentdate,
      appointmenttime: appointmenttime,
      requestdate: requestdate,
      requeststatus: "Pending",
      latitude: 18.2881,
      longitude: 99.4921,
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
      pickuplocation: "45/2 ซอยสุขสวัสดิ์ จ.ลำปาง",
      dropofflocation: "คลินิกกายภาพบำบัด",
      hospitalname: "โรงพยาบาลศูนย์",
      departmentname: "เวชศาสตร์ฟื้นฟู",
      appointmentdate: req2AppointmentDate,
      appointmenttime: req2AppointmentTime,
      requestdate: req2RequestDate,
      requeststatus: "Accepted",
      latitude: 18.2900,
      longitude: 99.5000,
      caretakerId: 'E7TZ3fTabuY8jEgzH81wDAE5LSS2',
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
      pickuplocation: "หมู่บ้านสวนสิริ จ.ลำปาง",
      dropofflocation: "โรงพยาบาลเขลางค์นคร-ราม",
      hospitalname: "โรงพยาบาลเขลางค์นคร-ราม",
      departmentname: "แผนกอายุรกรรม",
      appointmentdate: req3AppointmentDate,
      appointmenttime: req3AppointmentTime,
      requestdate: req3RequestDate,
      requeststatus: "Completed",
      latitude: 18.2800,
      longitude: 99.4800,
      caretakerId: 'E7TZ3fTabuY8jEgzH81wDAE5LSS2',
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
      pickuplocation: "โรงพยาบาลลำปาง ตึกผู้ป่วยใน",
      dropofflocation: "โรงพยาบาลลำปาง ตึกผู้ป่วยใน",
      hospitalname: "โรงพยาบาลลำปาง",
      departmentname: "กุมารเวชกรรม",
      appointmentdate: req4AppointmentDate,
      appointmenttime: req4AppointmentTime,
      requestdate: req4RequestDate,
      requeststatus: "Completed",
      latitude: 18.2881,
      longitude: 99.4921,
      caretakerId: 'E7TZ3fTabuY8jEgzH81wDAE5LSS2',
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
        .child('-OvPuEuRLVe0Iib5TZrC')
        .child('Request')
        .push()
        .key;
    final snapshot = _dbRef
        .child('Login')
        .child('-OvPuEuRLVe0Iib5TZrC')
        .child('Relative')
        .child('Request')
        .child(requestId!);
    snapshot.set(req3.toJson());
  }

  Future<void> addRelative() async {
    String loginId = _dbRef.child('Login').push().key!;
    String patientId = _dbRef.child('Login').child('Patient').push().key!;

    LoginModel login1 = LoginModel(
      username: 'itsci',
      password: 'itsme12345678',
      usertype: 'Relative',
    );

    DateTime patient2BirthDate = DateTime.parse(
      "2014-08-20T00:00:00.000",
    ); // อายุประมาณ 12 ปี

    PatientModel patient2 = PatientModel(
      patientId: patientId,
      patientphoto:
          "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",
      firstname: "ก้องเกียรติ",
      lastname: "พัฒนา",
      phonenumber: "082-222-2222",
      gender: "ชาย",
      birthdate: patient2BirthDate,
      disease: "ไข้เลือดออก",
      mobility: "เดินได้ปกติ (แต่อ่อนเพลีย)",
      latitude: 18.2881,
      longitude: 99.4921,
    );

    RelativeModel relative2 = RelativeModel(
      relativeId: loginId,
      firstname: "มารตี",
      lastname: "พัฒนา",
      email: "maratee.pat@email.com",
      phonenumber: "088-888-8888",
      lineId: "maratee_mom",
      relationship: "มารดา",
      login: null,
      patient: patient2, // 🌟 ผูกข้อมูลน้องก้องเกียรติเข้าไป
      requests:
          [], // 🌟 นำ req4 (สถานะ Completed มีรีพอร์ต) จากตัวอย่างที่แล้วมาใส่ใน List
    );

    await _dbRef.child('Login').child(loginId).set(login1.toJson());

    await _dbRef
        .child('Login')
        .child(loginId)
        .child('Relative')
        .set(relative2.toJson());
  }
}
