import 'package:http/http.dart';
import 'package:miniproject/models/review_model.dart';
import 'package:miniproject/models/report_model.dart';
import 'package:miniproject/models/notification_model.dart';
import 'package:miniproject/models/doctor_advice_model.dart';

class RequestModel {
  String? requestId;
  String? requestdetail;
  String? pickuplocation;
  String? dropofflocation;
  String? hospitalname;
  String? departmentname;
  DateTime? appointmentdate;
  DateTime? appointmenttime;
  DateTime? requestdate;
  String? requeststatus;
  double? latitude;
  double? longitude;

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
    this.latitude,
    this.longitude,
    this.review,
    this.doctoradvice,
    this.report,
    this.notifications,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      requestId: json['requestId'],
      requestdetail: json['requestdetail'],
      pickuplocation: json['pickuplocation'],
      dropofflocation: json['dropofflocation'],
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
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      review: json['review'] != null
          ? ReviewModel.fromJson(json['review'])
          : null,
      doctoradvice: json['doctoradvice'] != null
          ? DoctorAdviceModel.fromJson(json['doctoradvice'])
          : null,
      report: json['report'] != null
          ? ReportModel.fromJson(json['report'])
          : null,
      notifications: json['notifications'] != null
          ? (json['notifications'] as List)
                .map((e) => NotificationModel.fromJson(e))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    RequestModel requestModel = new RequestModel();

    return {
      'requestId': requestId,
      'requestdetail': requestdetail,
      'pickuplocation': pickuplocation,
      'dropofflocation': dropofflocation,
      'hospitalname': hospitalname,
      'departmentname': departmentname,
      'appointmentdate': appointmentdate?.toIso8601String(),
      'appointmenttime': appointmenttime?.toIso8601String(),
      'requestdate': requestdate?.toIso8601String(),
      'requeststatus': requeststatus,
      'latitude': latitude,
      'longitude': longitude,
      'review': review?.toJson(),
      'doctoradvice': doctoradvice?.toJson(),
      'report': report?.toJson(),
      'notifications': notifications?.map((e) => e.toJson()).toList(),
    };
  }
}
