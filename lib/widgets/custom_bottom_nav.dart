import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: const Color(0xFF8E6FF0), // สีม่วงหลักของแอป
      type: BottomNavigationBarType.fixed, // บังคับให้สีพื้นหลังคงที่
      selectedItemColor: Colors.white, // สีไอคอนและข้อความที่ถูกเลือก
      unselectedItemColor: Colors.white70, // สีไอคอนและข้อความที่ไม่ได้เลือก
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 12,
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: 28),
          label: 'บ้าน',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.support_agent,
            size: 28,
          ), // ไอคอนคอลเซ็นเตอร์/ขอใช้บริการ
          label: 'ขอใช้บริการ',
        ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.notifications, size: 28), // ไอคอนกระดิ่ง
        //   label: 'แจ้งเตือน',
        // ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline, size: 28), // ไอคอนโปรไฟล์
          label: 'ผู้ดูแล',
        ),
      ],
    );
  }
}
