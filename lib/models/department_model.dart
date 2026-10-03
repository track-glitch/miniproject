import 'package:miniproject/models/hospital_model.dart'; // อย่าลืม Import HospitalModel เข้ามา

class DepartmentModel {
  String? departmentId;
  String? departmentname;
  HospitalModel? hospital; // 1 : 1..n

  DepartmentModel({this.departmentId, this.departmentname, this.hospital});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      departmentId: json['departmentId'],
      departmentname: json['departmentname'],
      hospital: json['Hospital'] != null
          ? HospitalModel.fromJson(Map<String, dynamic>.from(json['Hospital']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'departmentId': departmentId,
      'departmentname': departmentname,
      'Hospital': hospital?.toJson(),
    };
  }
}
