import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/caretaker_service.dart';
import 'package:intl/intl.dart';

class CaretakerCarlendar extends StatefulWidget {
  final String caretalerId; // *ระวังพิมพ์ผิดนะครับ ในโค้ดคุณใช้ caretalerId

  const CaretakerCarlendar({super.key, required this.caretalerId});

  @override
  State<CaretakerCarlendar> createState() => _CustomCalendarWidgetState();
}

class _CustomCalendarWidgetState extends State<CaretakerCarlendar> {
  CaretakerService caretakerService = CaretakerService();

  DateTime _focusedDay = DateTime.now();

  // 🌟 1. เพิ่มตัวแปรเก็บวันที่ที่ถูกจองแล้ว และสถานะการโหลด
  List<DateTime> _bookedDates = [];
  bool _isLoading = true;

  // สีที่ใช้ในหน้าปฏิทิน
  final Color primaryColor = const Color(0xFFA052BE);
  final Color availableBg = const Color(0xFFF0FAF3);
  final Color availableText = const Color(0xFF1B8749);
  final Color fullBg = const Color(0xFFFFF0F0);
  final Color fullText = const Color(0xFFD32F2F);
  final Color disabledBg = const Color(0xFFF5F5F5);
  final Color disabledText = const Color(0xFFBDBDBD);

  @override
  void initState() {
    super.initState();
    // 🌟 2. สั่งให้โหลดข้อมูลคิวงาทันทีที่เปิดหน้านี้
    _loadAppointments();
  }

  // 🌟 3. ฟังก์ชันโหลดข้อมูลจาก Service และเก็บใส่ List
  Future<void> _loadAppointments() async {
    try {
      final List<Map<dynamic, dynamic>> rawData = await caretakerService
          .getAppointmentDateFromRelative(widget.caretalerId);

      List<DateTime> dates = [];
      for (var item in rawData) {
        if (item['appointmentdate'] != null) {
          // ดึงค่า DateTime ออกมาเก็บไว้ใน List
          dates.add(item['appointmentdate'] as DateTime);
        }
      }

      // เมื่อดึงเสร็จแล้ว สั่งให้หน้าจอรีเฟรช และเอาป้าย Loading ออก
      setState(() {
        _bookedDates = dates;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading appointments: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🌟 4. แก้ฟังก์ชันเช็กสถานะ ให้เอาวันในปฏิทินไปเทียบกับวันในคิวงาน (_bookedDates)
  String _getDayStatus(DateTime day) {
    // ใช้คำสั่ง isSameDay (ของ table_calendar) เพื่อเทียบแค่วัน/เดือน/ปี (ไม่สนเวลา)
    bool isBooked = _bookedDates.any(
      (bookedDate) => isSameDay(bookedDate, day),
    );

    if (isBooked) {
      return 'full'; // ถ้าตรงกันแปลว่าวันนั้นเต็มแล้ว
    }
    return 'available'; // ถ้าไม่ตรงแปลว่าว่าง
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black87, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ส่วนหัวปฏิทิน (Header)
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 8,
              top: 16,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ตารางงาน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 28),
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime(
                            _focusedDay.year,
                            _focusedDay.month - 1,
                            _focusedDay.day,
                          );
                        });
                      },
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${DateFormat('MMM', 'th').format(_focusedDay)} ${_focusedDay.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 28),
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime(
                            _focusedDay.year,
                            _focusedDay.month + 1,
                            _focusedDay.day,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🌟 5. ครอบ TableCalendar ด้วย 조건ตรวจสอบว่ากำลังโหลดอยู่ไหม
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _isLoading
                ? const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ), // โชว์วงกลมโหลดรอ
                  )
                : TableCalendar(
                    locale: 'th_TH',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    headerVisible: false,
                    daysOfWeekHeight: 40,
                    calendarBuilders: CalendarBuilders(
                      dowBuilder: (context, day) {
                        final text = DateFormat(
                          'E',
                          'th',
                        ).format(day).substring(0, 1);
                        String displayDow = text;
                        if (day.weekday == DateTime.thursday) displayDow = 'พฤ';
                        if (day.weekday == DateTime.sunday) displayDow = 'อา';
                        return Center(
                          child: Text(
                            displayDow,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        String status = _getDayStatus(
                          day,
                        ); // เรียกเช็กสถานะที่นี่
                        return _buildCalendarCell(
                          day: day.day.toString(),
                          bgColor: status == 'available' ? availableBg : fullBg,
                          textColor: status == 'available'
                              ? availableText
                              : fullText,
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        // สมมติว่าอยากให้ "วันนี้" เปลี่ยนสีตามคิวงานด้วย ก็เช็กสถานะตรงนี้ได้
                        String status = _getDayStatus(day);
                        // ถ้าวันนี้เต็ม ก็โชว์สีแดง แต่ทำให้เข้มกว่าปกติเพื่อแยกกับวันอื่น
                        if (status == 'full') {
                          return _buildCalendarCell(
                            day: day.day.toString(),
                            bgColor: fullText.withValues(alpha: 0.8),
                            textColor: Colors.white,
                          );
                        }

                        return _buildCalendarCell(
                          day: day.day.toString(),
                          bgColor: primaryColor.withValues(alpha: 0.4),
                          textColor: Colors.white,
                        );
                      },
                      outsideBuilder: (context, day, focusedDay) {
                        return _buildCalendarCell(
                          day: day.day.toString(),
                          bgColor: disabledBg,
                          textColor: disabledText,
                        );
                      },
                    ),
                  ),
          ),

          const Divider(height: 30, thickness: 1, indent: 20, endIndent: 20),

          // แถบบอกความหมายสีด้านล่าง
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 20),
            child: Row(
              children: [
                _buildLegendItem(
                  color: availableText,
                  label: 'ว่าง',
                  isBorder: true,
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  color: fullText,
                  label: 'มีคิวงาน',
                  isBorder: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCell({
    required String day,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        day,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isBorder,
  }) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isBorder ? Colors.transparent : color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
