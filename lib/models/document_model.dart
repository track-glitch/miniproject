class DocumentModel {
  String? documentId;
  String? documenttype;
  String? filepath;
  DateTime? uploaddate;
  String? status;

  DocumentModel({
    this.documentId,
    this.documenttype,
    this.filepath,
    this.uploaddate,
    this.status = 'PENDING', // กำหนดให้ตอนอัปโหลดครั้งแรกเป็น รอดำเนินการ เสมอ
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      documentId: json['documentId'],
      documenttype: json['documenttype'],
      filepath: json['filepath'],
      uploaddate: json['uploaddate'] != null
          ? DateTime.parse(json['uploaddate'])
          : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'documenttype': documenttype,
      'filepath': filepath,
      'uploaddate': uploaddate?.toIso8601String(),
      'status': status,
    };
  }
}
