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
  final Color backgroundColor = const Color(0xFFF9F9F9); // พื้นหลังสว่างสบายตา
  final Color borderColor = Colors.black87; // สีขอบตามดีไซน์ดราฟ

  int _currentCarImageIndex = 0; // ตัวแปรเก็บหน้าปัจจุบันของ Carousel รูปรถ

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🌟 ฟังก์ชันจัดการรูปภาพ (รองรับ Base64 และ Asset เดิม)
  // ==========================================
  ImageProvider? _getImageProvider(String? data, {String folder = 'Profile'}) {
    if (data == null || data.trim().isEmpty) return null;
    if (data.contains('.')) return AssetImage('assets/images/$folder/$data');
    try {
      return MemoryImage(base64Decode(data));
    } catch (e) {
      return null;
    }
  }

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

  // 🌟 ฟังก์ชันซูมรูปเต็มจอ (มีประโยชน์มากเวลาแอดมินตรวจใบขับขี่)
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

  // ฟังก์ชันคำนวณอายุ
  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return '-';
    int age = DateTime.now().year - birthDate.year;
    return '$age ปี';
  }

  // ==========================================
  // 🌟 UI Helpers (สร้างกล่องแบบคลีนๆ ตามดราฟ)
  // ==========================================
  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.8), width: 1),
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

  // ==========================================
  // 🌟 ฟังก์ชันแสดง Popup (อนุมัติ/ไม่อนุมัติ)
  // ==========================================
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
          'คุณต้องการอนุมัติ ${widget.caretaker.firstname} ${widget.caretaker.lastname} ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await _adminService.approveCaretaker(
                widget.caretaker.caretakerId!,
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'ไม่อนุมัติการลงทะเบียน',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ระบุเหตุผลที่ไม่อนุมัติ:'),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'เช่น เอกสารใบขับขี่ไม่ชัดเจน...',
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
                    content: Text('กรุณาระบุหมายเหตุก่อนไม่อนุมัติ'),
                  ),
                );
                return;
              }
              await _adminService.rejectCaretaker(
                widget.caretaker.caretakerId!,
                _reasonController.text.trim(),
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกการไม่อนุมัติสำเร็จ')),
                );
              }
            },
            child: const Text(
              'ไม่อนุมัติ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.caretaker.vehicle;
    final docs = widget.caretaker.documents ?? [];

    String dobString = '-';
    if (widget.caretaker.birthdate != null) {
      final date = widget.caretaker.birthdate!;
      dobString =
          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year + 543}";
    }

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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 📦 1. การ์ดโปรไฟล์ (อิงตามดราฟแรก)
                  _buildCardContainer(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          backgroundImage: _getImageProvider(
                            widget.caretaker.profilephoto,
                          ),
                          child:
                              (widget.caretaker.profilephoto?.isEmpty ?? true)
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                )
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const Divider(height: 30),
                        _buildInfoRow(
                          'Username:',
                          widget.caretaker.login?.username ?? '',
                        ),
                      ],
                    ),
                  ),

                  // 📦 2. การ์ดข้อมูลส่วนตัว
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.caretaker.aboutme ?? '-',
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'อุปกรณ์ที่มี:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.caretaker.equipmentdetails ?? '-',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),

                  // 📦 3. การ์ดที่อยู่
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
                          widget.caretaker.address ?? '-',
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  // 📦 4. การ์ดรถยนต์ (🌟 ทำเป็น Carousel ตามดราฟ)
                  if (vehicle != null)
                    _buildCardContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ยานพาหนะ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.15),
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

                          // 🌟 Carousel รูปรถยนต์
                          if (vehicle.vehiclephotos != null &&
                              vehicle.vehiclephotos!.isNotEmpty) ...[
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // รูปรถใช้ PageView
                                  SizedBox(
                                    height: 200,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(15),
                                      ),
                                      child: PageView.builder(
                                        itemCount:
                                            vehicle.vehiclephotos!.length,
                                        onPageChanged: (index) => setState(
                                          () => _currentCarImageIndex = index,
                                        ),
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () => _showFullScreenImage(
                                              vehicle
                                                  .vehiclephotos![index]
                                                  .photo,
                                              'Vehicle',
                                            ),
                                            child: _buildImageWidget(
                                              vehicle
                                                  .vehiclephotos![index]
                                                  .photo,
                                              folder: 'Vehicle',
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  // จุดไข่ปลา (Dots Indicator)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                            color:
                                                _currentCarImageIndex == index
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
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
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
                    ),

                  // 📦 5. การ์ดเอกสารแนบ (🌟 ลิสต์แนวตั้ง ใหญ่ๆ ชัดๆ)
                  _buildCardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ข้อมูลเอกสาร',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.documenttype == 'driver_license'
                                          ? 'ใบอนุญาตขับขี่'
                                          : doc.documenttype == 'car_insurance'
                                          ? 'ประกันภัยรถยนต์'
                                          : doc.documenttype ==
                                                'first_aid_certificate'
                                          ? 'ใบรับรองปฐมพยาบาล'
                                          : (doc.documenttype ?? 'เอกสาร'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => _showFullScreenImage(
                                        doc.filepath,
                                        'Document',
                                      ),
                                      child: Container(
                                        height: 180,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: _buildImageWidget(
                                            doc.filepath,
                                            folder: 'Document',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '👆 กดที่รูปเพื่อขยายดูเต็มจอ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔘 แถบปุ่มกดด้านล่างสุด (Sticky Bottom Bar)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _showRejectDialog,
                    child: const Text(
                      'ไม่อนุมัติ',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _showApproveDialog,
                    child: const Text(
                      'อนุมัติ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
