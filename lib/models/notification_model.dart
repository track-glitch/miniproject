class NotificationModel {
  String? notifyId;
  String? notifystatus;
  String? notifydetail;
  String? notifydate;

  NotificationModel({
    this.notifyId,
    this.notifystatus,
    this.notifydetail,
    this.notifydate,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notifyId: json['notifyId'],
      notifystatus: json['notifystatus'],
      notifydetail: json['notifydetail'],
      notifydate: json['notifydate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifyId': notifyId,
      'notifystatus': notifystatus,
      'notifydetail': notifydetail,
      'notifydate': notifydate,
    };
  }
}
