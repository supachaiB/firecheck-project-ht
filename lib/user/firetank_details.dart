import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FireTankDetailsPage extends StatelessWidget {
  final String tankId; // รับ tankId จาก main.dart

  const FireTankDetailsPage({Key? key, required this.tankId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดถังดับเพลิงและประวัติการตรวจสอบ'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Container 1 - รายละเอียดถังดับเพลิง
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('firetank_Collection')
                    .where('tank_id',
                        isEqualTo: tankId) // ใช้ tank_id ที่ส่งมาจาก main.dart
                    .limit(1) // จำกัดผลลัพธ์ให้ได้เอกสารเดียว
                    .get()
                    .then((querySnapshot) =>
                        querySnapshot.docs.first), // ดึงเอกสารแรก
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('เกิดข้อผิดพลาด'));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                        child: Text('ไม่พบรายละเอียดถังดับเพลิง'));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'รายละเอียดถังดับเพลิง',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text('ถังดับเพลิง ID: ${data['tank_id']}'),
                      Text('ประเภท: ${data['type']}'),
                      Text('อาคาร: ${data['building']}'),
                      Text('ชั้น: ${data['floor']}'),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Container 2 - ประวัติการตรวจสอบ
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('form_checks')
                    .where('tank_id',
                        isEqualTo: tankId) // ดึงข้อมูลประวัติของถังนี้
                    .orderBy('date_checked',
                        descending: true) // เรียงตามวันที่ล่าสุด
                    .orderBy('time_checked',
                        descending: true) // เรียงตามเวลาล่าสุด
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    // พิมพ์ข้อผิดพลาดที่เกิดขึ้นใน Console
                    print('เกิดข้อผิดพลาด: ${snapshot.error}');

                    // แสดงข้อความใน UI
                    return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('ไม่พบประวัติการตรวจสอบ'));
                  }

                  final formChecks = snapshot.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ประวัติการตรวจสอบ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      // เอา Expanded ออกและใช้ shrinkWrap เพียงอย่างเดียว
                      ListView.builder(
                        shrinkWrap: true, // จำกัดความสูงของ ListView
                        physics:
                            const NeverScrollableScrollPhysics(), // ปิดการเลื่อนแยก
                        itemCount: formChecks.length,
                        itemBuilder: (context, index) {
                          final checkData =
                              formChecks[index].data()! as Map<String, dynamic>;

                          // พิมพ์ค่าที่ได้รับจาก Firestore
                          print('Date Checked: ${checkData['date_checked']}');
                          print('Time Checked: ${checkData['time_checked']}');
                          print('Inspector: ${checkData['inspector']}');

                          if (checkData['date_checked'] == null ||
                              checkData['time_checked'] == null ||
                              checkData['inspector'] == null) {
                            return const Center(
                                child: Text('ข้อมูลไม่ครบถ้วน'));
                          }

                          Map<String, dynamic> equipmentStatus =
                              checkData['equipment_status'];

                          // ตรวจสอบว่ามีอุปกรณ์ชำรุดหรือไม่
                          bool isDamaged = equipmentStatus.values
                              .any((status) => status == 'ชำรุด');

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'วันที่: ${checkData['date_checked']} ${checkData['time_checked']}'),
                                const SizedBox(height: 5),
                                Text('ผู้ตรวจสอบ: ${checkData['inspector']}'),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Text('สถานะ: '),
                                    if (isDamaged) ...[
                                      const Icon(Icons.circle,
                                          color: Colors.red, size: 10),
                                      const SizedBox(width: 5),
                                      const Text('ชำรุด'),
                                    ] else ...[
                                      const Icon(Icons.circle,
                                          color: Colors.green, size: 10),
                                      const SizedBox(width: 5),
                                      const Text('ตรวจสอบแล้ว'),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
