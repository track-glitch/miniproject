import 'package:http/http.dart';
import 'package:miniproject/models/department_model.dart';
import 'package:miniproject/models/review_model.dart';
import 'package:miniproject/models/report_model.dart';
import 'package:miniproject/models/notification_model.dart';
import 'package:miniproject/models/doctor_advice_model.dart';
import 'package:miniproject/models/location_model.dart'; // 🌟 Import LocationModel เข้ามา

class RequestModel {
  String? requestId;
  String? requestdetail;
  DateTime? appointmentdate;
  DateTime? appointmenttime;
  DateTime? requestdate;
  String? requeststatus;
  String? pickupaddress;
  String? caretakerId;
  String? patientId;
  bool? isReadCaretaker;
  double? longitude;
  double? latitude;

  // ความสัมพันธ์
  ReviewModel? review; // 1 : 1
  DoctorAdviceModel? doctoradvice; // 1 : 1
  ReportModel? report; // 1 : 1
  List<NotificationModel>? notifications; // 1 : 1..n
  DepartmentModel? department; //1 : 1

  RequestModel({
    this.requestId,
    this.requestdetail,
    this.appointmentdate,
    this.appointmenttime,
    this.requestdate,
    this.requeststatus,
    this.pickupaddress,
    this.caretakerId,
    this.patientId,
    this.longitude,
    this.latitude,
    this.review,
    this.doctoradvice,
    this.report,
    this.notifications,
    this.department,
    this.isReadCaretaker,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      requestId: json['requestId'],
      requestdetail: json['requestdetail'],
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
      pickupaddress: json['pickupaddress'],
      caretakerId: json['caretakerId'],
      patientId: json['patientId'],
      longitude: json['longitude'],
      latitude: json['latitude'],
      isReadCaretaker: json['isReadCaretaker'] ?? false,
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
          ? (json['Notification'] is Map)
                ? (json['Notification'] as Map).values
                      .map(
                        (e) => NotificationModel.fromJson(
                          Map<String, dynamic>.from(e),
                        ),
                      )
                      .toList()
                : (json['Notification'] as List)
                      .map(
                        (e) => NotificationModel.fromJson(
                          Map<String, dynamic>.from(e),
                        ),
                      )
                      .toList()
          : null,
      department: json['Department'] != null
          ? DepartmentModel.fromJson(
              Map<String, dynamic>.from(json['Department']),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'requestdetail': requestdetail,
      'appointmentdate': appointmentdate?.toIso8601String(),
      'appointmenttime': appointmenttime?.toIso8601String(),
      'requestdate': requestdate?.toIso8601String(),
      'requeststatus': requeststatus,
      'caretakerId': caretakerId,
      'patientId': patientId,
      'isReadCaretaker': isReadCaretaker ?? false,
      'Review': review?.toJson(),
      'DoctorAdvice': doctoradvice?.toJson(),
      'Report': report?.toJson(),
      'Notification': notifications?.map((e) => e.toJson()).toList(),
      'Department': department?.toJson(),
    };
  }
}
