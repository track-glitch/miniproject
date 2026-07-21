import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:miniproject/views/caretaker/add_doctor_advice_page.dart';
import 'dart:async';
import 'dart:convert'; // 🌟 เพิ่ม import
import 'package:http/http.dart' as http; // 🌟 เพิ่ม import

import '../../widgets/custom_header_nav.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../caretaker/edit_profile_page.dart';
import '../../views/caretaker/list_relative_request_page.dart';
import '../../services/caretaker_service.dart';

class AddStatusNotificationPage extends StatefulWidget {
  final RequestCard requestData;
  final String uid;

  const AddStatusNotificationPage({
    super.key,
    required this.requestData,
    required this.uid,
  });

  @override
  State<AddStatusNotificationPage> createState() =>
      _AddStatusNotificationPageState();
}

class _AddStatusNotificationPageState extends State<AddStatusNotificationPage> {
  int _bottomNavIndex = 1;
  final CaretakerService _service = CaretakerService();

  final List<String> _statusList = [
    'กำลังเดินทางไปรับ',
    'ถึงจุดรับผู้ป่วย',
    'กำลังเดินทางไปโรงพยาบาล',
    'ถึงโรงพยาบาล',
    'รอคิวพบแพทย์',
    'กำลังรักษา',
    'ตรวจรักษาเสร็จสิ้น',
    'กำลังเดินทางกลับ',
    'ถึงจุดหมายปลายทาง',
    'เสร็จสิ้นการให้บริการ',
  ];

  bool _isLoading = true;
  bool _hasStarted = false;
  int _currentStepIndex = 0;
  String? _selectedStatus;

  LatLng? _currentLocation;
  List<LatLng> _routePoints = []; // 🌟 เก็บจุดวาดเส้นถนนจริง
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _trackingTimer; // 🌟 Timer สำหรับอัปเดตทุก 10 วิ

  LatLng pointA = const LatLng(18.8055, 98.9950);
  LatLng pointB = const LatLng(18.8236, 99.0068);
  final String maptilerApiKey = 'JCT1H6ehzlMaKZyrC5mp';

  // 🌟 ฟังก์ชันหาว่าตอนนี้อยู่ในสถานะไหน
  String get _activeStatus => _currentStepIndex > 0
      ? _statusList[_currentStepIndex - 1]
      : 'ยังไม่เริ่ม';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
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

    List<Map<dynamic, dynamic>> existingNotifs = await _service
        .getNotifications(
          widget.requestData.relativeUid,
          widget.requestData.id,
        );

    _currentStepIndex = existingNotifs.length;

    if (_currentStepIndex > 0) {
      _hasStarted = true;
      await _startLocationTracking();
    }

