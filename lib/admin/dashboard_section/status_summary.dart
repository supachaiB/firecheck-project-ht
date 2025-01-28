// status_summary_widget.dart
import 'package:flutter/material.dart';

class StatusSummaryWidget extends StatelessWidget {
  final int totalTanks;
  final int checkedCount;
  final int brokenCount;
  final int repairCount;

  StatusSummaryWidget({
    required this.totalTanks,
    required this.checkedCount,
    required this.brokenCount,
    required this.repairCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryCard("ถังทั้งหมด", totalTanks, Colors.blue),
            _buildSummaryCard("ตรวจสอบแล้ว", checkedCount, Colors.green),
            _buildSummaryCard(
                "ยังไม่ตรวจสอบ",
                totalTanks - checkedCount - brokenCount - repairCount,
                Colors.grey),
            _buildSummaryCard("ชำรุด", brokenCount, Colors.red),
            _buildSummaryCard("ส่งซ่อม", repairCount, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        SizedBox(height: 8),
        Text(
          '$count',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
