import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../../widgets/custom_header_nav.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../caretaker/add_status_notification_page.dart';
import '../../views/caretaker/list_relative_request_page.dart';
import '../caretaker/edit_profile_page.dart';
import '../../services/caretaker_service.dart'; // 🌟 เพิ่มไว้บนสุด

enum RequestStatus {
  pending,
  acceptedEarly,
  acceptedReady,
  completed,
  cancelled,
}

class ViewRelativeRequestPage extends StatefulWidget {
  final RequestCard requestData;
  final String uid;

  const ViewRelativeRequestPage({
    super.key,
    required this.requestData,
    required this.uid,
  });

  @override
  State<ViewRelativeRequestPage> createState() =>
      _ViewRelativeRequestPageStage();
}

class _ViewRelativeRequestPageStage extends State<ViewRelativeRequestPage> {
  late RequestStatus currentStatus;
  int _bottomNavIndex = 1;
  bool _isLoading = true;

  LatLng pointA = const LatLng(18.8055, 98.9950);
  LatLng pointB = const LatLng(18.8236, 99.0068);
  List<LatLng> routePoints = [];

  // 🌟 1. เพิ่มตัวแปรเก็บข้อความระยะทาง
  String _distanceText = 'กำลังคำนวณ...';

  final String maptilerApiKey = 'JCT1H6ehzlMaKZyrC5mp';

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });

    if (index == 0) {
      // ไปหน้าแรก (บ้าน)
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ListRelativeRequestPage(uid: widget.uid),
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfilePage(uid: widget.uid),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    switch (widget.requestData.statusType) {
      case 'pending':
        currentStatus = RequestStatus.pending;
        break;
      case 'accepted':
        currentStatus = widget.requestData.hasAlert
            ? RequestStatus.acceptedReady
            : RequestStatus.acceptedEarly;
        break;
      case 'completed':
        currentStatus = RequestStatus.completed;
        break;
      case 'cancelled':
        currentStatus = RequestStatus.cancelled;
        break;
      default:
        currentStatus = RequestStatus.pending;
    }

    var pickup = widget.requestData.requestModel.pickuplocation;
    var dropoff = widget.requestData.requestModel.dropofflocation;
    if (pickup != null && pickup.latitude != null && pickup.longitude != null) {
      pointA = LatLng(pickup.latitude!, pickup.longitude!);
    }
    if (dropoff != null &&
        dropoff.latitude != null &&
        dropoff.longitude != null) {
      pointB = LatLng(dropoff.latitude!, dropoff.longitude!);
    }

    _getRoute();
  }

  // 🌟 ดึงข้อมูลพิกัดและระยะทางจาก API
  Future<void> _getRoute() async {
    try {
      final url =
          'http://router.project-osrm.org/route/v1/driving/${pointA.longitude},${pointA.latitude};${pointB.longitude},${pointB.latitude}?geometries=geojson';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coords = data['routes'][0]['geometry']['coordinates'];

        // 🌟 2. ดึงข้อมูลระยะทาง (หน่วยเป็นเมตร)
        final double distanceInMeters = data['routes'][0]['distance']
            .toDouble();

        setState(() {
          routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
          // แปลงเป็นกิโลเมตรและทศนิยม 1 ตำแหน่ง
          _distanceText =
              'ระยะทาง ${(distanceInMeters / 1000).toStringAsFixed(1)} กม.';
          _isLoading = false;
        });
      } else {
        setState(() {
          routePoints = [pointA, pointB];
          _distanceText = 'ไม่สามารถระบุได้';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        routePoints = [pointA, pointB];
        _distanceText = 'ไม่สามารถระบุได้';
        _isLoading = false;
      });
    }
  }

  void _showConfirmationDialog(bool isAccept) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAccept
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF44336),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAccept ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isAccept
                      ? 'คุณต้องการตอบรับคำขอไหม?'
                      : 'คุณต้องการปฏิเสธคำขอไหม?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAccept
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF44336),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade500,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C00),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          String newStatus = isAccept
                              ? 'Accepted'
                              : 'Cancelled';

                          await CaretakerService().updateRequestStatus(
                            widget
                                .requestData
                                .relativeUid, // เอา UID ญาติจากการ์ด
                            widget.requestData.id, // เอารหัส Request จากการ์ด
                            newStatus,
                          );

                          setState(() {
                            if (isAccept) {
                              currentStatus = RequestStatus.acceptedEarly;
                            } else {
                              currentStatus = RequestStatus.cancelled;
                            }
                          });
                        },
                        child: const Text(
                          'ตกลง',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: const CustomHeader(
          title: 'รายละเอียดคำขอ',
          showBackButton: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF9B59B6)),
              SizedBox(height: 16),
              Text(
                'กำลังโหลดเส้นทางและข้อมูล...',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _bottomNavIndex,
          onTap: _onBottomNavTapped,
          uid: widget.uid,
        ),
      );
    }

    Map<String, dynamic> pat = widget.requestData.patientData;
    Map<String, dynamic> rel = widget.requestData.relativeData;
    var reqModel = widget.requestData.requestModel;

    String patAge = 'ไม่ระบุอายุ';
    if (pat['birthdate'] != null) {
      DateTime dob = DateTime.tryParse(pat['birthdate']) ?? DateTime.now();
      patAge = '${DateTime.now().year - dob.year} ปี';
    }
    String patGender = pat['gender'] ?? 'ไม่ระบุเพศ';

    // 🌟 ดึงข้อมูลชื่อผู้ป่วยออกมาตรงนี้เลย จะได้หาเจอง่ายๆ และมีคำนำหน้า
    String patPrefix = patGender == 'ชาย'
        ? 'นาย '
        : (patGender == 'หญิง' ? 'นาง ' : 'คุณ ');
    String patName =
        "$patPrefix${pat['firstname'] ?? ''} ${pat['lastname'] ?? ''}".trim();
    if (patName == 'คุณ' || patName.isEmpty) patName = 'ไม่ระบุชื่อผู้ป่วย';

    String patMobility = pat['mobility'] ?? 'ไม่ระบุการเคลื่อนไหว';
    String patDisease = pat['disease'] ?? 'ไม่มีโรคประจำตัว';
    String patPhone = pat['phonenumber'] ?? 'ไม่มีเบอร์โทรศัพท์';
    String patImage = pat['patientphoto'] ?? '';
    String relGender = rel['gender'] ?? '';

    String relPrefix = relGender == 'ชาย'
        ? 'นาย '
        : (relGender == 'หญิง' ? 'นาง ' : 'คุณ ');
    String relName =
        "$relPrefix${rel['firstname'] ?? ''} ${rel['lastname'] ?? ''}".trim();
    if (relName == 'คุณ' || relName.trim().isEmpty) relName = 'ไม่ระบุชื่อญาติ';
    String relRelation = rel['relationship'] ?? 'ไม่ระบุ';
    String relPhone = rel['phonenumber'] ?? 'ไม่มีเบอร์โทรศัพท์';
    String relLine = rel['lineId'] ?? 'ไม่มีข้อมูล';

    String requestDetail = reqModel.requestdetail ?? 'ไม่มีรายละเอียดเพิ่มเติม';
    String pickupAddress = reqModel.pickuplocation?.address ?? 'ไม่ระบุจุดรับ';
    String dropoffAddress =
        reqModel.dropofflocation?.address ?? 'ไม่ระบุจุดส่ง';

    String countdownText = '';
    if (reqModel.appointmentdate != null) {
      final now = DateTime.now();
      final appt = reqModel.appointmentdate!;
      final difference = appt.difference(now).inDays;
      if (difference > 0) {
        countdownText = 'อีก $difference วัน';
      } else if (difference == 0) {
        countdownText = 'วันนี้';
      } else {
        countdownText = 'ผ่านมาแล้ว';
      }
    }

    String statusText = 'อยู่ระหว่างรอ';
    Color statusColor = const Color(0xFFFF8C00);
    Color statusBgColor = const Color(0xFFFFF3E0);

    if (currentStatus == RequestStatus.acceptedEarly ||
        currentStatus == RequestStatus.acceptedReady) {
      statusText = 'ตอบรับแล้ว';
      statusColor = const Color(0xFF00B14F);
      statusBgColor = const Color(0xFFB9F6CA);
    } else if (currentStatus == RequestStatus.completed) {
      statusText = 'สิ้นสุดบริการ';
      statusColor = const Color(0xFF00B14F);
      statusBgColor = const Color(0xFFB9F6CA);
    } else if (currentStatus == RequestStatus.cancelled) {
      statusText = 'ยกเลิกบริการ';
      statusColor = const Color(0xFFF44336);
      statusBgColor = const Color(0xFFFFEBEE);
    }

    List<String> dateParts = widget.requestData.date.split('·');
    String dateOnly = dateParts[0].trim();
    String timeOnly = dateParts.length > 1 ? dateParts[1].trim() : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4EDFB),
      appBar: const CustomHeader(title: 'รายละเอียดคำขอ', showBackButton: true),
      body: Column(
        children: [
          if (currentStatus == RequestStatus.acceptedEarly)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFEBEE),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                '* สามารถเริ่มส่งสถานะการแจ้งเตือนได้เมื่อถึงระยะเวลาทำการ *',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF44336),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.requestData.serviceName,
                                maxLines:
                                    2, // 🌟 เผื่อชื่อ รพ. ยาว ให้ลงมาได้ 2 บรรทัด
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E5F5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.requestData.category,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFA052BE),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '# ${widget.requestData.id}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _buildSectionTitle('ข้อมูลผู้ป่วย'),
                  _buildSectionBox(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: patImage.length > 100
                                  ? MemoryImage(base64Decode(patImage))
                                  : null,
                              child: patImage.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patName, // 🌟 เปลี่ยนมาใช้ตัวแปรนี้แทน
                                    maxLines: 1, // 🌟 กันชื่อยาวทะลุจอ
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'อายุ $patAge · เพศ$patGender · $patMobility',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize
                                          .min, // 🌟 หดกรอบให้พอดีข้อความ
                                      children: [
                                        const Icon(
                                          Icons.favorite,
                                          color: Colors.orange,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        // 🌟 ใช้ Flexible เพื่อให้ข้อความตัดจบเมื่อยาวเกิน โดยกรอบไม่แตก
                                        Flexible(
                                          child: Text(
                                            patDisease,
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 18,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'เบอร์ผู้ป่วย',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              // 🌟 ใช้ Expanded ครอบ
                              child: Text(
                                patPhone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _buildSectionTitle('ญาติ'),
                  _buildSectionBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              // 🌟 ใช้ Expanded ครอบไว้เผื่อชื่อญาติยาวมาก
                              child: Text(
                                relName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                relRelation,
                                style: const TextStyle(
                                  color: Color(0xFFA052BE),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 18,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'เบอร์โทร',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              relPhone,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LINE ID',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              // 🌟 ใช้ Expanded ครอบ
                              child: Text(
                                relLine,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _buildSectionTitle('วันและเวลานัดหมาย'),
                  _buildSectionBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // จัดให้อยู่กึ่งกลางแนวตั้ง
                      children: [
                        // 🌟 1. ใช้ Expanded ครอบฝั่งซ้าย (ไอคอน + วันที่) ทั้งหมด
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E5F5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFFA052BE),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 🌟 2. ใช้ Expanded ครอบ Column ตัวหนังสืออีกชั้น
                              // เพื่อให้มันยอมหดตัวหรือตัดคำ (...) ถ้ายาวเกิน
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateOnly,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines:
                                          2, // เผื่อยาวไปให้ลงมาบรรทัด 2 ได้
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'เวลา $timeOnly',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ), // 🌟 เว้นระยะห่างนิดนึงไม่ให้ชิดกันเกินไป
                        // 🌟 3. ฝั่งขวา (ป้ายเวลานับถอยหลัง) ปล่อยไว้เหมือนเดิม มันจะไม่โดนดันตกจอแล้วครับ
                        if (currentStatus != RequestStatus.completed &&
                            currentStatus != RequestStatus.cancelled &&
                            countdownText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min, // ให้กล่องหดพอดีข้อความ
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: Color(0xFFFF8C00),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  countdownText,
                                  style: const TextStyle(
                                    color: Color(0xFFFF8C00),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  _buildSectionTitle('จุดรับจุดส่ง'),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenMapPage(
                                  pointA: pointA,
                                  pointB: pointB,
                                  routePoints: routePoints,
                                  distanceText:
                                      _distanceText, // 🌟 ส่งข้อมูลระยะทางไปหน้าแผนที่ใหญ่
                                  maptilerApiKey: maptilerApiKey,
                                ),
                              ),
                            );
                          },
                          child: SizedBox(
                            height: 180,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  IgnorePointer(
                                    child: FlutterMap(
                                      options: MapOptions(
                                        initialCameraFit: CameraFit.bounds(
                                          bounds: LatLngBounds.fromPoints([
                                            pointA,
                                            pointB,
                                          ]),
                                          padding: const EdgeInsets.all(
                                            40.0,
                                          ), // ระยะเว้นขอบไม่ให้หมุดชิดขอบจอเกินไป
                                        ),
                                        interactionOptions:
                                            const InteractionOptions(
                                              flags: InteractiveFlag.none,
                                            ),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$maptilerApiKey',
                                          userAgentPackageName:
                                              'com.example.app',
                                        ),
                                        PolylineLayer(
                                          polylines: [
                                            Polyline(
                                              points: routePoints,
                                              color: Colors.blue.shade400,
                                              strokeWidth: 4.0,
                                            ),
                                          ],
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: pointA,
                                              width: 28,
                                              height: 28,
                                              alignment: Alignment.center,
                                              child: _buildMapPin(
                                                'A',
                                                const Color(0xFFA052BE),
                                              ), // 🌟 เปลี่ยนหมุด A เป็นสีม่วง
                                            ),
                                            Marker(
                                              point: pointB,
                                              width: 28,
                                              height: 28,
                                              alignment: Alignment.center,
                                              child: _buildMapPin(
                                                'B',
                                                Colors.black,
                                              ), // 🌟 เปลี่ยนหมุด B เป็นสีดำ
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 🌟 3. ป้ายบอกระยะทาง มุมขวาบนของแผนที่เล็ก
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _distanceText,
                                        style: const TextStyle(
                                          color: Color(0xFFA052BE),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // ปุ่มขยาย
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.zoom_out_map,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'กดเพื่อขยายแผนที่',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
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
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHollowCircle(const Color(0xFFA052BE)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'A จุดรับ',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFA052BE),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          pickupAddress,
                                          maxLines:
                                              2, // 🌟 ให้ที่อยู่ยาวสุดได้ 2 บรรทัด
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                margin: const EdgeInsets.only(
                                  left: 7,
                                  top: 4,
                                  bottom: 4,
                                ),
                                height: 20,
                                width: 2,
                                color: Colors.grey.shade300,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHollowCircle(Colors.black),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'B จุดส่ง',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          dropoffAddress,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSectionTitle('รายละเอียดคำร้อง'),
                  _buildSectionBox(
                    child: Text(
                      requestDetail,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  _buildBottomActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
        uid: widget.uid,
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    if (currentStatus == RequestStatus.completed ||
        currentStatus == RequestStatus.cancelled)
      return const SizedBox.shrink();

    if (currentStatus == RequestStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _showConfirmationDialog(true),
              child: const Text(
                'ตกลง',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _showConfirmationDialog(false),
              child: const Text(
                'ปฏิเสธ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    bool isReady = (currentStatus == RequestStatus.acceptedReady);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isReady
              ? const Color(0xFFA052BE)
              : Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isReady
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddStatusNotificationPage(
                      requestData: widget.requestData,
                      uid: widget.uid,
                    ),
                  ),
                );
              }
            : null,
        child: const Text(
          'ส่งการแจ้งเตือน',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFA052BE),
        ),
      ),
    );
  }

  Widget _buildSectionBox({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildHollowCircle(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3.5),
      ),
    );
  }

  Widget _buildMapPin(String label, Color color) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 22, // 🌟 ขนาดตัวหนังสือสำหรับแผนที่เล็ก
          fontWeight: FontWeight.w900, // หนาพิเศษ
          shadows: const [
            // 🌟 เงาสีขาวช่วยให้ตัวหนังสือไม่จมไปกับพื้นหลังแผนที่
            Shadow(color: Colors.white, blurRadius: 6, offset: Offset(0, 0)),
            Shadow(color: Colors.white, blurRadius: 6, offset: Offset(0, 0)),
            Shadow(color: Colors.white, blurRadius: 6, offset: Offset(0, 0)),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 🌟 หน้าต่างใหม่สำหรับขยายแผนที่
// =========================================================
class FullScreenMapPage extends StatelessWidget {
  final LatLng pointA;
  final LatLng pointB;
  final List<LatLng> routePoints;
  final String distanceText; // 🌟 4. ตัวรับข้อมูลระยะทาง
  final String maptilerApiKey;

  const FullScreenMapPage({
    super.key,
    required this.pointA,
    required this.pointB,
    required this.routePoints,
    required this.distanceText,
    required this.maptilerApiKey,
  });

  @override
  Widget build(BuildContext context) {
    LatLng centerPoint = LatLng(
      (pointA.latitude + pointB.latitude) / 2,
      (pointA.longitude + pointB.longitude) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'แผนที่เส้นทาง',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFA052BE),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // 🌟 ใช้ Stack ครอบเพื่อแสดงป้ายระยะทางทับบนแผนที่ใหญ่
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints([pointA, pointB]),
                padding: const EdgeInsets.all(
                  60.0,
                ), // เผื่อขอบหน้าจอใหญ่เยอะหน่อย
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$maptilerApiKey',
                userAgentPackageName: 'com.example.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: Colors.blue.shade400,
                    strokeWidth: 5.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: pointA,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: _buildLargeMapPin(
                      'A',
                      const Color(0xFFA052BE),
                    ), // 🌟 หมุด A สีม่วง
                  ),
                  Marker(
                    point: pointB,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: _buildLargeMapPin(
                      'B',
                      Colors.black,
                    ), // 🌟 หมุด B สีดำ
                  ),
                ],
              ),
            ],
          ),

          // 🌟 5. ป้ายแสดงระยะทางบนมุมซ้ายบนของแผนที่ใหญ่
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_car,
                      color: Color(0xFFA052BE),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      distanceText,
                      style: const TextStyle(
                        color: Color(0xFFA052BE),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeMapPin(String label, Color color) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize:
              28, // 🌟 ขนาดตัวหนังสือสำหรับแผนที่ใหญ่ (ใหญ่ขึ้นให้เห็นชัด)
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 8, offset: Offset(0, 0)),
            Shadow(color: Colors.white, blurRadius: 8, offset: Offset(0, 0)),
            Shadow(color: Colors.white, blurRadius: 8, offset: Offset(0, 0)),
          ],
        ),
      ),
    );
  }
}
