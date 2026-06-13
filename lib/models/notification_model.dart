class NotificationModel {
  final String notifyId;
  final String notifystatus;
  final String notifydetail;
  final DateTime notifydate;

  NotificationModel({
    required this.notifyId,
    required this.notifystatus,
    required this.notifydetail,
    required this.notifydate,
  });

  // แปลงเป็น Map สำหรับส่งเข้าคอลเลกชันแจ้งเตือน
  Map<String, dynamic> toMap() {
    return {
      'notifyId': notifyId,
      'notifystatus': notifystatus,
      'notifydetail': notifydetail,
      'notifydate': notifydate.toIso8601String(),
    };
  }

  // แปลงกลับจาก Map มาเป็นคลาสเพื่อโชว์ในหน้าต่างกระดิ่งแจ้งเตือนของแอป
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notifyId: map['notifyId'] ?? '',
      notifystatus: map['notifystatus'] ?? '',
      notifydetail: map['notifydetail'] ?? '',
      notifydate: map['notifydate'] != null
          ? (map['notifydate'] as dynamic).toDate()
          : DateTime.now(),
    );
  }
}
