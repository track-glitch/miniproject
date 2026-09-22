import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
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
  // 🌟 1. เพิ่ม 2 ตัวแปรนี้สำหรับเก็บคะแนนรีวิว
  double _averageRating = 0.0;
  int _reviewCount = 0;
  List<ReportModel> _sortedReports = [];
  bool _showAllReports = false; // 🌟 สถานะเปิด-ปิด แสดงรายการรีพอร์ตทั้งหมด
  final Map<int, bool> _expandedDetails =
      {}; // 🌟 สถานะขยายข้อความยาวในแต่ละการ์ด

  Map<String, int> _reportSummary = {
    'พฤติกรรมเข้าข่ายความรุนแรง': 0,
    'ไม่มาตามนัดหมาย': 0,
    'การดูแลผู้ป่วยไม่ปลอดภัย': 0,
    'เรียกเก็บเงินเพิ่ม': 0,
    'กิริยามารยาทไม่เหมาะสม': 0,
    'อื่นๆ': 0,
  };

  @override
  void initState() {
    super.initState();
    _prepareReportData();
    _fetchCaretakerReviews();
  }

  // 🌟 2. ฟังก์ชันไปดึงคะแนนรีวิวจากฐานข้อมูล (อิงจาก caretakerId)
  Future<void> _fetchCaretakerReviews() async {
    String? caretakerId = widget.caretaker.caretakerId;
    if (caretakerId == null) return;

    int count = 0;
    double sum = 0.0;

    try {
      final snapshot = await FirebaseDatabase.instance.ref('Login').get();
      if (snapshot.exists && snapshot.value is Map) {
        final users = snapshot.value as Map<dynamic, dynamic>;

        users.forEach((uid, userData) {
          if (userData is Map && userData['Relative'] != null) {
            var relativeNode = userData['Relative'];
            if (relativeNode is Map && relativeNode['Request'] != null) {
              var requests = relativeNode['Request'];
              if (requests is Map) {
                requests.forEach((reqId, reqData) {
                  if (reqData is Map &&
                      reqData['caretakerId']?.toString().trim() ==
                          caretakerId.trim()) {
                    var reviewData = reqData['Review'] ?? reqData['review'];
                    if (reviewData != null && reviewData is Map) {
                      double ratingScore = 0.0;
                      var rawRating =
                          reviewData['rating'] ?? reviewData['ratingscore'];
                      if (rawRating != null) {
                        ratingScore =
                            double.tryParse(rawRating.toString()) ?? 0.0;
                      }
                      count++;
                      sum += ratingScore;
                    }
                  }
                });
              }
            }
          }
        });
      }

      if (mounted) {
        setState(() {
          _reviewCount = count;
          _averageRating = count > 0 ? sum / count : 0.0;
        });
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  void _prepareReportData() {
    List<ReportModel> rawReports = widget.reports ?? [];

    _reportSummary = {
      'พฤติกรรมเข้าข่ายความรุนแรง': 0, // 1. แดง
      'ไม่มาตามนัดหมาย': 0, // 2. แดง
      'การดูแลผู้ป่วยไม่ปลอดภัย': 0, // 3. ส้ม
      'เรียกเก็บเงินเพิ่ม': 0, // 4. ส้ม
      'กิริยามารยาทไม่เหมาะสม': 0, // 5. เหลือง
      'อื่นๆ': 0, // 6. เหลือง
    };

    for (var report in rawReports) {
      String type = report.reporttype ?? 'อื่นๆ';
      if (type == 'ใช้ความรุนแรง') {
        type = 'พฤติกรรมเข้าข่ายความรุนแรง';
      }

      if (!_reportSummary.containsKey(type)) {
        type = 'อื่นๆ';
      }
      _reportSummary[type] = (_reportSummary[type] ?? 0) + 1;
    }

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

  int _getReportPriority(String? type) {
    if (type == 'พฤติกรรมเข้าข่ายความรุนแรง' ||
        type == 'ใช้ความรุนแรง' ||
        type == 'ไม่มาตามนัดหมาย') {
      return 1;
    }
    if (type == 'การดูแลผู้ป่วยไม่ปลอดภัย' || type == 'เรียกเก็บเงินเพิ่ม') {
      return 2;
    }
    return 3;
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

                          try {
                            String adminReason = commentController.text.trim();
                            DatabaseReference dbRef = FirebaseDatabase.instance
                                .ref('Login');

                            // 🌟 1. ค้นหา UID จากเลขบัตรประชาชน (caretakerId)
                            final query = await dbRef
                                .orderByChild('Caretaker/caretakerId')
                                .equalTo(widget.caretaker.caretakerId)
                                .once();

                            if (query.snapshot.exists) {
                              final users =
                                  query.snapshot.value as Map<dynamic, dynamic>;
                              final targetUid = users.keys.first.toString();

                              // 🌟 2. อัปเดตข้อมูลลงโหนดของ Caretaker
                              await dbRef
                                  .child(targetUid)
                                  .child('Caretaker')
                                  .update({
                                    'accountstatus': 'Suspended',
                                    'admincomment': adminReason,
                                  });

                              // อัปเดต accountstatus ชั้นนอกสุดด้วย (เพื่อให้ครอบคลุมโครงสร้าง Login)
                              await dbRef.child(targetUid).update({
                                'accountstatus': 'Suspended',
                              });
                            }

                            if (context.mounted) {
                              Navigator.pop(context); // ปิด Dialog
                              Navigator.pop(context); // ปิดหน้ารายละเอียด
                              widget
                                  .onSuspend(); // เรียก Callback เพื่อรีเฟรชหน้าหลักแอดมิน
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ระงับบัญชีผู้ดูแลสำเร็จ'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('เกิดข้อผิดพลาด: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
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
    // 🌟 กรองแสดงเฉพาะ 3 รายการแรกก่อน ถ้ายังไม่ได้กด "ดูทั้งหมด"
    List<ReportModel> displayReports = _showAllReports
        ? _sortedReports
        : _sortedReports.take(3).toList();

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
                            Text(
                              '${_averageRating.toStringAsFixed(1)} ',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // 🌟 วนลูปสร้างดาว 5 ดวงแบบคำนวณทศนิยม
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < _averageRating.floor()
                                    ? Icons.star_rounded
                                    : (i < _averageRating
                                          ? Icons.star_half_rounded
                                          : Icons.star_border_rounded),
                                color: Colors.orange,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($_reviewCount รีวิว)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
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

            // --- สรุปประเภทการรายงาน (เรียงลำดับ แดง -> ส้ม -> เหลือง) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black87),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'สรุปประเภทการรายงาน',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'รวม ${_sortedReports.length} รายการ',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._reportSummary.entries.toList().asMap().entries.map((
                    entry,
                  ) {
                    int index = entry.key + 1;
                    String type = entry.value.key;
                    int count = entry.value.value;
                    bool hasReport = count > 0;

                    Color themeColor;
                    if (index <= 2) {
                      themeColor = const Color(0xFFE53935); // 🔴 แดง
                    } else if (index <= 4) {
                      themeColor = const Color(0xFFFB8C00); // 🟠 ส้ม
                    } else {
                      themeColor = const Color(0xFFFBC02D); // 🟡 เหลือง
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: hasReport
                            ? themeColor.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: hasReport
                            ? Border.all(
                                color: themeColor.withOpacity(0.4),
                                width: 1.2,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: themeColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$index',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: hasReport
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: hasReport
                                    ? Colors.black87
                                    : Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: hasReport
                                  ? themeColor
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '($count ครั้ง)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: hasReport
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: hasReport
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
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

            // --- รายการ Report (จำกัดแสดงผล 3 รายการแรก + ปุ่มกดขยายดูทั้งหมด) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black87),
              ),
              child: _sortedReports.isEmpty
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'รายละเอียดคำร้องเรียน',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'แสดง ${displayReports.length}/${_sortedReports.length} รายการ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // แสดงเฉพาะรายการตามตัวแปร displayReports (3 รายการแรก หรือ ทั้งหมด)
                        ...displayReports.asMap().entries.map((entry) {
                          int itemIndex = entry.key;
                          var report = entry.value;

                          String type = report.reporttype ?? 'ไม่ระบุประเภท';
                          if (type == 'ใช้ความรุนแรง') {
                            type = 'พฤติกรรมเข้าข่ายความรุนแรง';
                          }

                          int priority = _getReportPriority(type);
                          Color typeColor;
                          if (priority == 1) {
                            typeColor = const Color(0xFFE53935);
                          } else if (priority == 2) {
                            typeColor = const Color(0xFFFB8C00);
                          } else {
                            typeColor = const Color(0xFFFBC02D);
                          }

                          bool isExpanded =
                              _expandedDetails[itemIndex] ?? false;
                          String detailText = report.reportdetail ?? '-';
                          bool isTextLong = detailText.length > 90;

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type,
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

                                      // ย่อข้อความถ้ายาวเกินไป
                                      Text(
                                        detailText,
                                        maxLines: isExpanded ? null : 3,
                                        overflow: isExpanded
                                            ? TextOverflow.visible
                                            : TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                          height: 1.4,
                                        ),
                                      ),

                                      if (isTextLong)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _expandedDetails[itemIndex] =
                                                  !isExpanded;
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4.0,
                                            ),
                                            child: Text(
                                              isExpanded
                                                  ? 'ย่อข้อความ'
                                                  : '...อ่านเพิ่มเติม',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (report.reportphoto != null &&
                                    report.reportphoto!.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => Dialog(
                                          child: Image(
                                            image: _getImageProvider(
                                              report.reportphoto!,
                                            )!,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      );
                                    },
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
                        }),

                        // 🌟 ปุ่มกดดูรีพอร์ตทั้งหมด (แสดงกรณีมีรีพอร์ตมากกว่า 3 รายการ)
                        if (_sortedReports.length > 3)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  backgroundColor: primaryColor.withOpacity(
                                    0.08,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showAllReports = !_showAllReports;
                                  });
                                },
                                icon: Icon(
                                  _showAllReports
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 20,
                                  color: primaryColor,
                                ),
                                label: Text(
                                  _showAllReports
                                      ? 'ซ่อนรีพอร์ตที่เหลือ'
                                      : 'ดูรีพอร์ตทั้งหมดอีก ${_sortedReports.length - 3} รายการ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
