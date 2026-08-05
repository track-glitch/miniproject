import 'package:flutter/material.dart';
import '../views/login_page.dart';
// 🌟 นำเข้าไฟล์หน้า Edit ของคุณ (สมมติชื่อไฟล์)
// import '../views/caretaker/caretaker_edit_register_page.dart';

class RejectedPage extends StatelessWidget {
  final String adminComment;
  final String uid; // 🌟 เพิ่มรับค่า uid
  final dynamic
  documents; // 🌟 เพิ่มรับค่ารายการเอกสาร (เป็น dynamic เผื่อกรณี Firebase คืนค่ามาเป็น Map หรือ List)

  const RejectedPage({
    super.key,
    required this.adminComment,
    required this.uid,
    required this.documents,
  });

  // 🌟 ฟังก์ชันช่วยแปลงข้อมูลเอกสารจาก Firebase ให้เป็น List
  List<Map<String, dynamic>> _getParsedDocuments() {
    List<Map<String, dynamic>> docList = [];
    if (documents == null) return docList;

    if (documents is List) {
      for (var doc in documents) {
        if (doc != null) docList.add(Map<String, dynamic>.from(doc));
      }
    } else if (documents is Map) {
      documents.forEach((key, value) {
        if (value != null) docList.add(Map<String, dynamic>.from(value));
      });
    }
    return docList;
  }

  @override
  Widget build(BuildContext context) {
    final Color errorColor = const Color(0xFFF44336);
    final Color lightErrorColor = const Color(0xFFFFEBEE);
    final Color primaryColor = const Color(0xFF9B59B6);

    final parsedDocs = _getParsedDocuments();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'ผลการตรวจสอบข้อมูล',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: errorColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🌟 กล่องแจ้งสถานะไม่อนุมัติ
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: lightErrorColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: errorColor,
                            child: const Icon(
                              Icons.close,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ไม่ผ่านการอนุมัติ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: errorColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ข้อมูลการสมัครของคุณไม่ผ่านการตรวจสอบ\nโปรดดูเหตุผลและแก้ไขเอกสารที่ไม่ผ่านด้านล่าง',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🌟 กล่องแสดงข้อความจาก Admin
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: errorColor.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.message_outlined,
                                color: errorColor,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'ข้อเสนอแนะจากผู้ดูแลระบบ:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            adminComment.isNotEmpty
                                ? adminComment
                                : 'ไม่มีการระบุเหตุผลเพิ่มเติม',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🌟 กล่องแสดงรายการเอกสาร (ตาม Mockup)
                    if (parsedDocs.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'สถานะเอกสารของคุณ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...parsedDocs.map((doc) {
                              String docName =
                                  doc['documenttype'] ?? 'เอกสารไม่ระบุชื่อ';
                              String status = doc['status'] ?? 'PENDING';
                              bool isApproved = status == 'APPROVED';

                              // แปลงชื่อให้ดูสวยงาม
                              if (docName == 'driver_license')
                                docName = 'ใบอนุญาตขับขี่';
                              if (docName == 'car_insurance')
                                docName = 'ประกันภัยรถยนต์';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        docName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    // 🌟 ไอคอนวงกลมสีเทา ติ๊กถูก/กากบาท ตาม Mockup
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isApproved ? Icons.check : Icons.close,
                                        color: Colors.black87,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 🌟 ปุ่มกดด้านล่าง 2 ปุ่ม (ไปหน้า Edit และ กลับสู่หน้าล็อกอิน)
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            primaryColor, // ใช้สีหลักเพื่อเน้นให้ไปแก้ไข
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // 🌟 นำทางไปหน้า Edit พร้อมส่ง UID ไป เพื่อให้หน้า Edit ไป Fetch ข้อมูลต่อ
                        /*
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CaretakerEditRegisterPage(uid: uid),
                          ),
                        );
                        */
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'กำลังไปหน้าแก้ไขข้อมูล... (เชื่อมหน้า Edit ที่นี่)',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'แก้ไขข้อมูลการสมัคร',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'กลับสู่หน้าเข้าสู่ระบบ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
