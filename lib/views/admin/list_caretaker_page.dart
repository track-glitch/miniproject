import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // 🌟 นำเข้า Firebase
import 'package:miniproject/views/admin/view_report_page.dart';
import 'dart:convert';

import '../../models/caretaker_model.dart';
import '../../models/report_model.dart'; // 🌟 นำเข้า ReportModel
import '../../services/admin_service.dart';
import 'view_caretaker_registration_page.dart';
import 'view_report_page.dart'; // 🌟 นำเข้าหน้ารายละเอียดรีพอร์ตที่คุณเพิ่งสร้าง
import '../../views/login_page.dart';

class ListCaretakerPage extends StatefulWidget {
  final String uid;
  const ListCaretakerPage({super.key, required this.uid});

  @override
  State<ListCaretakerPage> createState() => _ListCaretakerPageState();
}

class _ListCaretakerPageState extends State<ListCaretakerPage> {
  final AdminService _adminService = AdminService();
  String adminName = '';
  String _selectedStatus = 'Pending';
  bool _isLoading = true;

  // แยก List เก็บสถานะต่างๆ เพื่อใช้นับจำนวน
  List<CaretakerModel> _pendingList = [];
  List<CaretakerModel> _approvedList = [];
  List<CaretakerModel> _suspendedList = [];
  Map<String, int> _reportCounts = {};
  final Color primaryColor = const Color(0xFFA052BE);
  final Color backgroundColor = const Color(0xFFF4EDFB);

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      String name = await _adminService.getAdminName(widget.uid);

      // ดึงข้อมูลตามสถานะ
      var pending = await _adminService.getCaretakersByStatus('Pending');
      var approved = await _adminService.getCaretakersByStatus('Approved');
      var suspended = await _adminService.getCaretakersByStatus('Suspended');

      // 🌟 2. ดึงจำนวนรีพอร์ตจาก Firebase มาเก็บไว้ใน Map
      for (var caretaker in approved) {
        if (caretaker.caretakerId != null) {
          var reports = await _fetchReportsForCaretaker(caretaker.caretakerId);
          _reportCounts[caretaker.caretakerId!] = reports.length;
        }
      }

      // 🌟 3. เรียงลำดับหน้าอนุมัติ ตามจำนวนรีพอร์ตจากมากไปน้อย โดยอิงจาก Map ที่นับไว้
      approved.sort((a, b) {
        int aReports = _reportCounts[a.caretakerId] ?? 0;
        int bReports = _reportCounts[b.caretakerId] ?? 0;
        return bReports.compareTo(aReports);
      });

      setState(() {
        adminName = name;
        _pendingList = pending;
        _approvedList = approved;
        _suspendedList = suspended;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching data: $e");
    }
  }

