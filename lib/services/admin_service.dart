import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/request_model.dart';
import 'package:miniproject/models/vehicle_photo_model.dart';
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

  Future<void> seed10CaretakersCorrectPath() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('Login');

    final List<Map<String, dynamic>> rawCaretakers = [
      // คนที่ 1-5
      {
        'id': '1509901234501',
        'fname': 'สมชาย',
        'lname': 'ใจดี',
        'gender': 'ชาย',
        'dob': '1988-03-15T00:00:00.000',
        'phone': '0812345001',
        'email': 'somchai01@gmail.com',
        'exp': 'มีประสบการณ์ดูแลผู้สูงอายุและ อสม. ประจำตำบล 5 ปี',
        'address': 'ต.สุเทพ อ.เมืองเชียงใหม่ จ.เชียงใหม่ 50200',
        'lat': 18.7903,
        'lng': 98.9562,
        'vehicleType': 'รถเก๋ง',
        'brand': 'Toyota',
        'model': 'Yaris',
        'plate': 'กข 1234',
        'province': 'เชียงใหม่',
        'color': 'ขาว',
      },
      {
        'id': '1509901234502',
        'fname': 'วิภา',
        'lname': 'แสงทอง',
        'gender': 'หญิง',
        'dob': '1992-07-20T00:00:00.000',
        'phone': '0812345002',
        'email': 'wipha02@gmail.com',
        'exp': 'ผ่านการอบรมหลักสูตรการดูแลผู้ป่วยระยะประคับประคอง 70 ชม.',
        'address': 'ต.ช้างคลาน อ.เมืองเชียงใหม่ จ.เชียงใหม่ 50100',
        'lat': 18.7758,
        'lng': 99.0012,
        'vehicleType': 'รถอเนกประสงค์',
        'brand': 'Honda',
        'model': 'City',
        'plate': 'งข 5678',
        'province': 'เชียงใหม่',
        'color': 'บรอนซ์เงิน',
      },
      {
        'id': '1509901234503',
        'fname': 'อนันต์',
        'lname': 'รักสงบ',
        'gender': 'ชาย',
        'dob': '1985-11-04T00:00:00.000',
        'phone': '0812345003',
        'email': 'anan03@gmail.com',
        'exp': 'อดีตพนักงานขับรถพยาบาล มีใบประกาศนียบัตรปฐมพยาบาลเบื้องต้น',
        'address': 'ต.แม่เหียะ อ.เมืองเชียงใหม่ จ.เชียงใหม่ 50100',
        'lat': 18.7521,
        'lng': 98.9489,
        'vehicleType': 'รถอเนกประสงค์',
        'brand': 'Toyota',
        'model': 'Corolla Cross',
        'plate': 'ขค 9012',
        'province': 'เชียงใหม่',
        'color': 'เทาดำ',
      },
      {
        'id': '1509901234504',
        'fname': 'กัญญา',
        'lname': 'สุขเกษม',
        'gender': 'หญิง',
        'dob': '1990-01-25T00:00:00.000',
        'phone': '0812345004',
        'email': 'kanya04@gmail.com',
        'exp': 'ดูแลผู้สูงอายุติดบ้านมานานกว่า 4 ปี ชำนาญเส้นทาง รพ.สวนดอก',
        'address': 'ต.หนองป่าครั่ง อ.เมืองเชียงใหม่ จ.เชียงใหม่ 50000',
        'lat': 18.7942,
        'lng': 99.0276,
        'vehicleType': 'รถเก๋ง',
        'brand': 'Mazda',
        'model': 'Mazda 2',
        'plate': 'จข 3456',
        'province': 'เชียงใหม่',
        'color': 'แดง',
      },
      {
        'id': '1509901234505',
        'fname': 'ประเสริฐ',
        'lname': 'แก้วมณี',
        'gender': 'ชาย',
        'dob': '1980-05-18T00:00:00.000',
        'phone': '0812345005',
        'email': 'prasert05@gmail.com',
        'exp': 'เคยทำงานศูนย์ดูแลผู้สูงอายุ มีทักษะพยุงตัวและวัดความดัน',
        'address': 'ต.ฟ้าฮ่าม อ.เมืองเชียงใหม่ จ.เชียงใหม่ 50000',
        'lat': 18.8154,
        'lng': 99.0089,
        'vehicleType': 'รถเก๋ง',
        'brand': 'Nissan',
        'model': 'Almera',
        'plate': 'ฉข 7890',
        'province': 'เชียงใหม่',
        'color': 'ขาว',
      },
      // คนที่ 6-10
      {
        'id': '1509901234506',
        'fname': 'นฤมล',
        'lname': 'พงษ์พาณิช',
        'gender': 'หญิง',
        'dob': '1995-09-12T00:00:00.000',
        'phone': '0812345006',
        'email': 'narumon06@gmail.com',
        'exp': 'ผู้ช่วยพยาบาล (PN) ประสบการณ์ 3 ปี มีความรู้เรื่องจัดยา',
        'address': 'ต.ป่าแดด อ.เมืองเชียงใหม่ จ.เชียงใหม่ 50100',
        'lat': 18.7582,
        'lng': 98.9873,
        'vehicleType': 'รถเก๋ง',
        'brand': 'Honda',
        'model': 'Jazz',
        'plate': 'ชข 2345',
        'province': 'เชียงใหม่',
        'color': 'น้ำเงิน',
      },
      {
        'id': '1509901234507',
        'fname': 'ธนากร',
        'lname': 'จิตรดี',
        'gender': 'ชาย',
        'dob': '1987-12-30T00:00:00.000',
        'phone': '0812345007',
        'email': 'thanakorn07@gmail.com',
        'exp': 'จิตอาสาพาผู้ป่วยล้างไต 3 ปี ชำนาญโรงพยาบาลนครพิงค์',
        'address': 'ต.ดอนแก้ว อ.แม่ริม จ.เชียงใหม่ 50180',
        'lat': 18.8687,
        'lng': 98.9664,
        'vehicleType': 'รถอเนกประสงค์',
        'brand': 'Isuzu',
        'model': 'MU-X',
        'plate': 'ซข 6789',
        'province': 'เชียงใหม่',
        'color': 'ดำ',
      },
      {
        'id': '1509901234508',
        'fname': 'วรรณา',
        'lname': 'ศรีสะอาด',
        'gender': 'หญิง',
        'dob': '1983-04-08T00:00:00.000',
        'phone': '0812345008',
        'email': 'wanna08@gmail.com',
        'exp': 'อสม. ดีเด่นระดับตำบล ให้บริการพาผู้ป่วยรับยาเป็นประจำ',
        'address': 'ต.ริมใต้ อ.แม่ริม จ.เชียงใหม่ 50180',
        'lat': 18.9142,
        'lng': 98.9451,
        'vehicleType': 'รถเก๋ง',
        'brand': 'Toyota',
        'model': 'Vios',
        'plate': 'ฌข 0123',
        'province': 'เชียงใหม่',
        'color': 'บรอนซ์ทอง',
      },
      {
        'id': '1509901234509',
        'fname': 'พิชัย',
        'lname': 'มั่นคง',
        'gender': 'ชาย',
        'dob': '1979-08-22T00:00:00.000',
        'phone': '0812345009',
        'email': 'pichai09@gmail.com',
        'exp': 'ขับรถรับส่งผู้ป่วยเอกชน 6 ปี ไม่มีประวัติอุบัติเหตุ',
        'address': 'ต.สันทรายน้อย อ.สันทราย จ.เชียงใหม่ 50210',
        'lat': 18.8256,
        'lng': 99.0432,
        'vehicleType': 'รถอเนกประสงค์',
        'brand': 'Mitsubishi',
        'model': 'Xpander',
        'plate': 'ญข 4567',
        'province': 'เชียงใหม่',
        'color': 'ขาว',
      },
      {
        'id': '1509901234510',
        'fname': 'ศิริพร',
        'lname': 'บุญมี',
        'gender': 'หญิง',
        'dob': '1991-06-17T00:00:00.000',
        'phone': '0812345010',
        'email': 'siriporn10@gmail.com',
        'exp': 'บริบาลผู้ป่วยพักฟื้น 4 ปี เข้าใจสภาพจิตใจผู้สูงอายุ',
        'address': 'ต.หนองหาร อ.สันทราย จ.เชียงใหม่ 50290',
        'lat': 18.8921,
        'lng': 99.0145,
        'vehicleType': 'รถเก๋ง',
        'brand': 'Suzuki',
        'model': 'Swift',
        'plate': 'ฎข 8901',
        'province': 'เชียงใหม่',
        'color': 'บรอนซ์เงิน',
      },
    ];

    for (var item in rawCaretakers) {
      String cId = item['id'];
      String email = item['email'];
      String password = 'password123';
      String authUid = '';

      // 1. สร้างบัญชีใน Firebase Authentication
      try {
        UserCredential cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        authUid = cred.user!.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          try {
            UserCredential existingCred = await auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            authUid = existingCred.user!.uid;
          } catch (_) {}
        }
      } catch (e) {
        print('Auth error for $cId: $e');
      }

      // 2. จัดเตรียม Location Model
      LocationModel location = LocationModel(
        address: item['address'],
        latitude: item['lat'],
        longitude: item['lng'],
      );

      // 3. จัดเตรียม Vehicle Photos (3 มุมตามหน้า Register)
      List<VehiclePhotoModel> vehiclePhotos = [
        VehiclePhotoModel(vehiclephotoid: 'exterior_photo', photo: ''),
        VehiclePhotoModel(vehiclephotoid: 'interior_photo', photo: ''),
        VehiclePhotoModel(vehiclephotoid: 'storage_photo', photo: ''),
      ];

      // 4. จัดเตรียม Vehicle Model
      VehicleModel vehicle = VehicleModel(
        vehicleId: item['plate'],
        vehicletype: item['vehicleType'],
        brand: item['brand'],
        model: item['model'],
        licenseplate: item['plate'],
        province: item['province'],
        color: item['color'],
        vehiclephotos: vehiclePhotos,
      );

      // 5. จัดเตรียม Document Model (เอกสารบังคับ 5 รายการตามหน้า Register)
      List<DocumentModel> documentsList = [
        DocumentModel(
          documentId: 'doc_idcard',
          documenttype: 'สำเนาบัตรประชาชน',
          filepath: '',
          uploaddate: DateTime.now(),
        ),
        DocumentModel(
          documentId: 'doc_driver_license',
          documenttype: 'สำเนาใบขับขี่',
          filepath: '',
          uploaddate: DateTime.now(),
        ),
        DocumentModel(
          documentId: 'doc_vehicle_reg',
          documenttype: 'สำเนาทะเบียนรถ',
          filepath: '',
          uploaddate: DateTime.now(),
        ),
        DocumentModel(
          documentId: 'doc_insurance',
          documenttype: 'สำเนาประกันภัยรถยนต์',
          filepath: '',
          uploaddate: DateTime.now(),
        ),
        DocumentModel(
          documentId: 'doc_resume',
          documenttype: 'ประวัติการทำงาน (Resume)',
          filepath: '',
          uploaddate: DateTime.now(),
        ),
      ];

      // 6. ประกอบร่าง Caretaker Model
      CaretakerModel caretaker = CaretakerModel(
        caretakerId: cId,
        password: password,
        usertype: 'caretaker',
        profilephoto: '',
        firstname: item['fname'],
        lastname: item['lname'],
        gender: item['gender'],
        birthdate: DateTime.parse(item['dob']),
        phonenumber: item['phone'],
        email: email,
        experience: item['exp'],
        servicestatus: 'พร้อมให้บริการ',
        accountstatus: 'Approved',
        admincomment: 'ตรวจสอบข้อมูลผ่านเรียบร้อยแล้ว',
        location: location,
        vehicle: vehicle,
        documents: documentsList,
      );

      String targetKey = authUid.isNotEmpty ? authUid : cId;

      // 🌟 7. บันทึกลง Realtime Database (โครงสร้างตรงกับ _dbRef.child('Login').child(uid).set({'Caretaker': caretaker.toJson()}); เป๊ะๆ)
      await dbRef.child(targetKey).set({'Caretaker': caretaker.toJson()});
    }

    await auth.signOut();
    print(
      'สร้างข้อมูล Mockup Caretaker รวม 10 คน (โครงสร้างตรงกับระบบแล้ว) สำเร็จเรียบร้อย!',
    );
  }

  Future<void> seed4RelativesCorrectPath() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('Login');

    final List<Map<String, dynamic>> rawRelatives = [
      {
        'patIdCard': '1509909876001',
        'patFname': 'สมศรี',
        'patLname': 'แซ่ตั้ง',
        'patGender': 'หญิง',
        'patDob': '1952-04-12T00:00:00.000',
        'patPhone': '0861113301',
        'patLineId': 'somsri_pt',
        'disease': 'เบาหวาน, ความดันโลหิตสูง',
        'mobility': 'ไม่ปกติ: ใช้วีลแชร์ (ต้องการความช่วยเหลือในการพยุง)',
        'address': 'ต.สุเทพ อ.เมืองเชียงใหม่ จ.เชียงใหม่ 50200',
        'lat': 18.7915,
        'lng': 98.9610,
        'relFname': 'กิตติศักดิ์',
        'relLname': 'แซ่ตั้ง',
        'relPhone': '0891112201',
        'relEmail': 'kittisak_rel01@gmail.com',
        'relLineId': 'kittisak_line',
        'relationship': 'บุตร',
      },
      {
        'patIdCard': '1509909876002',
        'patFname': 'ประสิทธิ์',
        'patLname': 'สุขสำราญ',
        'patGender': 'ชาย',
        'patDob': '1948-08-25T00:00:00.000',
        'patPhone': '0861113302',
        'patLineId': '',
        'disease': 'โรคไตเรื้อรัง (นัดฟอกไตเป็นประจำ)',
        'mobility': 'ไม่ปกติ: เดินได้ช้า มีไม้เท้าช่วยพยุง',
        'address': 'ต.ช้างเผือก อ.เมืองเชียงใหม่ จ.เชียงใหม่ 50300',
        'lat': 18.8072,
        'lng': 98.9723,
        'relFname': 'พิมพา',
        'relLname': 'สุขสำราญ',
        'relPhone': '0891112202',
        'relEmail': 'pimpa_rel02@gmail.com',
        'relLineId': 'pimpa_s',
        'relationship': 'หลาน',
      },
      {
        'patIdCard': '1509909876003',
        'patFname': 'สายใจ',
        'patLname': 'เจริญพงศ์',
        'patGender': 'หญิง',
        'patDob': '1955-12-03T00:00:00.000',
        'patPhone': '0861113303',
        'patLineId': 'saijai_c',
        'disease': 'ไม่มีโรคประจำตัว',
        'mobility': 'ปกติ',
        'address': 'ต.ฟ้าฮ่าม อ.เมืองเชียงใหม่ จ.เชียงใหม่ 50000',
        'lat': 18.8124,
        'lng': 99.0112,
        'relFname': 'วรเมธ',
        'relLname': 'เจริญพงศ์',
        'relPhone': '0891112203',
        'relEmail': 'worameth_rel03@gmail.com',
        'relLineId': 'worameth_c',
        'relationship': 'บุตร',
      },
      {
        'patIdCard': '1509909876004',
        'patFname': 'บุญเลิศ',
        'patLname': 'ตันติเวช',
        'patGender': 'ชาย',
        'patDob': '1946-02-18T00:00:00.000',
        'patPhone': '0861113304',
        'patLineId': '',
        'disease': 'พาร์กินสัน',
        'mobility': 'ไม่ปกติ: ต้องมีคนช่วยประคองเดินตลอดเวลา',
        'address': 'ต.หนองหอย อ.เมืองเชียงใหม่ จ.เชียงใหม่ 50000',
        'lat': 18.7610,
        'lng': 99.0065,
        'relFname': 'ศิรินทิพย์',
        'relLname': 'ตันติเวช',
        'relPhone': '0891112204',
        'relEmail': 'sirinthip_rel04@gmail.com',
        'relLineId': 'siri_tanti',
        'relationship': 'คู่สมรส',
      },
    ];

    for (var item in rawRelatives) {
      String idCard =
          item['patIdCard']; // ใช้เลขบัตรผู้ป่วยเป็น ID หลักตามหน้าสมัคร
      String email = item['relEmail'];
      String password = 'password123';
      String authUid = '';

      // 1. สร้างบัญชีใน Firebase Auth สำหรับญาติ
      try {
        UserCredential cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        authUid = cred.user!.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          try {
            UserCredential existingCred = await auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            authUid = existingCred.user!.uid;
          } catch (_) {}
        }
      } catch (e) {
        print('Auth error for $idCard: $e');
      }

      // 2. จัดเตรียม Location Model ของผู้ป่วย
      LocationModel location = LocationModel(
        address: item['address'],
        latitude: item['lat'],
        longitude: item['lng'],
      );

      // 3. จัดเตรียม Patient Model
      PatientModel patient = PatientModel(
        patientId: idCard,
        patientphoto: '', // Base64 ว่างจำลองรูปโปรไฟล์
        firstname: item['patFname'],
        lastname: item['patLname'],
        phonenumber: item['patPhone'],
        gender: item['patGender'],
        birthdate: DateTime.parse(item['patDob']),
        disease: item['disease'],
        mobility:
            item['mobility'], // รับคำว่า 'ปกติ' หรือ 'ไม่ปกติ: ...' เข้ามาเลย
        location: location,
      );

      // 4. จัดเตรียม Relative Model
      RelativeModel relative = RelativeModel(
        relativeId: idCard,
        password: password,
        usertype: 'relative',
        firstname: item['relFname'],
        lastname: item['relLname'],
        email: email,
        phonenumber: item['relPhone'],
        lineId: item['relLineId'],
        relationship: item['relationship'],
        patients: {
          patient.patientId ?? idCard: patient,
        },
      );

      String targetKey = authUid.isNotEmpty ? authUid : idCard;

      // 5. บันทึกลง Realtime Database (โครงสร้างตรงกับ _dbRef.child('Login').child(uid).set({'Relative': relative.toJson()}); เป๊ะๆ)
      await dbRef.child(targetKey).set({'Relative': relative.toJson()});
    }

    await auth.signOut();
    print('สร้างข้อมูล Mockup ญาติและผู้ป่วย 4 คน สำเร็จเรียบร้อย!');
  }
}
