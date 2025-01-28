import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // เพิ่มการ import

class DamageInfoSection extends StatelessWidget {
  const DamageInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('firetank_Collection')
          .where('status',
              isEqualTo: 'ชำรุด') // เงื่อนไขการดึงข้อมูลจาก firetank_Collection
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('ไม่มีข้อมูลการชำรุด'));
        }

        final damageList = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('ข้อมูลการชำรุด'),
              const SizedBox(height: 10),
              ...damageList.map((damage) {
                final data = damage.data() as Map<String, dynamic>;
                final tankId = data['tank_id'] ?? 'ไม่ระบุ';

                // ใช้ StreamBuilder ในการดึงข้อมูลจาก form_checks ที่มี tank_id ตรงกัน
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('form_checks')
                      .where('tank_id', isEqualTo: tankId)
                      .orderBy('date_checked',
                          descending: true) // เรียงลำดับจากวันที่ล่าสุด
                      .limit(1) // เลือกแค่เอกสารแรก
                      .snapshots(),
                  builder: (context, reportSnapshot) {
                    if (reportSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox
                          .shrink(); // แสดงเป็นช่องว่างขณะรอข้อมูล
                    }

                    if (reportSnapshot.hasError) {
                      return const SizedBox
                          .shrink(); // ถ้ามีข้อผิดพลาดให้แสดงช่องว่าง
                    }

                    String reportDate = '-'; // ตั้งค่าวันที่เริ่มต้น
                    if (reportSnapshot.hasData &&
                        reportSnapshot.data!.docs.isNotEmpty) {
                      final reportData = reportSnapshot.data!.docs.first.data()
                          as Map<String, dynamic>;
                      var dateChecked = reportData['date_checked'];

                      // ถ้า date_checked เป็น Timestamp
                      if (dateChecked is Timestamp) {
                        DateTime dateTime = dateChecked.toDate();
                        reportDate = DateFormat('yyyy-MM-dd')
                            .format(dateTime); // ใช้ DateFormat เพื่อเอาเวลาออก
                      }
                      // ถ้า date_checked เป็น String
                      else if (dateChecked is String) {
                        try {
                          DateTime dateTime = DateTime.parse(dateChecked);
                          reportDate = DateFormat('yyyy-MM-dd').format(
                              dateTime); // ใช้ DateFormat เพื่อเอาเวลาออก
                        } catch (e) {
                          reportDate = '-'; // ถ้าแปลงไม่ได้ให้ตั้งค่าเป็น -
                        }
                      }
                    }

                    return _buildDamageAlert(
                      tankId: tankId,
                      type: data['type'] ?? 'ไม่ระบุ',
                      building: data['building'] ?? 'ไม่ระบุ',
                      floor: data['floor'] ?? 'ไม่ระบุ',
                      reportDate: reportDate,
                    );
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDamageAlert({
    required String tankId,
    required String type,
    required String building,
    required String floor,
    required String reportDate,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 3,
        child: ListTile(
          leading: const Icon(Icons.warning, color: Colors.red),
          title: Text('ถัง: $tankId - $type'),
          subtitle:
              Text('อาคาร: $building, ชั้น: $floor\nวันที่แจ้ง: $reportDate'),
        ),
      ),
    );
  }
}
