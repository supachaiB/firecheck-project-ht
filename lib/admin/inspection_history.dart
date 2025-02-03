import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firecheck_setup/admin/fire_tank_status.dart';
import 'package:firecheck_setup/admin/dashboard_section/status_summary.dart';
import 'package:firecheck_setup/admin/dashboard_section/scheduleBox.dart';
//import 'package:firecheck_setup/admin/fire_tank_status.dart';

class InspectionHistoryPage extends StatefulWidget {
  const InspectionHistoryPage({super.key});

  @override
  _InspectionHistoryPageState createState() => _InspectionHistoryPageState();
}

class _InspectionHistoryPageState extends State<InspectionHistoryPage> {
  String? selectedBuilding;
  String? selectedFloor;
  String? selectedStatus;
  String? sortBy = 'tank_number'; // เริ่มต้นการเรียงตามหมายเลขถัง

  List<String> _buildings = [];
  List<String> _floors = [];
  List<Map<String, dynamic>> combinedData = [];

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
    try {
      // ใช้ Future.wait เพื่อทำคิวรีพร้อมกันและรอให้เสร็จ
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('firetank_Collection').get(),
        FirebaseFirestore.instance
            .collection('firetank_Collection')
            .where('status', isEqualTo: 'ตรวจสอบแล้ว')
            .get(),
        FirebaseFirestore.instance
            .collection('firetank_Collection')
            .where('status', isEqualTo: 'ชำรุด')
            .get(),
        FirebaseFirestore.instance
            .collection('firetank_Collection')
            .where('status', isEqualTo: 'ส่งซ่อม')
            .get(),
      ]);

      // กำหนดค่าผลลัพธ์จาก Future
      final totalSnapshot = results[0];
      totalTanks = totalSnapshot.size;

      final checkedSnapshot = results[1];
      checkedCount = checkedSnapshot.size;

      final brokenSnapshot = results[2];
      brokenCount = brokenSnapshot.size;

      final repairSnapshot = results[3];
      repairCount = repairSnapshot.size;

      setState(() {}); // อัปเดตข้อมูลหลังจากดึงข้อมูลมา
    } catch (e) {
      // หากเกิดข้อผิดพลาดใดๆ แสดงข้อความ
      print("Error fetching fire tank data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchFireTankData(); // ดึงข้อมูลเมื่อหน้าเริ่มต้น
    fetchBuildings();

    remainingQuarterTimeInSeconds =
        FireTankStatusPageState.calculateNextQuarterEnd()
            .difference(DateTime.now())
            .inSeconds;
  }

  Future<void> fetchBuildings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .get();
    final buildings =
        snapshot.docs.map((doc) => doc['building'] as String).toSet().toList();

    setState(() {
      _buildings = buildings;
    });
  }

  /// ดึงรายชื่อชั้นของอาคารที่เลือก
  Future<void> fetchFloors(String building) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('building', isEqualTo: building)
        .get();

    final floors = snapshot.docs
        .map((doc) => doc['floor'].toString()) // แปลงเป็น String
        .toSet()
        .toList();

    floors.sort(
        (a, b) => int.parse(a).compareTo(int.parse(b))); // เรียงจากน้อยไปมาก

    setState(() {
      _floors = floors;
      selectedFloor = null;
    });
  }

  // ฟังก์ชันสำหรับการแก้ไขสถานะการตรวจสอบ
  Future<void> _updateStatus(String tankId, String newStatus) async {
    try {
      // ค้นหาถังที่มี tank_id ตรงกับที่ระบุ
      var docSnapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .where('tank_id', isEqualTo: tankId) // ค้นหาจากฟิลด์ tank_id
          .get();

      if (docSnapshot.docs.isNotEmpty) {
        // ถ้ามีข้อมูลตรงกับ tank_id
        var docRef = docSnapshot.docs.first.reference;
        // อัปเดตสถานะใน firetank_Collection
        await docRef.update({'status': newStatus});

        // อัปเดตสถานะใน form_checks
        await FirebaseFirestore.instance
            .collection('form_checks')
            .where('tank_id', isEqualTo: tankId)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({'status': newStatus});
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('สถานะการตรวจสอบได้รับการอัปเดต')));
      } else {
        throw Exception('ไม่พบถังที่มี tank_id: $tankId');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  Future<void> _deleteTank(String tankId, String dateChecked) async {
    try {
      // ค้นหาเอกสารที่ตรงกับ tank_id และ date_checked
      var formCheckDocs = await FirebaseFirestore.instance
          .collection('form_checks')
          .where('tank_id', isEqualTo: tankId)
          .where('date_checked', isEqualTo: dateChecked) // เพิ่มตัวกรองวันที่
          .get();

      if (formCheckDocs.docs.isEmpty) {
        debugPrint(
            "ไม่พบข้อมูลที่ตรงกับ tank_id: $tankId และ date_checked: $dateChecked");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลที่ต้องการลบ')));
        return;
      }

      // ฟังก์ชันแจ้งเตือนการลบ
      void _showDeleteConfirmationDialog(String tankId, String dateChecked) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('ยืนยันการลบ'),
              content: Text(
                  'คุณต้องการลบข้อมูลของถัง $tankId ที่วันที่ตรวจสอบ $dateChecked หรือไม่?'),
              actions: [
                TextButton(
                  onPressed: () {
                    // ถ้าผู้ใช้เลือก "ยืนยัน"
                    Navigator.pop(context); // ปิด Dialog
                    _deleteTank(tankId, dateChecked); // เรียกฟังก์ชันลบ
                  },
                  child: const Text('ยืนยัน'),
                ),
                TextButton(
                  onPressed: () {
                    // ถ้าผู้ใช้เลือก "ยกเลิก"
                    Navigator.pop(context); // ปิด Dialog
                  },
                  child: const Text('ยกเลิก'),
                ),
              ],
            );
          },
        );
      }

      // หาเอกสารที่มี time_checked ล่าสุด
      QueryDocumentSnapshot<Map<String, dynamic>> latestDoc =
          formCheckDocs.docs.first;

      for (var doc in formCheckDocs.docs) {
        String aTimeChecked = latestDoc['time_checked'] as String;
        String bTimeChecked = doc['time_checked'] as String;

        // เปรียบเทียบเวลาในรูปแบบ "HH:mm"
        if (aTimeChecked.compareTo(bTimeChecked) < 0) {
          latestDoc = doc;
        }
      }

      // ลบเอกสารที่มี time_checked ล่าสุด
      debugPrint(
          "ลบเอกสารที่มี time_checked ล่าสุด: ${latestDoc['time_checked']}");
      await latestDoc.reference.delete();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบข้อมูลการตรวจสอบล่าสุดเรียบร้อย')));

      // อัปเดต UI โดยการเอาแถวข้อมูลออกจาก DataTable
      setState(() {
        combinedData = combinedData
            .where((inspection) =>
                inspection['tank_id'] != tankId ||
                inspection['date_checked'] != dateChecked ||
                inspection['time_checked'] != latestDoc['time_checked'])
            .toList();
      });

      debugPrint("ข้อมูลการตรวจสอบที่อัปเดตใหม่: $combinedData");
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาด: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการตรวจสอบ'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // จัดตำแหน่งกลาง
              children: [
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
                const SizedBox(height: 5),
                // ส่วนตัวกรอง
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ค้นหาและจัดเรียงข้อมูล',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                hint: const Text('เลือกอาคาร'),
                                value: selectedBuilding,
                                onChanged: (value) {
                                  setState(() {
                                    selectedBuilding = value;
                                    selectedFloor = null;
                                    fetchFloors(
                                        value!); // อัปเดตรายชื่อชั้นเมื่อเลือกอาคาร
                                  });
                                },
                                items: _buildings
                                    .map((building) => DropdownMenuItem<String>(
                                          value: building,
                                          child: Text(building),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButton<String>(
                                hint: const Text('เลือกชั้น'),
                                value: selectedFloor,
                                onChanged: (value) {
                                  setState(() {
                                    selectedFloor = value;
                                  });
                                },
                                items: _floors
                                    .map((floor) => DropdownMenuItem<String>(
                                          value: floor,
                                          child: Text(floor),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedStatus,
                                isExpanded: true,
                                hint: const Text('เลือกสถานะการตรวจสอบ'),
                                items: [
                                  'ตรวจสอบแล้ว',
                                  'ส่งซ่อม',
                                  'ชำรุด',
                                  'ยังไม่ตรวจสอบ'
                                ].map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedStatus = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                        // **ปุ่มรีเซ็ตตัวกรอง**
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedBuilding = null;
                                  selectedFloor = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                    255, 118, 36, 212), // สีของปุ่ม
                              ),
                              child: const Text('รีเซ็ตตัวกรองทั้งหมด'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // ส่วนแสดงข้อมูล
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('firetank_Collection')
                      .snapshots(),
                  builder: (context, firetankSnapshot) {
                    if (firetankSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!firetankSnapshot.hasData ||
                        firetankSnapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('ไม่มีข้อมูลใน Firetank Collection'));
                    }

                    List<Map<String, dynamic>> firetankData = firetankSnapshot
                        .data!.docs
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .toList();

                    // ดึงข้อมูลจาก form_checks
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('form_checks')
                          .orderBy('date_checked',
                              descending: true) // เรียงจากวันที่ล่าสุด

                          .snapshots(),
                      builder: (context, formChecksSnapshot) {
                        if (formChecksSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!formChecksSnapshot.hasData ||
                            formChecksSnapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text('ไม่มีข้อมูลใน Form Checks'));
                        }

// ดึงข้อมูลล่าสุดสำหรับ tank_id แต่ละรายการ
                        Map<String, Map<String, dynamic>> latestFormChecks = {};
                        for (var doc in formChecksSnapshot.data!.docs) {
                          Map<String, dynamic> data =
                              doc.data() as Map<String, dynamic>;
                          String tankId = data['tank_id'] ?? 'N/A';

                          // เก็บข้อมูลล่าสุดของแต่ละ tank_id
                          if (!latestFormChecks.containsKey(tankId)) {
                            latestFormChecks[tankId] = data;
                          }
                        }
                        List<Map<String, dynamic>> formChecksData =
                            formChecksSnapshot.data!.docs
                                .map(
                                    (doc) => doc.data() as Map<String, dynamic>)
                                .toList();

                        // รวมข้อมูลจากทั้งสอง collection โดยใช้วันที่ตรวจสอบล่าสุด
                        List<Map<String, dynamic>> combinedData =
                            firetankData.map((firetank) {
                          String tankId = firetank['tank_id'] ?? 'N/A';

                          // หา form_check ที่มี date_checked ล่าสุดและ tank_id ตรงกัน
                          var relevantFormChecks = formChecksData
                              .where((check) => check['tank_id'] == tankId);
                          var latestFormCheck = relevantFormChecks.isNotEmpty
                              ? relevantFormChecks.reduce((a, b) {
                                  DateTime dateTimeA = DateTime.tryParse(
                                          '${a['date_checked']} ${a['time_checked'] ?? '00:00:00'}') ??
                                      DateTime.fromMillisecondsSinceEpoch(0);
                                  DateTime dateTimeB = DateTime.tryParse(
                                          '${b['date_checked']} ${b['time_checked'] ?? '00:00:00'}') ??
                                      DateTime.fromMillisecondsSinceEpoch(0);
                                  return dateTimeA.isAfter(dateTimeB) ? a : b;
                                })
                              : {
                                  'date_checked': 'N/A',
                                  'time_checked': 'N/A',
                                  'inspector': 'N/A',
                                  'user_type': 'N/A',
                                  'status': 'N/A',
                                  'remarks': 'N/A'
                                };

                          return {
                            'tank_id': tankId,
                            'building': firetank['building']?.toString() ??
                                'N/A', // แปลงเป็น String
                            'floor': firetank['floor']?.toString() ??
                                'N/A', // แปลงเป็น String
                            'date_checked':
                                latestFormCheck['date_checked']?.toString() ??
                                    'N/A', // แปลงเป็น String
                            'inspector':
                                latestFormCheck['inspector']?.toString() ??
                                    'N/A', // แปลงเป็น String
                            'user_type':
                                latestFormCheck['user_type']?.toString() ??
                                    'N/A', // แปลงเป็น String
                            'status': firetank['status']?.toString() ??
                                'N/A', // แปลงเป็น String
                            'remarks': latestFormCheck['remarks']?.toString() ??
                                'N/A', // แปลงเป็น String
                          };
                        }).toList();

                        // กรองข้อมูลตามตัวเลือก
                        if (selectedBuilding != null &&
                            selectedBuilding!.isNotEmpty) {
                          combinedData = combinedData.where((inspection) {
                            return inspection['building'] == selectedBuilding;
                          }).toList();
                        }
                        if (selectedFloor != null &&
                            selectedFloor!.isNotEmpty) {
                          combinedData = combinedData.where((inspection) {
                            return inspection['floor'] == selectedFloor;
                          }).toList();
                        }
                        if (selectedStatus != null &&
                            selectedStatus!.isNotEmpty) {
                          combinedData = combinedData.where((inspection) {
                            return inspection['status'] == selectedStatus;
                          }).toList();
                        }

                        // การจัดเรียงข้อมูล
                        if (sortBy == 'tank_number') {
                          combinedData.sort((a, b) {
                            return a['tank_id'].compareTo(b['tank_id']);
                          });
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor: MaterialStateColor.resolveWith(
                              (states) => Colors.blueGrey.shade50,
                            ),
                            dataRowColor: MaterialStateColor.resolveWith(
                              (states) => Colors.white,
                            ),
                            columns: const [
                              DataColumn(label: Text('หมายเลขถัง')),
                              DataColumn(label: Text('อาคาร')),
                              DataColumn(label: Text('ชั้น')),
                              DataColumn(label: Text('วันที่ตรวจสอบ')),
                              DataColumn(label: Text('ผู้ตรวจสอบ')),
                              DataColumn(label: Text('ประเภทผู้ใช้')),
                              DataColumn(label: Text('ผลการตรวจสอบ')),
                              DataColumn(label: Text('หมายเหตุ')),
                              DataColumn(label: Text('การกระทำ')),
                            ],
                            rows: combinedData.map((inspection) {
                              Color statusColor = Colors.grey;

                              if (inspection['status'] == 'ตรวจสอบแล้ว') {
                                statusColor = Colors.green;
                              } else if (inspection['status'] == 'ชำรุด') {
                                statusColor = Colors.red;
                              } else if (inspection['status'] == 'ส่งซ่อม') {
                                statusColor = Colors.orange;
                              }

                              return DataRow(
                                color: MaterialStateColor.resolveWith(
                                    (states) => Colors.white),
                                cells: [
                                  DataCell(Text(
                                      inspection['tank_id']?.toString() ??
                                          'N/A')),
                                  DataCell(Text(
                                      inspection['building']?.toString() ??
                                          'N/A')),
                                  DataCell(Text(
                                      inspection['floor']?.toString() ??
                                          'N/A')),
                                  DataCell(Text(
                                      inspection['date_checked']?.toString() ??
                                          'N/A')),
                                  DataCell(Text(
                                      inspection['inspector']?.toString() ??
                                          'N/A')),
                                  DataCell(Text(
                                      inspection['user_type']?.toString() ??
                                          'N/A')),
                                  DataCell(
                                    Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(inspection['status']?.toString() ??
                                            'N/A'),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(
                                      inspection['remarks']?.toString() ??
                                          'N/A')),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            _showStatusDialog(
                                                inspection['tank_id'] ?? '',
                                                inspection['status'] ?? '');
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            _showDeleteConfirmationDialog(
                                              inspection['tank_id'] ?? '',
                                              inspection['date_checked'] ?? '',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ฟังก์ชันแจ้งเตือนการลบ
  void _showDeleteConfirmationDialog(String tankId, String dateChecked) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text(
              'คุณต้องการลบข้อมูลของถัง $tankId ที่วันที่ตรวจสอบ $dateChecked หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                // ถ้าผู้ใช้เลือก "ยืนยัน"
                Navigator.pop(context); // ปิด Dialog
                _deleteTank(tankId, dateChecked); // เรียกฟังก์ชันลบ
              },
              child: const Text('ยืนยัน'),
            ),
            TextButton(
              onPressed: () {
                // ถ้าผู้ใช้เลือก "ยกเลิก"
                Navigator.pop(context); // ปิด Dialog
              },
              child: const Text('ยกเลิก'),
            ),
          ],
        );
      },
    );
  }

  // Dialog ให้ผู้ใช้เลือกสถานะใหม่
  void _showStatusDialog(String tankId, String currentStatus) {
    String? newStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('เลือกสถานะใหม่'),
          content: DropdownButton<String>(
            value: newStatus,
            isExpanded: true,
            items: ['ตรวจสอบแล้ว', 'ส่งซ่อม', 'ชำรุด', 'ยังไม่ตรวจสอบ']
                .map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                newStatus = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                // ตรวจสอบว่า newStatus ไม่เป็น null ก่อนบันทึก
                if (newStatus != null) {
                  _updateStatus(
                      tankId, newStatus!); // เพิ่ม ! เพื่อบอกว่าไม่เป็น null
                  Navigator.pop(context);
                } else {
                  // จัดการกรณีที่ newStatus เป็น null
                  // เช่น แสดงข้อความผิดพลาดหรือไม่ทำอะไร
                }
              },
              child: const Text('บันทึก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ยกเลิก'),
            ),
          ],
        );
      },
    );
  }
}
