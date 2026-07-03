import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

@Preview(name: 'Search Page with Caretaker List')
Widget searchPagePreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SearchPreviewPage(),
  );
}

class SearchPreviewPage extends StatefulWidget {
  const SearchPreviewPage({super.key});

  @override
  State<SearchPreviewPage> createState() => _SearchPreviewPageState();
}

class _SearchPreviewPageState extends State<SearchPreviewPage> {
  int _selectedIndex = 0;
  final Color primaryPurple = const Color(0xFFA154B2);

  // 🌟 จำลองข้อมูลผู้ดูแล (Mock Data)
  final List<Map<String, String>> mockCaretakers = [
    {
      'name': 'นายสมชาย ใจดี',
      'role': 'อาสาผู้ดูแลทั่วไป',
      'time': '08:00 - 17:00 น.',
      'image':
          'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=150',
    },
    {
      'name': 'นางสาวสมหญิง รักงาน',
      'role': 'พยาบาลวิชาชีพ',
      'time': '09:00 - 18:00 น.',
      'image':
          'https://images.unsplash.com/photo-1594824436998-f2da15893d56?auto=format&fit=crop&w=150',
    },
    {
      'name': 'นายมานะ อดทน',
      'role': 'ผู้ช่วยพยาบาล',
      'time': '06:00 - 15:00 น.',
      'image':
          'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=150',
    },
    {
      'name': 'คุณสมศรี ยินดี',
      'role': 'อาสาผู้ดูแลทั่วไป',
      'time': '10:00 - 19:00 น.',
      'image':
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FC),

      body: Stack(
        children: [
          // 1. คลื่นด้านบน (Top Wave Layer)
          ClipPath(
            clipper: TopWaveClipperOffset(),
            child: Container(
              height: 290,
              color: primaryPurple.withOpacity(0.3),
            ),
          ),
          ClipPath(
            clipper: TopWaveClipper(),
            child: Container(height: 270, color: primaryPurple),
          ),

          // 2. คลื่นด้านล่าง (Bottom Wave Layer)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                height: 120,
                color: primaryPurple.withOpacity(0.15),
              ),
            ),
          ),

          // 3. เนื้อหาหลักของหน้าจอ
          SafeArea(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // จัดให้ Title ชิดซ้าย
              children: [
                // --- ส่วน Top Bar ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 26,
                              backgroundImage: NetworkImage(
                                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'สวัสดี, เดวิด',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'อรุณสวัสดิ์',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- ส่วน Search Bar และ Filter ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.grey.shade400,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'ค้นหาบริการที่ต้องการ...',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: primaryPurple,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- 🌟 หัวข้อ "รายการอาสาผู้ดูแล" ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'รายการอาสาผู้ดูแล',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- 🌟 รายการ List ของผู้ดูแล (List ของ Cards) ---
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics:
                        const BouncingScrollPhysics(), // เลื่อนแล้วเด้งนุ่มๆ สไตล์ iOS
                    itemCount: mockCaretakers.length,
                    itemBuilder: (context, index) {
                      final caretaker = mockCaretakers[index];
                      return _buildCaretakerCard(
                        name: caretaker['name']!,
                        role: caretaker['role']!,
                        time: caretaker['time']!,
                        imageUrl: caretaker['image']!,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // 4. ส่วน Bottom Navigation Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: GNav(
            rippleColor: Colors.grey.shade300,
            hoverColor: Colors.grey.shade100,
            gap: 8,
            activeColor: primaryPurple,
            iconSize: 26,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: primaryPurple.withOpacity(0.1),
            color: Colors.grey.shade400,
            tabs: const [
              GButton(icon: Icons.home_rounded, text: 'หน้าแรก'),
              GButton(icon: Icons.assignment_rounded, text: 'คำขอ'),
              GButton(icon: Icons.favorite_border_rounded, text: 'แจ้งเตือน'),
              GButton(icon: Icons.person_outline_rounded, text: 'โปรไฟล์'),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🌟 ฟังก์ชันสร้าง Card รายชื่อผู้ดูแล (Caretaker Card)
  // ==========================================
  Widget _buildCaretakerCard({
    required String name,
    required String role,
    required String time,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // ขอบมน
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // เงาบางๆ ให้ดูลอยขึ้นมา
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // รูปโปรไฟล์สี่เหลี่ยมขอบมน
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          // ข้อมูลรายละเอียด
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      role,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // จำลองเรตติ้ง 5 ดาว
                    Row(
                      children: List.generate(
                        5,
                        (index) => const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // ปุ่ม "ดูโปรไฟล์"
                    Row(
                      children: [
                        Text(
                          'ดูโปรไฟล์',
                          style: TextStyle(
                            color: primaryPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_circle_right_rounded,
                          color: primaryPurple,
                          size: 18,
                        ),
                      ],
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
}

// ==========================================
// Custom Clippers (สูตรคำนวณวาดเส้นโค้งเหมือนเดิม)
// ==========================================
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 30,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 60,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TopWaveClipperOffset extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height - 80,
      size.width * 0.6,
      size.height - 30,
    );
    path.quadraticBezierTo(
      size.width * 0.85,
      size.height + 10,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 40);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 40);
    path.quadraticBezierTo(size.width * 0.75, 80, size.width, 20);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
