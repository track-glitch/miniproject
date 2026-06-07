class PatientModel {
  final String patientId;
  final String patientphoto;
  final String firstname;
  final String lastname;
  final String phonenumber;
  final String gender;
  final DateTime birthdate;
  final String disease;
  final String mobility;
  final String address;
  final double latitude;
  final double longitude;

  PatientModel({
    required this.patientId,
    required this.patientphoto,
    required this.firstname,
    required this.lastname,
    required this.phonenumber,
    required this.gender,
    required this.birthdate,
    required this.disease,
    required this.mobility,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  // ✨ แปลงข้อมูลในคลาสให้เป็น Map เพื่อใช้บันทึกลง Firebase Firestore
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientphoto': patientphoto,
      'firstname': firstname,
      'lastname': lastname,
      'phonenumber': phonenumber,
      'gender': gender,
      'birthdate': birthdate, // Firestore จัดการเป็น Timestamp ให้เองครับ
      'disease': disease,
      'mobility': mobility,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}