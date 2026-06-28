import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AddDoctorAdvicePage extends StatefulWidget {
  const AddDoctorAdvicePage({super.key});

  @override
  State<AddDoctorAdvicePage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<AddDoctorAdvicePage> {
  AdminService adminService = AdminService();

  void addRequest() {
    adminService.addRequest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. เปิดโครงหน้าจอหลักก่อน
      appBar: AppBar(
        // 2. ใส่แถบด้านบนไว้ข้างใน Scaffold
        title: Text('หน้าแรก'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: addRequest,
                  child: Text('AddRequest'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
