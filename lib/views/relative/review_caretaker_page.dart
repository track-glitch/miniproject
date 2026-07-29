import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ReviewCaretakerPage extends StatefulWidget {
  final String requestId;
  final String relativeUid;
  final String caretakerUid;
  final String caretakerName;
  final String hospitalName;
  final String appointmentDateStr;
  final String? caretakerImage;

  const ReviewCaretakerPage({
    super.key,
    required this.requestId,
    required this.relativeUid,
    required this.caretakerUid,
    required this.caretakerName,
    required this.hospitalName,
    required this.appointmentDateStr,
    this.caretakerImage,
  });

  @override
  State<ReviewCaretakerPage> createState() => _ReviewCaretakerPageState();
}

class _ReviewCaretakerPageState extends State<ReviewCaretakerPage> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final Color primaryPurple = const Color(0xFF8763E6);
  final Color lightPurpleLine = const Color(0xFFECE2FE);
  final Color bgPurple = const Color(0xFFF5EFFF);

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกดาวเพื่อให้คะแนนก่อนครับ')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final requestRef = FirebaseDatabase.instance.ref(
        'Login/${widget.relativeUid}/Relative/Request/${widget.requestId}',
      );

      await requestRef.update({
        'Review': {
          'ratingscore': _rating.toString(),
          'comment': _commentController.text.trim(),
          'reviewdate': DateTime.now().toIso8601String(),
        },
        'isReviewed': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ขอบคุณสำหรับการประเมินครับ!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  ImageProvider? _getAvatarImage() {
    if (widget.caretakerImage != null && widget.caretakerImage!.isNotEmpty) {
      try {
        String clean = widget.caretakerImage!.replaceAll('\n', '').trim();
        if (clean.contains(',')) clean = clean.split(',').last;
        return MemoryImage(base64Decode(clean));
      } catch (_) {}
    }
    return null;
  }

  // 🌟 ฟังก์ชันสร้าง Header แบบมีเส้นคั่นตามรูปภาพ
  Widget _buildSectionHeader(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: primaryPurple,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1.5, color: lightPurpleLine)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPurple,
      appBar: AppBar(
        backgroundColor: primaryPurple,
        title: const Text(
          'ให้คะแนนบริการ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ข้อมูลบริการเบื้องต้น ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '# ${widget.requestId}',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      'สิ้นสุดบริการ',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.hospitalName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.appointmentDateStr,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // --- 1. ผู้ดูแลของคุณ ---
              _buildSectionHeader('ผู้ดูแลของคุณ'),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 35, // ปรับให้ใหญ่ขึ้นนิดหน่อยตามแบบ
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _getAvatarImage(),
                    child: _getAvatarImage() == null
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.caretakerName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // --- 2. คะแนนโดยรวม ---
              _buildSectionHeader('คะแนนโดยรวม'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFF5A623), // สีส้มอมเหลืองตามรูป
                      size: 55, // ขนาดใหญ่สะใจ
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'แตะดาวเพื่อให้คะแนน',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),

              const SizedBox(height: 32),

              // --- 3. ความคิดเห็นเพิ่มเติม ---
              _buildSectionHeader('ความคิดเห็นเพิ่มเติม'),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500, // เปิดใช้งานตัวนับตัวอักษร 0 / 500
                decoration: InputDecoration(
                  hintText: 'เขียนความคิดเห็นของคุณที่นี่...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black87),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.black87,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryPurple, width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEFEFEF), // สีพื้นหลังเทาอ่อนตามภาพ
                ),
              ),

              const SizedBox(height: 24),

              // --- ปุ่มส่งคะแนน ---
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        30,
                      ), // ขอบมนเป็นแคปซูล
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'ส่งคะแนน',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
}
