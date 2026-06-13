class DoctorAdviceModel {
  String? doctoradviceId;
  String? doctorname;
  String? advicedetail;
  String? departmentname;
  String? hospitalname;
  DateTime? appointmentdate;
  DateTime? appointmenttime;
  String? medicalphoto;

  DoctorAdviceModel({
    this.doctoradviceId,
    this.doctorname,
    this.advicedetail,
    this.departmentname,
    this.hospitalname,
    this.appointmentdate,
    this.appointmenttime,
    this.medicalphoto,
  });

  factory DoctorAdviceModel.fromJson(Map<String, dynamic> json) {
    return DoctorAdviceModel(
      doctoradviceId: json['doctoradviceId'],
      doctorname: json['doctorname'],
      advicedetail: json['advicedetail'],
      departmentname: json['departmentname'],
      hospitalname: json['hospitalname'],
      appointmentdate: json['appointmentdate'] != null
          ? DateTime.parse(json['appointmentdate'])
          : null,
      appointmenttime: json['appointmenttime'] != null
          ? DateTime.parse(json['appointmenttime'])
          : null,
      medicalphoto: json['medicalphoto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctoradviceId': doctoradviceId,
      'doctorname': doctorname,
      'advicedetail': advicedetail,
      'departmentname': departmentname,
      'hospitalname': hospitalname,
      'appointmentdate': appointmentdate?.toIso8601String(),
      'appointmenttime': appointmenttime?.toIso8601String(),
      'medicalphoto': medicalphoto,
    };
  }
}
