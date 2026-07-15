import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:miniproject/views/caretaker/list_relative_request_page.dart';
import 'dart:convert';
import 'dart:io';
import 'login_page.dart';

// --- เปลี่ยน Path ให้ตรงกับโปรเจกต์ของคุณ ---
import '../services/auth_service.dart';
import '../models/vehicle_model.dart';
import '../models/vehicle_photo_model.dart';

class VehicleRegisterPage extends StatefulWidget {
  final String uid;
  const VehicleRegisterPage({super.key, required this.uid});

  @override
  State<VehicleRegisterPage> createState() => _VehicleRegisterPageState();
}

class _VehicleRegisterPageState extends State<VehicleRegisterPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _submitErrorMessage;

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  String _selectedVehicleType = "";

  // 🌟 1. แยกตัวแปรรับรูปภาพเป็น 2 มุม (ภายนอก และ ภายใน)
  File? _exteriorImageFile;
  String? _exteriorPhotoBase64;

  File? _interiorImageFile;
  String? _interiorPhotoBase64;

  File? _storageImageFile;
  String? _storagePhotoBase64;

  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF7D3C98);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color greyBorder = const Color(0xFFE1BEE7);

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  // 🌟 1. ฟังก์ชันเช็คว่าพิมพ์หรืออัปโหลดรูปค้างไว้หรือไม่
  bool get _hasAnyData {
    return [
          _brandController,
          _modelController,
          _licensePlateController,
          _colorController,
        ].any((c) => c.text.trim().isNotEmpty) ||
        _selectedVehicleType.isNotEmpty ||
        _exteriorImageFile != null ||
        _interiorImageFile != null;
  }

  // 🌟 2. ฟังก์ชันแจ้งเตือนก่อนออกไปหน้า Login
  Future<bool> _onWillPop() async {
    if (!_hasAnyData) return true;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกการเพิ่มข้อมูลยานพาหนะ?'),
        content: const Text(
          'ข้อมูลที่คุณกรอกจะสูญหาย คุณต้องการกลับไปหน้าเข้าสู่ระบบหรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('อยู่ต่อ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ออก', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  // --- ฟังก์ชันเกี่ยวกับรูปภาพ ---
  Future<void> _pickVehicleImage(Function(File, String) onPicked) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      int fileSizeInBytes = await file.length();
      if ((fileSizeInBytes / (1024 * 1024)) > 20) {
        _showErrorSnackBar('ขนาดไฟล์ต้องไม่เกิน 20MB');
        return;
      }
      List<int> imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);

      // ส่งค่ากลับไปบันทึกใน State
      onPicked(file, base64String);
    }
  }

  void _showImagePreview(File imageFile) {
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
                minScale: 0.5,
                maxScale: 4,
                child: Image.file(imageFile, fit: BoxFit.contain),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- ฟังก์ชันบันทึกข้อมูล ---
  void _submitVehicleInfo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehicleType.isEmpty) {
      _showErrorSnackBar('กรุณาเลือกประเภทรถยนต์');
      return;
    }

    // 🌟 2. ดักให้ผู้ใช้ต้องอัปโหลดให้ครบทั้ง 2 รูป
    if (_exteriorPhotoBase64 == null ||
        _interiorPhotoBase64 == null ||
        _storagePhotoBase64 == null) {
      _showErrorSnackBar('กรุณาอัปโหลดรูปถ่ายรถยนต์ให้ครบทั้ง 3 มุม');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // 🌟 3. สร้างก้อนข้อมูลรูปภาพ (VehiclePhotoModel) ทั้ง 2 มุม
      List<VehiclePhotoModel> photosList = [
        VehiclePhotoModel(
          vehiclephotoid: "exterior_photo",
          photo: _exteriorPhotoBase64,
        ),
        VehiclePhotoModel(
          vehiclephotoid: "interior_photo",
          photo: _interiorPhotoBase64,
        ),
        VehiclePhotoModel(
          vehiclephotoid: "storage_photo",
          photo: _storagePhotoBase64,
        ),
      ];

      VehicleModel vehicleData = VehicleModel(
        vehicleId: _licensePlateController.text.trim(),
        vehicletype: _selectedVehicleType,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        licenseplate: _licensePlateController.text.trim(),
        color: _colorController.text.trim(),
        vehiclephotos: photosList, // ยัดรูป 2 มุมลงไปเลย
      );
      bool success = await _authService.updateVehicleAndServiceStatus(
        uid: uid,
        vehicle: vehicleData,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'อัปเดตข้อมูลสำเร็จ! พร้อมรับงานแล้ว',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        // 🌟 2. เพิ่มโค้ดส่วนนี้ เพื่อพาไปหน้า Home และล้างประวัติหน้าจอเก่าทิ้ง
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ListRelativeRequestPage(uid: widget.uid),
          ), // เปลี่ยนชื่อคลาสให้ตรงกับหน้า Home ของคุณ
          (route) => false,
        );
      } else {
        setState(() => _submitErrorMessage = 'เกิดข้อผิดพลาดในการอัปเดตข้อมูล');
      }
    } catch (e) {
      setState(() => _submitErrorMessage = 'ระบบขัดข้อง: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop) {
          if (context.mounted) {
            // 🌟 1. Sign Out ออกจาก Firebase
            await FirebaseAuth.instance.signOut();
            // 🌟 2. ล้างหน้าจอที่ค้างอยู่ แล้วพากลับไปหน้า Login
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'ข้อมูลยานพาหนะ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                color: primaryColor.withOpacity(0.1),
                child: Column(
                  children: [
                    Icon(Icons.directions_car, size: 40, color: primaryColor),
                    const SizedBox(height: 10),
                    Text(
                      'ขั้นตอนสุดท้ายก่อนเริ่มรับงาน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkPurple,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'บัญชีของคุณได้รับการอนุมัติแล้ว\nกรุณาเพิ่มข้อมูลรถยนต์ของคุณเพื่อเปิดสถานะพร้อมให้บริการ',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // 🌟 ส่วนข้อมูลรถยนต์ (ย้ายมาไว้ข้างบนให้กรอกข้อมูลหลักก่อน)
                        _buildSectionContainer(
                          title: 'ข้อมูลยานพาหนะ',
                          children: [
                            _buildLabelField('ประเภทรถ', isRequired: true),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DropdownButtonFormField<String>(
                                value: _selectedVehicleType.isEmpty
                                    ? null
                                    : _selectedVehicleType,
                                decoration: InputDecoration(
                                  hintText: 'เลือกประเภทรถ',
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: greyBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: greyBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: primaryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'รถเก๋ง',
                                    child: Text('รถเก๋ง (Sedan)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'รถอเนกประสงค์',
                                    child: Text('รถอเนกประสงค์ (SUV)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'รถกระบะ',
                                    child: Text('รถกระบะ (Pickup)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'รถตู้',
                                    child: Text('รถตู้ (Van)'),
                                  ),
                                ],
                                onChanged: (val) => setState(
                                  () => _selectedVehicleType = val ?? '',
                                ),
                                validator: (val) => (val == null || val.isEmpty)
                                    ? 'กรุณาเลือกประเภทรถ'
                                    : null,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabelField(
                                        'ยี่ห้อ (Brand)',
                                        isRequired: true,
                                      ),
                                      _buildTextField(
                                        controller: _brandController,
                                        hint: 'เช่น Toyota',
                                        validator: (val) =>
                                            val!.isEmpty ? 'ระบุยี่ห้อ' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabelField(
                                        'รุ่น (Model)',
                                        isRequired: true,
                                      ),
                                      _buildTextField(
                                        controller: _modelController,
                                        hint: 'เช่น Altis',
                                        validator: (val) =>
                                            val!.isEmpty ? 'ระบุรุ่น' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            _buildLabelField('สีรถ', isRequired: true),
                            _buildTextField(
                              controller: _colorController,
                              hint: 'เช่น ขาว, ดำ, บรอนซ์เงิน',
                              validator: (val) =>
                                  val!.isEmpty ? 'ระบุสีรถ' : null,
                            ),

                            _buildLabelField('ทะเบียนรถ', isRequired: true),
                            _buildTextField(
                              controller: _licensePlateController,
                              hint: 'เช่น กข 1234 เชียงใหม่',
                              validator: (val) =>
                                  val!.isEmpty ? 'กรุณาระบุทะเบียนรถ' : null,
                            ),
                          ],
                        ),

                        // 🌟 ส่วนอัปโหลดรูปถ่ายรถยนต์ (แยก 2 มุม)
                        _buildSectionContainer(
                          title: 'อัปโหลดรูปรถยนต์เพื่อประเมินความพร้อม',
                          children: [
                            const Text(
                              'ผู้ป่วยและญาติจะเห็นรูปเหล่านี้ก่อนตัดสินใจเรียกใช้บริการ กรุณาใช้รูปที่ชัดเจนและสว่าง',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 15),

                            // มุมที่ 1: ภายนอกรถ
                            _buildPhotoUploadWidget(
                              title: '1. รูปภายนอกรถ',
                              description: '(ถ่ายให้เห็นลักษณะของรถ)',
                              imageFile: _exteriorImageFile,
                              onUpload: () => _pickVehicleImage((file, base64) {
                                setState(() {
                                  _exteriorImageFile = file;
                                  _exteriorPhotoBase64 = base64;
                                });
                              }),
                              onRemove: () => setState(() {
                                _exteriorImageFile = null;
                                _exteriorPhotoBase64 = null;
                              }),
                            ),

                            const SizedBox(height: 10),

                            // มุมที่ 2: ภายในรถ
                            _buildPhotoUploadWidget(
                              title: '2. รูปภายในห้องโดยสาร',
                              description:
                                  '(ถ่ายเบาะหลังหรือบริเวณที่ผู้ป่วยนั่ง)',
                              imageFile: _interiorImageFile,
                              onUpload: () => _pickVehicleImage((file, base64) {
                                setState(() {
                                  _interiorImageFile = file;
                                  _interiorPhotoBase64 = base64;
                                });
                              }),
                              onRemove: () => setState(() {
                                _interiorImageFile = null;
                                _interiorPhotoBase64 = null;
                              }),
                            ),
                            const SizedBox(height: 10),

                            // มุมที่ 2: ภายในรถ
                            _buildPhotoUploadWidget(
                              title: '3. รูปภายในห้องโดยสาร',
                              description:
                                  '(ถ่ายบริเวณที่เก็บอุปกรณ์สัมภาระของผู้ป่วย)',
                              imageFile: _storageImageFile,
                              onUpload: () => _pickVehicleImage((file, base64) {
                                setState(() {
                                  _storageImageFile = file;
                                  _storagePhotoBase64 = base64;
                                });
                              }),
                              onRemove: () => setState(() {
                                _storageImageFile = null;
                                _storagePhotoBase64 = null;
                              }),
                            ),
                          ],
                        ),

                        if (_submitErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFF44336),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _submitErrorMessage!,
                                      style: const TextStyle(
                                        color: Color(0xFFF44336),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 🌟 ปุ่มยืนยันด้านล่าง
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitVehicleInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'บันทึกข้อมูลและเริ่มรับงาน',
                            style: TextStyle(
                              fontSize: 16,
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
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: darkPurple,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabelField(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: greyBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: greyBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
        ),
      ),
    );
  }

  // 🌟 Widget พิเศษสำหรับอัปโหลดรูปรถ
  Widget _buildPhotoUploadWidget({
    required String title,
    required String description,
    required File? imageFile,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(description, style: TextStyle(fontSize: 12, color: primaryColor)),
        const SizedBox(height: 8),
        if (imageFile == null)
          InkWell(
            onTap: onUpload,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: greyBorder, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_a_photo, color: primaryColor, size: 30),
                  const SizedBox(height: 8),
                  Text(
                    'แตะเพื่ออัปโหลดรูปภาพ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showImagePreview(imageFile),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      imageFile,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'อัปโหลดสำเร็จ',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _showImagePreview(imageFile),
                        child: const Text(
                          'แตะที่รูปเพื่อดูขนาดเต็ม',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'ลบรูปภาพ',
                  onPressed: onRemove,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