    if (_currentStepIndex < _statusList.length) {
      _selectedStatus = _statusList[_currentStepIndex];
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 🌟 ฟังก์ชันตัวช่วยสำหรับคำนวณว่าตอนนี้ต้องลากเส้นไปหาหมุด A หรือ B
  Future<void> _updateRouteTarget() async {
    if (_currentLocation == null) return;

    LatLng? targetPoint;
    if (['กำลังเดินทางไปรับ', 'กำลังเดินทางกลับ'].contains(_activeStatus)) {
      targetPoint = pointA; // ลากเส้นเป้าหมายไปที่จุดรับ (A)
    } else if (_activeStatus == 'กำลังเดินทางไปโรงพยาบาล') {
      targetPoint = pointB; // ลากเส้นเป้าหมายไปที่โรงพยาบาล (B)
    }

    // ถ้ามีจุดหมาย ให้เรียก API ลากเส้นทาง
    if (targetPoint != null) {
      await _fetchRoute(_currentLocation!, targetPoint);
    }
  }

  // 🌟 ดึงเส้นทางจากถนนจริง (อัปเดตให้เสถียรและเร็วขึ้น)
  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    try {
      // 🌟 1. เปลี่ยนมาใช้ Server หลักของ OSRM ที่เสถียรที่สุด (รองรับ HTTPS)
      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson';

      // 🌟 2. แนบ Header (User-Agent) เพื่อไม่ให้ Server มองว่าเราเป็น Bot และบล็อกการขอข้อมูล
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'MiniProjectApp/1.0 (Flutter Mobile App)',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 10),
          ); // 🌟 3. ตั้งเวลา Time-out ป้องกันแอปรอนานเกินไป

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List coords = data['routes'][0]['geometry']['coordinates'];
          if (mounted) {
            setState(() {
              // ล้างเส้นเก่าทิ้ง แล้ววาดเส้นถนนจริงใหม่
              _routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
            });
          }
        }
      } else {
        print('OSRM API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  // 🌟 ปรับให้ดึงเส้นทางแค่ครั้งแรก และอัปเดตแค่ตำแหน่งพิกัดใน Timer
  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // 1. หาตำแหน่งเริ่มต้น แล้ววาดเส้นถนน "แค่ครั้งเดียว" ตอนเปิดจอ
    Position initialPos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(initialPos.latitude, initialPos.longitude);
      });
      await _updateRouteTarget(); // 🌟 วาดเส้นทางครั้งแรก
    }

    // 2. ดักจับพิกัดให้หมุดขยับ (รันอยู่เบื้องหลัง)
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // ขยับ 5 เมตรถึงจะอัปเดตพิกัดบนจอ
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(
              () => _currentLocation = LatLng(
                position.latitude,
                position.longitude,
              ),
            );
          }
        });

    // 3. 🌟 ส่งพิกัดขึ้น Firebase ทุก 10 วินาที (ไม่มีการเรียก API วาดเส้นทางตรงนี้แล้ว!)
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_currentLocation != null) {
        // อัปเดตแค่ตำแหน่ง GPS ลงฐานข้อมูลเพื่อให้ญาติดู
        await _service.updateRealtimeLocation(
          widget.requestData.relativeUid,
          widget.requestData.id,
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        );
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _trackingTimer?.cancel(); // 🌟 อย่าลืมล้าง Timer ทิ้งตอนออกหน้าจอ
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() => _bottomNavIndex = index);
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfilePage(uid: widget.uid),
        ),
      );
    }
  }

  void _submitStatus() async {
    if (_isLoading) return;

    if (_selectedStatus != null && _currentStepIndex < _statusList.length) {
      setState(() => _isLoading = true);

      try {
        if (!_hasStarted) await _startLocationTracking();

        await _service.addStatusNotification(
          relativeUid: widget.requestData.relativeUid,
          requestId: widget.requestData.id,
          status: _selectedStatus!,
          lat: _currentLocation?.latitude,
          lng: _currentLocation?.longitude,
        );

        if (_selectedStatus == 'เสร็จสิ้นการให้บริการ') {
          await _service.updateRequestStatus(
            widget.requestData.relativeUid,
            widget.requestData.id,
            'pending_advice',
          );
          _positionStreamSubscription?.cancel();
          _trackingTimer?.cancel();

          List<String> dateParts = widget.requestData.date.split('·');
          String dateOnly = dateParts[0].trim();
          String timeOnly = dateParts.length > 1 ? dateParts[1].trim() : '';

          Map<String, dynamic> reqInfo = {
            'patientName': widget.requestData.patient,
            'dateTime': '$dateOnly $timeOnly',
            'hospital': widget.requestData.serviceName,
            'department': widget.requestData.category,
          };

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AddDoctorAdvicePage(
                relativeUid: widget.requestData.relativeUid,
                requestId: widget.requestData.id,
                requestInfo: reqInfo,
              ),
            ),
          );
          return;
        }

        setState(() {
          _hasStarted = true;
          _currentStepIndex++;
          if (_currentStepIndex < _statusList.length) {
            _selectedStatus = _statusList[_currentStepIndex];
          } else {
            _selectedStatus = null;
          }
        });

        // 🌟 รีเฟรชเส้นทางทันทีเมื่อเปลี่ยนสถานะ โดยไม่ต้องรอ 10 วิ
        if (_currentLocation != null) {
          LatLng? targetPoint;
          if ([
            'กำลังเดินทางไปรับ',
            'กำลังเดินทางกลับ',
          ].contains(_activeStatus)) {
            targetPoint = pointA;
          } else if (_activeStatus == 'กำลังเดินทางไปโรงพยาบาล') {
            targetPoint = pointB;
          }
          if (targetPoint != null) {
            await _fetchRoute(_currentLocation!, targetPoint);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งสถานะสำเร็จแล้ว!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print("Error submitting status: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> dateParts = widget.requestData.date.split('·');
    String dateOnly = dateParts[0].trim();
    String timeOnly = dateParts.length > 1 ? dateParts[1].trim() : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4EDFB),
      appBar: const CustomHeader(
        title: 'ส่งสถานะการแจ้งเตือน',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ข้อมูลบริการปัจจุบัน',
                        style: TextStyle(
                          color: Color(0xFF7D3C98),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        widget.requestData.id,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'ผู้ป่วย:',
                    widget.requestData.patient,
                    isBold: true,
                  ),
                  _buildInfoRow('วัน/เวลา:', '$dateOnly  $timeOnly'),
                  _buildInfoRow('สถานที่:', widget.requestData.serviceName),
                  _buildInfoRow('แผนก:', widget.requestData.category),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _hasStarted ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ระบบติดตามสถานะ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMapSection(),
            const SizedBox(height: 20),

            const Text(
              'รายละเอียดของการแจ้งเตือน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black87),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedStatus,
                  hint: const Text(
                    'เสร็จสิ้นทุกสถานะแล้ว',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                    size: 30,
                  ),
                  items: _statusList
                      .asMap()
                      .entries
                      .where((entry) => entry.key >= _currentStepIndex)
                      .map((entry) {
                        int index = entry.key;
                        String status = entry.value;
                        bool isEnabled = (index == _currentStepIndex);

                        return DropdownMenuItem<String>(
                          value: status,
                          enabled: isEnabled,
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isEnabled
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isEnabled
                                  ? Colors.black
                                  : Colors.grey.shade400,
                            ),
                          ),
                        );
                      })
                      .toList(),
                  onChanged: (String? newValue) =>
                      setState(() => _selectedStatus = newValue),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (_currentStepIndex < _statusList.length && !_isLoading)
                      ? const Color(0xFFA052BE)
                      : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    (_currentStepIndex < _statusList.length && !_isLoading)
                    ? _submitStatus
                    : null,
                child: _isLoading && _currentStepIndex < _statusList.length
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _currentStepIndex < _statusList.length
                            ? 'เพิ่มสถานะ'
                            : 'เสร็จสิ้นการแจ้งเตือนทั้งหมด',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    if (!_hasStarted) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'ยังไม่ได้เริ่มต้นการเดินทาง',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'กดส่งสถานะแรกเพื่อเปิดระบบนำทาง',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // 🌟 ถ้อยู่ในกระบวนการรักษาที่โรงพยาบาล ให้ซ่อนแผนที่และโชว์ UI นี้แทน
    if ([
      'ถึงโรงพยาบาล',
      'รอคิวพบแพทย์',
      'กำลังรักษา',
      'ตรวจรักษาเสร็จสิ้น',
    ].contains(_activeStatus)) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_hospital_rounded,
              size: 50,
              color: Color(0xFFFFB300),
            ),
            const SizedBox(height: 12),
            Text(
              _activeStatus,
              style: const TextStyle(
                color: Color(0xFFF57F17),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ผู้ป่วยกำลังอยู่ระหว่างดำเนินการที่โรงพยาบาล',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_currentLocation == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFA052BE)),
              SizedBox(height: 12),
              Text(
                'กำลังค้นหาพิกัด GPS ของคุณ...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // 🌟 หาจุดหมายปลายทางตามสถานะ เพื่อเอาไปปักหมุด
    LatLng? targetMarker;
    String targetLabel = '';
    Color targetColor = Colors.grey;
    if (['กำลังเดินทางไปรับ', 'กำลังเดินทางกลับ'].contains(_activeStatus)) {
      targetMarker = pointA;
      targetLabel = 'A';
      targetColor = const Color(0xFF2196F3);
    } else if (_activeStatus == 'กำลังเดินทางไปโรงพยาบาล') {
      targetMarker = pointB;
      targetLabel = 'B';
      targetColor = const Color(0xFFF44336);
    }

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _currentLocation!,
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all, // 🌟 เปิดให้เลื่อนแผนที่ดูเส้นทางได้
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
                  points: _routePoints.isNotEmpty
                      ? _routePoints
                      : [
                          _currentLocation!,
                          targetMarker ?? _currentLocation!,
                        ], // ถ้าโหลดไม่ทันให้ตีเส้นตรงไปก่อน
                  color: Colors.blue.shade400,
                  strokeWidth: 5.0,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                // หมุดเป้าหมายที่จะไป
                if (targetMarker != null)
                  Marker(
                    point: targetMarker,
                    width: 34,
                    height: 34,
                    child: _buildMapPin(targetLabel, targetColor),
                  ),
                // หมุดรถปัจจุบัน (อาสาสมัคร)
                Marker(
                  point: _currentLocation!,
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                      const Positioned(
                        top: 0,
                        child: Text(
                          'คุณ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.white, blurRadius: 2),
                            ],
                          ),
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
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(String label, Color color) {
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
