import 'package:flutter/material.dart';

/// หน้าจอ "สถานะการแจ้งเตือน" (Track Status Notification Page)
/// ใช้ข้อมูลสมมุติ (mock data) ตามดีไซน์ที่ให้มา
class TrackStatusNotificationPage extends StatelessWidget {
  const TrackStatusNotificationPage({super.key});

  // ---------- Mock Data ----------
  final List<_NotificationItem> _items = const [
    _NotificationItem(
      dateTime: '22/02/2026 11:00 น.',
      requestId: '#REQ-12345',
      status: 'กำลังให้บริการ',
      detailLabel: 'รายละเอียด:',
      detail: 'กำลังเดินทางไปรับ\nผู้ดูแล: สมศักดิ์ ใจดี',
      isLatest: false,
    ),
    _NotificationItem(
      dateTime: '22/02/2026 11:00 น.',
      requestId: '#REQ-12345',
      status: 'กำลังให้บริการ',
      detailLabel: 'รายละเอียด:',
      detail: 'ถึงโรงพยาบาล\nผู้ดูแล: สมศักดิ์ ใจดี',
      isLatest: false,
    ),
    _NotificationItem(
      dateTime: '22/02/2026 11:15 น.',
      requestId: '#REQ-12345',
      status: 'กำลังให้บริการ',
      detailLabel: 'รายละเอียด:',
      detail: 'รอคิวพบแพทย์\nผู้ดูแล: สมศักดิ์ ใจดี',
      isLatest: true,
    ),
  ];

  static const Color primaryPurple = Color(0xFF8E5DB8);
  static const Color lightPurpleBg = Color(0xFFE9DCF3);
  static const Color cardBg = Colors.white;
  static const Color redAccent = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurpleBg,
      appBar: AppBar(
        backgroundColor: primaryPurple,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        title: const Text(
          'สถานะการแจ้งเตือน',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          for (int i = 0; i < _items.length; i++) ...[
            if (_items[i].isLatest) _buildLatestDivider(),
            _NotificationCard(item: _items[i]),
            const SizedBox(height: 14),
          ],
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildLatestDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: redAccent, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'สถานะล่าสุด',
              style: TextStyle(
                color: redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(child: Divider(color: redAccent, thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: primaryPurple,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home, label: 'บ้าน', selected: false),
            _NavItem(icon: Icons.person_outline, label: 'ขอใช้บริการ', selected: false),
            _NavItem(
              icon: Icons.notifications,
              label: 'แจ้งเตือน',
              selected: true,
              badgeCount: 9,
            ),
            _NavItem(icon: Icons.person, label: 'ญาติ', selected: false),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  final String dateTime;
  final String requestId;
  final String status;
  final String detailLabel;
  final String detail;
  final bool isLatest;

  const _NotificationItem({
    required this.dateTime,
    required this.requestId,
    required this.status,
    required this.detailLabel,
    required this.detail,
    required this.isLatest,
  });
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool latest = item.isLatest;

    return Container(
      decoration: BoxDecoration(
        color: TrackStatusNotificationPage.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: latest
            ? const Border(left: BorderSide(color: Color(0xFFE53935), width: 4))
            : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.dateTime,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              Text(
                item.requestId,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: latest ? FontWeight.bold : FontWeight.w500,
                  color: latest ? const Color(0xFFE53935) : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.status,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: latest ? const Color(0xFFE53935) : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.detailLabel,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            item.detail,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.white70,
              size: 24,
            ),
            if (badgeCount != null)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
