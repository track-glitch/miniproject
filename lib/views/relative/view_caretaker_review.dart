import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:miniproject/services/caretaker_service.dart';

class ViewCaretakerReview extends StatefulWidget {
  final String caretakerId;
  final List<Map<String, dynamic>> reviews;
  const ViewCaretakerReview({
    super.key,
    required this.caretakerId,
    required this.reviews,
  });

  @override
  State<ViewCaretakerReview> createState() => _ViewCaretakerReviewState();
}

class _ViewCaretakerReviewState extends State<ViewCaretakerReview> {
  final CaretakerService _service = CaretakerService();
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF9B59B6);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;

  int _selectedFilterValue = 0;
  final List<int> _filterValues = [0, 5, 4, 3, 2, 1];

  String caretakerName = '';
  String caretakerCitizenId = '';
  String caretakerImage = '';

  List<Map<String, dynamic>> allReviews = [];
  List<Map<String, dynamic>> filteredReviews = [];

  // 🌟 ฟังก์ชันแปลงเพศเป็นคำนำหน้าชื่อ นาย / นาง
  String getPrefix(String? gender) {
    if (gender == null) return '';
    final g = gender.trim();
    if (g == 'ชาย' || g.toLowerCase() == 'male') {
      return 'นาย';
    } else if (g == 'หญิง' || g.toLowerCase() == 'female') {
      return 'นาง';
    }
    return '';
  }

  // 🌟 ฟังก์ชันรวมคำนำหน้า + ชื่อ + นามสกุล (เว้นวรรค 1 เคาะหลังคำนำหน้า)
  String formatFullNameWithTitle({
    required String? gender,
    required String? firstname,
    required String? lastname,
  }) {
    String prefix = getPrefix(gender);
    String fName = (firstname ?? '').trim();
    String lName = (lastname ?? '').trim();

    if (fName.isEmpty && lName.isEmpty) return 'ไม่ระบุ';
    String prefixWithSpace = prefix.isNotEmpty ? '$prefix ' : '';

    return '$prefixWithSpace$fName $lName'.trim();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final profile = await _service.getCaretakerProfile(widget.caretakerId);
      if (profile != null) {
        // 🌟 ใส่คำนำหน้าชื่อ นาย / นาง แบบเว้นวรรค
        caretakerName = formatFullNameWithTitle(
          gender: profile['gender']?.toString(),
          firstname: profile['firstname']?.toString(),
          lastname: profile['lastname']?.toString(),
        );
        caretakerCitizenId = profile['caretakerId'] ?? '';
        caretakerImage = profile['profilephoto'] ?? '';
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }

    setState(() {
      allReviews = widget.reviews;
      filteredReviews = widget.reviews;
      _isLoading = false;
    });
  }

  // 🌟 ฟังก์ชันจัดรูปแบบตัวเลขจำนวนรีวิวให้อ่านง่าย (เผื่อมีรีวิวเยอะๆ เป็นหลักพัน)
  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // 🌟 ฟังก์ชันนับจำนวนรีวิวตามดาว
  int _getReviewCount(int starValue) {
    if (starValue == 0) return allReviews.length;
    return allReviews
        .where((r) => (r['ratingscore'] as double).floor() == starValue)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? caretakerImageProvider;
    if (caretakerImage.isNotEmpty) {
      try {
        if (caretakerImage.startsWith('http')) {
          caretakerImageProvider = NetworkImage(caretakerImage);
        } else {
          String clean = caretakerImage;
          if (clean.contains(',')) clean = clean.split(',').last;
          clean = clean.replaceAll(RegExp(r'\s+'), '');
          int pad = clean.length % 4;
          if (pad > 0) clean += '=' * (4 - pad);
          caretakerImageProvider = MemoryImage(base64Decode(clean));
        }
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'รีวิว (${_formatCount(allReviews.length)})',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 10.0,
                            children: _filterValues.map((star) {
                              int count = _getReviewCount(star);
                              bool isSelected = _selectedFilterValue == star;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedFilterValue = star;
                                    if (star == 0) {
                                      filteredReviews = allReviews;
                                    } else {
                                      filteredReviews = allReviews
                                          .where(
                                            (r) =>
                                                (r['ratingscore'] as double)
                                                    .floor() ==
                                                star,
                                          )
                                          .toList();
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF9B59B6)
                                        : const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF9B59B6)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (star == 0) ...[
                                        Text(
                                          'ทั้งหมด',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${_formatCount(count)})',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ] else if (star == 1) ...[
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFFC107),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${_formatCount(count)})',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ] else ...[
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFFC107),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$star',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${_formatCount(count)})',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 8),

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

                                      String formattedDate = '';
                                      if (review['reviewdate'] != null) {
                                        try {
                                          DateTime d = DateTime.parse(
                                            review['reviewdate'].toString(),
                                          );
                                          formattedDate =
                                              '${d.day}/${d.month}/${d.year + 543}';
                                        } catch (_) {}
                                      }

                                      return _buildReviewItem(
                                        name:
                                            review['reviewerName'] ??
                                            'ผู้ใช้บริการ',
                                        ratingscore:
                                            (review['ratingscore'] ?? 0)
                                                .toDouble(),
                                        comment: review['comment'] ?? '',
                                        reviewdate: formattedDate,
                                        imageUrl: review['reviewerImage'] ?? '',
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

  Widget _buildReviewItem({
    required String name,
    required double ratingscore,
    required String comment,
    required String reviewdate,
    required String imageUrl,
  }) {
    ImageProvider? reviewerImageProvider;
    if (imageUrl.isNotEmpty) {
      try {
        if (imageUrl.startsWith('http')) {
          reviewerImageProvider = NetworkImage(imageUrl);
        } else {
          String clean = imageUrl;
          if (clean.contains(',')) clean = clean.split(',').last;
          clean = clean.replaceAll(RegExp(r'\s+'), '');
          int pad = clean.length % 4;
          if (pad > 0) clean += '=' * (4 - pad);

          reviewerImageProvider = MemoryImage(base64Decode(clean));
        }
      } catch (e) {
        print('Error decoding Reviewer Profile Image: $e');
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: reviewerImageProvider,
          child: reviewerImageProvider == null
              ? Icon(Icons.person, color: Colors.grey.shade400, size: 26)
              : null,
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
                        index < ratingscore.floor()
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
                reviewdate,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
