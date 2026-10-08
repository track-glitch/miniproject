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

  // ── 🎨 ชุดสีหลักตามธีม ─────────────────────────────────────────
  final Color primaryPurple = const Color(0xFF9B59B6);
  final Color darkPurple = const Color(0xFF9B59B6);
  final Color lightPurple = const Color(0xFFECE2FE);
  final Color bgPurple = const Color.fromARGB(255, 225, 202, 255);
  final Color borderColor = const Color(0xFFD3C2F0);
  final Color sectionBgColor = const Color(0xFFF8F5FF);

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

  // 🌟 ฟังก์ชันสร้าง Header ภายในกรอบ Card
  Widget _buildSectionHeaderInside(IconData icon, String title) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: primaryPurple, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(height: 1.5, color: lightPurple),
        const SizedBox(height: 14),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: primaryPurple.withOpacity(0.12),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPurple,
      appBar: AppBar(
        backgroundColor: darkPurple,
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
        child: Column(
          children: [
            // --- กรอบที่ 1: ข้อมูลบริการเบื้องต้น ---
            Container(
              decoration: _cardDecoration(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '# ${widget.requestId}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5FE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF00B0FF)),
                        ),
                        child: const Text(
                          'เสร็จสิ้น',
                          style: TextStyle(
                            color: Color(0xFF00B0FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.hospitalName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryPurple,
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
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- กรอบที่ 2: ผู้ดูแลของคุณ ---
            Container(
              decoration: _cardDecoration(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSectionHeaderInside(
                    Icons.support_agent_rounded,
                    'ผู้ให้บริการ',
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: lightPurple,
                        backgroundImage: _getAvatarImage(),
                        child: _getAvatarImage() == null
                            ? Icon(Icons.person, size: 40, color: primaryPurple)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.caretakerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9B59B6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- กรอบที่ 3: ให้คะแนนและความคิดเห็น ---
            Container(
              decoration: _cardDecoration(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSectionHeaderInside(Icons.star_rounded, 'คะแนนโดยรวม'),
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
                          color: const Color(0xFFF5A623),
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'แตะดาวเพื่อให้คะแนน',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeaderInside(
                    Icons.rate_review_rounded,
                    'ความคิดเห็นเพิ่มเติม',
                  ),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'เขียนความคิดเห็นของคุณที่นี่...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: primaryPurple,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: sectionBgColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- ปุ่มส่งคะแนน ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 4,
                  shadowColor: primaryPurple.withOpacity(0.4),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
