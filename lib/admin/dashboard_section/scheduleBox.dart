import 'package:flutter/material.dart';

class ScheduleBox extends StatelessWidget {
  final int remainingTime;
  final int remainingQuarterTime;

  const ScheduleBox({
    Key? key,
    required this.remainingTime,
    required this.remainingQuarterTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // คำนวณเวลาสำหรับผู้ใช้ทั่วไป
    int days = remainingTime ~/ (24 * 3600); // คำนวณจำนวนวัน
    int hours = (remainingTime % (24 * 3600)) ~/ 3600; // คำนวณชั่วโมง
    int minutes = (remainingTime % 3600) ~/ 60; // คำนวณนาที
    int seconds = remainingTime % 60; // คำนวณวินาที

    // คำนวณเวลาสำหรับช่างเทคนิค
    int quarterDays = remainingQuarterTime ~/ (24 * 3600);
    int quarterHours = (remainingQuarterTime % (24 * 3600)) ~/ 3600;
    int quarterMinutes = (remainingQuarterTime % 3600) ~/ 60;
    int quarterSeconds = remainingQuarterTime % 60;

    return Align(
      alignment: Alignment.centerLeft, // จัดชิดซ้าย
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // ชิดซ้ายในกล่อง
            children: [
              Text(
                "กำหนดการตรวจ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "ผู้ใช้ทั่วไปเหลือ :  $days วัน ",
                style: TextStyle(fontSize: 14),
              ),
              Text(
                "ช่างเทคนิคเหลือ : $quarterDays วัน ",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
