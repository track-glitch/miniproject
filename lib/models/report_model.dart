class ReportModel {
  final String reportId;
  final String reporttype;
  final String reportdetail;
  final String reportphoto;
  final DateTime reportdate;

  ReportModel({
    required this.reportId,
    required this.reporttype,
    required this.reportdetail,
    required this.reportphoto,
    required this.reportdate,
  });
  Map<String, dynamic> toMap() => {
    'reportId': reportId,
    'reporttype': reporttype,
    'reportdetail': reportdetail,
    'reportphoto': reportphoto,
    'reportdate': reportdate.toIso8601String(),
  };
}
