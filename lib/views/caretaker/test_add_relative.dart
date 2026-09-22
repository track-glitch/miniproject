import 'package:flutter/material.dart';
import 'package:miniproject/services/admin_service.dart';

class TestAddRelative extends StatelessWidget {
  const TestAddRelative({super.key});

  @override
  Widget build(BuildContext context) {
    AdminService adminService = AdminService();
    void addCaretaker() {
      adminService.seed10CaretakersCorrectPath();
    }

    void addRelative() {
      adminService.seed4RelativesCorrectPath();
    }

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
                  onPressed: addCaretaker,
                  child: Text('AddCaretaker'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: addRelative,
                  child: Text('AddRelative'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
