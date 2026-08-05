import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/caretaker_model.dart';
import '../../services/admin_service.dart';

class ViewCaretakerRegistrationPage extends StatefulWidget {
  final CaretakerModel caretaker;
  const ViewCaretakerRegistrationPage({super.key, required this.caretaker});

  @override
  State<ViewCaretakerRegistrationPage> createState() =>
      _ViewCaretakerRegistrationPageState();
}

class _ViewCaretakerRegistrationPageState
    extends State<ViewCaretakerRegistrationPage> {
  final AdminService _adminService = AdminService();
  final TextEditingController _reasonController = TextEditingController();

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color backgroundColor = const Color(0xFFF9F9F9);
  final Color borderColor = Colors.black87;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _currentCarImageIndex = 0;

  // 🌟 เก็บสถานะผ่าน(true)/ไม่ผ่าน(false) ของเอกสารแต่ละอัน (Key = index)
  final Map<int, bool> _documentStatuses = {};

  @override
  void dispose() {
    _reasonController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 🌟 รองรับ URL รูปภาพจากอินเทอร์เน็ต
  ImageProvider? _getImageProvider(String? data, {String folder = 'Profile'}) {
    if (data == null || data.trim().isEmpty) return null;
    if (data.startsWith('http')) return NetworkImage(data);
    if (data.contains('.')) return AssetImage('assets/images/$folder/$data');
    try {
      return MemoryImage(base64Decode(data));
    } catch (e) {
      return null;
    }
  }

  // 🌟 รองรับ URL รูปภาพจากอินเทอร์เน็ตสำหรับ Widget
  Widget _buildImageWidget(
    String? data, {
    String folder = 'Document',
    double height = 200,
    BoxFit fit = BoxFit.cover,
  }) {
    if (data == null || data.trim().isEmpty) {
      return Container(
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
      );
    }
    if (data.startsWith('http')) {
      return Image.network(
        data,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
        ),
      );
    }
    if (data.contains('.')) {
      return Image.asset(
        'assets/images/$folder/$data',
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
        ),
      );
    }
    try {
      return Image.memory(
        base64Decode(data),
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
        ),
      );
    } catch (e) {
      return Container(
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
      );
    }
  }

  void _showFullScreenImage(String? data, String folder) {
    if (data == null || data.isEmpty) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: false,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: _buildImageWidget(
                  data,
                  folder: folder,
                  height: MediaQuery.of(context).size.height * 0.7,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white, size: 35),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return '-';
    int age = DateTime.now().year - birthDate.year;
    return '$age ปี';
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 กด Submit แล้วเช็กเงื่อนไข (บังคับ Reject ถ้ามีเอกสารไม่ผ่าน)
  void _handleSubmitReview() {
    final docsCount = widget.caretaker.documents?.length ?? 0;

    // 1. เช็กว่ากดตรวจเอกสารครบทุกใบหรือยัง
    if (_documentStatuses.length < docsCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาตรวจสอบและเลือกสถานะเอกสารให้ครบทุกรายการ'),
        ),
      );
      return;
    }

    // 2. เช็กว่ามีอันไหน "ไม่ผ่าน" (false) ไหม
    bool hasRejectedDoc = _documentStatuses.values.contains(false);

    if (hasRejectedDoc) {
      _showRejectDialog(); // บังคับให้เด้งไปกรอก Comment
    } else {
      _showApproveDialog(); // ผ่านหมด ให้ยืนยัน
    }
  }

  void _showApproveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ยืนยันการอนุมัติ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'เอกสารผ่านทั้งหมด คุณต้องการอนุมัติ ${widget.caretaker.firstname} ${widget.caretaker.lastname} ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          // ค้นหาจุดนี้แล้วแก้ตามได้เลยครับ
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await _adminService.approveCaretaker(
                widget.caretaker.caretakerId!,
                widget.caretaker.documents ??
                    [], // 🌟 เพิ่มการส่ง List เอกสารเข้าไป
              );
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('อนุมัติสำเร็จ')));
              }
            },
            child: const Text('อนุมัติ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // บังคับให้ต้องกรอกหรือยกเลิก
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'เอกสารไม่ผ่าน / ไม่อนุมัติ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'พบเอกสารที่ไม่ผ่านเกณฑ์ กรุณาระบุสิ่งที่ต้องแก้ไข:',
              style: TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'เช่น เอกสารใบขับขี่ไม่ชัดเจน กรุณาถ่ายใหม่...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (_reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาระบุสิ่งที่ต้องแก้ไขก่อนส่งกลับ'),
                  ),
                );
                return;
              }
              await _adminService.rejectCaretaker(
                widget.caretaker.caretakerId!,
                _reasonController.text.trim(),
                widget.caretaker.documents ?? [], // 🌟 1. ส่ง List เอกสาร
                _documentStatuses, // 🌟 2. ส่งสถานะที่ติ๊กผ่าน/ไม่ผ่าน
              );
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ส่งข้อมูลกลับให้ผู้ใช้งานแก้ไขเรียบร้อยแล้ว',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'ส่งกลับให้แก้ไข',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    String dobString = '-';
    if (widget.caretaker.birthdate != null) {
      final date = widget.caretaker.birthdate!;
      dobString =
          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year + 543}";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCardContainer(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  backgroundImage: _getImageProvider(
                    widget.caretaker.profilephoto,
                  ),
                  child: (widget.caretaker.profilephoto?.isEmpty ?? true)
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.caretaker.firstname} ${widget.caretaker.lastname}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${widget.caretaker.caretakerId}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          _buildCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'ข้อมูลส่วนตัว',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('เพศ:', widget.caretaker.gender ?? ''),
                _buildInfoRow(
                  'อายุ:',
                  _calculateAge(widget.caretaker.birthdate),
                ),
                _buildInfoRow('วันเกิด:', dobString),
                _buildInfoRow(
                  'เบอร์โทรศัพท์:',
                  widget.caretaker.phonenumber ?? '',
                ),
                _buildInfoRow('อีเมล:', widget.caretaker.email ?? ''),
                const Divider(height: 24),
                const Text(
                  'เกี่ยวกับฉัน:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.caretaker.experience ?? '-',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    final vehicle = widget.caretaker.vehicle;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 28,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ข้อมูลที่อยู่',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.caretaker.location?.address ?? 'ไม่มีข้อมูลที่อยู่',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
          if (vehicle != null)
            _buildCardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ยานพาหนะ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: primaryColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.vehicletype ?? '-',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${vehicle.brand ?? ''} ${vehicle.model ?? ''}, สี${vehicle.color ?? ''}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (vehicle.vehiclephotos != null &&
                      vehicle.vehiclephotos!.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              child: PageView.builder(
                                itemCount: vehicle.vehiclephotos!.length,
                                onPageChanged: (index) => setState(
                                  () => _currentCarImageIndex = index,
                                ),
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _showFullScreenImage(
                                      vehicle.vehiclephotos![index].photo,
                                      'Vehicle',
                                    ),
                                    child: _buildImageWidget(
                                      vehicle.vehiclephotos![index].photo,
                                      folder: 'Vehicle',
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                vehicle.vehiclephotos!.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentCarImageIndex == index
                                        ? Colors.black
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ป้ายทะเบียน:',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        vehicle.licenseplate ?? '-',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("ไม่มีข้อมูลยานพาหนะ"),
              ),
            ),
        ],
      ),
    );
  }

  // 🌟 หน้าที่ 3: ระบบตรวจสอบเอกสาร
  Widget _buildPage3() {
    final docs = widget.caretaker.documents ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildCardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ตรวจสอบเอกสาร',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (docs.isEmpty)
              const Text(
                'ไม่มีเอกสารแนบมา',
                style: TextStyle(color: Colors.grey),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  bool? currentStatus = _documentStatuses[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: currentStatus == true
                            ? Colors.green.shade300
                            : currentStatus == false
                            ? Colors.red.shade300
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: currentStatus == true
                          ? Colors.green.shade50
                          : currentStatus == false
                          ? Colors.red.shade50
                          : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.documenttype == 'driver_license'
                              ? 'ใบอนุญาตขับขี่'
                              : doc.documenttype == 'car_insurance'
                              ? 'ประกันภัยรถยนต์'
                              : doc.documenttype == 'first_aid_certificate'
                              ? 'ใบรับรองปฐมพยาบาล'
                              : (doc.documenttype ?? 'เอกสาร'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () =>
                              _showFullScreenImage(doc.filepath, 'Document'),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImageWidget(
                                doc.filepath,
                                folder: 'Document',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 🌟 ปุ่ม ติ๊กถูก / กากบาท
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(
                                    () => _documentStatuses[index] = true,
                                  );
                                },
                                icon: const Icon(Icons.check_circle),
                                label: const Text('ผ่าน'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentStatus == true
                                      ? Colors.green
                                      : Colors.grey.shade300,
                                  foregroundColor: currentStatus == true
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  elevation: currentStatus == true ? 2 : 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(
                                    () => _documentStatuses[index] = false,
                                  );
                                },
                                icon: const Icon(Icons.cancel),
                                label: const Text('ไม่ผ่าน'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentStatus == false
                                      ? Colors.red
                                      : Colors.grey.shade300,
                                  foregroundColor: currentStatus == false
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  elevation: currentStatus == false ? 2 : 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'ตรวจสอบข้อมูล',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepIndicator(0, 'ข้อมูลส่วนตัว'),
                _buildStepLine(),
                _buildStepIndicator(1, 'ที่อยู่/รถยนต์'),
                _buildStepLine(),
                _buildStepIndicator(2, 'เอกสาร'),
              ],
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [_buildPage1(), _buildPage2(), _buildPage3()],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _previousPage,
                      child: const Text(
                        'ย้อนกลับ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                if (_currentPage < 2) ...[
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _nextPage,
                      child: const Text(
                        'ถัดไป',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // 🌟 หน้าสุดท้าย โชว์ปุ่มส่งผลการตรวจสอบ ปุ่มเดียว
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _handleSubmitReview,
                      child: const Text(
                        'ส่งผลการตรวจสอบ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    bool isActive = _currentPage >= stepIndex;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? primaryColor : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              '${stepIndex + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? primaryColor : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 15, left: 8, right: 8),
        height: 2,
        color: Colors.grey.shade300,
      ),
    );
  }
}
