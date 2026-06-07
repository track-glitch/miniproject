class RelativeModel {
  final String relativeId;
  final String firstname;
  final String lastname;
  final String email;
  final String phonenumber;
  final String lineid;
  final String relationship;

  RelativeModel({
    required this.relativeId,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phonenumber,
    required this.lineid,
    required this.relationship,
  });

  // ✨ แปลงข้อมูลให้เป็น Map สำหรับส่งขึ้นคลาวด์
  Map<String, dynamic> toMap() {
    return {
      'relativeId': relativeId,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'phonenumber': phonenumber,
      'lineid': lineid,
      'relationship': relationship,
    };
  }
}