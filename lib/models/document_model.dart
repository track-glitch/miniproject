class DocumentModel {
  String? documentId;
  String? documenttype;
  String? filepath;
  DateTime? uploaddate;

  DocumentModel({
    this.documentId,
    this.documenttype,
    this.filepath,
    this.uploaddate,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      documentId: json['documentId'],
      documenttype: json['documenttype'],
      filepath: json['filepath'],
      uploaddate: json['uploaddate'] != null
          ? DateTime.parse(json['uploaddate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'documenttype': documenttype,
      'filepath': filepath,
      'uploaddate': uploaddate?.toIso8601String(),
    };
  }
}
