import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🌟 เพิ่ม import สำหรับบังคับกรอกตัวเลข
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:miniproject/views/relative/relative_home_page.dart';
import 'package:miniproject/widgets/location_picker_widget.dart';

import 'package:miniproject/models/patient_model.dart';
import 'package:miniproject/models/relative_model.dart';

class EditRelativeInfoPage extends StatefulWidget {
  final PatientModel currentPatient;
  final RelativeModel currentRelative;
  final String loggedUid;

  const EditRelativeInfoPage({
    super.key,
    required this.currentPatient,
    required this.currentRelative,
    required this.loggedUid,
  });

  @override
  State<EditRelativeInfoPage> createState() => _EditRelativeInfoPageState();
}

class _EditRelativeInfoPageState extends State<EditRelativeInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;

  // 🌟 State สำหรับรองรับผู้ป่วยหลายคนภายใต้โหนด Patient/{patientId}
  Map<String, Map<String, dynamic>> _patientsData = {};
  String _currentPatientKey = '';
  bool _isAddingNewPatient = false;

  // 🎨 โทนสีม่วง
  final Color primaryColor = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF9B59B6);
  final Color lightPurple = const Color(0xFFF3E5F5);
  final Color bgColor = const Color.fromARGB(255, 225, 202, 255);
  final Color greyBorder = const Color(0xFF9B59B6);

  final Color headerGradientStart = const Color(0xFF9B59B6);
  final Color headerGradientEnd = const Color(0xFF9B59B6);
  final Color bgGradientTop = const Color.fromARGB(255, 225, 202, 255);
  final Color bgGradientBottom = const Color.fromARGB(255, 225, 202, 255);
  final Color cardColor = Colors.white;

  LatLng _selectedLocation = const LatLng(13.7563, 100.5018);
  bool _hasPinned = false;

  File? _profileImageFile;
  String? _profilePhotoBase64;

  final TextEditingController _patFirstNameController = TextEditingController();
  final TextEditingController _patLastNameController = TextEditingController();
  final TextEditingController _patIdCardController = TextEditingController();
  final TextEditingController _patLineIdController = TextEditingController();
  final TextEditingController _patPhoneController = TextEditingController();
  final TextEditingController _patGenderController = TextEditingController();
  final TextEditingController _patBirthDateController = TextEditingController();
  final TextEditingController _patAgeController = TextEditingController();
  final TextEditingController _patDiseaseController = TextEditingController();
  final TextEditingController _patAddressController = TextEditingController();

  String _selectedPatMobility = "ปกติ";
  final TextEditingController _patMobilityController = TextEditingController();

  final TextEditingController _relFirstNameController = TextEditingController();
  final TextEditingController _relLastNameController = TextEditingController();
  final TextEditingController _relEmailController = TextEditingController();
  final TextEditingController _relPhoneController = TextEditingController();
  final TextEditingController _relLineIdController = TextEditingController();
  final TextEditingController _relRelationController = TextEditingController();

  String _initialRelEmail = '';
  String _initialRelPhone = '';
  String _initialPatPhone = '';

  @override
  void initState() {
    super.initState();
    _initRelativeData();

    _fetchAndForceShowData().then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _calculateAge(String birthDateStr) {
    if (birthDateStr.isEmpty) {
      _patAgeController.text = '';
      return;
    }
    try {
      List<String> parts = birthDateStr.split('/');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);

        if (year > 2400) {
          year -= 543;
        }

        DateTime birthDate = DateTime(year, month, day);
        DateTime today = DateTime.now();

        int age = today.year - birthDate.year;
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }

        _patAgeController.text = age >= 0 ? '$age ปี' : '0 ปี';
      }
    } catch (e) {
      _patAgeController.text = '';
    }
  }

  void _initRelativeData() {
    _relFirstNameController.text = widget.currentRelative.firstname ?? '';
    _relLastNameController.text = widget.currentRelative.lastname ?? '';
    _relEmailController.text = widget.currentRelative.email ?? '';
    _relPhoneController.text = widget.currentRelative.phonenumber ?? '';
    _relLineIdController.text = widget.currentRelative.lineId ?? '';
    _relRelationController.text = widget.currentRelative.relationship ?? '';

    _initialRelEmail = (widget.currentRelative.email ?? '').trim().toLowerCase();
    _initialRelPhone = (widget.currentRelative.phonenumber ?? '').trim();
  }

  Future<void> _fetchAndForceShowData() async {
    String uid = widget.loggedUid;

    if (uid.isNotEmpty) {
      final relSnapshot =
          await FirebaseDatabase.instance.ref('Login/$uid/Relative').get();

      if (!mounted) return;

      if (relSnapshot.exists && relSnapshot.value is Map) {
        final relData = Map<String, dynamic>.from(relSnapshot.value as Map);
        
        _patLineIdController.text = relData['lineId'] ?? _patLineIdController.text;
        _relLineIdController.text = relData['lineId'] ?? _relLineIdController.text;
        _relEmailController.text = relData['email'] ?? _relEmailController.text;
        _relPhoneController.text = relData['phonenumber'] ?? _relPhoneController.text;

        _initialRelEmail = _relEmailController.text.trim().toLowerCase();
        _initialRelPhone = _relPhoneController.text.trim();

        _patientsData.clear();

        // 🌟 ดึงข้อมูลจากโหนด Patient ย่อย (รองรับทั้ง 'Patient' และ 'patients')
        dynamic patientNode = relData['Patient'] ?? relData['patients'];
        if (patientNode != null && patientNode is Map) {
          final pMap = Map<String, dynamic>.from(patientNode);
          pMap.forEach((pKey, pVal) {
            if (pVal is Map) {
              _patientsData[pKey.toString()] = Map<String, dynamic>.from(pVal);
            }
          });
        }

        // รองรับ fallback ข้อมูลแบบเดิมถ้ายังมีตกค้าง
        if (_patientsData.isEmpty) {
          relData.forEach((key, value) {
            if (key.startsWith('Patient') && value is Map) {
              _patientsData[key] = Map<String, dynamic>.from(value);
            }
          });
        }

        if (_patientsData.isNotEmpty) {
          // 🌟 ตรวจสอบว่ามีผู้ป่วยที่เลือกไว้ล่าสุดหรือไม่ (activePatientNode)
          if (relData.containsKey('activePatientNode') &&
              _patientsData.containsKey(relData['activePatientNode'].toString())) {
            _currentPatientKey = relData['activePatientNode'].toString();
          } else {
            _currentPatientKey = _patientsData.keys.first;
          }
          _isAddingNewPatient = false;
          _loadPatientDataToForm(_currentPatientKey);
        } else {
          _prepareNewPatient();
        }
      }
    }
  }

  void _loadPatientDataToForm(String patientKey) {
    if (!_patientsData.containsKey(patientKey)) return;

    final data = _patientsData[patientKey]!;
    
    setState(() {
      _patFirstNameController.text = data['firstname']?.toString() ?? '';
      _patLastNameController.text = data['lastname']?.toString() ?? '';
      _patIdCardController.text = data['patientId']?.toString() ?? '';
      _patGenderController.text = data['gender']?.toString() ?? '';
      _patDiseaseController.text = data['disease']?.toString() ?? '';
      _patPhoneController.text = data['phonenumber']?.toString() ?? '';
      _initialPatPhone = _patPhoneController.text.trim();

      if (data['Location'] != null && data['Location'] is Map) {
        final loc = Map<String, dynamic>.from(data['Location'] as Map);
        _patAddressController.text = loc['address']?.toString() ?? '';
        double lat = double.tryParse(loc['latitude']?.toString() ?? '0') ?? 0.0;
        double lng = double.tryParse(loc['longitude']?.toString() ?? '0') ?? 0.0;
        if (lat != 0.0 && lng != 0.0) {
          _selectedLocation = LatLng(lat, lng);
          _hasPinned = true;
        } else {
          _hasPinned = false;
        }
      } else {
        _patAddressController.text = data['address']?.toString() ?? '';
        double lat = double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0;
        double lng = double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0;
        if (lat != 0.0 && lng != 0.0) {
          _selectedLocation = LatLng(lat, lng);
          _hasPinned = true;
        } else {
          _hasPinned = false;
        }
      }

      String fetchedMobility = data['mobility']?.toString() ?? 'ปกติ';
      if (fetchedMobility.startsWith('ไม่ปกติ')) {
        _selectedPatMobility = 'ไม่ปกติ';
        if (fetchedMobility.contains(': ')) {
          _patMobilityController.text = fetchedMobility.split(': ')[1];
        } else {
          _patMobilityController.text = fetchedMobility.replaceFirst('ไม่ปกติ', '').trim();
        }
      } else {
        _selectedPatMobility = 'ปกติ';
        _patMobilityController.clear();
      }

      if (data['birthdate'] != null) {
        try {
          DateTime parsedDate = DateTime.parse(data['birthdate'].toString());
          _patBirthDateController.text =
              "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year + 543}";
        } catch (e) {
          _patBirthDateController.text = data['birthdate'].toString();
        }
        _calculateAge(_patBirthDateController.text);
      } else {
        _patBirthDateController.clear();
        _patAgeController.clear();
      }

      _profilePhotoBase64 = data['patientphoto']?.toString();
      _profileImageFile = null;
    });
  }

  void _prepareNewPatient() {
    setState(() {
      _isAddingNewPatient = true;
      _currentPatientKey = '';
      
      _patFirstNameController.clear();
      _patLastNameController.clear();
      _patIdCardController.clear();
      _patGenderController.clear();
      _patDiseaseController.clear();
      _patPhoneController.clear();
      _patBirthDateController.clear();
      _patAgeController.clear();
      _patAddressController.clear();
      _patMobilityController.clear();
      
      _selectedPatMobility = 'ปกติ';
      _hasPinned = false;
      _profileImageFile = null;
      _profilePhotoBase64 = null;
      _initialPatPhone = '';
    });
  }

  @override
  void dispose() {
    _patFirstNameController.dispose();
    _patLastNameController.dispose();
    _patIdCardController.dispose();
    _patLineIdController.dispose();
    _patPhoneController.dispose();
    _patGenderController.dispose();
    _patBirthDateController.dispose();
    _patAgeController.dispose();
    _patDiseaseController.dispose();
    _patAddressController.dispose();
    _patMobilityController.dispose();

    _relFirstNameController.dispose();
    _relLastNameController.dispose();
    _relEmailController.dispose();
    _relPhoneController.dispose();
    _relLineIdController.dispose();
    _relRelationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      List<int> imageBytes = await file.readAsBytes();
      setState(() {
        _profileImageFile = file;
        _profilePhotoBase64 = base64Encode(imageBytes);
      });
    }
  }

  Future<void> _selectBirthDate() async {
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 20),
    );
    try {
      if (_patBirthDateController.text.isNotEmpty) {
        final parts = _patBirthDateController.text.split('/');
        int year = int.parse(parts[2]);
        if (year > 2400) year -= 543;
        initialDate = DateTime(year, int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _patBirthDateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year + 543}";
        _calculateAge(_patBirthDateController.text);
      });
    }
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 🌟 ตรวจสอบว่าเลือกเพศหรือยัง
    if (_patGenderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กรุณาเลือกเพศของผู้ป่วย'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final String relEmail = _relEmailController.text.trim().toLowerCase();
    final String relPhone = _relPhoneController.text.trim();
    final String patPhone = _patPhoneController.text.trim();
    final String patIdCard = _patIdCardController.text.trim();

    if (relPhone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(relPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กรุณากรอกเบอร์โทรศัพท์ญาติให้ถูกต้อง (ตัวเลข 10 หลัก)'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (patPhone.isNotEmpty && (patPhone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(patPhone))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กรุณากรอกเบอร์โทรศัพท์ผู้ป่วยให้ถูกต้อง (ตัวเลข 10 หลัก)'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (patIdCard.length != 13 || !RegExp(r'^[0-9]+$').hasMatch(patIdCard)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กรุณากรอกหมายเลขบัตรประชาชนผู้ป่วยให้ครบ 13 หลัก'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (relEmail.isNotEmpty && !emailRegex.hasMatch(relEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('รูปแบบอีเมลไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String uid = widget.loggedUid;

      bool needCheckRelEmail = relEmail != _initialRelEmail;
      bool needCheckRelPhone = relPhone != _initialRelPhone;
      bool needCheckPatPhone = patPhone.isNotEmpty && patPhone != _initialPatPhone;

      if (needCheckRelEmail || needCheckRelPhone || needCheckPatPhone) {
        final snapshot = await FirebaseDatabase.instance.ref('Login').get();
        if (snapshot.exists && snapshot.value is Map) {
          final allUsers = Map<String, dynamic>.from(snapshot.value as Map);

          for (var entry in allUsers.entries) {
            String userKey = entry.key;
            var userData = entry.value;

            if (userKey == uid) continue;

            if (userData is Map) {
              if (userData['Caretaker'] is Map) {
                var cData = userData['Caretaker'];
                String cPhone = (cData['phonenumber'] ?? '').toString().trim();
                String cEmail = (cData['email'] ?? '').toString().trim().toLowerCase();

                if (needCheckRelEmail && cEmail.isNotEmpty && cEmail == relEmail) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('อีเมลนี้ถูกใช้งานแล้วในระบบ กรุณาใช้อีเมลอื่น'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                if (needCheckRelPhone && cPhone.isNotEmpty && cPhone == relPhone) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('เบอร์โทรศัพท์ญาตินี้ถูกใช้งานแล้วในระบบ'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                if (needCheckPatPhone && cPhone.isNotEmpty && cPhone == patPhone) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('เบอร์โทรศัพท์ผู้ป่วยนี้ถูกใช้งานแล้วในระบบ'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
              }

              if (userData['Relative'] is Map) {
                var rData = userData['Relative'];
                String rPhone = (rData['phonenumber'] ?? '').toString().trim();
                String rEmail = (rData['email'] ?? '').toString().trim().toLowerCase();

                if (needCheckRelEmail && rEmail.isNotEmpty && rEmail == relEmail) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('อีเมลนี้ถูกใช้งานแล้วในระบบ กรุณาใช้อีเมลอื่น'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                if (needCheckRelPhone && rPhone.isNotEmpty && rPhone == relPhone) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('เบอร์โทรศัพท์ญาตินี้ถูกใช้งานแล้วในระบบ'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                if (needCheckPatPhone && rPhone.isNotEmpty && rPhone == patPhone) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('เบอร์โทรศัพท์ผู้ป่วยนี้ตรงกับเบอร์ญาติคนอื่นในระบบ'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }

                dynamic pNode = rData['Patient'] ?? rData['patients'];
                if (pNode is Map) {
                  pNode.forEach((k, v) {
                    if (v is Map) {
                      String pPhone = (v['phonenumber'] ?? '').toString().trim();
                      if (needCheckPatPhone && pPhone.isNotEmpty && pPhone == patPhone) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('เบอร์โทรศัพท์ผู้ป่วยนี้ถูกใช้งานแล้วในระบบ'),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }
                    }
                  });
                }
              }
            }
          }
        }
      }

      if (uid.isNotEmpty) {
        // 🌟 กำหนด Key ของผู้ป่วย: ถ้าเพิ่มใหม่ให้ใช้หมายเลขบัตรประชาชน (หรือ Key เดิมกรณีแก้ไข)
        String targetPatientKey = _isAddingNewPatient ? patIdCard : _currentPatientKey;
        if (targetPatientKey.isEmpty) {
          targetPatientKey = patIdCard;
        }

        // 🌟 บันทึกข้อมูลญาติ และตั้ง activePatientNode
        await FirebaseDatabase.instance.ref('Login/$uid/Relative').update({
          'firstname': _relFirstNameController.text.trim(),
          'lastname': _relLastNameController.text.trim(),
          'email': relEmail,
          'phonenumber': relPhone,
          'lineId': _relLineIdController.text.trim(),
          'relationship': _relRelationController.text.trim(),
          'activePatientNode': targetPatientKey,
        });

        String finalMobility = _selectedPatMobility == 'ไม่ปกติ'
            ? 'ไม่ปกติ: ${_patMobilityController.text.trim()}'
            : 'ปกติ';

        // 🌟 บันทึกข้อมูลผู้ป่วยลงในโหนด Login/$uid/Relative/Patient/$targetPatientKey
        await FirebaseDatabase.instance
            .ref('Login/$uid/Relative/Patient/$targetPatientKey')
            .update({
              'patientId': patIdCard,
              'firstname': _patFirstNameController.text.trim(),
              'lastname': _patLastNameController.text.trim(),
              'phonenumber': patPhone,
              'gender': _patGenderController.text.trim(),
              'birthdate': _patBirthDateController.text.trim(),
              'disease': _patDiseaseController.text.trim(),
              'mobility': finalMobility,
              'patientphoto': _profilePhotoBase64 ?? '',
              'address': _patAddressController.text.trim(),
              'latitude': _hasPinned ? _selectedLocation.latitude : 0.0,
              'longitude': _hasPinned ? _selectedLocation.longitude : 0.0,
              'Location': {
                'address': _patAddressController.text.trim(),
                'latitude': _hasPinned ? _selectedLocation.latitude : 0.0,
                'longitude': _hasPinned ? _selectedLocation.longitude : 0.0,
              },
            });

        _initialRelEmail = relEmail;
        _initialRelPhone = relPhone;
        _initialPatPhone = patPhone;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสำเร็จแล้ว'))
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RelativeHomePage(loggedUid: widget.loggedUid),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 ดึงชื่อผู้ป่วยมาแสดงใน Dropdown
    List<DropdownMenuItem<String>> dropdownItems = [];
    
    _patientsData.keys.forEach((key) {
      final pData = _patientsData[key]!;
      String fname = pData['firstname']?.toString().trim() ?? '';
      String lname = pData['lastname']?.toString().trim() ?? '';
      String displayName = '';
      
      if (fname.isNotEmpty || lname.isNotEmpty) {
        displayName = '$fname $lname';
      } else {
        displayName = 'ผู้ป่วย ID: $key';
      }
          
      dropdownItems.add(
        DropdownMenuItem(
          value: key,
          child: Text(
            displayName, 
            style: TextStyle(fontWeight: FontWeight.bold, color: darkPurple, fontSize: 16),
          ),
        ),
      );
    });

    dropdownItems.add(
      DropdownMenuItem(
        value: 'NEW',
        child: Row(
          children: [
            Icon(Icons.add_circle, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'เพิ่มผู้ป่วยใหม่', 
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );

    String selectedValue = _isAddingNewPatient ? 'NEW' : _currentPatientKey;

    return Scaffold(
      backgroundColor: bgGradientBottom,
      appBar: AppBar(
        title: const Text(
          'แก้ไขข้อมูลผู้ป่วยและญาติ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [headerGradientStart, headerGradientEnd],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RelativeHomePage(loggedUid: widget.loggedUid),
              ),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgGradientTop, bgGradientBottom],
            stops: const [0.0, 0.35],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        
                        // 🌟 ส่วน UI เลือกผู้ป่วยแบบ Dropdown
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: primaryColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: (selectedValue.isNotEmpty && 
                                     (selectedValue == 'NEW' || _patientsData.containsKey(selectedValue)))
                                  ? selectedValue 
                                  : (_patientsData.isNotEmpty ? _patientsData.keys.first : null),
                              isExpanded: true,
                              icon: Icon(Icons.keyboard_arrow_down, color: primaryColor, size: 28),
                              items: dropdownItems,
                              onChanged: (String? newValue) {
                                if (newValue == 'NEW') {
                                  _prepareNewPatient();
                                } else if (newValue != null) {
                                  setState(() {
                                    _isAddingNewPatient = false;
                                    _currentPatientKey = newValue;
                                    _loadPatientDataToForm(newValue);
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                        _buildProfileImageSection(),
                        const SizedBox(height: 20),

                        _buildSectionContainer(
                          title: _isAddingNewPatient ? 'เพิ่มข้อมูลผู้ป่วยใหม่' : 'ข้อมูลผู้ป่วย',
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'ชื่อจริง',
                                    controller: _patFirstNameController,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'นามสกุล',
                                    controller: _patLastNameController,
                                  ),
                                ),
                              ],
                            ),
                            _buildInputField(
                              hint: 'หมายเลขบัตรประชาชน',
                              controller: _patIdCardController,
                              keyboardType: TextInputType.number,
                              maxLength: 13,
                              readOnly: !_isAddingNewPatient,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 🌟 บังคับตัวเลข
                            ),
                            _buildInputField(
                              hint: 'ไอดีไลน์ผู้ป่วย (ถ้ามี)',
                              controller: _patLineIdController,
                              isRequired: false,
                            ),
                            _buildInputField(
                              hint: 'เบอร์โทรศัพท์ผู้ป่วย',
                              controller: _patPhoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 🌟 บังคับตัวเลข
                            ),
                            
                            // 🌟 ชุด UI เพศ เปลี่ยนเป็นแบบ Radio
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4, left: 2),
                                  child: Row(
                                    children: [
                                      Text('เพศ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF9B59B6))),
                                      Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: 'ชาย',
                                        groupValue: _patGenderController.text,
                                        activeColor: primaryColor,
                                        onChanged: (value) {
                                          setState(() {
                                            _patGenderController.text = value!;
                                          });
                                        },
                                      ),
                                      const Text('ชาย', style: TextStyle(fontSize: 14)),
                                      const SizedBox(width: 20),
                                      Radio<String>(
                                        value: 'หญิง',
                                        groupValue: _patGenderController.text,
                                        activeColor: primaryColor,
                                        onChanged: (value) {
                                          setState(() {
                                            _patGenderController.text = value!;
                                          });
                                        },
                                      ),
                                      const Text('หญิง', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _buildInputField(
                                    hint: 'วันเกิด [DD/MM/YYYY]',
                                    controller: _patBirthDateController,
                                    readOnly: true,
                                    onTap: _selectBirthDate,
                                    suffixIcon: const Icon(
                                      Icons.calendar_month,
                                      color: Color(0xFF9B59B6),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 4,
                                  child: _buildInputField(
                                    hint: 'อายุ',
                                    controller: _patAgeController,
                                    enabled: false,
                                  ),
                                ),
                              ],
                            ),
                            _buildInputField(
                              hint: 'โรคประจำตัว (ถ้าไม่มีให้เว้นว่าง)',
                              controller: _patDiseaseController,
                              isRequired: false,
                            ),
                            _buildMobilitySection(),
                          ],
                        ),

                        _buildSectionContainer(
                          title: 'ข้อมูลที่อยู่ผู้ป่วย',
                          children: [
                            LocationPickerWidget(
                              key: ValueKey(
                                '${_selectedLocation.latitude}_${_selectedLocation.longitude}_${_patAddressController.text}',
                              ),
                              initialLocation: _selectedLocation,
                              initialAddress: _patAddressController.text,
                              onLocationChanged: (newLocation, newAddress) {
                                setState(() {
                                  _selectedLocation = newLocation;
                                  _patAddressController.text = newAddress;
                                  _hasPinned = true;
                                });
                              },
                            ),
                          ],
                        ),

                        _buildSectionContainer(
                          title: 'ข้อมูลติดต่อญาติ (ข้อมูลเดียวกันทุกผู้ป่วย)',
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'ชื่อจริงญาติ',
                                    controller: _relFirstNameController,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'นามสกุลญาติ',
                                    controller: _relLastNameController,
                                  ),
                                ),
                              ],
                            ),
                            _buildInputField(
                              hint: 'อีเมล (Email) (ถ้ามี)',
                              controller: _relEmailController,
                              keyboardType: TextInputType.emailAddress,
                              isRequired: false,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'เบอร์โทรศัพท์ญาติ',
                                    controller: _relPhoneController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 🌟 บังคับตัวเลข
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInputField(
                                    hint: 'ไอดีไลน์ญาติ (ถ้ามี)',
                                    controller: _relLineIdController,
                                    isRequired: false,
                                  ),
                                ),
                              ],
                            ),
                            _buildInputField(
                              hint: 'ความสัมพันธ์กับผู้ป่วย',
                              controller: _relRelationController,
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    elevation: 4,
                                    shadowColor: primaryColor.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _handleSave,
                                  child: const Text(
                                    'บันทึก',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: primaryColor.withOpacity(0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RelativeHomePage(loggedUid: widget.loggedUid),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'ยกเลิก',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: darkPurple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 16,
                decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkPurple)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    ImageProvider? imageProvider;
    try {
      if (_profileImageFile != null) {
        imageProvider = FileImage(_profileImageFile!);
      } else if (_profilePhotoBase64 != null && _profilePhotoBase64!.isNotEmpty) {
        String cleanBase64 = _profilePhotoBase64!.trim();
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        imageProvider = MemoryImage(base64Decode(cleanBase64));
      }
    } catch (e) {
      imageProvider = null;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: CircleAvatar(
                radius: 43,
                backgroundColor: primaryColor,
                child: CircleAvatar(
                  radius: 41,
                  backgroundColor: Colors.white,
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Icon(Icons.person, size: 55, color: primaryColor.withOpacity(0.6))
                      : null,
                ),
              ),
            ),
            InkWell(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text('รูปโปรไฟล์ผู้ป่วย', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
      ],
    );
  }

  Widget _buildMobilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 2),
          child: Row(
            children: const [
              Text('สภาพร่างกายในการเคลื่อนไหว', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Radio<String>(
                    value: 'ปกติ',
                    groupValue: _selectedPatMobility,
                    activeColor: primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _selectedPatMobility = value!;
                        _patMobilityController.clear();
                      });
                    },
                  ),
                  const Text('ปกติ', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: 'ไม่ปกติ',
                    groupValue: _selectedPatMobility,
                    activeColor: primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _selectedPatMobility = value!;
                      });
                    },
                  ),
                  const Text('ไม่ปกติ', style: TextStyle(fontSize: 14)),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: _buildInputField(
                    hint: 'โปรดระบุ (เช่น ต้องพยุง, นั่งรถเข็น, ติดเตียง)',
                    controller: _patMobilityController,
                    maxLength: 100,
                    isRequired: _selectedPatMobility == 'ไม่ปกติ',
                    validator: (val) {
                      if (_selectedPatMobility == 'ไม่ปกติ' && (val == null || val.trim().isEmpty)) {
                        return 'กรุณาระบุอาการเมื่อเลือก "ไม่ปกติ"';
                      }
                      return null;
                    },
                  ),
                ),
                crossFadeState: _selectedPatMobility == 'ไม่ปกติ' ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
    Widget? suffixIcon,
    bool isRequired = true,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters, // 🌟 1. เพิ่ม property รับ Formatter
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        readOnly: readOnly,
        enabled: enabled,
        onTap: onTap,
        inputFormatters: inputFormatters, // 🌟 2. เรียกใช้ Formatter
        style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.normal),
        validator: validator ?? (v) {
          if (!enabled) return null;
          if (isRequired && (v == null || v.trim().isEmpty)) {
            return 'กรุณากรอกข้อมูล';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: hint,
          hintText: hint,
          suffixIcon: suffixIcon,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF9B59B6)),
          filled: true,
          fillColor: const Color(0xFFFAF8FF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          counterStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: greyBorder, width: 2.3)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: greyBorder, width: 2.3)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: greyBorder, width: 2.3)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2.3)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2.3)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2.3)),
          errorStyle: const TextStyle(fontSize: 11, color: Colors.redAccent),
        ),
      ),
    );
  }
}