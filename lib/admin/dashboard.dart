import 'package:flutter/material.dart';
import 'package:firecheck_setup/admin/dashboard_section/damage_info_section.dart';
import 'package:firecheck_setup/admin/dashboard_section/status_summary.dart';
import 'package:firecheck_setup/admin/dashboard_section/scheduleBox.dart';
import 'package:firecheck_setup/admin/fire_tank_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int remainingTime = FireTankStatusPageState.calculateRemainingTime();
  int remainingQuarterTimeInSeconds =
      FireTankStatusPageState.calculateNextQuarterEnd()
          .difference(DateTime.now())
          .inSeconds;

  int totalTanks = 0;
  int checkedCount = 0;
  int brokenCount = 0;
  int repairCount = 0;

  // ดึงข้อมูลจาก Firestore
  void _fetchFireTankData() async {
    final totalSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .get();
    totalTanks = totalSnapshot.size;

    final checkedSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status', isEqualTo: 'ตรวจสอบแล้ว')
        .get();
    checkedCount = checkedSnapshot.size;

    final brokenSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status', isEqualTo: 'ชำรุด')
        .get();
    brokenCount = brokenSnapshot.size;

    final repairSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status', isEqualTo: 'ส่งซ่อม')
        .get();
    repairCount = repairSnapshot.size;

    setState(() {}); // อัปเดตข้อมูลหลังจากดึงข้อมูลมา
  }

  @override
  void initState() {
    super.initState();
    _fetchFireTankData(); // ดึงข้อมูลเมื่อหน้าเริ่มต้น

    remainingQuarterTimeInSeconds =
        FireTankStatusPageState.calculateNextQuarterEnd()
            .difference(DateTime.now())
            .inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: _buildDrawer(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('firetank_Collection')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('ไม่พบข้อมูลถังดับเพลิง'));
          }
          // ดึงข้อมูลสถานะจาก snapshot
          final tanks = snapshot.data!.docs;
          final totalTanks = tanks.length;
          final checkedCount =
              tanks.where((doc) => doc['status'] == 'ตรวจสอบแล้ว').length;
          final brokenCount =
              tanks.where((doc) => doc['status'] == 'ชำรุด').length;
          final repairCount =
              tanks.where((doc) => doc['status'] == 'ส่งซ่อม').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ใช้ Widget StatusSummary พร้อมกับส่งข้อมูลที่ดึงมาจาก Firestore
                ScheduleBox(
                  remainingTime: remainingTime,
                  remainingQuarterTime: remainingQuarterTimeInSeconds,
                ),
                const SizedBox(height: 10),

                StatusSummaryWidget(
                  totalTanks: totalTanks,
                  checkedCount: checkedCount,
                  brokenCount: brokenCount,
                  repairCount: repairCount,
                ),
                const SizedBox(height: 20),
                const DamageInfoSection(),
                const SizedBox(height: 20),
                //const GraphInfoSection(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Text(
              'เมนู',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          /*ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('ตรวจสอบสถานะถัง'),
            onTap: () {
              Navigator.pushNamed(context, '/firetankstatus');
            },
          ),*/
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('ประวัติการตรวจสอบ'),
            onTap: () {
              Navigator.pushNamed(context, '/inspectionhistory');
            },
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('การจัดการถังดับเพลิง'),
            onTap: () {
              Navigator.pushNamed(context, '/fire_tank_management');
            },
          ),
          ListTile(
            leading: const Icon(Icons.apartment),
            title: const Text('การจัดการอาคาร'),
            onTap: () {
              Navigator.pushNamed(context, '/BuildingManagement');
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_fire_department),
            title: const Text('ประเภทถังดับเพลิง'),
            onTap: () {
              Navigator.pushNamed(context, '/FireTankTypes');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ออกจากระบบ'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/user');
            },
          ),
        ],
      ),
    );
  }
}
