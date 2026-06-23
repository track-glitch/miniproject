import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/custom_header_nav.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../caretaker/add_status_notification_page.dart';
import '../../views/caretaker/list_relative_request_page.dart';
import '../caretaker/edit_profile_page.dart';

enum RequestStatus {
  pending,
  acceptedEarly,
  acceptedReady,
  completed,
  cancelled,
}

class ViewRelativeRequestPage extends StatefulWidget {
  final RequestCard requestData;

  const ViewRelativeRequestPage({super.key, required this.requestData});

  @override
  State<ViewRelativeRequestPage> createState() =>
      _ViewRelativeRequestPageStage();
}

class _ViewRelativeRequestPageStage extends State<ViewRelativeRequestPage> {
  late RequestStatus currentStatus;
  int _bottomNavIndex = 1;

  final LatLng pointA = const LatLng(18.8055, 98.9950);
  final LatLng pointB = const LatLng(18.8236, 99.0068);
  final String maptilerApiKey = 'JCT1H6ehzlMaKZyrC5mp';

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });

    // เช็คเลขให้ตรงกับลำดับใหม่
    if (index == 0) {
      // ไปหน้าแรก (บ้าน)
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ListRelativeRequestPage(),
        ),
      );
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
                        onPressed: () {
                          Navigator.pop(context);
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
    String statusText = 'อยู่ระหว่างรอ'; // อิงตาม Mockup
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
      backgroundColor: const Color(0xFFF4EDFB), // พื้นหลังสีม่วงอ่อนตาม Mockup
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
                  // 🌟 1. ส่วนหัว (Header) --------------------------------------
                  // 🌟 1. ส่วนหัว (Header) --------------------------------------
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
                                  color: const Color(0xFFF3E5F5), // ม่วงอ่อน
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget
                                      .requestData
                                      .category, // นำคำว่า "แผนก" ออก เพราะใน Mockup มีแค่ชื่อแผนก
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
                  // ลบ SizedBox(height: 24) ตัวเก่าออกได้เลย เพราะ _buildSectionBox มีระยะห่างด้านล่าง (margin) ให้อยู่แล้วครับ

                  // 🌟 2. ข้อมูลผู้ป่วย (Patient Info) --------------------------------------
                  _buildSectionTitle('ข้อมูลผู้ป่วย'),
                  _buildSectionBox(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(
                                'https://i.pravatar.cc/150?img=60',
                              ), // สมมติรูปอวตาร
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.requestData.patient,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'อายุ 68 ปี · เพศหญิง · เดินได้ปกติ',
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
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          color: Colors.orange,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'โรคหัวใจ',
                                          style: TextStyle(
                                            color: Colors.orange,
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
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(
                            height: 1,
                            color: Color(0xFFEEEEEE),
                          ), // เส้นคั่น
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
                            const Text(
                              '062-345-6789',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 🌟 3. ญาติ (Relative Info) --------------------------------------
                  _buildSectionTitle('ญาติ'),
                  _buildSectionBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'นาย สมศักดิ์ รักดี',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
                              child: const Text(
                                'บุตร',
                                style: TextStyle(
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
                            const Text(
                              '081-234-5678',
                              style: TextStyle(
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
                            ), // คล้าย Line Icon
                            const SizedBox(width: 8),
                            Text(
                              'LINE ID',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'somsak_rd',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 🌟 4. วันและเวลานัดหมาย (Date & Time) --------------------------------------
                  _buildSectionTitle('วันและเวลานัดหมาย'),
                  _buildSectionBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateOnly,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
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
                          ],
                        ),
                        if (currentStatus != RequestStatus.completed &&
                            currentStatus != RequestStatus.cancelled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: Color(0xFFFF8C00),
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'อีก 4 วัน',
                                  style: TextStyle(
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

                  // 🌟 5. จุดรับจุดส่ง (Locations & Map) --------------------------------------
                  _buildSectionTitle('จุดรับจุดส่ง'),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      // ไม่มีเส้นขอบ ใช้เงาเบาๆ หรือพื้นทึบแทน
                    ),
                    child: Column(
                      children: [
                        // Map
                        SizedBox(
                          height: 180,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: const LatLng(18.8145, 99.0009),
                                initialZoom: 13.5,
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
                                      points: [
                                        pointA,
                                        const LatLng(18.8100, 99.0000),
                                        pointB,
                                      ],
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
                                      alignment: Alignment.topCenter,
                                      child: _buildMapPin(
                                        'A',
                                        const Color(0xFF2196F3),
                                      ),
                                    ),
                                    Marker(
                                      point: pointB,
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.topCenter,
                                      child: _buildMapPin(
                                        'B',
                                        Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Details
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ระยะทาง Pill
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E5F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ระยะทาง 12.4 กม.',
                                    style: TextStyle(
                                      color: Color(0xFFA052BE),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // ตำแหน่ง A
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHollowCircle(
                                    const Color(0xFFA052BE),
                                  ), // วงกลมสีม่วง
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
                                        const Text(
                                          '99/12 หมู่ 5 ซอยสุขใจ ต.เชียงใหม่-แม่โจ้',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'ต.หนองหาร อ.สันทราย จ.เชียงใหม่ 50290',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // เส้นประเชื่อม
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
                              // ตำแหน่ง B
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHollowCircle(Colors.black), // วงกลมสีดำ
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
                                          widget.requestData.serviceName +
                                              ' (ทางเข้าหลัก)',
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

                  // 🌟 6. รายละเอียดคำร้อง (Description) --------------------------------------
                  _buildSectionTitle('รายละเอียดคำร้อง'),
                  _buildSectionBox(
                    child: const Text(
                      'ต้องการผู้ดูแลพาคุณแม่อายุ 68 ปี ไปพบแพทย์เพื่อตรวจติดตามอาการโรคหัวใจ ขอให้ดูแลเป็นพิเศษระหว่างเดินทาง',
                      style: TextStyle(
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
      ),
    );
  }

  // =========================================================
  // 🌟 ฟังก์ชันการทำงานและ UI Helpers
  // =========================================================

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

  // ชื่อหัวข้อ (สีม่วง)
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

  // กล่องสีขาวมุมมน
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

  // วงกลมจุดพิกัด A B ด้านล่างแผนที่ (แบบโปร่ง)
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
    return Stack(
      alignment: Alignment.topCenter,
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
