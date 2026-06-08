class RequestModel {
  final String requestId;
  final String requestdetail;
  final String pickuplocation;
  final String dropoflocation;
  final String hospitalname;
  final String departmentname;
  final DateTime appointmentdate; // ใช้ DateTime แทน Date
  final String appointmenttime;   // เก็บเป็น String หรือใช้ TimeOfDay ก็ได้
  final DateTime requestdate;
  final String requeststatus;
  final double latitude;
  final double longitude;

  RequestModel({
    required this.requestId,
    required this.requestdetail,
    required this.pickuplocation,
    required this.dropoflocation,
    required this.hospitalname,
    required this.departmentname,
    required this.appointmentdate,
    required this.appointmenttime,
    required this.requestdate,
    required this.requeststatus,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'requestdetail': requestdetail,
      'pickuplocation': pickuplocation,
      'dropoflocation': dropoflocation,
      'hospitalname': hospitalname,
      'departmentname': departmentname,
      'appointmentdate': appointmentdate.toIso8601String(),
      'appointmenttime': appointmenttime,
      'requestdate': requestdate.toIso8601String(),
      'requeststatus': requeststatus,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}