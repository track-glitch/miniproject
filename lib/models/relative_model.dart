import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/request_model.dart';

class RelativeModel {
  String? relativeId;
  String? password;
  String? usertype;
  String? firstname;
  String? lastname;
  String? email;
  String? phonenumber;
  String? lineId;
  String? relationship;

  PatientModel? patient; // 1 : 1
  List<RequestModel>? requests; // 1 : 1..n

  RelativeModel({
    this.relativeId,
    this.password,
    this.usertype,
    this.firstname,
    this.lastname,
    this.email,
    this.phonenumber,
    this.lineId,
    this.relationship,
    this.patient,
    this.requests,
  });

  factory RelativeModel.fromJson(Map<String, dynamic> json) {
    return RelativeModel(
      relativeId: json['relativeId'],
      password: json['password'],
      usertype: json['usertype'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email'],
      phonenumber: json['phonenumber'],
      lineId: json['lineId'],
      relationship: json['relationship'],
      patient: json['patient'] != null
          ? PatientModel.fromJson(json['patient'])
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
      'relativeId': relativeId,
      'password': password,
      'usertype': usertype,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'phonenumber': phonenumber,
      'lineId': lineId,
      'relationship': relationship,
      'Patient': patient?.toJson(),
      'Request': requests?.map((e) => e.toJson()).toList(),
    };
  }
}
