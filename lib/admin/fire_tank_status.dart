import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // ใช้ Timer
import 'package:rxdart/rxdart.dart';

class FireTankStatusPage extends StatefulWidget {
  const FireTankStatusPage({Key? key}) : super(key: key);

  @override
  FireTankStatusPageState createState() => FireTankStatusPageState();
}

class FireTankStatusPageState extends State<FireTankStatusPage> {
  late Stream<int> totalTanksStream;
  late Stream<int> checkedCountStream;
  late Stream<int> brokenCountStream;
  late Stream<int> repairCountStream;

  // เพิ่ม Stream รวม
  Stream<Map<String, int>> get combinedStreams {
    return Rx.combineLatest4<int, int, int, int, Map<String, int>>(
      totalTanksStream,
      checkedCountStream,
      brokenCountStream,
      repairCountStream,
      (total, checked, broken, repair) => {
        "totalTanks": total,
        "checkedCount": checked,
        "brokenCount": broken,
        "repairCount": repair,
      },
    );
  }

  int remainingTime = 120; // เริ่มต้นที่ 2 นาที (120 วินาที)
  late int remainingQuarterTime;
  late Timer _timer;

  static int calculateRemainingTime() {
    final now = DateTime.now();
    final nextResetDate =
        DateTime(now.year, now.month + 1, 1); // วันที่ 1 ของเดือนถัดไป
    return nextResetDate.difference(now).inSeconds; // เวลาที่เหลือในวินาที
  }

  static DateTime calculateNextQuarterEnd() {
    final now = DateTime.now();
    int nextQuarterMonth;

    // หาค่าเดือนที่สิ้นสุดของไตรมาสถัดไป
    if (now.month <= 3) {
      nextQuarterMonth = 3; // ไตรมาสแรก
    } else if (now.month <= 6) {
      nextQuarterMonth = 6; // ไตรมาสที่สอง
    } else if (now.month <= 9) {
      nextQuarterMonth = 9; // ไตรมาสที่สาม
    } else {
      nextQuarterMonth = 12; // ไตรมาสสุดท้าย
    }

    // คืนค่าวันที่สิ้นสุดของไตรมาส
    return DateTime(now.year, nextQuarterMonth + 1, 1)
        .subtract(Duration(days: 1));
  }

  @override
  void initState() {
    super.initState();
    totalTanksStream = _getTotalTanksStream();
    checkedCountStream = _getStatusCountStream('ตรวจสอบแล้ว');
    brokenCountStream = _getStatusCountStream('ชำรุด');
    repairCountStream = _getStatusCountStream('ส่งซ่อม');

    remainingTime = calculateRemainingTime(); // คำนวณเวลาที่เหลือ
    remainingQuarterTime = calculateNextQuarterEnd()
        .difference(DateTime.now())
        .inSeconds; // สำหรับช่างเทคนิค

    startTimer();
  }

  // ฟังก์ชันเริ่มนับเวลา
  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--; // ลดเวลาผู้ใช้ทั่วไป
        } else {
          _updateAllTanksStatus(); // รีเซตสถานะ
          remainingTime = calculateRemainingTime(); // รีเซตเวลาใหม่
        }

        if (remainingQuarterTime > 0) {
          remainingQuarterTime--; // ลดเวลาของช่างเทคนิค
        } else {
          // รีเซตเวลาไตรมาสใหม่
          remainingQuarterTime =
              calculateNextQuarterEnd().difference(DateTime.now()).inSeconds;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // ยกเลิก Timer
    super.dispose();
  }

  // อัพเดตสถานะทุกๆ document ใน Firestore ให้เป็น "ยังไม่ตรวจสอบ"
  Future<void> _updateAllTanksStatus() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'status': 'ยังไม่ตรวจสอบ'});
      }
      print('Updated all tanks to "ยังไม่ตรวจสอบ"');
    } catch (e) {
      print("Error updating tanks: $e");
    }
  }

  // สร้าง Stream สำหรับจำนวนเอกสารทั้งหมด
  Stream<int> _getTotalTanksStream() {
    return FirebaseFirestore.instance
        .collection('firetank_Collection')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // สร้าง Stream สำหรับสถานะเฉพาะ
  Stream<int> _getStatusCountStream(String status) {
    return FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สถานะถังดับเพลิง'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
