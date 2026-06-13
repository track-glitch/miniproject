class DocumentModel {
  final String documentId;
  final String documenttype;
  final String
  filepath; // มักเก็บเป็น URL ลิงก์ไฟล์ที่อัปโหลดขึ้น Firebase Storage
  final DateTime uploaddate;

  DocumentModel({
    required this.documentId,
    required this.documenttype,
    required this.filepath,
    required this.uploaddate,
  });

  // แปลงเป็น Map สำหรับยิงขึ้นคลาวด์ Firestore
  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'documenttype': documenttype,
      'filepath': filepath,
      'uploaddate': uploaddate.toIso8601String(),
    };
  }

  // แปลงกลับจาก Map มาเป็นคลาสเพื่อดึงมาใช้งานในแอป
  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      documentId: map['documentId'] ?? '',
      documenttype: map['documenttype'] ?? '',
      filepath: map['filepath'] ?? '',
      uploaddate: map['uploaddate'] != null
          ? (map['uploaddate'] as dynamic)
                .toDate() // แปลงจาก Timestamp ของ Firebase กลับเป็น DateTime
          : DateTime.now(),
    );
  }
}
