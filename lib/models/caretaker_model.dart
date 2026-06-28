import 'package:miniproject/models/login_model.dart';
import 'package:miniproject/models/vehicle_model.dart';
import 'package:miniproject/models/document_model.dart';
import 'package:miniproject/models/request_model.dart';
import 'package:miniproject/models/location_model.dart'; // 🌟 Import เข้ามา

class CaretakerModel {
  String? caretakerId;
  String? profilephoto;
  String? firstname;
  String? lastname;
  String? gender;
  DateTime? birthdate;
  String? phonenumber;
  String? email;
  String? aboutme;
  String? equipmentdetails;
  String? admincomment;
  String? servicestatus;
  String? accountstatus;

  LocationModel? location; // 🌟 แทนที่ address, latitude, longitude แบบเก่า

  // ความสัมพันธ์
  LoginModel? login;
  VehicleModel? vehicle;
  List<DocumentModel>? documents;
  List<RequestModel>? requests;

  CaretakerModel({
    this.caretakerId,
    this.profilephoto,
    this.firstname,
    this.lastname,
    this.gender,
    this.birthdate,
    this.phonenumber,
    this.email,
    this.aboutme,
    this.equipmentdetails,
    this.admincomment,
    this.servicestatus,
    this.accountstatus,
    this.location, // 🌟
    this.login,
    this.vehicle,
    this.documents,
    this.requests,
  });

  factory CaretakerModel.fromJson(Map<String, dynamic> json) {
    return CaretakerModel(
      caretakerId: json['caretakerId'],
      profilephoto: json['profilephoto'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      gender: json['gender'],
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : null,
      phonenumber: json['phonenumber'],
      email: json['email'],
      aboutme: json['aboutme'],
      equipmentdetails: json['equipmentdetails'],
      admincomment: json['admincomment'],
      servicestatus: json['servicestatus'],
      accountstatus: json['accountstatus'],

      // 🌟 ดึงข้อมูลจาก JSON แปลงเป็น Object LocationModel
      location: json['location'] != null
          ? LocationModel.fromJson(Map<String, dynamic>.from(json['location']))
          : null,

      login: json['login'] != null
          ? LoginModel.fromJson(Map<String, dynamic>.from(json['login']))
          : null,
      vehicle: json['vehicle'] != null
          ? VehicleModel.fromJson(Map<String, dynamic>.from(json['vehicle']))
          : null,
      documents: json['documents'] != null
          ? (json['documents'] as List)
                .map(
                  (e) => DocumentModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : null,
      requests: json['requests'] != null
          ? (json['requests'] as List)
                .map((e) => RequestModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caretakerId': caretakerId,
      'profilephoto': profilephoto,
      'firstname': firstname,
      'lastname': lastname,
      'gender': gender,
      'birthdate': birthdate?.toIso8601String(),
      'phonenumber': phonenumber,
      'email': email,
      'aboutme': aboutme,
      'equipmentdetails': equipmentdetails,
      'admincomment': admincomment,
      'servicestatus': servicestatus,
      'accountstatus': accountstatus,
      'Location': location?.toJson(), // 🌟 แปลง Location กลับเป็น JSON
      'login': login?.toJson(),
      'vehicle': vehicle?.toJson(),
      'documents': documents?.map((e) => e.toJson()).toList(),
      'requests': requests?.map((e) => e.toJson()).toList(),
    };
  }
}
