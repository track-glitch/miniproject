class ReviewModel {
  final String reviewId;
  final String ratingscore;
  final String comment;
  final DateTime reviewdate;

  ReviewModel({required this.reviewId, required this.ratingscore, required this.comment, required this.reviewdate});
  Map<String, dynamic> toMap() => {'reviewId': reviewId, 'ratingscore': ratingscore, 'comment': comment, 'reviewdate': reviewdate};
}