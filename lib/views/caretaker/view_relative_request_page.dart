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
  int _bottomNavIndex = 0;
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ListRelativeRequestPage(uid: widget.uid),
        ),
      );
    } else if (index == 1) {
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
                            widget.requestData.relativeUid,
                            widget.requestData.id,
                            newStatus,
                          );

                          setState(() {
                            if (isAccept) {
                              // 🌟 1. เช็คเวลานัดหมายว่าถึงหรือยัง ณ ตอนที่กดอนุมัติ
                              bool isTimeArrived = false;
                              final appt = widget
                                  .requestData
                                  .requestModel
                                  .appointmentdate;
                              if (appt != null) {
                                // ถ้าเวลาปัจจุบัน เลยเวลานัด หรือถึงเวลานัดพอดี
                                if (DateTime.now().isAfter(appt) ||
                                    DateTime.now().isAtSameMomentAs(appt)) {
                                  isTimeArrived = true;
                                }
                              }

                              // 🌟 2. ถ้าถึงเวลาแล้ว ให้สถานะเป็น acceptedReady เลย (ปุ่มกดได้ทันที แจ้งเตือนสีแดงหายไป)
                              // ถ้ายังไม่ถึง ให้เป็น acceptedEarly
                              currentStatus =
                                  isTimeArrived || widget.requestData.hasAlert
                                  ? RequestStatus.acceptedReady
                                  : RequestStatus.acceptedEarly;
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

    // 🌟 1. ดึงชุดสีเดียวกับหน้า List มาใช้
    String statusText = 'อยู่ระหว่างรอ';
    Color statusColor = Colors.grey;
    Color statusBgColor = Colors.grey.shade200;

    switch (currentStatus) {
      case RequestStatus.pending:
        statusColor = const Color(0xFF757BFF); // สีน้ำเงิน
        statusBgColor = const Color(0xFFB4BEFF).withOpacity(0.3);
        statusText = 'รอตอบรับ';
        break;
      case RequestStatus.acceptedEarly:
      case RequestStatus.acceptedReady:
        statusColor = const Color(0xFF00C853); // สีเขียว
        statusBgColor = const Color(0xFFB9F6CA);
        statusText = 'ตอบรับแล้ว';
        break;
      case RequestStatus.completed:
        statusColor = const Color(0xFF00B14F);
        statusBgColor = const Color(0xFFB9F6CA);
        statusText = 'สิ้นสุดบริการ';
        break;
      case RequestStatus.cancelled:
        statusColor = const Color(0xFFFF5C5C); // สีแดง
        statusBgColor = const Color(0xFFFFB6B6).withOpacity(0.3);
        statusText = 'ยกเลิกบริการ';
        break;
      default:
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.shade200;
        statusText = 'ไม่ทราบสถานะ';
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
                  // 🌟 2. ข้อมูลหลัก (Header) คงโครงสร้างเดิม แต่เปลี่ยนสี
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  // 🌟 เอา const ออก
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor, // 🌟 ใช้สีเดียวกับสถานะ
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
                                color: statusBgColor, // 🌟 สีพื้นหลังป้าย
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor,
                                ), // 🌟 สีขอบป้าย
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor, // 🌟 สีตัวหนังสือป้าย
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

                  // 🌟 2. รายละเอียดคำร้อง (ย้ายมาไว้ด้านบน และเน้นสีพื้นหลังให้ชัดเจน)
                  _buildSectionTitle('รายละเอียดคำร้อง (งานที่ต้องทำ)'),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // สีเหลืองนวลให้สะดุดตา
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD54F),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      requestDetail,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // 🌟 3. วันและเวลานัดหมาย
                  _buildSectionTitle('วันและเวลานัดหมาย'),
                  _buildSectionBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                                      maxLines: 2,
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
                        const SizedBox(width: 8),
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
                              mainAxisSize: MainAxisSize.min,
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

                  // 🌟 4. จุดรับจุดส่ง และ แผนที่
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
                                  distanceText: _distanceText,
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
                                          padding: const EdgeInsets.all(40.0),
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
                                              width: 32,
                                              height: 32,
                                              alignment: Alignment.center,
                                              // 🌟 เปลี่ยนหมุด A ให้เป็นสีฟ้า
                                              child: _buildMapPin(
                                                'A',
                                                const Color(0xFF2196F3),
                                              ),
                                            ),
                                            Marker(
                                              point: pointB,
                                              width: 32,
                                              height: 32,
                                              alignment: Alignment.center,
                                              // 🌟 เปลี่ยนหมุด B ให้เป็นสีแดง
                                              child: _buildMapPin(
                                                'B',
                                                const Color(0xFFF44336),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
                                  // 🌟 ปรับสีวงกลมให้ตรงกับหมุดในแผนที่
                                  _buildHollowCircle(const Color(0xFF2196F3)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'A จุดรับ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF2196F3),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          pickupAddress,
                                          maxLines: 2,
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
                                  // 🌟 ปรับสีวงกลมให้ตรงกับหมุดในแผนที่
                                  _buildHollowCircle(const Color(0xFFF44336)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'B จุดส่ง',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFFF44336),
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

                  // 🌟 5. ข้อมูลผู้ป่วย
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
                                    patName,
                                    maxLines: 1,
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
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.favorite,
                                          color: Colors.orange,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
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

                  // 🌟 6. ข้อมูลญาติ (ย้ายมาล่างสุด)
                  _buildSectionTitle('ข้อมูลญาติผู้ติดต่อ'),
                  _buildSectionBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
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
        currentStatus == RequestStatus.cancelled) {
      return const SizedBox.shrink();
    }

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
    // 🌟 เปลี่ยนจากการแสดงเงาเฉยๆ เป็นกรอบวงกลมสีสันสวยงามคล้ายหมุด
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// 🌟 อย่าลืมอัปเดต FullScreenMapPage ด้านล่างนี้ด้วยนะครับ
class FullScreenMapPage extends StatelessWidget {
  final LatLng pointA;
  final LatLng pointB;
  final List<LatLng> routePoints;
  final String distanceText;
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
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints([pointA, pointB]),
                padding: const EdgeInsets.all(60.0),
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
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: _buildLargeMapPin(
                      'A',
                      const Color(0xFF2196F3),
                    ), // 🌟 สีฟ้า
                  ),
                  Marker(
                    point: pointB,
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: _buildLargeMapPin(
                      'B',
                      const Color(0xFFF44336),
                    ), // 🌟 สีแดง
                  ),
                ],
              ),
            ],
          ),
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
    // 🌟 เปลี่ยนหมุดแผนที่ใหญ่ให้เป็นวงกลมสวยๆ เหมือนกัน
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3.5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
