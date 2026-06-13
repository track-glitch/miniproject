import 'package:miniproject/models/login_model.dart';
import 'package:miniproject/models/vehicle_model.dart';
import 'package:miniproject/models/document_model.dart';
import 'package:miniproject/models/request_model.dart';

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
  String? address;
  String? admincomment;
  String? servicestatus;
  String? accountstatus;
  double? latitude;
  double? longitude;

  // ความสัมพันธ์
  LoginModel? login;                   // 1 : 1
  VehicleModel? vehicle;               // 1 : 1
  List<DocumentModel>? documents;      // 1 : 1..n
  List<RequestModel>? requests;        // 1 : 1..n

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
    this.address,
    this.admincomment,
    this.servicestatus,
    this.accountstatus,
    this.latitude,
    this.longitude,
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
      address: json['address'],
      admincomment: json['admincomment'],
      servicestatus: json['servicestatus'],
      accountstatus: json['accountstatus'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      login: json['login'] != null ? LoginModel.fromJson(json['login']) : null,
      vehicle:
          json['vehicle'] != null ? VehicleModel.fromJson(json['vehicle']) : null,
      documents: json['documents'] != null
          ? (json['documents'] as List)
              .map((e) => DocumentModel.fromJson(e))
              .toList()
          : null,
      requests: json['requests'] != null
          ? (json['requests'] as List)
              .map((e) => RequestModel.fromJson(e))
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
      'address': address,
      'admincomment': admincomment,
      'servicestatus': servicestatus,
      'accountstatus': accountstatus,
      'latitude': latitude,
      'longitude': longitude,
      'login': login?.toJson(),
      'vehicle': vehicle?.toJson(),
      'documents': documents?.map((e) => e.toJson()).toList(),
      'requests': requests?.map((e) => e.toJson()).toList(),
    };
  }
}
