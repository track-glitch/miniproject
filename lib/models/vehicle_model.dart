class VehicleModel {
  final String vehicleId;
  final String vehicletype;
  final String brand;
  final String model;
  final String licenseplate;
  final String color;
  final List<String>
  vehiclePhotos; // เก็บเป็น List เพื่อรองรับ Vehiclephoto (1..n) ในภาพ

  VehicleModel({
    required this.vehicleId,
    required this.vehicletype,
    required this.brand,
    required this.model,
    required this.licenseplate,
    required this.color,
    required this.vehiclePhotos,
  });

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'vehicletype': vehicletype,
      'brand': brand,
      'model': model,
      'licenseplate': licenseplate,
      'color': color,
      'vehiclePhotos': vehiclePhotos,
    };
  }
}
