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
  double? latitude;
  double? longitude;
  String? address;

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
    this.latitude,
    this.longitude,
      this.address,
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
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
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
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}
