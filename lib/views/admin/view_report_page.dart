import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/caretaker_model.dart';
import '../../models/report_model.dart';

class ViewCaretakerReportPage extends StatefulWidget {
  final CaretakerModel caretaker;
  final VoidCallback onSuspend;
  final List<ReportModel>? reports;

  const ViewCaretakerReportPage({
    super.key,
    required this.caretaker,
    required this.onSuspend,
    this.reports,
  });

  @override
  State<ViewCaretakerReportPage> createState() =>
      _ViewCaretakerReportPageState();
}

class _ViewCaretakerReportPageState extends State<ViewCaretakerReportPage> {
  final Color primaryColor = const Color(0xFFA052BE);
  final Color backgroundColor = const Color(0xFFF4EDFB);

  List<ReportModel> _sortedReports = [];

  // 🌟 1. ตั้งค่าเริ่มต้นให้แสดงทั้ง 3 ประเภทเสมอ (ถ้าไม่มีข้อมูลจะเป็น 0)
  Map<String, int> _reportSummary = {
    'ใช้ความรุนแรง': 0,
    'กิริยามารยาทไม่เหมาะสม': 0,
    'อื่นๆ': 0,
  };

  @override
  void initState() {
    super.initState();
    _prepareReportData();
  }

  void _prepareReportData() {
    // 🌟 2. ใช้ข้อมูลที่ส่งเข้ามาจริงๆ (ถ้า null ให้เป็น List ว่าง) ไม่ใช้ Mock data แล้ว
    List<ReportModel> rawReports = widget.reports ?? [];

    // รีเซ็ตค่าใหม่ทุกครั้งเผื่อมีการโหลดข้อมูลซ้ำ
    _reportSummary = {
      'ใช้ความรุนแรง': 0,
      'กิริยามารยาทไม่เหมาะสม': 0,
      'อื่นๆ': 0,
    };

    // 🌟 3. นับจำนวนแยกตามประเภท
    for (var report in rawReports) {
      String type = report.reporttype ?? 'อื่นๆ';
      // ป้องกันกรณีมีข้อมูลเก่าที่ประเภทไม่ตรงกับ 3 หมวดนี้ ให้ปัดเข้าหมวด "อื่นๆ"
      if (!_reportSummary.containsKey(type)) {
        type = 'อื่นๆ';
      }
      _reportSummary[type] = (_reportSummary[type] ?? 0) + 1;
    }

    // 🌟 4. จัดเรียง Report ตามความรุนแรง (Priority)
    rawReports.sort((a, b) {
      int priorityA = _getReportPriority(a.reporttype);
      int priorityB = _getReportPriority(b.reporttype);
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      DateTime dateA = a.reportdate ?? DateTime(2000);
      DateTime dateB = b.reportdate ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    setState(() {
      _sortedReports = rawReports;
    });
  }

  // 🌟 5. ฟังก์ชันจัดระดับความรุนแรงอิงตาม 3 ประเภทหลัก
  int _getReportPriority(String? type) {
    if (type == 'ใช้ความรุนแรง') return 1; // รุนแรงมาก (สีแดง)
    if (type == 'กิริยามารยาทไม่เหมาะสม') return 2; // ปานกลาง (สีส้ม)
    return 3; // อื่นๆ (สีเหลือง)
  }

  Color _getPriorityColor(int priority) {
    if (priority == 1) return Colors.red;
    if (priority == 2) return Colors.orange;
    return Colors.amber;
  }

  void _showSuspendDialog() {
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'ระงับบัญชีผู้ดูแล',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'กรุณาระบุสาเหตุ (Admin Comment):',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'เช่น ระงับบัญชีชั่วคราวเนื่องจาก...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (commentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('กรุณาระบุสาเหตุ'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);

                          // TODO: เรียก API อัปเดตสถานะและ admincomment ไปที่ Firebase
                          await Future.delayed(const Duration(seconds: 1));

                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            widget.onSuspend();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ระงับบัญชีสำเร็จ'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ยืนยันระงับบัญชี',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatThaiDateFull(DateTime? date) {
    if (date == null) return '-';
    List<String> months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} น.';
  }

  ImageProvider? _getImageProvider(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(base64String));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'รายละเอียดรายงาน',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- การ์ดข้อมูลผู้ดูแล ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black87),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _getImageProvider(
                      widget.caretaker.profilephoto,
                    ),
                    child: (widget.caretaker.profilephoto?.isEmpty ?? true)
                        ? const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.caretaker.firstname} ${widget.caretaker.lastname}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              '4.9 ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 14,
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 14,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${_sortedReports.length} รีพอร์ต',
                              style: const TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'พื้นที่ให้บริการ: ${widget.caretaker.location?.address ?? '-'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'ยี่ห้อรถ: ${widget.caretaker.vehicle?.brand ?? '-'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- สรุปประเภทการรายงาน ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black87),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'สรุปประเภทการรายงาน',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._reportSummary.entries.toList().asMap().entries.map((
                    entry,
                  ) {
                    int index = entry.key + 1;
                    String type = entry.value.key;
                    int count = entry.value.value;
                    int priority = _getReportPriority(type);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(priority),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$index',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              type,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '($count ครั้ง)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- รายการ Report ---
            Container(
              width: double.infinity, // ทำให้ Container กว้างเต็มพื้นที่
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black87),
              ),
              child: _sortedReports.isEmpty
                  // 🌟 6. แสดงข้อความนี้ถ้าไม่มีข้อมูล
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'ไม่พบข้อมูลการรายงานปัญหา',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: _sortedReports.map((report) {
                        int priority = _getReportPriority(report.reporttype);
                        Color typeColor = _getPriorityColor(priority);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.reporttype ?? 'ไม่ระบุประเภท',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: typeColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatThaiDateFull(report.reportdate),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      report.reportdetail ?? '-',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (report.reportphoto != null &&
                                  report.reportphoto!.isNotEmpty)
                                GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    margin: const EdgeInsets.only(left: 10.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      image: DecorationImage(
                                        image: _getImageProvider(
                                          report.reportphoto!,
                                        )!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 24),

            // --- ปุ่มระงับบัญชี ---
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _showSuspendDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ระงับบัญชี',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
