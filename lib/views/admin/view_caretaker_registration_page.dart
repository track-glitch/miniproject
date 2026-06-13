import 'package:flutter/material.dart';
import '../../models/caretaker_model.dart';
import '../../services/admin_service.dart';


class ViewCaretakerRegistrationPage
    extends StatelessWidget {

  final CaretakerModel caretaker;

  const ViewCaretakerRegistrationPage({
    super.key,
    required this.caretaker,
  });

  @override
  Widget build(BuildContext context) {

    final adminService =
        AdminService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายละเอียดผู้สมัคร',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              '${caretaker.firstname} ${caretaker.lastname}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text('เพศ : ${caretaker.gender}'),

            Text(
              'เบอร์โทร : ${caretaker.phonenumber}',
            ),

            Text(
              'อีเมล : ${caretaker.email}',
            ),

            Text(
              'ที่อยู่ : ${caretaker.address}',
            ),

            const SizedBox(height: 20),

            const Text(
              'แนะนำตัว',
            ),

            Text(
              caretaker.aboutme,
            ),

            const SizedBox(height: 20),

            const Text(
              'อุปกรณ์',
            ),

            Text(
              caretaker.equipmentdetails,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {

                  await adminService
                      .approveCaretaker(
                    caretaker.caretakerId,
                  );

                  Navigator.pop(
                    context,
                  );
                },
                child: const Text(
                  'อนุมัติ',
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {

                  await adminService
                      .suspendCaretaker(
                    caretaker.caretakerId,
                  );

                  Navigator.pop(
                    context,
                  );
                },
                child: const Text(
                  'ระงับสิทธิ์',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
