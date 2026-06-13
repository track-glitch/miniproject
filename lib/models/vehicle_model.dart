import 'package:miniproject/models/vehicle_photo_model.dart';

class VehicleModel {
  String? vehicleId;
  String? vehicletype;
  String? brand;
  String? model;
  String? licenseplate;
  String? color;

  // ความสัมพันธ์ 1 : 1..n
  List<VehiclePhotoModel>? vehiclephotos;

  VehicleModel({
    this.vehicleId,
    this.vehicletype,
    this.brand,
    this.model,
    this.licenseplate,
    this.color,
    this.vehiclephotos,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      vehicleId: json['vehicleId'],
      vehicletype: json['vehicletype'],
      brand: json['brand'],
      model: json['model'],
      licenseplate: json['licenseplate'],
      color: json['color'],
      vehiclephotos: json['vehiclephotos'] != null
          ? (json['vehiclephotos'] as List)
              .map((e) => VehiclePhotoModel.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'vehicletype': vehicletype,
      'brand': brand,
      'model': model,
      'licenseplate': licenseplate,
      'color': color,
      'vehiclephotos': vehiclephotos?.map((e) => e.toJson()).toList(),
    };
  }
}
