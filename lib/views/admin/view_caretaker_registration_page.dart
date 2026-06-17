import 'package:flutter/material.dart';
import '../../models/caretaker_model.dart';
import '../../services/admin_service.dart';

class ViewCaretakerRegistrationPage extends StatefulWidget {
  final CaretakerModel caretaker;
  const ViewCaretakerRegistrationPage({super.key, required this.caretaker});

  @override
  State<ViewCaretakerRegistrationPage> createState() => _ViewCaretakerRegistrationPageState();
}

class _ViewCaretakerRegistrationPageState extends State<ViewCaretakerRegistrationPage> {
  final AdminService _adminService = AdminService();
  final TextEditingController _reasonController = TextEditingController();

  final Color primaryColor = const Color(0xFFA052BE);
  final Color backgroundColor = const Color(0xFFF9F5FF);
  final Color sectionBoxColor = const Color(0xFFEFE5FD);

  // ----------------------------------------------------
  // ฟังก์ชันแสดง Popup อนุมัติ
  // ----------------------------------------------------
  void _showApproveDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('อนุมัติการลงทะเบียน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF82CDA4),
                  backgroundImage: (widget.caretaker.profilephoto?.isNotEmpty ?? false)
                      ? AssetImage('assets/images/Profile/${widget.caretaker.profilephoto}')
                      : null,
                  child: (widget.caretaker.profilephoto?.isEmpty ?? true) ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                ),
                const SizedBox(height: 12),
                Text('${widget.caretaker.firstname} ${widget.caretaker.lastname}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('คุณต้องการอนุมัติไหม?', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        await _adminService.approveCaretaker(widget.caretaker.caretakerId!);
                        if (mounted) {
                          Navigator.pop(context); // ปิด popup
                          Navigator.pop(context); // กลับไปหน้าลิสต์
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อนุมัติสำเร็จ')));
                        }
                      },
                      child: const Text('อนุมัติ', style: TextStyle(color: Colors.white)),
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

