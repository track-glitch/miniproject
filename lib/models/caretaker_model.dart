class CaretakerModel {
  final String caretakerId;
  final String profilephoto;
  final String firstname;
  final String lastname;
  final String gender;
  final DateTime birthdate;
  final String phonenumber;
  final String email;
  final String aboutme;
  final String equipmentdetails;
  final String address;
  final String admincomment;
  final String servicestatus;
  final String accountstatus;
  final double latitude;
  final double longitude;

  CaretakerModel({
    required this.caretakerId,
    required this.profilephoto,
    required this.firstname,
    required this.lastname,
    required this.gender,
    required this.birthdate,
    required this.phonenumber,
    required this.email,
    required this.aboutme,
    required this.equipmentdetails,
    required this.address,
    required this.admincomment,
    required this.servicestatus,
    required this.accountstatus,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'caretakerId': caretakerId,
      'profilephoto': profilephoto,
      'firstname': firstname,
      'lastname': lastname,
      'gender': gender,
      'birthdate': birthdate,
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
    };
  }
}