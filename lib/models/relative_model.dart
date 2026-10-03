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

  Map<String, PatientModel>? patients; // 1 : 1..n
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
    this.patients,
    this.requests,
  });

  factory RelativeModel.fromJson(Map<String, dynamic> json) {
    Map<String, PatientModel>? parsedPatients;
    if (json['Patient'] != null || json['patients'] != null) {
      final patientsData = json['Patient'] ?? json['patients'];
      if (patientsData is Map) {
        parsedPatients = patientsData.map(
          (key, value) => MapEntry(
            key.toString(),
            PatientModel.fromJson(Map<String, dynamic>.from(value)),
          ),
        );
      }
    }

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
      patients: parsedPatients,
      requests: json['Request'] != null || json['requests'] != null
          ? ((json['Request'] ?? json['requests']) as dynamic)
              .values
              .map((e) => RequestModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
              .cast<RequestModel>()
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
      'Patient': patients?.map((key, val) => MapEntry(key, val.toJson())),
      'Request': requests?.map((e) => e.toJson()).toList(),
    };
  }
}