  // ----------------------------------------------------
  // ฟังก์ชันแสดง Popup ไม่อนุมัติ (ปฏิเสธ)
  // ----------------------------------------------------
  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('ปฏิเสธการลงทะเบียน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF82CDA4),
                  backgroundImage: (widget.caretaker.profilephoto?.isNotEmpty ?? false)
                      ? AssetImage('assets/images/Profile/${widget.caretaker.profilephoto}')
                      : null,
                  child: (widget.caretaker.profilephoto?.isEmpty ?? true) ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                ),
                const SizedBox(height: 12),
                Text('${widget.caretaker.firstname} ${widget.caretaker.lastname}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerLeft, child: Text('ระบุหมายเหตุ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'เอกสารไม่ครบ...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        if (_reasonController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุหมายเหตุก่อนไม่อนุมัติ')));
                          return; // บังคับให้ต้องกรอกเหตุผล
                        }
                        // ใช้ฟังก์ชัน rejectCaretaker เพื่อเปลี่ยนสถานะเป็น Suspended พร้อมบันทึกเหตุผล
                        await _adminService.rejectCaretaker(widget.caretaker.caretakerId!, _reasonController.text.trim());
                        if (mounted) {
                          Navigator.pop(context); 
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกการไม่อนุมัติสำเร็จ')));
                        }
                      },
                      child: const Text('ไม่อนุมัติ', style: TextStyle(color: Colors.white)),
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

  // ----------------------------------------------------
  // Widget ตัวช่วยสร้างช่องกรอกข้อมูลให้อ่านอย่างเดียว (ReadOnly) พร้อม Label
  // ----------------------------------------------------
  Widget _buildReadOnlyField(String hint, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value.isEmpty ? '-' : value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: hint,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลความสัมพันธ์ออกมาใช้งาน
    final vehicle = widget.caretaker.vehicle;
    final docs = widget.caretaker.documents ?? [];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('ข้อมูลผู้สมัครผู้ดูแล', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🖼️ ส่วนบนสุด: รูปถ่ายโปรไฟล์
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF82CDA4),
              backgroundImage: (widget.caretaker.profilephoto?.isNotEmpty ?? false)
                  ? AssetImage('assets/images/Profile/${widget.caretaker.profilephoto}')
                  : null,
              child: (widget.caretaker.profilephoto?.isEmpty ?? true) ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
            ),
            const SizedBox(height: 20),

            // 📦 หมวดหมู่ที่ 1: ข้อมูลผู้ดูแล (ระบบล็อกอินและอีเมล)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: sectionBoxColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ข้อมูลผู้ดูแล', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildReadOnlyField('ชื่อผู้ใช้ (Username)', widget.caretaker.login?.username ?? ''),
                  _buildReadOnlyField('รหัสผ่าน (Password)', widget.caretaker.login?.password ?? ''),
                  _buildReadOnlyField('อีเมล', widget.caretaker.email ?? ''),
                ],
              ),
            ),

            // 📦 หมวดหมู่ที่ 2: ข้อมูลส่วนตัว
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: sectionBoxColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ข้อมูลส่วนตัว', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildReadOnlyField('ชื่อจริง', widget.caretaker.firstname ?? '')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildReadOnlyField('นามสกุล', widget.caretaker.lastname ?? '')),
                    ],
                  ),
                  _buildReadOnlyField('วันเกิด', widget.caretaker.birthdate != null ? widget.caretaker.birthdate!.toIso8601String().split('T')[0] : ''),
                  _buildReadOnlyField('เพศ', widget.caretaker.gender ?? ''),
                  _buildReadOnlyField('เบอร์โทรศัพท์', widget.caretaker.phonenumber ?? ''),
                ],
              ),
            ),

            // 📦 หมวดหมู่ที่ 3: ข้อมูลที่อยู่
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: sectionBoxColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ข้อมูลที่อยู่', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildReadOnlyField('รายละเอียดที่อยู่', widget.caretaker.address ?? ''),
                ],
              ),
            ),

            // 📦 หมวดหมู่ที่ 4: ข้อมูลยานพาหนะ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: sectionBoxColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ข้อมูลยานพาหนะ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // *ตรวจสอบชื่อตัวแปร vehicleType/brand ให้ตรงกับ VehicleModel ของคุณ
                      Expanded(child: _buildReadOnlyField('ประเภท', vehicle?.vehicletype ?? '')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildReadOnlyField('ยี่ห้อ', vehicle?.brand ?? '')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _buildReadOnlyField('รุ่น', vehicle?.model ?? '')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildReadOnlyField('สี', vehicle?.color ?? '')),
                    ],
                  ),
                  _buildReadOnlyField('ป้ายทะเบียน', vehicle?.licenseplate ?? ''),
                ],
              ),
            ),

            // 📦 หมวดหมู่ที่ 4.5: ภาพถ่ายยานพาหนะแบบ List
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: sectionBoxColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ภาพถ่ายยานพาหนะ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  
                  // *ตรวจสอบชื่อตัวแปร vehiclePhotos ให้ตรงกับ VehicleModel ของคุณ
                  (vehicle?.vehiclephotos == null || vehicle!.vehiclephotos!.isEmpty)
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0), 
                            child: Text('ไม่มีภาพถ่ายยานพาหนะ', style: TextStyle(color: Colors.grey))
                          )
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: vehicle.vehiclephotos!.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, 
                            crossAxisSpacing: 10, 
                            mainAxisSpacing: 10,  
                            childAspectRatio: 1,  
                          ),
                          itemBuilder: (context, index) {
                            // 1. ดึงก้อนโมเดลรูปรถออกมา
                            var photoModel = vehicle.vehiclephotos![index];
                            
                            // 2. ดึงเฉพาะชื่อไฟล์รูปออกมาจากตัวแปร photo
                            String photoPath = photoModel.photo ?? ''; 

                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/images/Vehicle/$photoPath', // เอาชื่อไฟล์มาต่อ Path ได้เลย
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.directions_car, color: Colors.grey, size: 30),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),

            // 📦 หมวดหมู่ที่ 5: ข้อมูลเอกสารแนบ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: sectionBoxColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ข้อมูลเอกสาร', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  docs.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('ไม่มีเอกสารแนบมา')))
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white, 
                                borderRadius: BorderRadius.circular(8), 
                                border: Border.all(color: Colors.grey.shade300)
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Image.asset(
                                        'assets/images/Document/${doc.filepath}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Text(
                                      doc.documenttype ?? 'เอกสาร',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),

            // 🔘 แถบปุ่มกดด้านล่างสุด (อนุมัติ / ไม่อนุมัติ)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _showApproveDialog,
                    child: const Text('อนุมัติ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _showRejectDialog,
                    child: const Text('ไม่อนุมัติ', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}