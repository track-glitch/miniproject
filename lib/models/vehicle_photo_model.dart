class VehiclePhotoModel {

  String? vehiclephotoid;
  String? photo;

  VehiclePhotoModel({
    this.vehiclephotoid,
    this.photo,
  });

  factory VehiclePhotoModel.fromJson(Map<String, dynamic> json) {
    return VehiclePhotoModel(
      vehiclephotoid: json['vehiclephotoid'],
      photo: json['photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehiclephotoid': vehiclephotoid,
      'photo': photo,
    };
  }
}
