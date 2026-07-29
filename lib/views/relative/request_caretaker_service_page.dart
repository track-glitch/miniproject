import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:miniproject/views/login_page.dart';
import 'package:miniproject/widgets/location_picker_widget.dart';

class ServiceRequestPage extends StatefulWidget {
  final Map<String, dynamic> caretakerData;
  final String caretakerId;
  final String? loggedUid;
  final DateTime? initialSelectedDate;

  const ServiceRequestPage({
    super.key,
    required this.caretakerData,
    required this.caretakerId,
    this.loggedUid,
    this.initialSelectedDate,
  });

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  final Color primaryColor = const Color(0xFF8763E6);
  final Color darkPurple = const Color.fromARGB(255, 153, 116, 255);
  final Color lightPurple = const Color(0xFFECE2FE);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;
  final Color borderColor = const Color(0xFFD3C2F0);
  final Color labelColor = const Color(0xFF241C2B);

  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  // สำหรับจุดรับ
  // 1 = กรอกที่อยู่เอง + ปักหมุดพิกัด, 2 = ระบุชื่อสถานที่นัดรับเอง
  int _pickupOption = 1;
  final TextEditingController _pickupNameController = TextEditingController();
  final TextEditingController _pickupAddressController =
      TextEditingController();
  LatLng _pickupLocation = const LatLng(13.7563, 100.5018);
  bool _pickupHasPinned = false;

  // สำหรับจุดส่ง
  // 1 = กรอกที่อยู่เอง + ปักหมุดพิกัด, 2 = ระบุชื่อสถานที่นัดส่งเอง
  int _dropoffOption = 1;
  final TextEditingController _dropoffNameController = TextEditingController();
  final TextEditingController _dropoffAddressController =
      TextEditingController();
  LatLng _dropoffLocation = const LatLng(13.7563, 100.5018);
  bool _dropoffHasPinned = false;

  // สถานะหุบ/ขยายของแผนที่จุดรับและจุดส่ง
  bool _pickupMapExpanded = false;
  bool _dropoffMapExpanded = false;

  // ข้อมูลจากโปรไฟล์
  Map<String, dynamic>? _relativeData;
  Map<String, dynamic>? _patientData;
  List<DateTime> _caretakerBusyDates = [];

  @override
  void initState() {
    super.initState();
    _selectedDate =
        widget.initialSelectedDate ??
        DateTime.now().add(const Duration(days: 1));
    _fetchProfileData();
    _fetchCaretakerBusyDates();
  }

