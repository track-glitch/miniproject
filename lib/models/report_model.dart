class ReportModel {
  String? reportId;
  String? reporttype;
  String? reportdetail;
  String? reportphoto;
  DateTime? reportdate;

  ReportModel({
    this.reportId,
    this.reporttype,
    this.reportdetail,
    this.reportphoto,
    this.reportdate,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['reportId'],
      reporttype: json['reporttype'],
      reportdetail: json['reportdetail'],
      reportphoto: json['reportphoto'],
      reportdate: json['reportdate'] != null
          ? DateTime.parse(json['reportdate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reporttype': reporttype,
      'reportdetail': reportdetail,
      'reportphoto': reportphoto,
      'reportdate': reportdate?.toIso8601String(),
    };
  }
}
