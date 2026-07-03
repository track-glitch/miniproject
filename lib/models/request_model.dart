import 'package:http/http.dart';
import 'package:miniproject/models/review_model.dart';
import 'package:miniproject/models/report_model.dart';
import 'package:miniproject/models/notification_model.dart';
import 'package:miniproject/models/doctor_advice_model.dart';
import 'package:miniproject/models/location_model.dart'; // 🌟 Import LocationModel เข้ามา

class RequestModel {
  String? requestId;
  String? requestdetail;

  // 🌟 เปลี่ยนมาใช้ LocationModel แทน String และ double แบบเดิม
  LocationModel? pickuplocation;
  LocationModel? dropofflocation;

  String? hospitalname;
  String? departmentname;
  DateTime? appointmentdate;
  DateTime? appointmenttime;
  DateTime? requestdate;
  String? requeststatus;
  String? caretakerId;

  // ความสัมพันธ์
  ReviewModel? review; // 1 : 1
  DoctorAdviceModel? doctoradvice; // 1 : 1
  ReportModel? report; // 1 : 1
  List<NotificationModel>? notifications; // 1 : 1..n

  RequestModel({
    this.requestId,
    this.requestdetail,
    this.pickuplocation,
    this.dropofflocation,
    this.hospitalname,
    this.departmentname,
    this.appointmentdate,
    this.appointmenttime,
    this.requestdate,
    this.requeststatus,
    this.caretakerId,
    this.review,
    this.doctoradvice,
    this.report,
    this.notifications,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      requestId: json['requestId'],
      requestdetail: json['requestdetail'],

      // 🌟 ดึงข้อมูล JSON ซ้อน JSON มาแปลงเป็น LocationModel
      pickuplocation: json['PickupLocation'] != null
          ? LocationModel.fromJson(
              Map<String, dynamic>.from(json['PickupLocation']),
            )
          : null,
      dropofflocation: json['DropoffLocation'] != null
          ? LocationModel.fromJson(
              Map<String, dynamic>.from(json['DropoffLocation']),
            )
          : null,

      hospitalname: json['hospitalname'],
      departmentname: json['departmentname'],
      appointmentdate: json['appointmentdate'] != null
          ? DateTime.parse(json['appointmentdate'])
          : null,
      appointmenttime: json['appointmenttime'] != null
          ? DateTime.parse(json['appointmenttime'])
          : null,
      requestdate: json['requestdate'] != null
          ? DateTime.parse(json['requestdate'])
          : null,
      requeststatus: json['requeststatus'],
      caretakerId: json['caretakerId'],
      review: json['Review'] != null
          ? ReviewModel.fromJson(Map<String, dynamic>.from(json['Review']))
          : null,
      doctoradvice: json['DoctorAdvice'] != null
          ? DoctorAdviceModel.fromJson(
              Map<String, dynamic>.from(json['DoctorAdvice']),
            )
          : null,
      report: json['Report'] != null
          ? ReportModel.fromJson(Map<String, dynamic>.from(json['Report']))
          : null,
      notifications: json['Notification'] != null
          ? (json['Notification'] as List)
                .map(
                  (e) =>
                      NotificationModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'requestdetail': requestdetail,

      // 🌟 สั่งให้ LocationModel แปลงตัวเองเป็น JSON
      'PickupLocation': pickuplocation?.toJson(),
      'DropoffLocation': dropofflocation?.toJson(),

      'hospitalname': hospitalname,
      'departmentname': departmentname,
      'appointmentdate': appointmentdate?.toIso8601String(),
      'appointmenttime': appointmenttime?.toIso8601String(),
      'requestdate': requestdate?.toIso8601String(),
      'requeststatus': requeststatus,
      'caretakerId': caretakerId,
      'Review': review?.toJson(),
      'DoctorAdvice': doctoradvice?.toJson(),
      'Report': report?.toJson(),
      'Notification': notifications?.map((e) => e.toJson()).toList(),
    };
  }
}
