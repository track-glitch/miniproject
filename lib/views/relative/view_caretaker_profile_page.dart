import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';
import 'package:miniproject/views/login_page.dart';
import 'package:miniproject/views/relative/edit_relative_info_page.dart';
import 'package:miniproject/views/relative/request_caretaker_service_page.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:miniproject/services/caretaker_service.dart';
import 'view_caretaker_review.dart';

class CaretakerProfilePage extends StatefulWidget {
  final String caretakerId;
  final String? loggedUid;

  const CaretakerProfilePage({
    super.key,
    required this.caretakerId,
    this.loggedUid,
  });

  @override
  State<CaretakerProfilePage> createState() => _CaretakerProfilePageState();
}

class _CaretakerProfilePageState extends State<CaretakerProfilePage> {
  Map<String, dynamic>? caretakerData;
  Map<String, dynamic>? vehicleData;
  bool isLoading = true;

  List<Map<String, dynamic>> recentReviews = [];
  double rating = 0.0;
  int reviewCount = 0;
  int _currentCarImageIndex = 0;
  List<Uint8List> _cachedCarImages = [];

  // 🎨 ปรับ Theme สีให้คลีนและทันสมัย
  final Color primaryColor = const Color(0xFF8763E6);
  final Color bgPurple = const Color(0xFFF4EDFB);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    loadCaretaker();
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_outlined, size: 75, color: primaryColor),
                const SizedBox(height: 20),
                Text(
                  'กรุณาเข้าสู่ระบบก่อนใช้งาน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'คุณต้องลงชื่อเข้าใช้งานในระบบก่อน จึงจะสามารถกดส่งคำขอเรียกใช้บริการผู้ดูแลคนนี้ได้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LoginPage(caretakerId: widget.caretakerId),
                        ),
                      );
                    },
                    child: const Text(
                      'ไปหน้าเข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> loadCaretaker() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('Login/${widget.caretakerId}')
          .get();
      final allReviews = await CaretakerService().getAllReviews(
        widget.caretakerId,
      );

      double calcRating = 0;
      if (allReviews.isNotEmpty) {
        double sum = allReviews
            .map((r) => r['rating'] as double)
            .reduce((a, b) => a + b);
        calcRating = sum / allReviews.length;
      }

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (!mounted) return;
        setState(() {
          caretakerData = Map<String, dynamic>.from(data['Caretaker'] ?? {});
          vehicleData = caretakerData!['Vehicle'] != null
              ? Map<String, dynamic>.from(caretakerData!['Vehicle'])
              : null;
          rating = calcRating;
          reviewCount = allReviews.length;
          recentReviews = allReviews.take(2).toList();

          // ===============================================
          // 🌟 โค้ดที่เพิ่มใหม่: ดึง Base64 มาแปลงเป็นรูปรอไว้เลย 1 รอบ
          // ===============================================
          if (vehicleData != null && vehicleData!['vehiclephotos'] != null) {
            final photosData = vehicleData!['vehiclephotos'];
            List<String> rawPhotos = [];
            if (photosData is List) {
              rawPhotos = photosData
                  .map((e) => (e['photo'] ?? '').toString())
                  .where((e) => e.isNotEmpty)
                  .toList();
            } else if (photosData is Map) {
              rawPhotos = photosData.values
                  .map((e) => (e['photo'] ?? '').toString())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }

            _cachedCarImages = rawPhotos.map((base64Str) {
              String cleanBase64 = base64Str.replaceAll(RegExp(r'\s+'), '');
              if (cleanBase64.contains(','))
                cleanBase64 = cleanBase64.split(',').last;
              int pad = cleanBase64.length % 4;
              if (pad > 0) cleanBase64 += '=' * (4 - pad);
              return base64Decode(cleanBase64); // ถอดรหัสเก็บไว้ใน RAM
            }).toList();
          }
          // ===============================================

          isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR = $e');
    }
  }

  String calculateAge(String? birthdate) {
    if (birthdate == null || birthdate.isEmpty) return '-';
    final birth = DateTime.parse(birthdate);
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day))
      age--;
    return '$age ปี';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: bgPurple,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: bgPurple,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ข้อมูลผู้ดูแล',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHighlightCard(),
            const SizedBox(height: 16),

            _buildAboutMe(), // 🌟 เสียบ แนะนำตัว ตรงนี้
            const SizedBox(height: 12),

            _buildEquipment(), // 🌟 เสียบ อุปกรณ์ทางการแพทย์ ตรงนี้
            const SizedBox(height: 12),

            _buildVisualBadgeGrid(),
            const SizedBox(height: 16),
            _buildExpandableDetails(),
            const SizedBox(height: 16),
            _buildCompactReviews(),
          ],
        ),
      ),
      // 🌟 Sticky Action Footer + Bottom Nav
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildStickyActionFooter(), _buildBottomNavBar()],
      ),
    );
  }

  // ── 1. Top Highlight Card ──
  Widget _buildTopHighlightCard() {
    String rawStatus =
        (caretakerData?['servicestatus']?.toString() ?? 'ไม่พร้อมให้บริการ')
            .trim();
    bool isAvailable =
        rawStatus.toLowerCase() == 'online' ||
        rawStatus.toLowerCase() == 'on' ||
        rawStatus == 'พร้อมให้บริการ';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.9), primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFE8D5FF),
                  backgroundImage:
                      caretakerData?['profilephoto'] != null &&
                          caretakerData!['profilephoto'].toString().isNotEmpty
                      ? MemoryImage(
                          base64Decode(
                            caretakerData!['profilephoto']
                                .toString()
                                .replaceAll('\n', '')
                                .trim(),
                          ),
                        )
                      : null,
                  child:
                      caretakerData?['profilephoto'] == null ||
                          caretakerData!['profilephoto'].toString().isEmpty
                      ? Icon(Icons.person, size: 40, color: primaryColor)
                      : null,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 2),
                ),
                child: Icon(
                  Icons.circle,
                  color: isAvailable
                      ? Colors.greenAccent.shade400
                      : Colors.orange,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${caretakerData?['firstname'] ?? 'ไม่ระบุ'} ${caretakerData?['lastname'] ?? ''}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'รหัส: ${caretakerData?['caretakerId'] ?? '-'}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Colors.amberAccent,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${rating.toStringAsFixed(1)}  •  $reviewCount รีวิว',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Visual Badge Grid ──
  Widget _buildVisualBadgeGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildBadgeItem(
          Icons.cake_rounded,
          'อายุ',
          calculateAge(caretakerData?['birthdate']),
        ),
        _buildBadgeItem(
          Icons.male_rounded,
          'เพศ',
          caretakerData?['gender'] ?? '-',
        ),
        _buildBadgeItem(
          Icons.phone_rounded,
          'เบอร์โทร',
          caretakerData?['phonenumber'] ?? '-',
        ),
        _buildBadgeItem(
          Icons.directions_car_rounded,
          'รถยนต์',
          vehicleData?['brand'] ?? 'มีรถยนต์',
        ),
      ],
    );
  }

  Widget _buildBadgeItem(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bgPurple, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Expandable Preview ──
  // ── แก้ไข 3. Expandable Preview (ดึง Location แบบใหม่) ──
  // ── แก้ไข 3. Expandable Preview ──
  Widget _buildExpandableDetails() {
    String address =
        caretakerData?['address'] ??
        caretakerData?['Location']?['address'] ??
        'ไม่ระบุที่อยู่';

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: primaryColor,
          collapsedIconColor: Colors.grey,
          title: Text(
            'ข้อมูลที่อยู่ & ยานพาหนะเพิ่มเติม',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: primaryColor,
            ),
          ),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          children: [
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.red.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🌟 ข้อมูลป้ายทะเบียนรถ
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.badge_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ทะเบียน: ${vehicleData?['licenseplate'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${vehicleData?['brand'] ?? '-'} ${vehicleData?['model'] ?? '-'} · สี${vehicleData?['color'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🌟 เสียบอัลบั้มรูปรถยนต์ตรงนี้เลย!
            _buildVehicleGallery(),
          ],
        ),
      ),
    );
  }

  // ── 4. Compact Reviews ──
  Widget _buildCompactReviews() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รีวิวล่าสุด',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              if (reviewCount > 0)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ViewCaretakerReview(caretakerId: widget.caretakerId),
                    ),
                  ),
                  child: Text(
                    'ดูทั้งหมด',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentReviews.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'ยังไม่มีข้อมูลรีวิว',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          else
            ...recentReviews.asMap().entries.map((entry) {
              var review = entry.value;
              bool isLast = entry.key == recentReviews.length - 1;

              // 🌟 1. ถอดรหัสรูปภาพรีวิว (กันแครช)
              ImageProvider? imageProvider;
              String imageUrl = review['reviewerImage']?.toString() ?? '';
              if (imageUrl.isNotEmpty) {
                try {
                  String clean = imageUrl.replaceAll('\n', '').trim();
                  if (clean.contains(',')) clean = clean.split(',').last;
                  int pad = clean.length % 4;
                  if (pad > 0) clean += '=' * (4 - pad);
                  imageProvider = MemoryImage(base64Decode(clean));
                } catch (_) {}
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🌟 2. ใส่รูปลงไปตรงนี้ ถ้าไม่มีรูปค่อยโชว์ไอคอนคน
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: bgPurple,
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? Icon(Icons.person, size: 20, color: primaryColor)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    review['reviewerName'] ?? 'ไม่ระบุชื่อ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < (review['rating'] as double).floor()
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              review['comment'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // 🌟 โชว์เวลาที่รีวิวด้วย
                            Text(
                              review['timeAgo'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // ── 5. Sticky Action Footer ──
  Widget _buildStickyActionFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            onPressed: () {
              String? uid =
                  widget.loggedUid ?? FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                _showLoginRequiredDialog();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceRequestPage(
                      caretakerData: caretakerData!,
                      caretakerId: widget.caretakerId,
                      loggedUid: uid,
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'ขอใช้บริการ',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 6. Bottom Navigation Bar ──
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF6E5ABF),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white60,
      currentIndex: 1,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      onTap: (index) async {
        if (index == 3) {
          String? uid =
              widget.loggedUid ?? FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) {
            _showLoginRequiredDialog();
            return;
          }
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
          try {
            final snapshot = await FirebaseDatabase.instance
                .ref('Login/$uid')
                .get();
            if (context.mounted) Navigator.pop(context);
            if (snapshot.exists && snapshot.value is Map) {
              final userData = Map<String, dynamic>.from(snapshot.value as Map);
              RelativeModel relative = RelativeModel(
                relativeId: '',
                firstname: '',
                lastname: '',
                phonenumber: '',
                relationship: '',
                email: '',
              );
              PatientModel patient = PatientModel(
                patientId: '',
                patientphoto: '',
                firstname: '',
                lastname: '',
                phonenumber: '',
                gender: '',
              );

              if (userData.containsKey('Relative')) {
                final relMap = Map<String, dynamic>.from(
                  userData['Relative'] as Map,
                );
                relative = RelativeModel(
                  relativeId: relMap['relativeId'] ?? '',
                  firstname: relMap['firstname'] ?? '',
                  lastname: relMap['lastname'] ?? '',
                  phonenumber: relMap['phonenumber'] ?? '',
                  relationship: relMap['relationship'] ?? '',
                  email: relMap['email'] ?? '',
                );
                if (relMap.containsKey('Patient')) {
                  final pData = Map<String, dynamic>.from(
                    relMap['Patient'] as Map,
                  );
                  patient = PatientModel(
                    patientId: pData['patientId'] ?? '',
                    patientphoto: pData['patientphoto'] ?? '',
                    firstname: pData['firstname'] ?? '',
                    lastname: pData['lastname'] ?? '',
                    phonenumber: pData['phonenumber'] ?? '',
                    gender: pData['gender'] ?? '',
                    birthdate: pData['birthdate'] != null
                        ? DateTime.tryParse(pData['birthdate'].toString())
                        : null,
                    disease: pData['disease'] ?? '',
                    mobility: pData['mobility'] ?? '',
                  );
                }
              }
              if (context.mounted)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditRelativeInfoPage(
                      currentPatient: patient,
                      currentRelative: relative,
                      loggedUid: uid,
                    ),
                  ),
                );
            } else {
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ไม่พบข้อมูลประวัติในระบบ')),
                );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('เกิดข้อผิดพลาด: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'บ้าน'),
        BottomNavigationBarItem(
          icon: Icon(Icons.support_agent),
          label: 'ขอใช้บริการ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'แจ้งเตือน',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'ญาติ',
        ),
      ],
    );
  }

  // ── ส่วนที่เพิ่มใหม่: เกี่ยวกับฉัน ──
  Widget _buildAboutMe() {
    String aboutMe = (caretakerData?['aboutme'] ?? '').trim();
    if (aboutMe.isEmpty)
      return const SizedBox.shrink(); // ถ้าไม่มีข้อมูล จะซ่อนกล่องนี้ไปเลยเนียนๆ

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'แนะนำตัว',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              aboutMe,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ส่วนที่เพิ่มใหม่: อุปกรณ์ทางการแพทย์ ──
  Widget _buildEquipment() {
    String equipment = (caretakerData?['equipmentdetails'] ?? '').trim();
    if (equipment.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: Colors.teal.shade500,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'อุปกรณ์ที่เตรียมไว้ให้',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.teal.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              equipment,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── เทคนิคใหม่: สไลด์รูปภาพยานพาหนะ ──
  Widget _buildVehicleGallery() {
    // ถ้าไม่มีรูป ให้แสดงกล่อง Placeholder คลีนๆ
    if (_cachedCarImages.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'ไม่มีรูปภาพยานพาหนะ',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // ถ้ามีรูป ให้แสดง PageView พร้อมรูปภาพที่แคชไว้แล้ว
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _cachedCarImages.length,
            onPageChanged: (index) {
              setState(() => _currentCarImageIndex = index);
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _cachedCarImages[index], // 🌟 ดึงรูปภาพจาก RAM แทนการ Decode ใหม่
                  fit: BoxFit.cover,
                  width: double.infinity,
                  gaplessPlayback:
                      true, // 🌟 คำสั่งเทพของ Flutter: ป้องกันภาพกระพริบระหว่าง Rebuild
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              );
            },
          ),

          // ป้ายบอกจำนวนรูปมุมขวาล่าง
          if (_cachedCarImages.length > 1)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentCarImageIndex + 1} / ${_cachedCarImages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
