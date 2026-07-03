class LocationModel {
  String? locationId;
  String? address;
  double? latitude;
  double? longitude;

  LocationModel({this.locationId, this.address, this.latitude, this.longitude});

  // แปลงจาก JSON (Firebase) มาเป็น Object
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      locationId: json['locationId'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  // แปลงจาก Object เป็น JSON เพื่อส่งขึ้น Firebase
  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
