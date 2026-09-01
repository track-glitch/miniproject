import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:miniproject/views/admin/view_report_page.dart';
import 'dart:convert';

import '../../models/caretaker_model.dart';
import '../../models/report_model.dart';
import '../../services/admin_service.dart';
import 'view_caretaker_registration_page.dart';
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

  // แยก List เก็บสถานะต่างๆ
  List<CaretakerModel> _pendingList = [];
  List<CaretakerModel> _approvedList = [];
  List<CaretakerModel> _suspendedList = [];
  Map<String, int> _reportCounts = {};

  // 🌟 ระบบ Pagination (Lazy Loading)
  final ScrollController _scrollController = ScrollController();
  final int _perPage = 20;
  int _pendingPage = 1;
  int _approvedPage = 1;
  int _suspendedPage = 1;

  final Color primaryColor = const Color(0xFFA052BE);
  final Color backgroundColor = const Color(0xFFF4EDFB);
  final Color cardBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();

    // 🌟 ดักจับการเลื่อนจอ ถ้าถึงล่างสุดให้โหลดเพิ่มทีละ 20
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        _loadMoreCurrentTab();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreCurrentTab() {
    setState(() {
      if (_selectedStatus == 'Pending' &&
          (_pendingPage * _perPage) < _pendingList.length) {
        _pendingPage++;
      } else if (_selectedStatus == 'Approved' &&
          (_approvedPage * _perPage) < _approvedList.length) {
        _approvedPage++;
      } else if (_selectedStatus == 'Suspended' &&
          (_suspendedPage * _perPage) < _suspendedList.length) {
        _suspendedPage++;
      }
    });
  }

  // 🌟 ดึงข้อมูลมาแสดงตามจำนวนหน้า (ทีละ 20)
  List<CaretakerModel> _getCurrentDisplayList() {
    if (_selectedStatus == 'Pending') {
      return _pendingList.take(_pendingPage * _perPage).toList();
    } else if (_selectedStatus == 'Approved') {
      return _approvedList.take(_approvedPage * _perPage).toList();
    } else {
      return _suspendedList.take(_suspendedPage * _perPage).toList();
    }
  }

  bool _hasMoreInCurrentTab() {
    if (_selectedStatus == 'Pending') {
      return (_pendingPage * _perPage) < _pendingList.length;
    } else if (_selectedStatus == 'Approved') {
      return (_approvedPage * _perPage) < _approvedList.length;
    } else {
      return (_suspendedPage * _perPage) < _suspendedList.length;
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      String name = await _adminService.getAdminName(widget.uid);

      var pending = await _adminService.getCaretakersByStatus('Pending');
      var approved = await _adminService.getCaretakersByStatus('Approved');
      var suspended = await _adminService.getCaretakersByStatus('Suspended');

      for (var caretaker in approved) {
        if (caretaker.caretakerId != null) {
          var reports = await _fetchReportsForCaretaker(caretaker.caretakerId);
          _reportCounts[caretaker.caretakerId!] = reports.length;
        }
      }

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

  Widget _buildTab(String title, String status, int count, Color dotColor) {
    bool isActive = _selectedStatus == status;
    String displayTitle = count > 0 ? '$title ($count)' : title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = status;
            // 🌟 เลื่อนกลับไปบนสุดเมื่อสลับแท็บ
            if (_scrollController.hasClients) _scrollController.jumpTo(0);
          });
        },
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
                  color: isActive ? primaryColor : Colors.black87,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor ?? primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaretakerCard(CaretakerModel caretaker, String status) {
    final int age = _calculateAge(caretaker.birthdate);
    final String address = caretaker.location?.address ?? 'ไม่ระบุที่อยู่';
    final int reportCount = _reportCounts[caretaker.caretakerId] ?? 0;

    Color statusColor;
    String statusText;
    if (status == 'Pending') {
      statusColor = const Color(0xFFFF9800);
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
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: primaryColor.withOpacity(0.2),
                backgroundImage: _getProfileImageProvider(
                  caretaker.profilephoto,
                ),
                child: (caretaker.profilephoto?.isEmpty ?? true)
                    ? Icon(Icons.person, size: 40, color: primaryColor)
                    : null,
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
                            'นาย ${caretaker.firstname} ${caretaker.lastname}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
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
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
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
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'เพศ ${caretaker.gender ?? '-'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.cake_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'อายุ $age ปี',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (status != 'Pending')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Text(
                              '5.0 ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: reportCount > 0
                                    ? Colors.red.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$reportCount รีพอร์ต',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: reportCount > 0
                                      ? Colors.red.shade700
                                      : Colors.grey.shade700,
                                ),
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
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: status == 'Suspended'
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'รายละเอียดการถูกระงับ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (caretaker as dynamic).admincomment ??
                            'ไม่มีรายละเอียดสาเหตุการระงับบัญชี',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (caretaker.vehicle != null)
                        _buildDetailRow(
                          Icons.directions_car_filled_outlined,
                          'ยี่ห้อรถ : ${caretaker.vehicle!.brand} ${caretaker.vehicle!.model ?? ''}',
                        ),
                      _buildDetailRow(
                        Icons.phone_outlined,
                        'เบอร์โทร : ${caretaker.phonenumber ?? '-'}',
                      ),
                      _buildDetailRow(
                        Icons.location_on_outlined,
                        'ที่อยู่ : $address',
                        iconColor: Colors.red.shade400,
                      ),
                      if (caretaker.email != null &&
                          caretaker.email!.isNotEmpty)
                        _buildDetailRow(
                          Icons.email_outlined,
                          'อีเมล : ${caretaker.email}',
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          if (status == 'Pending')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ViewCaretakerRegistrationPage(caretaker: caretaker),
                  ),
                ).then((_) => _fetchInitialData()),
                icon: const Icon(
                  Icons.assignment_ind_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'ตรวจสอบเอกสาร',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            )
          else if (status == 'Approved')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );

                  List<ReportModel> fetchedReports =
                      await _fetchReportsForCaretaker(caretaker.caretakerId);

                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewCaretakerReportPage(
                          caretaker: caretaker,
                          reports: fetchedReports,
                          onSuspend: _fetchInitialData,
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  Icons.report_problem_outlined,
                  size: 18,
                  color: primaryColor,
                ),
                label: Text(
                  'ตรวจสอบรีพอร์ต',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _getCurrentDisplayList();
    final bool hasMore = _hasMoreInCurrentTab();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ยินดีต้อนรับ, $adminName',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
                Container(
                  width: double.infinity,
                  color: primaryColor,
                  padding: const EdgeInsets.only(bottom: 20),
                  child: const Center(
                    child: Text(
                      'จัดการข้อมูลผู้ดูแล',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -15),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildTab(
                            'รอตรวจสอบ',
                            'Pending',
                            _pendingList.length,
                            const Color(0xFFFF9800),
                          ),
                          _buildTab(
                            'อนุมัติแล้ว',
                            'Approved',
                            _approvedList.length,
                            const Color(0xFF4CAF50),
                          ),
                          _buildTab(
                            'ระงับ',
                            'Suspended',
                            _suspendedList.length,
                            const Color(0xFFF44336),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: displayList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'ไม่มีข้อมูลในหมวดหมู่นี้',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller:
                              _scrollController, // 🌟 ใช้งาน ScrollController ดักการเลื่อน
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          itemCount: displayList.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == displayList.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                  ),
                                ),
                              );
                            }
                            return _buildCaretakerCard(
                              displayList[index],
                              _selectedStatus,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
