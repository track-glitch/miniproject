import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // เปลี่ยนมาใช้ Realtime Database
import 'package:miniproject/views/relative/view_caretaker_profile_page.dart';
import 'dart:convert';

class CaretakerSearchPage extends StatefulWidget {
  const CaretakerSearchPage({super.key});

  @override
  State<CaretakerSearchPage> createState() => _CaretakerSearchPageState();
}

class _CaretakerSearchPageState extends State<CaretakerSearchPage> {
  // ตัวควบคุมช่องค้นหา
  final TextEditingController _searchController = TextEditingController();

  // โทนสีควบคุมตามรูปแบบภาพตัวอย่างเป๊ะๆ
  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF3E5F5); // สีม่วงพาสเทล
  final Color bgColor = const Color(0xFFFAFAFA);
  final Color greyBorder = const Color(0xFFE1BEE7); // สีเส้นกรอบด้านใน

  @override
  void initState() {
    super.initState();
    // ดักจับเมื่อมีการพิมพ์ข้อความในช่องค้นหา ให้รีเฟรชหน้าจอเพื่อกรองข้อมูล
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ฟังก์ชันแสดงปฏิทินเมื่อกดปุ่มกรอง (Filter) ด้านขวาช่องค้นหา
  void _openFilterCalendar() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor, // สีปุ่มและไฮไลท์ปฏิทิน
              onPrimary: Colors.white,
              onSurface: darkPurple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selectedDate != null) {
      // เพิ่ม Logic การกรองด้วยวันที่ได้ที่นี่
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(
        255,
        239,
        199,
        255,
      ), // พื้นหลังสีม่วงพาสเทลจางๆ
      appBar: AppBar(
        title: const Text(
          'ขอใช้บริการ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),
            // หัวข้อ ค้นหาบัญชี
            Text(
              'ค้นหาบัญชี',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),

            // แถบค้นหา และ ปุ่ม Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black87, width: 1.2),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText:
                              'ค้นหา ชื่อ-นามสกุล หรือ ที่อยู่ (อำเภอ จังหวัด)',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.black54,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ปุ่มกด Filter เปิดปฏิทิน
                  GestureDetector(
                    onTap: _openFilterCalendar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.transparent,
                      child: const Icon(
                        Icons.tune,
                        color: Colors.black,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // รายการผู้ดูแล (ดึงจากระดับรากฐานต้นสตรีมเพื่อดักจับโหนดลูกของแต่ละ UID)
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                // แก้ไขปัญหา: สตรีมจากโหนดรากฐานตรงๆ เพื่อดึงโครงสร้าง Map ซ้อน UID ได้ครบทุกตัว
                stream: FirebaseDatabase.instance.ref('Login').onValue,
                builder: (context, snapshot) {
                  // สถานะกำลังโหลด
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }
                  // กรณีเกิด Error
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('เกิดข้อผิดพลาดในการดึงข้อมูล'),
                    );
                  }
                  // กรณีไม่มีข้อมูลเลย หรือโหนดว่างเปล่า
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(
                      child: Text('ไม่พบข้อมูลผู้ดูแลในระบบ'),
                    );
                  }

                  // ดึงค่าแตกโครงสร้างออกมาเป็น Map ใหญ่
                  final dynamic rootValue = snapshot.data!.snapshot.value;
                  List<Map<String, dynamic>> caretakersList = [];

                  if (rootValue is Map) {
                    // วนลูปสแกนเจาะลึกเข้าไปในทุกๆ คีย์ UID ของระบบเพื่อดึงก้อนข้อมูลที่มีโหนดคำว่า 'Caretaker'
                    rootValue.forEach((userUidKey, userNodeValue) {
                      if (userNodeValue is Map &&
                          userNodeValue.containsKey('Caretaker')) {
                        final caretakerRawData = userNodeValue['Caretaker'];

                        if (caretakerRawData != null) {
                          final data = Map<String, dynamic>.from(
                            caretakerRawData as Map,
                          );

                          data['id'] = userUidKey;

                          // Vehicle อยู่ระดับเดียวกับ Caretaker
                          if (userNodeValue.containsKey('Vehicle')) {
                            data['vehicle'] = Map<String, dynamic>.from(
                              userNodeValue['Vehicle'],
                            );
                          }

                          caretakersList.add(data);
                        }
                      }
                    });
                  }

                  // ตรวจเช็คหลังจากวนสแกนหาแล้วไม่มีโหนด Caretaker เลย
                  if (caretakersList.isEmpty) {
                    return const Center(
                      child: Text('ไม่พบข้อมูลผู้ดูแลระบบในคลังข้อมูล'),
                    );
                  }

                  // ค้นหาและกรองข้อมูลตามที่ผู้ใช้พิมพ์แบบ Real-time
                  final searchQuery = _searchController.text.toLowerCase();
                  final filteredList = caretakersList.where((data) {
                    final name =
                        "${data['firstname'] ?? ''} ${data['lastname'] ?? ''}"
                            .toLowerCase();
                    final address = (data['address'] ?? '').toLowerCase();

                    return name.contains(searchQuery) ||
                        address.contains(searchQuery);
                  }).toList();

                  // ถ้าพิมพ์ค้นหาแล้วไม่แมตช์เจอกับรายชื่อใดๆ
                  if (filteredList.isEmpty) {
                    return const Center(child: Text('ไม่พบผลลัพธ์การค้นหา'));
                  }

                  // สร้างรายการการ์ดแสดงผล
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final data = filteredList[index];
                      return _buildCaretakerCard(data, data['id']);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar ด้านล่างสุด
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(color: primaryColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home_outlined, 'บ้าน', false),
            _buildBottomNavItem(
              Icons.support_agent,
              'ขอใช้บริการ',
              true,
            ), // แถบปัจจุบัน ไฮไลท์
            _buildBottomNavItem(Icons.notifications_none, 'แจ้งเตือน', false),
            _buildBottomNavItem(Icons.person_outline, 'ญาติ', false),
          ],
        ),
      ),
    );
  }

  // Widget สร้างการ์ดข้อมูลผู้ดูแล
  Widget _buildCaretakerCard(Map<String, dynamic> data, String docId) {
    // เตรียมข้อมูลพื้นฐาน
    String firstname = data['firstname'] ?? 'ไม่ระบุ';
    String lastname = data['lastname'] ?? '';
    String fullName = "$firstname $lastname".trim();
    String location = data['address'] ?? 'ไม่ระบุ';
    String gender = data['gender'] ?? 'ไม่ระบุ';

    // เตรียมข้อมูลยานพาหนะ (ดึงแกะโครงสร้างโหนดซ้อนจากรถคู่ขนานใน UID)
    String carDetail = 'ไม่ระบุ';
    print("Vehicle Data = ${data['vehicle']}");
    if (data['vehicle'] != null) {
      final v = Map<String, dynamic>.from(data['vehicle'] as Map);
      String brand = v['brand'] ?? '';
      String model = v['model'] ?? '';
      carDetail = "$brand $model".trim();
      if (carDetail.isEmpty) carDetail = 'ไม่ระบุ';
    }

    // ตรวจสอบสถานะการให้บริการ
    String status = data['servicestatus'] ?? 'Offline';
    bool isAvailable =
        (status.toLowerCase() == 'online' || status == 'พร้อมให้บริการ');

    // คะแนนเรตติ้งจำลอง
    double rating = data['rating'] != null
        ? (data['rating'] as num).toDouble()
        : 0.0;
    int comments = data['comments'] ?? 0;

    // จัดการสีโปรไฟล์ตามเพศ
    Color avatarBg;
    Color avatarIcon;
    if (gender == 'ชาย' || gender.toLowerCase() == 'male') {
      avatarBg = const Color(0xFFA2D9CE); // สีเขียวฟ้า
      avatarIcon = darkPurple;
    } else if (gender == 'หญิง' || gender.toLowerCase() == 'female') {
      avatarBg = const Color(0xFFF9E79F); // สีเหลืองทอง
      avatarIcon = Colors.deepOrange;
    } else {
      avatarBg = Colors.grey.shade300;
      avatarIcon = Colors.grey.shade700;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightPurple.withValues(alpha: 0.3), // กล่องการ์ดซ้อนหลัง
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูปโปรไฟล์
          CircleAvatar(
            radius: 25,
            backgroundImage:
                data['profilephoto'] != null &&
                    data['profilephoto'].toString().isNotEmpty
                ? MemoryImage(base64Decode(data['profilephoto']))
                : null,
            child:
                data['profilephoto'] == null ||
                    data['profilephoto'].toString().isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),

          // รายละเอียดข้อความด้านใน
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // ป้ายสถานะ
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xFF2ECC71).withOpacity(0.6)
                            : const Color(0xFFF39C12).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isAvailable ? 'พร้อมให้บริการ' : 'ไม่พร้อมให้บริการ',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // เรตติ้งดาวรีวิว
                Row(
                  children: [
                    Text(
                      '$rating ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange,
                          size: 14,
                        );
                      }),
                    ),
                    Text(
                      comments == 0
                          ? '  ยังไม่มีรีวิว'
                          : '  $comments คอมเมนต์',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ข้อมูลพื้นที่ให้บริการ
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'พื้นที่ให้บริการ: $location',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // ข้อมูลยานพาหนะ
                Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'ยี่ห้อรถ: $carDetail',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ปุ่มดูรายละเอียดด้านล่างขวา
                Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    height: 28,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // เพิ่มคำสั่ง Navigator เพื่อเปิดหน้าใหม่ตรงนี้ครับ
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CaretakerProfilePage(caretakerId: data['id']),
                          ),
                        );
                      },
                      child: const Text(
                        'ดูรายละเอียด',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  // Widget สร้างปุ่มเมนูด้านล่างสุด (Bottom Nav Bar Item)
  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 24),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
