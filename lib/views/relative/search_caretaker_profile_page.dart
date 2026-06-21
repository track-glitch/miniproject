import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // เปลี่ยนมาใช้ Realtime Database
import 'package:firebase_auth/firebase_auth.dart'; // สำหรับเช็คสิทธิ์ตอนกดปุ่ม
import 'package:miniproject/models/patient_model.dart'; //
import 'package:miniproject/models/relative_model.dart'; //
import 'package:miniproject/views/relative/edit_relative_info_page.dart'; //
import 'package:miniproject/views/relative/view_caretaker_profile_page.dart'; //
import 'package:miniproject/views/login_page.dart'; // นำเข้าหน้า Login เพื่อใช้งานตอนกดปุ่มใน Dialog
import 'dart:convert'; //

class CaretakerSearchPage extends StatefulWidget {
  final String? loggedUid; // 🎯 รับค่า Uid จริงที่ส่งมาจากตอนล็อกอินผ่านสำเร็จ
  const CaretakerSearchPage({super.key, this.loggedUid}); //

  @override
  State<CaretakerSearchPage> createState() => _CaretakerSearchPageState(); //
}

class _CaretakerSearchPageState extends State<CaretakerSearchPage> {
  // ตัวควบคุมช่องค้นหา
  final TextEditingController _searchController = TextEditingController(); //

  // โทนสีควบคุมตามรูปแบบภาพตัวอย่างเป๊ะๆ
  final Color primaryColor = const Color(0xFF9B59B6); //
  final Color darkPurple = const Color(0xFF7D3C98); //
  final Color lightPurple = const Color(0xFFF3E5F5); // สีม่วงพาสเทล
  final Color bgColor = const Color(0xFFFAFAFA); //
  final Color greyBorder = const Color(0xFFE1BEE7); // สีเส้นกรอบด้านใน

  @override
  void initState() {
    super.initState(); //
    
    // 🎯 สั่งตัดระบบจำรหัสค้างเก่าทิ้งทันทีที่ทำ Hot Restart/เริ่มรันแอปใหม่ เพื่อบังคับล็อกอินใหม่ทุกรอบ
    _autoLogoutOnStartup();

    _searchController.addListener(() {
      setState(() {}); //
    });
  }

