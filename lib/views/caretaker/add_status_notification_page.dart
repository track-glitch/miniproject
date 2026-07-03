import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/custom_header_nav.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../caretaker/edit_profile_page.dart';

// 🌟 Import โมเดล RequestCard เพื่อรับข้อมูลมาจากหน้าก่อนหน้า
import '../../views/caretaker/list_relative_request_page.dart';

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
  int _bottomNavIndex = 1; // Active ที่ Tab การแจ้งเตือน

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });

    // เช็คเลขให้ตรงกับลำดับใหม่
    if (index == 0) {
      // ไปหน้าแรก (บ้าน)
    } else if (index == 1) {
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => const ListRelativeRequestPage(),
      //   ),
      // );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const EditProfilePage(uid: 'E7TZ3fTabuY8jEgzH81wDAE5LSS2'),
        ),
      );
    }
  }

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

  // 🌟 ตัวแปรเก็บว่าตอนนี้อยู่ที่สเต็ปไหน (0 = ยังไม่เริ่ม, 4 = เสร็จหมดแล้ว)
  int _currentStepIndex = 0;

  // ตัวแปรสำหรับค่าที่ถูกเลือกใน Dropdown
  String? _selectedStatus;

  // พิกัดแผนที่ (สมมติ)
  LatLng pointA = const LatLng(18.8055, 98.9950);
  LatLng pointB = const LatLng(18.8236, 99.0068);
  final LatLng currentLocation = const LatLng(
    18.8100,
    99.0000,
  ); // จุดเขียว (สมมติว่าอยู่ตรงกลาง)
  final String maptilerApiKey = 'JCT1H6ehzlMaKZyrC5mp';

  @override
  void initState() {
    super.initState();
    // เซ็ตค่าเริ่มต้นของ Dropdown ให้ตรงกับสเต็ปปัจจุบัน
    if (_currentStepIndex < _statusList.length) {
      _selectedStatus = _statusList[_currentStepIndex];
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
  }

  // ฟังก์ชันเมื่อกดปุ่ม "เพิ่มสถานะ"
  void _submitStatus() {
    if (_selectedStatus != null && _currentStepIndex < _statusList.length) {
      // 1. ส่งข้อมูลขึ้น Database หรือ API ตรงนี้
      // ...

      // 2. แสดงแจ้งเตือนความสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งสถานะ "$_selectedStatus" เรียบร้อยแล้ว!'),
          backgroundColor: Colors.green,
        ),
      );

      // 3. ขยับไปยังสเต็ปถัดไป
      setState(() {
        _currentStepIndex++;
        // อัปเดต Dropdown ให้เลือกสเต็ปถัดไปอัตโนมัติ
        if (_currentStepIndex < _statusList.length) {
          _selectedStatus = _statusList[_currentStepIndex];
        } else {
          _selectedStatus = null; // เสร็จครบ 4 สเต็ป
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // แยกวันที่และเวลา
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
            // 🌟 1. กล่องข้อมูลบริการปัจจุบัน (สีขาวขอบมน)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade400, width: 1),
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

            // 🌟 2. แผนที่ตำแหน่งปัจจุบัน
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
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ), // ขอบขาวหนาๆ ตามแบบ
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: currentLocation,
                    initialZoom: 14.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ), // ล็อคแผนที่
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
                          points: [pointA, currentLocation, pointB],
                          color: Colors.blue.shade400,
                          strokeWidth: 5.0,
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
                        ), // สีฟ้า
                        Marker(
                          point: pointB,
                          width: 30,
                          height: 30,
                          child: _buildMapPin('B', Colors.grey),
                        ),
                        // 🟢 หมุดเขียว (ตำแหน่งปัจจุบัน)
                        Marker(
                          point: currentLocation,
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
            ),
            const SizedBox(height: 20),

            // 🌟 3. รายละเอียดการแจ้งเตือน (Dropdown)
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
                  hint: const Text('เลือกสถานะ'),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                    size: 30,
                  ),
                  items: _statusList.asMap().entries.map((entry) {
                    int index = entry.key;
                    String status = entry.value;

                    // 🌟 ล็อค Logic การเลือกสถานะ
                    // อนุญาตให้เลือกได้เฉพาะ Status ที่ตรงกับ _currentStepIndex เท่านั้น
                    bool isEnabled = (index == _currentStepIndex);

                    return DropdownMenuItem<String>(
                      value: status,
                      enabled: isEnabled, // ถ้าเป็น false จะกดไม่ได้
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isEnabled
                              ? FontWeight.bold
                              : FontWeight.normal,
                          // เปลี่ยนสีเทา ถ้าถูกส่งไปแล้ว หรือยังไม่ถึงคิว
                          color: isEnabled
                              ? Colors.black
                              : Colors.grey.shade400,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 🌟 4. ปุ่มเพิ่มสถานะ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // ถ้าเสร็จครบ 4 ขั้นตอน ให้ปุ่มเป็นสีเทาและกดไม่ได้
                  backgroundColor: _currentStepIndex < _statusList.length
                      ? const Color(0xFFA052BE)
                      : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _currentStepIndex < _statusList.length
                    ? _submitStatus
                    : null,
                child: Text(
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  // Helper สำหรับสร้างบรรทัดข้อมูลในกล่อง
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

  // Helper สร้างหมุด A, B เล็กๆ
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
