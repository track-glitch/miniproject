import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/caretaker_service.dart';

class ViewReviewPage extends StatefulWidget {
  final String caretakerId;
  const ViewReviewPage({super.key, required this.caretakerId});

  @override
  State<ViewReviewPage> createState() => _ViewReviewPageState();
}

class _ViewReviewPageState extends State<ViewReviewPage> {
  final CaretakerService _service = CaretakerService();
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF9B59B6);
  final Color headerGradientStart = const Color(0xFF9B59B6);
  final Color headerGradientEnd = const Color(0xFF9B59B6);
  final Color bgGradientTop = const Color.fromARGB(255, 225, 202, 255);
  final Color bgGradientBottom = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;

  String _selectedFilter = 'ทั้งหมด';

  String caretakerName = '';
  String caretakerCitizenId = '';
  String caretakerImage = '';

  List<Map<String, dynamic>> allReviews = [];
  List<Map<String, dynamic>> filteredReviews = [];
  int reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // 🌟 1. ดึงโปรไฟล์มาก่อน เพื่อเอาเลขบัตรประชาชนมาใช้เทียบ
    final profile = await _service.getCaretakerProfile(widget.caretakerId);
    String citizenId = '';

    if (profile != null) {
      caretakerName =
          "${profile['firstname'] ?? ''} ${profile['lastname'] ?? ''}".trim();
      caretakerCitizenId = profile['caretakerId']?.toString() ?? '';
      citizenId = caretakerCitizenId; // เก็บไว้เทียบคีย์
      caretakerImage = profile['profilephoto']?.toString() ?? '';
    }

    List<Map<String, dynamic>> fetchedReviews = [];
    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login').get();
      if (snapshot.exists && snapshot.value != null) {
        final allUsers = Map<dynamic, dynamic>.from(snapshot.value as Map);

        allUsers.forEach((userKey, userValue) {
          if (userValue is Map && userValue.containsKey('Relative')) {
            var relNode = userValue['Relative'];
            if (relNode is Map && relNode.containsKey('Request')) {
              var requests = relNode['Request'];
              if (requests is Map) {
                requests.forEach((reqId, reqData) {
                  if (reqData is Map && reqData['caretakerId'] != null) {
                    String cId = reqData['caretakerId'].toString();

                    // 🌟 2. เช็คเทียบทั้ง UID (widget.caretakerId) และ Citizen ID
                    if (cId == widget.caretakerId ||
                        (citizenId.isNotEmpty && cId == citizenId)) {
                      var reviewData = reqData['Review'] ?? reqData['review'];
                      if (reviewData != null && reviewData is Map) {
                        // 🌟 3. อ่านค่าดาว
                        double ratingScore = 0.0;
                        var rawRating =
                            reviewData['rating'] ?? reviewData['ratingscore'];
                        if (rawRating != null) {
                          ratingScore =
                              double.tryParse(rawRating.toString()) ?? 0.0;
                        }

                        String commentStr =
                            reviewData['comment']?.toString() ?? '';
                        String reviewDateStr =
                            reviewData['reviewdate']?.toString() ??
                            DateTime.now().toIso8601String();

                        // 🌟 4. เตรียมชื่อคนรีวิว (ยึดชื่อญาติเป็นหลัก)
                        String rFirstname = (relNode['firstname'] ?? '')
                            .toString();
                        String rLastname = (relNode['lastname'] ?? '')
                            .toString();
                        String reviewerName = "$rFirstname $rLastname".trim();
                        if (reviewerName.isEmpty) reviewerName = 'ผู้ใช้บริการ';

                        // 🌟 5. ดึงรูปโปรไฟล์แบบแยกผู้ป่วยหลายคน
                        String reviewerImage =
                            relNode['profilephoto']?.toString() ?? '';

                        if (reviewerImage.isEmpty) {
                          String requestedPatientId =
                              reqData['patientId']?.toString() ?? '';
                          dynamic pNode =
                              relNode['Patient'] ?? relNode['patients'];

                          if (pNode != null && pNode is Map) {
                            // ถ้ามี patientId ระบุในคำขอ ให้ดึงรูปคนนั้นมา
                            if (requestedPatientId.isNotEmpty &&
                                pNode.containsKey(requestedPatientId)) {
                              reviewerImage =
                                  pNode[requestedPatientId]['patientphoto']
                                      ?.toString() ??
                                  '';
                            }
                            // ถ้าหาไม่เจอ หรือเป็นโครงสร้างแบบเก่า ให้ดึงรูปคนแรกมาแสดงแทน
                            else if (pNode.isNotEmpty) {
                              final firstPatient = pNode.values.first;
                              if (firstPatient is Map) {
                                reviewerImage =
                                    firstPatient['patientphoto']?.toString() ??
                                    '';
                              }
                            }
                          }
                        }

                        String formattedDate = '';
                        try {
                          DateTime dt = DateTime.parse(reviewDateStr);
                          formattedDate =
                              "${dt.day}/${dt.month}/${dt.year + 543}";
                        } catch (_) {}

                        fetchedReviews.add({
                          'rating': ratingScore,
                          'comment': commentStr,
                          'timeAgo': formattedDate,
                          'reviewerName': reviewerName,
                          'reviewerImage': reviewerImage,
                          'rawDate': reviewDateStr,
                        });
                      }
                    }
                  }
                });
              }
            }
          }
        });

        fetchedReviews.sort((a, b) => b['rawDate'].compareTo(a['rawDate']));
      }
    } catch (e) {
      print("Error fetching reviews directly: $e");
    }

    if (mounted) {
      setState(() {
        reviewCount = fetchedReviews.length;
        allReviews = fetchedReviews;
        filteredReviews = fetchedReviews;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? caretakerImageProvider;
    if (caretakerImage.isNotEmpty) {
      try {
        if (caretakerImage.length > 100) {
          String clean = caretakerImage
              .split(',')
              .last
              .replaceAll(RegExp(r'\s+'), '');
          int pad = clean.length % 4;
          if (pad > 0) clean += '=' * (4 - pad);
          caretakerImageProvider = MemoryImage(base64Decode(clean));
        } else {
          caretakerImageProvider = NetworkImage(caretakerImage);
        }
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: bgGradientBottom,
      appBar: AppBar(
        title: Text(
          'รีวิว ($reviewCount)',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [headerGradientStart, headerGradientEnd],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgGradientTop, bgGradientBottom],
            stops: const [0.0, 0.35],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.10),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รีวิวล่าสุด',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: darkPurple,
                              ),
                            ),
                            const SizedBox(height: 12),

                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildStarFilterChip('ทั้งหมด'),
                                  _buildStarFilterChip('5'),
                                  _buildStarFilterChip('4'),
                                  _buildStarFilterChip('3'),
                                  _buildStarFilterChip('2'),
                                  _buildStarFilterChip('1'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            Expanded(
                              child: filteredReviews.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.rate_review_outlined,
                                            size: 48,
                                            color: Colors.grey.shade300,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'ไม่พบข้อมูลรีวิว',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: filteredReviews.length,
                                      separatorBuilder: (context, index) =>
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: Divider(
                                              height: 1,
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                      itemBuilder: (context, index) {
                                        final review = filteredReviews[index];
                                        return _buildReviewItem(
                                          name: review['reviewerName'],
                                          rating: review['rating'],
                                          comment: review['comment'],
                                          timeAgo: review['timeAgo'],
                                          imageUrl: review['reviewerImage'],
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStarFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    int count = 0;

    if (label == 'ทั้งหมด') {
      count = allReviews.length;
    } else {
      double targetStar = double.parse(label);
      count = allReviews
          .where((r) => (r['rating'] as double).floor() == targetStar.floor())
          .length;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          if (label == 'ทั้งหมด') {
            filteredReviews = allReviews;
          } else {
            double targetStar = double.parse(label);
            filteredReviews = allReviews.where((review) {
              return (review['rating'] as double).floor() == targetStar.floor();
            }).toList();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != 'ทั้งหมด') ...[
              const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
              const SizedBox(width: 4),
            ],
            Text(
              label == 'ทั้งหมด' ? 'ทั้งหมด ($count)' : '$label ($count)',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem({
    required String name,
    required double rating,
    required String comment,
    required String timeAgo,
    required String imageUrl,
  }) {
    ImageProvider? imageProvider;
    if (imageUrl.isNotEmpty) {
      try {
        if (imageUrl.length > 100) {
          String clean = imageUrl
              .split(',')
              .last
              .replaceAll(RegExp(r'\s+'), '');
          int pad = clean.length % 4;
          if (pad > 0) clean += '=' * (4 - pad);
          imageProvider = MemoryImage(base64Decode(clean));
        } else {
          imageProvider = NetworkImage(imageUrl);
        }
      } catch (e) {
        print('Error decoding Review Image: $e');
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: imageProvider != null
                ? Image(
                    image: imageProvider!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        color: Colors.grey.shade400,
                        size: 28,
                      );
                    },
                  )
                : Icon(Icons.person, color: Colors.grey.shade400, size: 28),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating.floor() ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFC107),
                        size: 16,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                timeAgo,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
