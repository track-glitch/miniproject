import 'package:miniproject/models/vehicle_model.dart';
import 'package:miniproject/models/document_model.dart';
import 'package:miniproject/models/request_model.dart';
import 'package:miniproject/models/location_model.dart'; // 🌟 Import เข้ามา

class CaretakerModel {
  String? caretakerId;
  String? password;
  String? usertype;
  String? profilephoto;
  String? firstname;
  String? lastname;
  String? gender;
  DateTime? birthdate;
  String? phonenumber;
  String? email;
  String? experience;
  String? admincomment;
  String? servicestatus;
  String? accountstatus;

  LocationModel? location; // 🌟 แทนที่ address, latitude, longitude แบบเก่า

  VehicleModel? vehicle;
  List<DocumentModel>? documents;
  List<RequestModel>? requests;

  CaretakerModel({
    this.caretakerId,
    this.password,
    this.usertype,
    this.profilephoto,
    this.firstname,
    this.lastname,
    this.gender,
    this.birthdate,
    this.phonenumber,
    this.email,
    this.experience,
    this.admincomment,
    this.servicestatus,
    this.accountstatus,
    this.location, // 🌟
    this.vehicle,
    this.documents,
    this.requests,
  });

  factory CaretakerModel.fromJson(Map<String, dynamic> json) {
    return CaretakerModel(
      caretakerId: json['caretakerId'],
      password: json['password'],
      usertype: json['usertype'],
      profilephoto: json['profilephoto'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      gender: json['gender'],
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : null,
      phonenumber: json['phonenumber'],
      email: json['email'],
      experience: json['experience'],
      admincomment: json['admincomment'],
      servicestatus: json['servicestatus'],
      accountstatus: json['accountstatus'],

      // 🌟 ดึงข้อมูลจาก JSON แปลงเป็น Object LocationModel
      location: json['location'] != null
          ? LocationModel.fromJson(Map<String, dynamic>.from(json['location']))
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
      'password': password,
      'usertype': usertype,
      'profilephoto': profilephoto,
      'firstname': firstname,
      'lastname': lastname,
      'gender': gender,
      'birthdate': birthdate?.toIso8601String(),
      'phonenumber': phonenumber,
      'email': email,
      'experience': experience,
      'admincomment': admincomment,
      'servicestatus': servicestatus,
      'accountstatus': accountstatus,
      'Location': location?.toJson(), // 🌟 แปลง Location กลับเป็น JSON
      'Vehicle': vehicle?.toJson(),
      'Document': documents?.map((e) => e.toJson()).toList(),
      'Request': requests?.map((e) => e.toJson()).toList(),
    };
  }
}
