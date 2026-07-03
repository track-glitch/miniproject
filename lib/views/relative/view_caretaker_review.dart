import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:miniproject/services/caretaker_service.dart';

class ViewCaretakerReview extends StatefulWidget {
  final String caretakerId; // 🌟 รับค่า ID เข้ามาเพื่อดึงข้อมูล
  const ViewCaretakerReview({super.key, required this.caretakerId});

  @override
  State<ViewCaretakerReview> createState() => _ViewCaretakerReviewState();
}

class _ViewCaretakerReviewState extends State<ViewCaretakerReview> {
  final CaretakerService _service = CaretakerService();
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF8763E6);
  final Color darkPurple = const Color(0xFF6E5ABF);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;

  String _selectedFilter = 'ทั้งหมด';
  final List<String> _filterOptions = [
    'ทั้งหมด',
    '5 คะแนน',
    '4 คะแนน',
    '3 คะแนน',
    '2 คะแนน',
    '1 คะแนน',
  ];

  String caretakerName = '';
  String caretakerCitizenId = '';
  String caretakerImage = '';

  List<Map<String, dynamic>> allReviews = [];
  List<Map<String, dynamic>> filteredReviews = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // ดึงโปรไฟล์อาสามาแสดงด้านบน
    final profile = await _service.getCaretakerProfile(widget.caretakerId);
    // ดึงรีวิวทั้งหมดของอาสาคนนี้
    final reviews = await _service.getAllReviews(widget.caretakerId);

    setState(() {
      if (profile != null) {
        caretakerName =
            "${profile['firstname'] ?? ''} ${profile['lastname'] ?? ''}".trim();
        caretakerCitizenId = profile['caretakerId'] ?? '';
        caretakerImage = profile['profilephoto'] ?? '';
      }

      allReviews = reviews;
      filteredReviews = reviews;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? caretakerImageProvider;
    if (caretakerImage.isNotEmpty) {
      try {
        if (caretakerImage.length > 100) {
          String clean = caretakerImage;
          if (clean.contains(',')) clean = clean.split(',').last;
          clean = clean.replaceAll(RegExp(r'\s+'), '');
          int pad = clean.length % 4;
          if (pad > 0) clean += '=' * (4 - pad);
          caretakerImageProvider = MemoryImage(base64Decode(clean));
        } else {
          caretakerImageProvider = NetworkImage(caretakerImage);
        }
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'รีวิวทั้งหมด',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : Column(
                children: [
                  // 🌟 1. ส่วน Profile Card ด้านบน (ดึงออกมาให้ลอยทับสวยๆ)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 45),
                          padding: const EdgeInsets.only(
                            top: 55,
                            bottom: 20,
                            left: 16,
                            right: 16,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                caretakerName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: darkPurple,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                caretakerCitizenId,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: const Color(0xFFE8D5FF),
                              backgroundImage: caretakerImageProvider,
                              child: caretakerImageProvider == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.black87,
                                      size: 40,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🌟 2. ส่วนรายการรีวิวและตัวกรอง
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'รีวิวทั้งหมด',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: darkPurple,
                                ),
                              ),
                              // 🌟 Dropdown กรองดาว
                              Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF8FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFB9A4F2),
                                    width: 1.2,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedFilter,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFF6E5ABF),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6E5ABF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    items: _filterOptions.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        _selectedFilter = newValue!;
                                        if (newValue == 'ทั้งหมด') {
                                          filteredReviews = allReviews;
                                        } else {
                                          double targetStar = double.parse(
                                            newValue.split(' ')[0],
                                          );
                                          filteredReviews = allReviews.where((
                                            review,
                                          ) {
                                            return (review['rating'] as double)
                                                    .floor() ==
                                                targetStar.floor();
                                          }).toList();
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 🌟 List แสดงการ์ดรีวิว
                          Expanded(
                            child: filteredReviews.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.rate_review_outlined,
                                          size: 40,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 8),
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
    );
  }

  // 🌟 ฟังก์ชันวาด UI แต่ละรีวิว (ใช้โค้ดเดียวกับหน้าโปรไฟล์เป๊ะๆ)
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
          String clean = imageUrl;
          if (clean.contains(',')) clean = clean.split(',').last;
          clean = clean.replaceAll(RegExp(r'\s+'), '');
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: imageProvider != null
                ? Image(
                    image: imageProvider!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      color: Colors.grey.shade400,
                      size: 26,
                    ),
                  )
                : Icon(Icons.person, color: Colors.grey.shade400, size: 26),
          ),
        ),
        const SizedBox(width: 12),
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
                        fontSize: 14,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating.floor()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFFFC107),
                        size: 16,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
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
