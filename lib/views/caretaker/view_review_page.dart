import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/caretaker_service.dart';
// import '../../widgets/custom_bottom_nav.dart'; // 🌟 อย่าลืมเอาคอมเมนต์ออกถ้าใช้

class ViewReviewPage extends StatefulWidget {
  final String caretakerId;
  const ViewReviewPage({super.key, required this.caretakerId});

  @override
  State<ViewReviewPage> createState() => _ViewReviewPageState();
}

class _ViewReviewPageState extends State<ViewReviewPage> {
  final CaretakerService _service = CaretakerService();
  bool _isLoading = true; // ตัวแปรสำหรับสถานะโหลดข้อมูล

  final Color primaryColor = const Color(0xFF7C5CFC);
  final Color darkPurple = const Color(0xFF6E5ABF);
  final Color headerGradientStart = const Color(0xFF8E6FF0);
  final Color headerGradientEnd = const Color(0xFF7C5CFC);
  final Color bgGradientTop = const Color.fromARGB(255, 225, 202, 255);
  final Color bgGradientBottom = const Color.fromARGB(255, 225, 202, 255);
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

  // 🌟 ตัวแปรเก็บข้อมูลจริงจาก Database
  String caretakerName = '';
  String caretakerCitizenId = '';
  String caretakerImage = '';

  List<Map<String, dynamic>> allReviews = [];
  List<Map<String, dynamic>> filteredReviews =
      []; // เอาไว้เก็บข้อมูลที่ถูกกรองดาว

  @override
  void initState() {
    super.initState();
    _fetchData(); // สั่งดึงข้อมูลตอนเปิดหน้า
  }

  Future<void> _fetchData() async {
    // ดึงโปรไฟล์ของอาสาคนนี้
    final profile = await _service.getCaretakerProfile(widget.caretakerId);
    // ดึงรีวิวทั้งหมด
    final reviews = await _service.getAllReviews(widget.caretakerId);

    setState(() {
      if (profile != null) {
        caretakerName =
            "${profile['firstname'] ?? ''} ${profile['lastname'] ?? ''}".trim();
        caretakerCitizenId = profile['caretakerId'] ?? '';
        caretakerImage = profile['profilephoto'] ?? '';
      }

      allReviews = reviews;
      filteredReviews = reviews; // ตอนแรกให้แสดงข้อมูลทั้งหมดก่อน
      _isLoading = false; // โหลดเสร็จแล้ว
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 ระบบถอดรหัส Base64 สำหรับ "รูปโปรไฟล์อาสา"
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
        title: const Text(
          'รีวิวทั้งหมด',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              ? Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ) // แสดงหลอดโหลด
              : Column(
                  children: [
                    // --- 🌟 2. ส่วนรายการรีวิว ---
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
                                  'รีวิวล่าสุด',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: darkPurple,
                                  ),
                                ),
                                Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF8FF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFB9A4F2),
                                      width: 1.5,
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
                                        fontSize: 13,
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
                                        // 🌟 3. ระบบกรองคะแนนดาว (Filter)
                                        setState(() {
                                          _selectedFilter = newValue!;
                                          if (newValue == 'ทั้งหมด') {
                                            filteredReviews =
                                                allReviews; // โชว์ทั้งหมด
                                          } else {
                                            // ดึงเฉพาะตัวเลขมาเช็ค (เช่น "5 คะแนน" -> 5)
                                            double targetStar = double.parse(
                                              newValue.split(' ')[0],
                                            );
                                            filteredReviews = allReviews.where((
                                              review,
                                            ) {
                                              return (review['rating']
                                                          as double)
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
                            const SizedBox(height: 16),

                            // List ของรีวิวที่ถูกกรองแล้ว
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
                                      itemCount: filteredReviews
                                          .length, // 🌟 ใช้ List ที่ถูกกรอง
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

  // ==========================================
  // 🌟 ฟังก์ชันสร้าง Row รีวิว (พ่วงระบบกันแครชรูป Base64)
  // ==========================================
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
