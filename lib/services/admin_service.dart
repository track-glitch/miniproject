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

      // 🌟 1. แปลงเป็น dynamic ก่อน เพื่อตรวจสอบประเภทข้อมูล
      final dynamic rawData = jsonDecode(jsonEncode(snapshot.value));
      Map<String, dynamic> data = {};

      // 🌟 2. ดักจับกรณี Firebase คืนค่าเป็น List หรือ Map
      if (rawData is List) {
        for (int i = 0; i < rawData.length; i++) {
          if (rawData[i] != null) {
            data[i.toString()] = rawData[i] as Map<String, dynamic>;
          }
        }
      } else if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      }

      List<CaretakerModel> caretakers = [];

      data.forEach((uid, userData) {
        // ข้ามถ้าไม่มีข้อมูล Caretaker
        if (userData == null || userData['Caretaker'] == null) return;

        final caretakerData = Map<String, dynamic>.from(userData['Caretaker']);

        // กรองเอาเฉพาะ accountstatus ที่ตรงกับแท็บที่เลือก
        if (caretakerData['accountstatus'] != status) return;

        // 🚗 1. ดึงข้อมูลยานพาหนะ (ถ้ามี)
        VehicleModel? vehicle;
        if (caretakerData['Vehicle'] != null) {
          vehicle = VehicleModel.fromJson(
            Map<String, dynamic>.from(caretakerData['Vehicle']),
          );
        }

        // 📂 2. ดึงข้อมูลรายการเอกสาร (ดัก List/Map ตรงนี้ด้วย เพราะเป็นจุดที่เกิดบั๊กบ่อย)
        List<DocumentModel>? documents;
        if (caretakerData['Document'] != null) {
          final docRaw = caretakerData['Document'];
          documents = [];

          if (docRaw is List) {
            for (var e in docRaw) {
              if (e != null) {
                documents.add(
                  DocumentModel.fromJson(Map<String, dynamic>.from(e)),
                );
              }
            }
          } else if (docRaw is Map) {
            docRaw.forEach((key, value) {
              if (value != null) {
                documents!.add(
                  DocumentModel.fromJson(Map<String, dynamic>.from(value)),
                );
              }
            });
          }
        }

        caretakers.add(
          CaretakerModel(
            caretakerId: caretakerData['caretakerId']?.toString() ?? '',
            password: caretakerData['password']?.toString() ?? '',
            usertype: caretakerData['usertype']?.toString() ?? '',
            profilephoto: caretakerData['profilephoto']?.toString() ?? '',
            firstname: caretakerData['firstname']?.toString() ?? '',
            lastname: caretakerData['lastname']?.toString() ?? '',
            gender: caretakerData['gender']?.toString() ?? '',
            birthdate: caretakerData['birthdate'] != null
                ? DateTime.tryParse(caretakerData['birthdate'].toString())
                : null,
            phonenumber: caretakerData['phonenumber']?.toString() ?? '',
            email: caretakerData['email']?.toString() ?? '',
            experience: caretakerData['experience']?.toString() ?? '',
            admincomment: caretakerData['admincomment']?.toString() ?? '',
            servicestatus: caretakerData['servicestatus']?.toString() ?? '',
            accountstatus: caretakerData['accountstatus']?.toString() ?? '',

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
      print('Error fetching caretakers: $e'); // ตรงนี้จะไม่ Error อีกต่อไป
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
        return data['Admin']['usertype']?.toString() ?? 'unknow';
      } else {
        return 'ไม่พบผู้ใช้ในระบบ';
      }
    } catch (e) {
      return 'เกิดข้อผิดพลาด';
    }
  }

  // =======================================================
  // 🌟 3. ฟังก์ชันอัปเดตสถานะ (แก้ไขให้บันทึกสถานะเอกสารรายใบ)
  // =======================================================
  Future<void> approveCaretaker(
    String caretakerId,
    List<DocumentModel> docs,
  ) async {
    String? uid = await _findUidByCaretakerId(caretakerId);
    if (uid != null) {
      // 1. อัปเดตสถานะบัญชีเป็น Approved
      await _dbRef.child('Login').child(uid).child('Caretaker').update({
        'accountstatus': 'Approved',
      });

      // 2. ปรับสถานะเอกสารทุกใบให้เป็น APPROVED (เพราะแอดมินให้ผ่านหมด)
      for (var doc in docs) {
        doc.status = 'APPROVED';
      }

      // 3. บันทึกรายการเอกสารกลับลง Firebase
      await _dbRef
          .child('Login')
          .child(uid)
          .child('Caretaker')
          .child('Document')
          .set(docs.map((e) => e.toJson()).toList());
    }
  }

  Future<void> suspendCaretaker(String caretakerId) async {
    String? uid = await _findUidByCaretakerId(caretakerId);
    if (uid != null) {
      await _dbRef.child('Login').child(uid).child('Caretaker').update({
        'accountstatus': 'Suspended',
      });
    }
  }

  // 🌟 รับ Parameter รูปแบบเอกสาร และ สถานะการติ๊ก (_documentStatuses) มาจากหน้า UI
  Future<void> rejectCaretaker(
    String caretakerId,
    String reason,
    List<DocumentModel> docs,
    Map<int, bool> docStatuses,
  ) async {
    String? uid = await _findUidByCaretakerId(caretakerId);
    if (uid != null) {
      // 1. อัปเดตสถานะบัญชีหลักเป็น Rejected พร้อมใส่ Comment
      await _dbRef.child('Login').child(uid).child('Caretaker').update({
        'accountstatus': 'Rejected',
        'admincomment': reason,
      });

      // 2. ปรับสถานะเอกสารแต่ละใบ ตามที่แอดมินติ๊ก ผ่าน/ไม่ผ่าน
      for (int i = 0; i < docs.length; i++) {
        bool isPassed =
            docStatuses[i] ?? false; // ถ้าดึงค่าไม่ได้ ถือว่าไม่ผ่านไว้ก่อน
        docs[i].status = isPassed ? 'APPROVED' : 'REJECTED';
      }

      // 3. บันทึกรายการเอกสารทับลงไปใหม่
      await _dbRef
          .child('Login')
          .child(uid)
          .child('Caretaker')
          .child('Document')
          .set(docs.map((e) => e.toJson()).toList());
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

  Future<void> addMockupRequestForRelative() async {
    DateTime currentTime = DateTime.now();

    // ===============================================
    // 🌟 1. ตั้งค่า UID ของญาติ และ ID ของอาสา
    // ===============================================

    // UID ของญาติจำลอง (เอาไอดีที่คุณใช้เทสต์มาใส่ได้เลย)
    String relativeUid = "3HFu0p120SU021mZ8nH6tYuYLtr2";

    // ⚠️ ต้องแก้เลขนี้ให้ตรงกับ "เลขบัตรประชาชน (caretakerId)" ของอาสาที่คุณกำลังล็อกอินอยู่นะครับ
    // ไม่งั้นระบบหน้า List จะหาไม่เจอเพราะมันแมตช์ ID ไม่ตรงกัน
    String myCaretakerId = "1234567891011";

    // ===============================================
    // 🌟 Mockup 1: สถานะ "อยู่ระหว่างรอ(ตอบรับ)" -> pending
    // งานเพิ่งเด้งเข้ามา อาสายังไม่ได้กดตกลงหรือปฏิเสธ
    // ===============================================
    // RequestModel reqPending = RequestModel(
    //   requestId:
    //       "REQ-PEND-${currentTime.millisecondsSinceEpoch.toString().substring(7)}",
    //   requestdetail: "พาผู้ป่วยไปทำกายภาพบำบัดและรอรับกลับ",
    //   pickuplocation: LocationModel(
    //     locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
    //     address: "บ้านพัก ต.พระบาท จ.ลำปาง",
    //     latitude: 18.2750,
    //     longitude: 99.5050,
    //   ),
    //   dropofflocation: LocationModel(
    //     locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
    //     address: "โรงพยาบาลเขลางค์นคร-ราม",
    //     latitude: 18.2865,
    //     longitude: 99.4855,
    //   ),
    //   hospitalname: "โรงพยาบาลเขลางค์นคร-ราม",
    //   departmentname: "แผนกเวชศาสตร์ฟื้นฟู",
    //   appointmentdate: currentTime.add(const Duration(days: 3)),
    //   appointmenttime: currentTime.add(const Duration(days: 3)),
    //   requestdate: currentTime,
    //   requeststatus: "pending", // 🌟 สถานะตัวพิมพ์เล็ก
    //   caretakerId: myCaretakerId, // 🌟 ผูกกับบัตร ปชช. อาสา
    //   isReadCaretaker: false,
    // );

    // ===============================================
    // 🌟 Mockup 2: สถานะ "อยู่ระหว่างรอ(ถึงเวลานัด)" -> accepted
    // อาสากดตอบรับแล้ว แต่วันนัดหมายยังมาไม่ถึง
    // ===============================================
    RequestModel reqAccepted = RequestModel(
      requestId:
          "REQ-WAIT-${currentTime.millisecondsSinceEpoch.toString().substring(7)}",
      requestdetail: "พาผู้ป่วยไปพบแพทย์เพื่อติดตามอาการเบาหวาน",
      pickuplocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "หมู่บ้านค่ายพระร่วง ต.หัวเวียง จ.ลำปาง",
        latitude: 18.2905,
        longitude: 99.5010,
      ),
      dropofflocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "โรงพยาบาลศูนย์ลำปาง",
        latitude: 18.2900,
        longitude: 99.5000,
      ),
      hospitalname: "โรงพยาบาลศูนย์ลำปาง",
      departmentname: "อายุรกรรม",
      appointmentdate: currentTime.add(const Duration(days: 1)),
      appointmenttime: currentTime.add(const Duration(days: 1)),
      requestdate: currentTime.subtract(const Duration(days: 1)),
      requeststatus: "accepted", // 🌟 สถานะตัวพิมพ์เล็ก
      caretakerId: myCaretakerId, // 🌟 ผูกกับบัตร ปชช. อาสา
      isReadCaretaker: true,
    );

    List<RequestModel> allRequests = [reqAccepted];

    // 🌟 2. วนลูปบันทึกเข้าโหนด Relative -> Request
    for (var req in allRequests) {
      await FirebaseDatabase.instance
          .ref()
          .child('Login')
          .child(relativeUid)
          .child('Relative')
          .child('Request')
          .child(req.requestId!)
          .set(req.toJson());
    }

    print("✅ เพิ่ม Mockup ข้อมูลลงโหนด Relative เสร็จเรียบร้อย!");
  }

  // ===============================================
  // 🌟 ฟังก์ชันสร้างข้อมูลจำลอง: สถานะเสร็จสิ้น (Completed)
  // แบบมี Review และ Doctor Advice ทั้งมีและไม่มีวันนัดหมายถัดไป
  // ===============================================
  Future<void> addMockupCompletedRequestForRelative() async {
    DateTime currentTime = DateTime.now();

    // UID ของญาติจำลอง และ ID ของอาสา (แก้ให้ตรงกับที่ใช้เทสต์)
    String relativeUid = "3HFu0p120SU021mZ8nH6tYuYLtr2";
    String myCaretakerId = "1234567891011";

    // ===============================================
    // 🌟 Mockup 1: สถานะ "เสร็จสิ้น" (completed)
    // มีรีวิว + มีคำแนะนำแพทย์แบบ "มีนัดหมายครั้งถัดไป"
    // ===============================================
    RequestModel reqCompletedWithAppt = RequestModel(
      requestId:
          "REQ-COMP1-${currentTime.millisecondsSinceEpoch.toString().substring(7)}",
      requestdetail: "พาผู้ป่วยไปตรวจตาและเบาหวาน",
      pickuplocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "บ้านพัก ต.พระบาท จ.ลำปาง",
        latitude: 18.2750,
        longitude: 99.5050,
      ),
      dropofflocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "โรงพยาบาลศูนย์ลำปาง",
        latitude: 18.2900,
        longitude: 99.5000,
      ),
      hospitalname: "โรงพยาบาลศูนย์ลำปาง",
      departmentname: "จักษุวิทยา",
      appointmentdate: currentTime.subtract(
        const Duration(days: 2),
      ), // นัดไปแล้วเมื่อ 2 วันก่อน
      appointmenttime: currentTime.subtract(const Duration(days: 2)),
      requestdate: currentTime.subtract(const Duration(days: 5)),
      requeststatus: "completed", // 🌟 สถานะเสร็จสิ้น
      caretakerId: myCaretakerId,
      isReadCaretaker: true,

      // 🌟 เพิ่มข้อมูล Review (คะแนนเต็ม 5)
      review: ReviewModel(
        reviewId: "REV-${FirebaseDatabase.instance.ref().push().key}",
        ratingscore: "5",
        comment:
            "ผู้ดูแลใจดีมากค่ะ พาไปถูกแผนกและช่วยจดคำแนะนำของหมอมาให้อย่างละเอียดเลย",
        reviewdate: currentTime.subtract(const Duration(days: 1)),
      ),

      // 🌟 เพิ่มข้อมูล Doctor Advice (มีนัดหมายครั้งถัดไป)
      doctoradvice: DoctorAdviceModel(
        doctoradviceId: "ADV-${FirebaseDatabase.instance.ref().push().key}",
        doctorname: "นพ. สมชาย ตาดี",
        advicedetail:
            "ความดันตาปกติ ให้หยอดยาแก้ตาแห้งทุก 4 ชั่วโมง ระวังอย่าให้ฝุ่นเข้าตา",
        departmentname: "จักษุวิทยา",
        hospitalname: "โรงพยาบาลศูนย์ลำปาง",
        appointmentdate: currentTime.add(
          const Duration(days: 30),
        ), // 📅 นัดอีกที 30 วันข้างหน้า
        appointmenttime: currentTime.add(const Duration(days: 30)),
        medicalphoto: "", // ปล่อยว่าง หรือใส่ Base64 ของรูปใบนัด
      ),
    );

    // ===============================================
    // 🌟 Mockup 2: สถานะ "เสร็จสิ้น" (completed)
    // มีรีวิว + มีคำแนะนำแพทย์แบบ "ไม่มีนัดหมายครั้งถัดไป"
    // ===============================================
    RequestModel reqCompletedNoAppt = RequestModel(
      requestId:
          "REQ-COMP2-${currentTime.millisecondsSinceEpoch.toString().substring(7)}",
      requestdetail: "พาผู้ป่วยไปทำแผลและตัดไหม",
      pickuplocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "บ้านพัก ต.พระบาท จ.ลำปาง",
        latitude: 18.2750,
        longitude: 99.5050,
      ),
      dropofflocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "คลินิกเวชกรรมเขลางค์",
        latitude: 18.2800,
        longitude: 99.4900,
      ),
      hospitalname: "คลินิกเวชกรรมเขลางค์",
      departmentname: "ศัลยกรรมทั่วไป",
      appointmentdate: currentTime.subtract(const Duration(days: 1)),
      appointmenttime: currentTime.subtract(const Duration(days: 1)),
      requestdate: currentTime.subtract(const Duration(days: 3)),
      requeststatus: "completed", // 🌟 สถานะเสร็จสิ้น
      caretakerId: myCaretakerId,
      isReadCaretaker: true,

      // 🌟 เพิ่มข้อมูล Review
      review: ReviewModel(
        reviewId: "REV-${FirebaseDatabase.instance.ref().push().key}",
        ratingscore: "4",
        comment: "บริการดีครับ ขับรถนิ่ม ตรงเวลา",
        reviewdate: currentTime,
      ),

      // 🌟 เพิ่มข้อมูล Doctor Advice (ไม่มีนัดหมาย)
      doctoradvice: DoctorAdviceModel(
        doctoradviceId: "ADV-${FirebaseDatabase.instance.ref().push().key}",
        doctorname: "พญ. สมหญิง แผลสวย",
        advicedetail:
            "แผลแห้งสนิทดี ตัดไหมเรียบร้อยแล้ว สามารถอาบน้ำโดนแผลได้ตามปกติ ไม่ต้องมาทำแผลแล้ว",
        departmentname: "ศัลยกรรมทั่วไป",
        hospitalname: "คลินิกเวชกรรมเขลางค์",
        appointmentdate: null, // ❌ ไม่มีนัดหมายครั้งถัดไปให้ส่งค่า null
        appointmenttime: null, // ❌ ไม่มีนัดหมายครั้งถัดไปให้ส่งค่า null
        medicalphoto: "",
      ),
    );

    List<RequestModel> allRequests = [reqCompletedWithAppt, reqCompletedNoAppt];

    // 🌟 วนลูปบันทึกเข้าโหนด Relative -> Request
    for (var req in allRequests) {
      await FirebaseDatabase.instance
          .ref()
          .child('Login')
          .child(relativeUid)
          .child('Relative')
          .child('Request')
          .child(req.requestId!)
          .set(req.toJson());
    }

    print(
      "✅ เพิ่ม Mockup งานที่เสร็จสิ้น (Completed) ลงโหนด Relative เสร็จเรียบร้อย!",
    );
  }

  Future<void> addMockupPendingRequestForRelative() async {
    DateTime currentTime = DateTime.now();

    // UID ของญาติจำลอง และ ID ของอาสา (แก้ให้ตรงกับที่ใช้เทสต์)
    String relativeUid = "3HFu0p120SU021mZ8nH6tYuYLtr2";
    String myCaretakerId = "1234567891011";

    // ===============================================
    // 🌟 Mockup 1: สถานะ "อยู่ระหว่างรอ" (pending)
    // งานนัดหมายล่วงหน้า 3 วัน
    // ===============================================
    RequestModel reqPending1 = RequestModel(
      requestId:
          "REQ-PEND1-${currentTime.millisecondsSinceEpoch.toString().substring(7)}",
      requestdetail: "พาผู้ป่วยไปตรวจสุขภาพประจำปี",
      pickuplocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "บ้านพัก ต.พระบาท จ.ลำปาง",
        latitude: 18.2750,
        longitude: 99.5050,
      ),
      dropofflocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "โรงพยาบาลศูนย์ลำปาง",
        latitude: 18.2900,
        longitude: 99.5000,
      ),
      hospitalname: "โรงพยาบาลศูนย์ลำปาง",
      departmentname: "แผนกตรวจสุขภาพ",
      appointmentdate: currentTime.add(
        const Duration(days: 3),
      ), // 📅 นัดหมายในอีก 3 วันข้างหน้า
      appointmenttime: currentTime.add(const Duration(days: 3)),
      requestdate: currentTime, // 📅 เพิ่งกดสร้างคำขอวันนี้
      requeststatus: "pending", // 🌟 สถานะอยู่ระหว่างรอ
      caretakerId: myCaretakerId,
      isReadCaretaker: false,
    );

    // ===============================================
    // 🌟 Mockup 2: สถานะ "อยู่ระหว่างรอ" (pending)
    // งานด่วน นัดหมายพรุ่งนี้
    // ===============================================
    RequestModel reqPending2 = RequestModel(
      requestId:
          "REQ-PEND2-${currentTime.millisecondsSinceEpoch.toString().substring(7)}",
      requestdetail: "พาไปทำกายภาพบำบัดต่อเนื่อง",
      pickuplocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "บ้านพัก ต.พระบาท จ.ลำปาง",
        latitude: 18.2750,
        longitude: 99.5050,
      ),
      dropofflocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "คลินิกกายภาพบำบัด",
        latitude: 18.2850,
        longitude: 99.4950,
      ),
      hospitalname: "คลินิกกายภาพบำบัด",
      departmentname: "กายภาพบำบัด",
      appointmentdate: currentTime.add(
        const Duration(days: 1),
      ), // 📅 นัดหมายพรุ่งนี้
      appointmenttime: currentTime.add(const Duration(days: 1)),
      requestdate: currentTime.subtract(
        const Duration(hours: 2),
      ), // 📅 สร้างคำขอเมื่อ 2 ชม. ที่แล้ว
      requeststatus: "pending",
      caretakerId: myCaretakerId,
      isReadCaretaker: false,
    );

    // ===============================================
    // 🌟 Mockup 3: สถานะ "อยู่ระหว่างรอ" (pending)
    // งานด่วน นัดหมายตอนนี้เลย (สำหรับใช้ทดสอบ)
    // ===============================================
    RequestModel reqPending3 = RequestModel(
      requestId:
          "REQ-PEND3-${currentTime.millisecondsSinceEpoch.toString().substring(7)}",
      requestdetail: "พาไปฟอกไต (งานถึงเวลาแล้ว)",
      pickuplocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "บ้านพัก ต.พระบาท จ.ลำปาง",
        latitude: 18.2750,
        longitude: 99.5050,
      ),
      dropofflocation: LocationModel(
        locationId: "LOC-${FirebaseDatabase.instance.ref().push().key}",
        address: "ศูนย์ฟอกไต โรงพยาบาลศูนย์ลำปาง",
        latitude: 18.2900,
        longitude: 99.5000,
      ),
      hospitalname: "โรงพยาบาลศูนย์ลำปาง",
      departmentname: "ศูนย์ฟอกไต",
      appointmentdate: currentTime, // 📅 นัดหมายตอนนี้เลย
      appointmenttime: currentTime, // 📅 นัดหมายตอนนี้เลย
      requestdate: currentTime.subtract(
        const Duration(hours: 1),
      ), // 📅 สร้างคำขอเมื่อ 1 ชม. ที่แล้ว
      requeststatus: "pending",
      caretakerId: myCaretakerId, // 🌟 รหัสของคุณ
      isReadCaretaker: false,
    );

    // 🌟 นำ reqPending3 ใส่เข้าไปใน List เพื่อบันทึกพร้อมกัน
    List<RequestModel> allPendingRequests = [
      reqPending1,
      reqPending2,
      reqPending3,
    ];

    // 🌟 วนลูปบันทึกเข้าโหนด Relative -> Request
    for (var req in allPendingRequests) {
      await FirebaseDatabase.instance
          .ref()
          .child('Login')
          .child(relativeUid)
          .child('Relative')
          .child('Request')
          .child(req.requestId!)
          .set(req.toJson());
    }

    print(
      "✅ เพิ่ม Mockup งานที่อยู่ระหว่างรอ (Pending) ทั้ง 3 งาน ลงโหนด Relative เสร็จเรียบร้อย!",
    );
  }
}