  // 🌟 ฟังก์ชันดึง Report เฉพาะของ Caretaker คนนั้นจาก Firebase
  Future<List<ReportModel>> _fetchReportsForCaretaker(
    String? caretakerId,
  ) async {
    if (caretakerId == null || caretakerId.isEmpty) return [];

    List<ReportModel> reports = [];
    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login').get();

      if (snapshot.exists && snapshot.value is Map) {
        final users = snapshot.value as Map<dynamic, dynamic>;

        users.forEach((uid, userData) {
          if (userData['Relative'] != null &&
              userData['Relative']['Request'] != null) {
            final requests =
                userData['Relative']['Request'] as Map<dynamic, dynamic>;

            requests.forEach((reqId, reqData) {
              if (reqData['caretakerId'] == caretakerId &&
                  reqData['Report'] != null) {
                reports.add(
                  ReportModel.fromJson(
                    Map<String, dynamic>.from(reqData['Report']),
                  ),
                );
              }
            });
          }
        });
      }
    } catch (e) {
      print("Error fetching reports: $e");
    }
    return reports;
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ออกจากระบบ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text(
              'ออกจากระบบ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  ImageProvider? _getProfileImageProvider(String? data) {
    if (data == null || data.trim().isEmpty) return null;
    if (data.startsWith('http')) return NetworkImage(data);
    if (data.contains('.')) return AssetImage('assets/images/Profile/$data');
    try {
      return MemoryImage(base64Decode(data));
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------
  // UI: แถบ Tab เลือกสถานะ
  // ---------------------------------------------------------
  Widget _buildTab(String title, String status, int count, Color dotColor) {
    bool isActive = _selectedStatus == status;
    String displayTitle = count > 0 ? '$title ($count)' : title;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? Border.all(color: primaryColor, width: 1.5)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                displayTitle,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // UI: Card แสดงข้อมูล
  // ---------------------------------------------------------
  Widget _buildCaretakerCard(CaretakerModel caretaker, String status) {
    final int age = _calculateAge(caretaker.birthdate);
    final String address = caretaker.location?.address ?? 'ไม่ระบุที่อยู่';
    final int reportCount = _reportCounts[caretaker.caretakerId] ?? 0;

    Color statusColor;
    String statusText;
    if (status == 'Pending') {
      statusColor = const Color(0xFFFFC107);
      statusText = 'รอตรวจสอบ';
    } else if (status == 'Approved') {
      statusColor = const Color(0xFF4CAF50);
      statusText = 'อนุมัติแล้ว';
    } else {
      statusColor = const Color(0xFFF44336);
      statusText = 'ระงับบัญชี';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black87, width: 1),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF82CDA4),
                backgroundImage: _getProfileImageProvider(
                  caretaker.profilephoto,
                ),
                child: (caretaker.profilephoto?.isEmpty ?? true)
                    ? const Icon(Icons.person, size: 36, color: Colors.white)
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
                            'นาย ${caretaker.firstname} ${caretaker.lastname}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'เพศ ${caretaker.gender ?? '-'} • อายุ $age ปี',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          '5.0 ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          '$reportCount รีพอร์ต',
                          style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: status == 'Suspended'
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'รายละเอียดการถูกระงับ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (caretaker as dynamic).admincomment ??
                            'ไม่มีรายละเอียดสาเหตุการระงับบัญชี',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (caretaker.vehicle != null)
                        Text(
                          '🚗 ยี่ห้อรถ : ${caretaker.vehicle!.brand} ${caretaker.vehicle!.model ?? ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '📞 เบอร์โทร : ${caretaker.phonenumber ?? '-'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📍 ที่อยู่ : $address',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (caretaker.email != null &&
                          caretaker.email!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '✉️ อีเมล : ${caretaker.email}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 12),

          if (status == 'Pending')
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ViewCaretakerRegistrationPage(caretaker: caretaker),
                  ),
                ).then((_) => _fetchInitialData()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'ตรวจสอบเอกสาร',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            )
          else if (status == 'Approved')
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 🌟 ปุ่มตรวจสอบรีพอร์ตที่อัปเดตแล้ว (มีระบบ Loading + ดึงข้อมูล Firebase)
                ElevatedButton(
                  onPressed: () async {
                    // 1. โชว์ Dialog Loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );

                    // 2. ดึงข้อมูล Report จาก Firebase
                    List<ReportModel> fetchedReports =
                        await _fetchReportsForCaretaker(caretaker.caretakerId);

                    // 3. ปิด Dialog Loading
                    if (context.mounted) Navigator.pop(context);

                    // 4. ไปหน้ารายละเอียดพร้อมแนบข้อมูล
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewCaretakerReportPage(
                            caretaker: caretaker,
                            reports: fetchedReports, // ส่งตัวแปรที่ดึงมา
                            onSuspend: _fetchInitialData,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'ตรวจสอบรีพอร์ต',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'แอดมิน $adminName',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutConfirmDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'ดูรายงานความประพฤติ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: Row(
                      children: [
                        _buildTab(
                          'รอตรวจสอบ',
                          'Pending',
                          _pendingList.length,
                          const Color(0xFFFFC107),
                        ),
                        _buildTab(
                          'อนุมัติแล้ว',
                          'Approved',
                          _approvedList.length,
                          const Color(0xFF4CAF50),
                        ),
                        _buildTab(
                          'บัญชีที่ระงับ',
                          'Suspended',
                          _suspendedList.length,
                          const Color(0xFFF44336),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      List<CaretakerModel> currentList;
                      if (_selectedStatus == 'Pending')
                        currentList = _pendingList;
                      else if (_selectedStatus == 'Approved')
                        currentList = _approvedList;
                      else
                        currentList = _suspendedList;

                      if (currentList.isEmpty) {
                        return const Center(
                          child: Text(
                            'ไม่มีข้อมูลในหมวดหมู่นี้',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: currentList.length,
                        itemBuilder: (context, index) {
                          return _buildCaretakerCard(
                            currentList[index],
                            _selectedStatus,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
