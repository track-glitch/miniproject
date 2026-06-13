class VehiclePhotoModel {
  final String vehiclephotoid;
  final String
  photo; // เก็บเป็น String (มักจะเป็น URL รูปภาพที่ได้จาก Firebase Storage)

  VehiclePhotoModel({required this.vehiclephotoid, required this.photo});

  // ✨ แปลงข้อมูลให้เป็น Map สำหรับใช้ใน Firebase
  Map<String, dynamic> toMap() {
    return {'vehiclephotoid': vehiclephotoid, 'photo': photo};
  }

  // 🔄 แถมฟังก์ชันสำหรับแปลงกลับจาก Map (JSON) มาเป็นคลาสใน Flutter เผื่อเอาไว้ใช้ตอนดึงข้อมูลมาแสดงผลครับ
  factory VehiclePhotoModel.fromMap(Map<String, dynamic> map) {
    return VehiclePhotoModel(
      vehiclephotoid: map['vehiclephotoid'] ?? '',
      photo: map['photo'] ?? '',
    );
  }
}
