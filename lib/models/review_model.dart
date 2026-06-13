class ReviewModel {
  String? reviewId;
  String? ratingscore;
  String? comment;
  DateTime? reviewdate;

  ReviewModel({
    this.reviewId,
    this.ratingscore,
    this.comment,
    this.reviewdate,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId'],
      ratingscore: json['ratingscore'],
      comment: json['comment'],
      reviewdate: json['reviewdate'] != null
          ? DateTime.parse(json['reviewdate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'ratingscore': ratingscore,
      'comment': comment,
      'reviewdate': reviewdate?.toIso8601String(),
    };
  }
}
