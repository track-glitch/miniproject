import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:geolocator/geolocator.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:miniproject/views/login_page.dart';

class ServiceRequestPage extends StatefulWidget {
  final Map<String, dynamic> caretakerData;
  final String caretakerId;
  final String? loggedUid;

  const ServiceRequestPage({
    super.key,
    required this.caretakerData,
    required this.caretakerId,
    this.loggedUid,
  });

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  final Color primaryColor = const Color(0xFF9B59B6);
  final Color bgColor = const Color(0xFFF3E5F5);

  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;

  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _customLocationController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  int _locationOption = 1; // 1 = ที่อยู่ปัจจุบัน, 2 = ระบุสถานที่รับ
  bool _isLoadingMap = false;

  // สำหรับแผนที่
  LatLng _selectedLocation = const LatLng(13.7563, 100.5018);
  bool _hasPinned = false;

  @override
  void initState() {
    super.initState();
  }

  // --- ระบบแผนที่ ---
  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
      bool hasPermission = await _requestLocationPermission();
      if (!hasPermission) return null;
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&accept-language=th',
    );
    try {
      final response = await http.get(url, headers: {'User-Agent': 'CaretakerAppFlutter'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          String subdistrict = address['subdistrict'] ?? address['village'] ?? address['suburb'] ?? '';
          String district = address['district'] ?? address['city_district'] ?? '';
          String province = address['state'] ?? address['province'] ?? '';
          setState(() {
            _selectedLocation = location;
            _hasPinned = true;
            _locationOption = 2;
            _customLocationController.text = "$subdistrict $district $province";
          });
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _showMapModal() async {
    setState(() => _isLoadingMap = true);
    LatLng? currentLocation = await _getCurrentLocation();
    setState(() => _isLoadingMap = false);

    LatLng initialLocation = currentLocation ?? _selectedLocation;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        LatLng tempLocation = initialLocation;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('คลิกบนแผนที่เพื่อย้ายตำแหน่งหมุด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: tempLocation,
                          initialZoom: 16.5,
                          onTap: (tapPosition, point) => setModalState(() => tempLocation = point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.miniproject',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: tempLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      onPressed: () {
                        Navigator.pop(context);
                        _getAddressFromLatLng(tempLocation);
                      },
                      child: const Text('ยืนยันตำแหน่งนี้', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.utc(2030, 12, 31),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatThaiDate(DateTime date) {
    final thaiMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('ส่งคำขอบริการ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // วันที่นัด
                const Text('วันที่นัดหมาย', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatThaiDate(_selectedDate), style: const TextStyle(fontSize: 14)),
                        const Icon(Icons.calendar_today, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // การ์ดผู้ดูแล
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: widget.caretakerData['profilephoto'] != null && widget.caretakerData['profilephoto'].toString().isNotEmpty
                            ? MemoryImage(base64Decode(widget.caretakerData['profilephoto'].toString().replaceAll('\n', '').trim()))
                            : null,
                        child: widget.caretakerData['profilephoto'] == null || widget.caretakerData['profilephoto'].toString().isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 35)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ผู้ดูแล', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                            Text(
                              'นาย ${widget.caretakerData['firstname'] ?? ''} ${widget.caretakerData['lastname'] ?? ''}'.trim(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Row(
                              children: [
                                Row(children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.orange, size: 14))),
                                const SizedBox(width: 4),
                                const Text('4.9 - 87 รีวิว', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 14, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text('เบอร์โทร ${widget.caretakerData['phonenumber'] ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('ระบุรายละเอียดคำขอ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _detailController,
                  maxLines: 3,
                  decoration: _inputDecoration(''),
                  validator: (value) => value!.isEmpty ? 'กรุณาระบุรายละเอียด' : null,
                ),
                const SizedBox(height: 16),

                const Text('ระบุสถานที่จุดรับ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ใช้ที่อยู่ปัจจุบันตามที่ระบุในโปรไฟล์', style: TextStyle(fontSize: 13)),
                  value: 1,
                  groupValue: _locationOption,
                  activeColor: primaryColor,
                  onChanged: (val) => setState(() => _locationOption = val as int),
                ),
                RadioListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('สถานที่จุดรับ', style: TextStyle(fontSize: 13)),
                  value: 2,
                  groupValue: _locationOption,
                  activeColor: primaryColor,
                  onChanged: (val) => setState(() => _locationOption = val as int),
                ),
                
                TextFormField(
                  controller: _customLocationController,
                  enabled: _locationOption == 2,
                  decoration: _inputDecoration('บ้านเลขที่ ถนน ตำบล อำเภอ').copyWith(
                    fillColor: _locationOption == 1 ? Colors.grey.shade100 : Colors.white,
                  ),
                  validator: (value) => _locationOption == 2 && value!.isEmpty ? 'กรุณาระบุสถานที่จุดรับ' : null,
                ),
                
                const SizedBox(height: 16),
                const Text('ปักหมุดบนแผนที่', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                
                InkWell(
                  onTap: _showMapModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_hasPinned ? 'แก้ไขจุดส่งบนแผนที่' : 'เลือกจุดส่งบนแผนที่', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                        const Icon(Icons.map_outlined, color: Colors.green, size: 28),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('ระบุโรงพยาบาล', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hospitalController,
                  decoration: _inputDecoration('ชื่อโรงพยาบาล'),
                  validator: (value) => value!.isEmpty ? 'กรุณาระบุโรงพยาบาล' : null,
                ),
                const SizedBox(height: 16),

                const Text('ระบุแผนกในโรงพยาบาล', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _departmentController,
                  decoration: _inputDecoration('ชื่อแผนก'),
                  validator: (value) => value!.isEmpty ? 'กรุณาระบุแผนก' : null,
                ),
                const SizedBox(height: 16),

                const Text('ระบุเวลานัดหมาย', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8), color: Colors.white),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedTime == null ? '--:-- --' : _selectedTime!.format(context), style: TextStyle(color: _selectedTime == null ? Colors.grey : Colors.black, fontSize: 14)),
                        const Icon(Icons.access_time, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && _selectedTime != null) {
                            String uid = widget.loggedUid ?? FirebaseAuth.instance.currentUser!.uid;
                            DatabaseReference requestRef = FirebaseDatabase.instance.ref().child("Login").child(uid).child("Relative").child("Request").push();
                            String requestId = requestRef.key!;
                            
                            DateTime appointmentDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime!.hour, _selectedTime!.minute);

                            await requestRef.set({
                              "requestId": requestId,
                              "caretakerId": widget.caretakerId,
                              "requestdetail": _detailController.text.trim(),
                              "pickuplocation": _locationOption == 1 ? "ที่อยู่จากโปรไฟล์ผู้ป่วย" : _customLocationController.text.trim(),
                              "dropofflocation": _hospitalController.text.trim(),
                              "hospitalname": _hospitalController.text.trim(),
                              "departmentname": _departmentController.text.trim(),
                              "appointmentdate": _selectedDate.toIso8601String(),
                              "appointmenttime": appointmentDateTime.toIso8601String(),
                              "requestdate": DateTime.now().toIso8601String(),
                              "requeststatus": "Pending",
                            });

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ส่งคำขอสำเร็จ"), backgroundColor: Colors.green));
                            Navigator.pop(context);
                          } else if (_selectedTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("กรุณาระบุเวลานัดหมาย"), backgroundColor: Colors.red));
                          }
                        },
                        child: const Text('ยืนยัน', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ยกเลิก', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'บ้าน'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'ขอใช้บริการ'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'แจ้งเตือน'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'ญาติ'),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor, width: 1.5)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}