  // 🎯 ฟังก์ชันล้างล็อกอินเก่าอัตโนมัติขณะดีบั๊ก/รันใหม่
  Future<void> _autoLogoutOnStartup() async {
    try {
      await FirebaseAuth.instance.signOut();
      print("🎯 รีเซ็ตระบบ: สั่งออกจากระบบเดิมเรียบร้อยแล้วตอนเริ่มต้นแอป");
    } catch (e) {
      print("Error auto logout: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose(); //
    super.dispose(); //
  }

  void _openFilterCalendar() async { //
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor, //
              onPrimary: Colors.white, //
              onSurface: darkPurple, //
            ),
          ),
          child: child!, //
        );
      },
    );
    if (selectedDate != null) {}
  }

  // ฟังก์ชันแสดงหน้าต่างเตือนให้เข้าสู่ระบบ
  void _showLoginRequiredDialog() { //
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), //
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30), //
            decoration: BoxDecoration(
              color: Colors.white, //
              borderRadius: BorderRadius.circular(20), //
              border: Border.all(color: primaryColor, width: 1.5), //
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, //
              children: [
                Icon(Icons.lock_person_outlined, size: 75, color: darkPurple), //
                const SizedBox(height: 20), //
                Text(
                  'กรุณาเข้าสู่ระบบก่อนใช้งาน', //
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkPurple), //
                ),
                const SizedBox(height: 12), //
                const Text(
                  'คุณต้องลงชื่อเข้าใช้งานในระบบก่อน จึงจะสามารถส่งคำขอผู้ดูแลและแก้ไขข้อมูลได้', //
                  textAlign: TextAlign.center, //
                  style: TextStyle(fontSize: 13, color: Colors.black), //
                ),
                const SizedBox(height: 25), //
                SizedBox(
                  width: double.infinity, //
                  height: 46, //
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, //
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)), //
                    ),
                    onPressed: () {
                      Navigator.pop(context); //
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()), //
                      );
                    },
                    child: const Text(
                      'ไปหน้าเข้าสู่ระบบ', //
                      style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold), //
                    ),
                  ),
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 199, 255), //
      appBar: AppBar(
        title: const Text('ขอใช้บริการ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), //
        centerTitle: true, //
        backgroundColor: primaryColor, //
        elevation: 0, //
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), //
          onPressed: () => Navigator.pop(context), //
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15), //
            Text(
              'ค้นหาบัญชี', //
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.8)), //
            ),
            const SizedBox(height: 12), //

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20), //
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44, //
                      decoration: BoxDecoration(
                        color: Colors.white, //
                        borderRadius: BorderRadius.circular(22), //
                        border: Border.all(color: Colors.black87, width: 1.2), //
                      ),
                      child: TextField(
                        controller: _searchController, //
                        decoration: const InputDecoration(
                          hintText: 'ค้นหา ชื่อ-นามสกุล หรือ ที่อยู่ (อำเภอ จังหวัด)', //
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey), //
                          prefixIcon: Icon(Icons.search, color: Colors.black54, size: 20), //
                          border: InputBorder.none, //
                          contentPadding: EdgeInsets.symmetric(vertical: 10), //
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), //
                  GestureDetector(
                    onTap: _openFilterCalendar, //
                    child: Container(
                      padding: const EdgeInsets.all(8), //
                      color: Colors.transparent, //
                      child: const Icon(Icons.tune, color: Colors.black, size: 26), //
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), //

            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('Login').onValue, //
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: primaryColor)); //
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('เกิดข้อผิดพลาดในการดึงข้อมูล')); //
                  }
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text('ไม่พบข้อมูลผู้ดูแลในระบบ')); //
                  }

                  final dynamic rootValue = snapshot.data!.snapshot.value; //
                  List<Map<String, dynamic>> caretakersList = []; //

                  if (rootValue is Map) { //
                    rootValue.forEach((userUidKey, userNodeValue) { //
                      if (userNodeValue is Map && userNodeValue.containsKey('Caretaker')) { //
                        final caretakerRawData = userNodeValue['Caretaker']; //
                        if (caretakerRawData != null) { //
                          final data = Map<String, dynamic>.from(caretakerRawData as Map); //
                          data['id'] = userUidKey; //
                          if (userNodeValue.containsKey('Vehicle')) { //
                            data['vehicle'] = Map<String, dynamic>.from(userNodeValue['Vehicle']); //
                          }
                          caretakersList.add(data); //
                        }
                      }
                    });
                  }

                  if (caretakersList.isEmpty) {
                    return const Center(child: Text('ไม่พบข้อมูลผู้ดูแลระบบในคลังข้อมูล')); //
                  }

                  final searchQuery = _searchController.text.toLowerCase(); //
                  final filteredList = caretakersList.where((data) {
                    final name = "${data['firstname'] ?? ''} ${data['lastname'] ?? ''}".toLowerCase(); //
                    final address = (data['address'] ?? '').toLowerCase(); //
                    return name.contains(searchQuery) || address.contains(searchQuery); //
                  }).toList();

                  if (filteredList.isEmpty) {
                    return const Center(child: Text('ไม่พบผลลัพธ์การค้นหา')); //
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20), //
                    itemCount: filteredList.length, //
                    itemBuilder: (context, index) {
                      final data = filteredList[index]; //
                      return _buildCaretakerCard(data, data['id']); //
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 65, //
        decoration: BoxDecoration(color: primaryColor), //
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, //
          children: [
            _buildBottomNavItem(Icons.home_outlined, 'บ้าน', false, onTap: () {}),
            _buildBottomNavItem(Icons.support_agent, 'ขอใช้บริการ', true, onTap: () {}), //
            _buildBottomNavItem(Icons.notifications_none, 'แจ้งเตือน', false, onTap: () {}),
            _buildBottomNavItem(
              Icons.person_outline, //
              'ญาติ', //
              false, //
              onTap: () async {
                // 1. ตรวจเช็คค่า UID ที่ได้รับส่งผ่านมาจากหน้า Login เป็นหลัก
                String? uid = widget.loggedUid;
                
                // 🎯 ถ้าเปิดแอปขึ้นมาใหม่/รีโค้ด แล้วค่าตัวแปร uid เป็น null ให้เด้งกล่องเตือนล็อกอินทันที
                if (uid == null) {
                  _showLoginRequiredDialog();
                  return;
                }

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  // 2. ดึงข้อมูลประวัติจริงจาก Realtime DB ด้วยคีย์ UID ของญาติ
                  final snapshot = await FirebaseDatabase.instance.ref('Login/$uid').get(); //
                  if (context.mounted) Navigator.pop(context); //

                  if (snapshot.exists && snapshot.value is Map) { //
                    final userData = Map<String, dynamic>.from(snapshot.value as Map); //

                    RelativeModel relative;
                    Map<String, dynamic> relativeMap = {};
                    
                    if (userData.containsKey('Relative')) {
                      relativeMap = Map<String, dynamic>.from(userData['Relative'] as Map);
                      relative = RelativeModel(
                        relativeId: relativeMap['relativeId'] ?? '',
                        firstname: relativeMap['firstname'] ?? '',
                        lastname: relativeMap['lastname'] ?? '',
                        phonenumber: relativeMap['phonenumber'] ?? '',
                        relationship: relativeMap['relationship'] ?? '',
                        email: relativeMap['email'] ?? '',
                      );
                    } else {
                      relative = RelativeModel(relativeId: '', firstname: '', lastname: '', phonenumber: '', relationship: '', email: '');
                    }

                    PatientModel patient;
                    if (relativeMap.containsKey('Patient')) {
                      final pData = Map<String, dynamic>.from(relativeMap['Patient'] as Map);
                      patient = PatientModel(
                        patientId: pData['patientId'] ?? '',
                        patientphoto: pData['patientphoto'] ?? '',
                        firstname: pData['firstname'] ?? '',
                        lastname: pData['lastname'] ?? '',
                        phonenumber: pData['phonenumber'] ?? '',
                        gender: pData['gender'] ?? '',
                        birthdate: pData['birthdate'] != null ? DateTime.tryParse(pData['birthdate'].toString()) : null,
                        disease: pData['disease'] ?? '',
                        mobility: pData['mobility'] ?? '',
                      );
                    } else {
                      patient = PatientModel(patientId: '', patientphoto: '', firstname: '', lastname: '', phonenumber: '', gender: '');
                    }

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditRelativeInfoPage(currentPatient: patient, currentRelative: relative, loggedUid: uid,), //
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลประวัติในระบบ'))); //
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); //
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red)); //
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaretakerCard(Map<String, dynamic> data, String docId) { //
    String firstname = data['firstname'] ?? 'ไม่ระบุ'; //
    String lastname = data['lastname'] ?? ''; //
    String fullName = "$firstname $lastname".trim(); //
    String location = data['address'] ?? 'ไม่ระบุ'; //
    String gender = data['gender'] ?? 'ไม่ระบุ'; //

    String carDetail = 'ไม่ระบุ'; //
    if (data['vehicle'] != null) { //
      final v = Map<String, dynamic>.from(data['vehicle'] as Map); //
      String brand = v['brand'] ?? ''; //
      String model = v['model'] ?? ''; //
      carDetail = "$brand $model".trim(); //
      if (carDetail.isEmpty) carDetail = 'ไม่ระบุ'; //
    }

    String status = data['servicestatus'] ?? 'Offline'; //
    bool isAvailable = (status.toLowerCase() == 'online' || status == 'พร้อมให้บริการ'); //
    double rating = data['rating'] != null ? (data['rating'] as num).toDouble() : 0.0; //
    int comments = data['comments'] ?? 0; //

    return Container(
      width: double.infinity, //
      margin: const EdgeInsets.only(bottom: 15), //
      padding: const EdgeInsets.all(12), //
      decoration: BoxDecoration(
        color: lightPurple.withValues(alpha: 0.3), //
        borderRadius: BorderRadius.circular(15), //
        border: Border.all(color: Colors.black, width: 1.5), //
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, //
        children: [
          CircleAvatar(
            radius: 25, //
            backgroundImage: data['profilephoto'] != null && data['profilephoto'].toString().isNotEmpty
                ? MemoryImage(base64Decode(data['profilephoto'])) //
                : null, //
            child: data['profilephoto'] == null || data['profilephoto'].toString().isEmpty ? const Icon(Icons.person) : null, //
          ),
          const SizedBox(width: 12), //
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, //
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, //
                  children: [
                    Expanded(
                      child: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis), //
                    ),
                    const SizedBox(width: 5), //
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), //
                      decoration: BoxDecoration(
                        color: isAvailable ? const Color(0xFF2ECC71).withOpacity(0.6) : const Color(0xFFF39C12).withOpacity(0.6), //
                        borderRadius: BorderRadius.circular(10), //
                      ),
                      child: Text(isAvailable ? 'พร้อมให้บริการ' : 'ไม่พร้อมให้บริการ', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)), //
                    ),
                  ],
                ),
                const SizedBox(height: 4), //
                Row(
                  children: [
                    Text('$rating ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), //
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(index < rating.floor() ? Icons.star : Icons.star_border, color: Colors.orange, size: 14); //
                      }),
                    ),
                    Text(comments == 0 ? '  ยังไม่มีรีวิว' : '  $comments คอมเมนต์', style: const TextStyle(fontSize: 12, color: Colors.black54, decoration: TextDecoration.underline)), //
                  ],
                ),
                const SizedBox(height: 6), //
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.black54), //
                    const SizedBox(width: 4), //
                    Expanded(child: Text('พื้นที่ให้บริการ: $location', style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)), //
                  ],
                ),
                const SizedBox(height: 4), //
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 14, color: Colors.black54), //
                    const SizedBox(width: 4), //
                    Expanded(child: Text('ยี่ห้อรถ: $carDetail', style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)), //
                  ],
                ),
                const SizedBox(height: 10), //
                Align(
                  alignment: Alignment.bottomRight, //
                  child: SizedBox(
                    height: 28, //
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor, //
                        padding: const EdgeInsets.symmetric(horizontal: 14), //
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), //
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CaretakerProfilePage(caretakerId: data['id']))); //
                      },
                      child: const Text('ดูรายละเอียด', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)), //
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

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) { //
    return InkWell(
      onTap: onTap, //
      borderRadius: BorderRadius.circular(8), //
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, //
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 24), //
          const SizedBox(height: 2), //
          Text(
            label, //
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70, //
              fontSize: 11, //
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal, //
            ),
          ),
        ],
      ),
    );
  }
}