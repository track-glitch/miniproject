import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:miniproject/views/caretaker/add_doctor_advice_page.dart';
import 'dart:async';

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
  StreamSubscription<Position>? _positionStreamSubscription;

  LatLng pointA = const LatLng(18.8055, 98.9950);
  LatLng pointB = const LatLng(18.8236, 99.0068);
  final String maptilerApiKey = 'JCT1H6ehzlMaKZyrC5mp';

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

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position pos = await Geolocator.getCurrentPosition();
    if (mounted)
      setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(
              () => _currentLocation = LatLng(
                position.latitude,
                position.longitude,
              ),
            );
            _service.updateRealtimeLocation(
              widget.requestData.relativeUid,
              widget.requestData.id,
              position.latitude,
              position.longitude,
            );
          }
        });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
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

        // 🌟 เมื่อถึงสถานะสุดท้าย 'เสร็จสิ้นการให้บริการ'
        if (_selectedStatus == 'เสร็จสิ้นการให้บริการ') {
          await _service.updateRequestStatus(
            widget.requestData.relativeUid,
            widget.requestData.id,
            'pending_advice', // 🚨 แก้บรรทัดนี้ จาก 'completed' เป็น 'pending_advice'
          );
          _positionStreamSubscription?.cancel(); // ปิดบริการ GPS

          // 💡 มัดรวมข้อมูลปัจจุบันส่งต่อให้หน้า AddDoctorAdvicePage โชว์บน Card ด้านบน
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
                requestInfo: reqInfo, // 🌟 ส่งข้อมูลที่แพ็คไว้ไปใช้งาน
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
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ตำแหน่งปัจจุบัน',
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
              flags: InteractiveFlag.none,
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
                  points: [pointA, _currentLocation!, pointB],
                  color: Colors.blue.shade400,
                  strokeWidth: 4.0,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pointA,
                  width: 30,
                  height: 30,
                  child: _buildMapPin('A', const Color(0xFF2196F3)),
                ),
                Marker(
                  point: pointB,
                  width: 30,
                  height: 30,
                  child: _buildMapPin('B', Colors.grey),
                ),
                Marker(
                  point: _currentLocation!,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.location_on, color: color, size: 30),
        Positioned(
          top: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
