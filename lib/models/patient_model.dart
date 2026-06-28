import 'package:miniproject/models/location_model.dart'; // 🌟 อย่าลืม Import LocationModel

class PatientModel {
  String? patientId;
  String? patientphoto;
  String? firstname;
  String? lastname;
  String? phonenumber;
  String? gender;
  DateTime? birthdate;
  String? disease;
  String? mobility;

  LocationModel? location; // 🌟 แทนที่ address, latitude, longitude แบบเก่า

  PatientModel({
    this.patientId,
    this.patientphoto,
    this.firstname,
    this.lastname,
    this.phonenumber,
    this.gender,
    this.birthdate,
    this.disease,
    this.mobility,
    this.location, // 🌟
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      patientId: json['patientId'],
      patientphoto: json['patientphoto'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      phonenumber: json['phonenumber'],
      gender: json['gender'],
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : null,
      disease: json['disease'],
      mobility: json['mobility'],

      // 🌟 ดึงข้อมูลจาก JSON แปลงเป็น Object LocationModel
      location: json['location'] != null
          ? LocationModel.fromJson(Map<String, dynamic>.from(json['location']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientphoto': patientphoto,
      'firstname': firstname,
      'lastname': lastname,
      'phonenumber': phonenumber,
      'gender': gender,
      'birthdate': birthdate?.toIso8601String(),
      'disease': disease,
      'mobility': mobility,

      'location': location?.toJson(), // 🌟 แปลง Location กลับเป็น JSON
    };
  }
}
