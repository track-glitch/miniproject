import 'package:flutter/material.dart';
import '../../widgets/caretaker_calendar.dart';
import '../../services/caretaker_service.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  CaretakerService caretakerService = CaretakerService();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final appointmentDate = await caretakerService
        .getAppointmentDateFromRelative('E7TZ3fTabuY8jEgzH81wDAE5LSS2');
    print(appointmentDate);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          CaretakerCarlendar(caretalerId: 'E7TZ3fTabuY8jEgzH81wDAE5LSS2'),
        ],
      ),
    );
  }
}
