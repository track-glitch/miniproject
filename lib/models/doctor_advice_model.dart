class DoctorAdviceModel {
  final String doctoradviceId;
  final String doctorname;
  final String advicedetail;
  final String departmentname;
  final String hospitalname;
  final DateTime appointmentdate;
  final String appointmenttime;
  final String medicalphoto;

  DoctorAdviceModel({
    required this.doctoradviceId,
    required this.doctorname,
    required this.advicedetail,
    required this.departmentname,
    required this.hospitalname,
    required this.appointmentdate,
    required this.appointmenttime,
    required this.medicalphoto,
  });
  Map<String, dynamic> toMap() => {
    'doctoradviceId': doctoradviceId,
    'doctorname': doctorname,
    'advicedetail': advicedetail,
    'departmentname': departmentname,
    'hospitalname': hospitalname,
    'appointmentdate': appointmentdate.toIso8601String(),
    'appointmenttime': appointmenttime,
    'medicalphoto': medicalphoto,
  };
}
