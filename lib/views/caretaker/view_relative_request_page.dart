import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart'; // 🌟 เพิ่ม import Firebase

import '../../widgets/custom_header_nav.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../caretaker/add_status_notification_page.dart';
import '../../views/caretaker/list_relative_request_page.dart';
import '../caretaker/edit_profile_page.dart';
import '../../services/caretaker_service.dart';

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

  // ── 🎨 ชุดสีหลักควบคุมธีม ─────────────────────────────────────────
  final Color primaryPurple = const Color(0xFF8763E6);
  final Color darkPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color lightPurple = const Color(0xFFECE2FE);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color borderColor = const Color(0xFFD3C2F0);
  final Color sectionBgColor = const Color(0xFFF8F5FF);

  LatLng pointA = const LatLng(18.8055, 98.9950);
  LatLng pointB = const LatLng(18.8236, 99.0068);
  List<LatLng> routePoints = [];

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

  Future<void> _getRoute() async {
    try {
      final url =
          'http://router.project-osrm.org/route/v1/driving/${pointA.longitude},${pointA.latitude};${pointB.longitude},${pointB.latitude}?geometries=geojson';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List coords = data['routes'][0]['geometry']['coordinates'];

        final double distanceInMeters = data['routes'][0]['distance']
            .toDouble();

        setState(() {
          routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
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

  // 🌟 ฟังก์ชันเช็คคิวงานซ้ำในวันเดียวกัน[cite: 24]
  Future<bool> _checkIsBusyOnDate(DateTime requestedDate) async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login').get();
      if (snapshot.exists && snapshot.value is Map) {
        final allUsers = snapshot.value as Map;

        for (var userValue in allUsers.values) {
          if (userValue is Map &&
              userValue['Relative'] != null &&
              userValue['Relative']['Request'] != null) {
            final requests = userValue['Relative']['Request'] as Map;

            for (var reqData in requests.values) {
              if (reqData['caretakerId'] == widget.uid) {
                // เช็คเฉพาะงานของผู้ดูแลคนนี้
                String status = (reqData['requeststatus'] ?? '')
                    .toString()
                    .toLowerCase();

                // ตรวจสอบเฉพาะงานที่ตอบรับแล้ว หรือรอประเมิน
                if (status == 'accepted' || status == 'pending_advice') {
                  String dateStr = reqData['appointmentdate'] ?? '';
                  if (dateStr.isNotEmpty) {
                    DateTime apptDate = DateTime.parse(dateStr);
                    // ถ้าปี เดือน วัน ตรงกัน แสดงว่าติดคิวแล้ว
                    if (apptDate.year == requestedDate.year &&
                        apptDate.month == requestedDate.month &&
                        apptDate.day == requestedDate.day) {
                      return true; // ติดคิว
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error checking busy dates: $e");
    }
    return false; // ว่าง
  }

  void _showConfirmationDialog(bool isAccept) async {
    // 🌟 เปลี่ยนเป็น async เพื่อรอผลการเช็คคิว

    // 🌟 ถ้ายืนยันรับงาน ให้เช็คคิวก่อน[cite: 24]
    if (isAccept) {
      DateTime? requestedDate = widget.requestData.requestModel.appointmentdate;
      if (requestedDate != null) {
        // เปิดหน้าต่างโหลดรอ
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        bool isBusy = await _checkIsBusyOnDate(requestedDate);

        // ปิดหน้าต่างโหลด
        if (context.mounted) Navigator.pop(context);

        if (isBusy) {
          // ถ้าติดคิว ให้แสดง Pop-up แจ้งเตือนและหยุดการทำงาน[cite: 24]
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    'ไม่สามารถตอบรับคำขอได้',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  content: const Text(
                    'คุณมีคิวงานที่ต้องให้บริการในวันที่ระบุไว้แล้ว\nกรุณาตรวจสอบตารางงานของคุณอีกครั้ง',
                  ),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'ตกลง',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            );
          }
          return; // ออกจากฟังก์ชัน ไม่ต้องโชว์ Pop-up ยืนยัน
        }
      }
    }

    // ถ้าผ่านการเช็ค (หรือกดปฏิเสธ) ให้แสดง Pop-up ยืนยันตามปกติ[cite: 24]
    if (!mounted) return;
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
                              bool isTimeArrived = false;
                              final appt = widget
                                  .requestData
                                  .requestModel
                                  .appointmentdate;
                              if (appt != null) {
                                if (DateTime.now().isAfter(appt) ||
                                    DateTime.now().isAtSameMomentAs(appt)) {
                                  isTimeArrived = true;
                                }
                              }

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

  // 🌟 Helper สร้างกรอบ Card คุมสไตล์ธีม
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: primaryPurple.withOpacity(0.12),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  // 🌟 Helper สร้างกรอบแต่ละ Section ด้านใน
  Widget _buildSectionWrapper({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: const CustomHeader(
          title: 'รายละเอียดคำขอ',
          showBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryPurple),
              const SizedBox(height: 16),
              const Text(
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
    if (pat['birthdate'] != null && pat['birthdate'].toString().isNotEmpty) {
      String dobStr = pat['birthdate'].toString();
      try {
        if (dobStr.contains('/')) {
          List<String> parts = dobStr.split('/');
          if (parts.length == 3) {
            int birthYear = int.parse(parts[2].trim());
            if (birthYear > 2400) {
              birthYear -= 543;
            }
            patAge = '${DateTime.now().year - birthYear} ปี';
          }
        } else {
          DateTime? dob = DateTime.tryParse(dobStr);
          if (dob != null) {
            patAge = '${DateTime.now().year - dob.year} ปี';
          }
        }
      } catch (e) {
        patAge = 'ระบุอายุไม่ได้';
      }
    }
    String patGender = pat['gender'] ?? 'ไม่ระบุเพศ';

    String patPrefix = patGender == 'ชาย'
        ? 'นาย '
        : (patGender == 'หญิง' ? 'นาง ' : 'คุณ ');
    String patName =
        "$patPrefix${pat['firstname'] ?? ''} ${pat['lastname'] ?? ''}".trim();
    if (patName == 'คุณ' || patName.isEmpty) patName = 'ไม่ระบุชื่อผู้ป่วย';

    String patMobility = pat['mobility'] ?? 'ไม่ระบุ';
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

    String statusText = 'อยู่ระหว่างรอ';
    Color statusColor = Colors.grey;
    Color statusBgColor = Colors.white;

    switch (currentStatus) {
      case RequestStatus.pending:
        statusColor = const Color(0xFF757BFF);
        statusBgColor = const Color(0xFFE8EAFF);
        statusText = 'รอตอบรับ';
        break;
      case RequestStatus.acceptedEarly:
      case RequestStatus.acceptedReady:
        statusColor = primaryPurple;
        statusBgColor = lightPurple;
        statusText = 'ตอบรับแล้ว';
        break;
      case RequestStatus.completed:
        statusColor = const Color(0xFF00B14F);
        statusBgColor = const Color(0xFFE8F5E9);
        statusText = 'สิ้นสุดบริการ';
        break;
      case RequestStatus.cancelled:
        statusColor = const Color(0xFFFF5C5C);
        statusBgColor = const Color(0xFFFFEBEE);
        statusText = 'ยกเลิกบริการ';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'ไม่ทราบสถานะ';
    }

    List<String> dateParts = widget.requestData.date.split('·');
    String dateOnly = dateParts[0].trim();
    String timeOnly = dateParts.length > 1 ? dateParts[1].trim() : '';

    return Scaffold(
      backgroundColor: bgColor,
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
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🌟 ส่วนหัวฟอร์ม
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ใบคำขอรับบริการ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '#REQ-${widget.requestData.id}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF241C2B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ส่งคำขอเมื่อ: ${widget.requestData.submitDate}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor,
                                  width: 1.5,
                                ),
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
                          ],
                        ),

                        // --- Section 1: ข้อมูลบริการ ---
                        _buildSectionWrapper(
                          title: 'ข้อมูลการนัดหมาย',
                          icon: Icons.calendar_month_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildInfoField(
                                      'วันที่นัดหมาย',
                                      dateOnly,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoField(
                                      'เวลานัดหมาย',
                                      timeOnly,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildInfoField(
                                      'สถานพยาบาล',
                                      widget.requestData.serviceName,
                                      maxLines: 2,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoField(
                                      'แผนก',
                                      widget.requestData.category,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoField(
                                'รายละเอียดคำขอ',
                                requestDetail,
                                maxLines: 5,
                              ),
                            ],
                          ),
                        ),

                        // --- Section 2: ข้อมูลผู้ป่วย ---
                        _buildSectionWrapper(
                          title: 'ข้อมูลผู้ป่วย',
                          icon: Icons.person_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: lightPurple,
                                    backgroundImage: patImage.length > 100
                                        ? MemoryImage(base64Decode(patImage))
                                        : null,
                                    child: patImage.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            size: 26,
                                            color: primaryPurple,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildInfoField(
                                      'ชื่อ-นามสกุล',
                                      patName,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildInfoField('อายุ', patAge),
                                  ),
                                  Expanded(
                                    child: _buildInfoField('เพศ', patGender),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildInfoField(
                                      'โรคประจำตัว',
                                      patDisease,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoField(
                                      'สภาพร่างกาย',
                                      patMobility,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoField('เบอร์โทรศัพท์ผู้ป่วย', patPhone),
                            ],
                          ),
                        ),

                        // --- Section 3: ข้อมูลญาติผู้ติดต่อ ---
                        _buildSectionWrapper(
                          title: 'ข้อมูลญาติผู้ติดต่อ',
                          icon: Icons.family_restroom_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildInfoField(
                                      'ชื่อ-นามสกุล',
                                      relName,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoField(
                                      'ความสัมพันธ์',
                                      relRelation,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildInfoField(
                                      'เบอร์โทรศัพท์',
                                      relPhone,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoField('LINE ID', relLine),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // --- Section 4: จุดรับ-จุดส่ง ---
                        _buildSectionWrapper(
                          title: 'ข้อมูลจุดรับ-จุดส่ง',
                          icon: Icons.alt_route_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
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
                                                30.0,
                                              ),
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
                                                  width: 24,
                                                  height: 24,
                                                  child: _buildMapPin(
                                                    'A',
                                                    const Color(0xFF2196F3),
                                                  ),
                                                ),
                                                Marker(
                                                  point: pointB,
                                                  width: 24,
                                                  height: 24,
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
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'กดเพื่อดูแผนที่เต็ม',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      FullScreenMapPage(
                                                        pointA: pointA,
                                                        pointB: pointB,
                                                        routePoints:
                                                            routePoints,
                                                        distanceText:
                                                            _distanceText,
                                                        maptilerApiKey:
                                                            maptilerApiKey,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildLocationField(
                                'A',
                                const Color(0xFF2196F3),
                                ' จุดรับ',
                                pickupAddress,
                              ),
                              const SizedBox(height: 12),
                              _buildLocationField(
                                'B',
                                const Color(0xFFF44336),
                                ' จุดส่ง',
                                dropoffAddress,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoField('ระยะทางประเมิน', _distanceText),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- ส่วนปุ่มกด (อยู่นอกกรอบเอกสาร) ---
                  const SizedBox(height: 24),
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

  Widget _buildInfoField(String label, String value, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF241C2B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField(
    String letter,
    Color color,
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              letter,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF241C2B),
            height: 1.4,
          ),
        ),
      ],
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
                backgroundColor: const Color(0xFF00B14F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () => _showConfirmationDialog(true),
              child: const Text(
                'ตกลงรับงาน',
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
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFFF5C5C), width: 1.5),
                ),
                elevation: 0,
              ),
              onPressed: () => _showConfirmationDialog(false),
              child: const Text(
                'ปฏิเสธ',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFFF5C5C),
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
          backgroundColor: isReady ? primaryPurple : Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
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
          'เริ่มส่งสถานะแจ้งเตือน',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMapPin(String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

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
        backgroundColor: const Color(0xFF8763E6),
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
                    child: _buildLargeMapPin('A', const Color(0xFF2196F3)),
                  ),
                  Marker(
                    point: pointB,
                    width: 44,
                    height: 44,
                    child: _buildLargeMapPin('B', const Color(0xFFF44336)),
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
                      color: Color(0xFF8763E6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      distanceText,
                      style: const TextStyle(
                        color: Color(0xFF8763E6),
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