  Future<void> _fetchProfileData() async {
    String uid = widget.loggedUid ?? FirebaseAuth.instance.currentUser!.uid;
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('Login/$uid/Relative')
          .get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _relativeData = data;
          if (data['Patient'] != null) {
            _patientData = Map<String, dynamic>.from(data['Patient'] as Map);
          }
        });
      }
    } catch (e) {
      print("Error fetch profile data: $e");
    }
  }

  Future<void> _fetchCaretakerBusyDates() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login').get();
      if (snapshot.exists && snapshot.value is Map) {
        final allUsers = snapshot.value as Map;
        List<DateTime> busy = [];

        allUsers.forEach((key, val) {
          if (val is Map &&
              val['Relative'] != null &&
              val['Relative']['Request'] != null) {
            final reqs = val['Relative']['Request'] as Map;
            reqs.forEach((reqId, reqData) {
              if (reqData['caretakerId'] == widget.caretakerId) {
                String status = (reqData['requeststatus'] ?? '')
                    .toString()
                    .toLowerCase();
                if (status == 'pending' ||
                    status == 'accepted' ||
                    status == 'pending_advice') {
                  String dateStr = reqData['appointmentdate'] ?? '';
                  if (dateStr.isNotEmpty) {
                    DateTime d = DateTime.parse(dateStr);
                    busy.add(DateTime(d.year, d.month, d.day));
                  }
                }
              }
            });
          }
        });
        setState(() {
          _caretakerBusyDates = busy;
        });
      }
    } catch (e) {
      print("Error fetching busy dates: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.utc(2030, 12, 31),
      selectableDayPredicate: (DateTime val) {
        DateTime checkDate = DateTime(val.year, val.month, val.day);
        return !_caretakerBusyDates.contains(checkDate);
      },
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
    final thaiMonths = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: darkPurple,
        elevation: 2,
        shadowColor: const Color.fromARGB(255, 153, 116, 255),
        centerTitle: true,
        title: const Text(
          'ส่งคำขอบริการ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 🌟 ส่วนที่ 1: ข้อมูลนัดหมาย ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('วันที่นัดหมาย', style: _labelStyle()),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatThaiDate(_selectedDate),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: primaryColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('เวลานัดหมาย', style: _labelStyle()),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedTime == null
                                        ? '--:-- น.'
                                        : '${_selectedTime!.format(context)} น.',
                                    style: TextStyle(
                                      color: _selectedTime == null
                                          ? Colors.grey
                                          : Colors.black,
                                      fontSize: 13,
                                      fontWeight: _selectedTime == null
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: primaryColor,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── 🌟 ส่วนที่ 2: ข้อมูลบุคคล ──
                Text('ข้อมูลผู้ป่วยและญาติ', style: _labelStyle()),
                const SizedBox(height: 8),
                _buildPatientCard(),
                _buildRelativeCard(),
                const SizedBox(height: 12),

                Text('ผู้ดูแลที่ให้บริการ', style: _labelStyle()),
                const SizedBox(height: 8),
                _buildCaretakerCard(),
                const SizedBox(height: 20),

                // ── 🌟 ส่วนที่ 3: ข้อมูลรายละเอียดการไปโรงพยาบาล ──
                Text('โรงพยาบาลที่ต้องการไปพบแพทย์', style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hospitalController,
                  style: const TextStyle(fontSize: 14),
                  decoration: _inputDecoration('ชื่อโรงพยาบาล'),
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาระบุโรงพยาบาล' : null,
                ),
                const SizedBox(height: 16),

                Text('ระบุแผนกในโรงพยาบาล', style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _departmentController,
                  style: const TextStyle(fontSize: 14),
                  decoration: _inputDecoration('ชื่อแผนก'),
                  validator: (value) => value!.isEmpty ? 'กรุณาระบุแผนก' : null,
                ),
                const SizedBox(height: 16),

                Text('ระบุรายละเอียดคำขอ', style: _labelStyle()),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _detailController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: _inputDecoration(
                    'อาการ หรือ สิ่งที่ต้องการให้ช่วยเหลือ...',
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณาระบุรายละเอียด' : null,
                ),
                const SizedBox(height: 28),
                const Divider(thickness: 1.5),
                const SizedBox(height: 12),

                // ── 🌟 ส่วนที่ 4: ข้อมูลการเดินทาง (Location) ──
                Text(
                  'ข้อมูลการเดินทาง',
                  style: _labelStyle().copyWith(fontSize: 16),
                ),
                const SizedBox(height: 16),

                _buildPickupSection(), // วิดเจ็ตจุดรับ

                const SizedBox(height: 16),

                _buildDropoffSection(), // วิดเจ็ตจุดส่ง

                const SizedBox(height: 28),

                // ── 🌟 ส่วนที่ 5: ปุ่มยืนยัน/ยกเลิก ──
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 4,
                          shadowColor: primaryColor.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (_pickupOption == 1 && !_pickupHasPinned) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("กรุณาปักหมุดพิกัดจุดรับ"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (_dropoffOption == 1 && !_dropoffHasPinned) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("กรุณาปักหมุดพิกัดจุดส่ง"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (_formKey.currentState!.validate() &&
                              _selectedTime != null) {
                            String uid =
                                widget.loggedUid ??
                                FirebaseAuth.instance.currentUser!.uid;
                            DatabaseReference requestRef = FirebaseDatabase
                                .instance
                                .ref()
                                .child("Login")
                                .child(uid)
                                .child("Relative")
                                .child("Request")
                                .push();
                            String requestId = requestRef.key!;

                            DateTime apptDT = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute,
                            );

                            Map<String, dynamic> pickupNode = {};
                            if (_pickupOption == 1) {
                              pickupNode = {
                                'locationName': 'ระบุที่อยู่',
                                'address': _pickupAddressController.text.trim(),
                                'latitude': _pickupLocation.latitude,
                                'longitude': _pickupLocation.longitude,
                              };
                            } else {
                              pickupNode = {
                                'locationName': _pickupNameController.text
                                    .trim(),
                                'address': _pickupNameController.text.trim(),
                                'latitude': 0.0,
                                'longitude': 0.0,
                              };
                            }

                            Map<String, dynamic> dropoffNode = {};
                            if (_dropoffOption == 1) {
                              dropoffNode = {
                                'locationName': 'ระบุที่อยู่',
                                'address': _dropoffAddressController.text
                                    .trim(),
                                'latitude': _dropoffLocation.latitude,
                                'longitude': _dropoffLocation.longitude,
                              };
                            } else {
                              dropoffNode = {
                                'locationName': _dropoffNameController.text
                                    .trim(),
                                'address': _dropoffNameController.text.trim(),
                                'latitude': 0.0,
                                'longitude': 0.0,
                              };
                            }

                            await requestRef.set({
                              "requestId": requestId,
                              "caretakerId": widget.caretakerId,
                              "requestdetail": _detailController.text.trim(),
                              "PickupLocation": pickupNode,
                              "DropoffLocation": dropoffNode,
                              "hospitalname": _hospitalController.text.trim(),
                              "departmentname": _departmentController.text
                                  .trim(),
                              "appointmentdate": _selectedDate
                                  .toIso8601String(),
                              "appointmenttime": apptDT.toIso8601String(),
                              "requestdate": DateTime.now().toIso8601String(),
                              "requeststatus": "Pending",
                            });

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("ส่งคำขอสำเร็จ"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          } else if (_selectedTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("กรุณาระบุเวลานัดหมาย"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'ยืนยัน',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'ยกเลิก',
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
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        backgroundColor: darkPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'บ้าน'),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'ขอใช้บริการ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'แจ้งเตือน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'ญาติ',
          ),
        ],
      ),
    );
  }

  // ---------------- วิดเจ็ตแยกสำหรับ จุดรับ (Pick-up) ----------------
  Widget _buildPickupSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('จุดนัดหมายรับ', style: _labelStyle().copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          RadioListTile(
            title: const Text(
              'ระบุที่อยู่จุดรับ',
              style: TextStyle(fontSize: 14),
            ),
            value: 1,
            groupValue: _pickupOption,
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            onChanged: (val) => setState(() => _pickupOption = val as int),
          ),
          RadioListTile(
            title: const Text(
              'ระบุชื่อสถานที่นัดรับเอง',
              style: TextStyle(fontSize: 14),
            ),
            value: 2,
            groupValue: _pickupOption,
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            onChanged: (val) => setState(() => _pickupOption = val as int),
          ),
          if (_pickupOption == 1)
            _buildAddressAndPinFields(
              addressController: _pickupAddressController,
              location: _pickupLocation,
              hasPinned: _pickupHasPinned,
              isExpanded: _pickupMapExpanded,
              onToggleMap: () =>
                  setState(() => _pickupMapExpanded = !_pickupMapExpanded),
              onLocationChanged: (loc) {
                setState(() {
                  _pickupLocation = loc;
                  _pickupHasPinned = true;
                });
              },
              addressLabel: 'สถานที่จุดรับ',
              addressErrorText: 'กรุณาระบุที่อยู่จุดรับ',
            ),
          if (_pickupOption == 2) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _pickupNameController,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration(
                'ระบุสถานที่ เช่น ปั๊มน้ำมัน..., โรงพยาบาล...',
              ),
              validator: (value) =>
                  value!.isEmpty ? 'กรุณาระบุจุดนัดหมายรับ' : null,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- วิดเจ็ตแยกสำหรับ จุดส่ง (Drop-off) ----------------
  Widget _buildDropoffSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('จุดนัดหมายส่ง', style: _labelStyle().copyWith(fontSize: 15)),
          const SizedBox(height: 12),
          RadioListTile(
            title: const Text(
              'ระบุที่อยู่จุดส่ง',
              style: TextStyle(fontSize: 14),
            ),
            value: 1,
            groupValue: _dropoffOption,
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            onChanged: (val) => setState(() => _dropoffOption = val as int),
          ),
          RadioListTile(
            title: const Text(
              'ระบุชื่อสถานที่นัดส่งเอง',
              style: TextStyle(fontSize: 14),
            ),
            value: 2,
            groupValue: _dropoffOption,
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            onChanged: (val) => setState(() => _dropoffOption = val as int),
          ),
          if (_dropoffOption == 1)
            _buildAddressAndPinFields(
              addressController: _dropoffAddressController,
              location: _dropoffLocation,
              hasPinned: _dropoffHasPinned,
              isExpanded: _dropoffMapExpanded,
              onToggleMap: () =>
                  setState(() => _dropoffMapExpanded = !_dropoffMapExpanded),
              onLocationChanged: (loc) {
                setState(() {
                  _dropoffLocation = loc;
                  _dropoffHasPinned = true;
                });
              },
              addressLabel: 'สถานที่จุดส่ง',
              addressErrorText: 'กรุณาระบุที่อยู่จุดส่ง',
            ),
          if (_dropoffOption == 2) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _dropoffNameController,
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration(
                'ระบุสถานที่ เช่น ปั๊มน้ำมัน..., โรงพยาบาล...',
              ),
              validator: (value) =>
                  value!.isEmpty ? 'กรุณาระบุจุดนัดหมายส่ง' : null,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- วิดเจ็ตรวม: กรอกที่อยู่เอง (manual) + ปุ่มเลือกพิกัดบนแผนที่ ----------------
  // ที่อยู่ (address) เป็นข้อความที่ผู้ใช้พิมพ์เอง ไม่ auto-fill จากโปรไฟล์หรือแผนที่
  // แผนที่ใช้เพื่อเลือก "พิกัด" (latitude/longitude) เท่านั้น
  Widget _buildAddressAndPinFields({
    required TextEditingController addressController,
    required LatLng location,
    required bool hasPinned,
    required bool isExpanded,
    required VoidCallback onToggleMap,
    required ValueChanged<LatLng> onLocationChanged,
    required String addressLabel,
    required String addressErrorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(addressLabel, style: _labelStyle().copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: addressController,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
          decoration: _inputDecoration('บ้านเลขที่ ถนน ตำบล อำเภอ จังหวัด เลขไปรษณีย์'),
          validator: (value) =>
              (value == null || value.isEmpty) ? addressErrorText : null,
        ),
        const SizedBox(height: 12),
        _buildPinButton(
          hasPinned: hasPinned,
          isExpanded: isExpanded,
          onTap: onToggleMap,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LocationPickerWidget(
                      initialLocation: location,
                      initialAddress: addressController.text,
                      showAddressTextField:
                          false, // 🌟 สั่งซ่อนช่องรายละเอียดที่อยู่เฉพาะหน้านี้
                      onLocationChanged: (loc, addr) {
                        onLocationChanged(loc);
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ปุ่มกดเพื่อเลือกพิกัดสถานที่บนแผนที่ (ไม่แสดงที่อยู่ เพราะแยกเป็นช่องกรอกต่างหากแล้ว)
  Widget _buildPinButton({
    required bool hasPinned,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasPinned ? lightPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPinned ? primaryColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.map_outlined,
              color: hasPinned ? primaryColor : Colors.grey.shade700,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasPinned
                    ? 'เลือกพิกัดแล้ว (แตะเพื่อแก้ไข)'
                    : 'กดเพื่อเลือกพิกัดสถานที่',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasPinned ? FontWeight.w600 : FontWeight.normal,
                  color: hasPinned ? primaryColor : Colors.grey.shade700,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down, color: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Helper Widgets พื้นฐาน ----------------

  Widget _buildPatientCard() {
    if (_patientData == null) return const SizedBox();
    return _buildInfoCard(
      title: 'ผู้ป่วย',
      firstName: _patientData!['firstname'] ?? '',
      lastName: _patientData!['lastname'] ?? '',
      phone: _patientData!['phonenumber'] ?? '-',
      photoBase64: _patientData!['patientphoto'],
      extraInfo:
          'โรคประจำตัว: ${_patientData!['disease'] ?? '-'} | การเดิน: ${_patientData!['mobility'] ?? '-'}',
    );
  }

  Widget _buildRelativeCard() {
    if (_relativeData == null) return const SizedBox();
    return _buildInfoCard(
      title: 'ญาติ (ผู้ติดต่อ)',
      firstName: _relativeData!['firstname'] ?? '',
      lastName: _relativeData!['lastname'] ?? '',
      phone: _relativeData!['phonenumber'] ?? '-',
      extraInfo: 'ความสัมพันธ์: ${_relativeData!['relationship'] ?? '-'}',
      showAvatar: false,
    );
  }

  Widget _buildCaretakerCard() {
    return _buildInfoCard(
      title: 'ผู้ดูแล',
      firstName: widget.caretakerData['firstname'] ?? '',
      lastName: widget.caretakerData['lastname'] ?? '',
      phone: widget.caretakerData['phonenumber'] ?? '-',
      photoBase64: widget.caretakerData['profilephoto'],
      isCaretaker: true,
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String firstName,
    required String lastName,
    required String phone,
    String? photoBase64,
    String? extraInfo,
    bool isCaretaker = false,
    bool showAvatar = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            CircleAvatar(
              radius: 28,
              backgroundColor: lightPurple,
              backgroundImage: photoBase64 != null && photoBase64.isNotEmpty
                  ? MemoryImage(
                      base64Decode(photoBase64.replaceAll('\n', '').trim()),
                    )
                  : null,
              child: (photoBase64 == null || photoBase64.isEmpty)
                  ? Icon(Icons.person, color: primaryColor, size: 35)
                  : null,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'คุณ $firstName $lastName'.trim(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isCaretaker) ...[
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '4.9 - 87 รีวิว',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
                if (extraInfo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    extraInfo,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      'เบอร์โทร $phone',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle() {
    return TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: labelColor,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
