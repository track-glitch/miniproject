class HospitalModel {
  String? hospitalId;
  String? hospitalname;
  double? latitude;
  double? longitude;

  HospitalModel({
    this.hospitalId,
    this.hospitalname,
    this.latitude,
    this.longitude,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      hospitalId: json['hospitalId'],
      hospitalname: json['hospitalname'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hospitalId': hospitalId,
      'hospitalname': hospitalname,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
