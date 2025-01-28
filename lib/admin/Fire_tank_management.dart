import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // สำหรับเปิด URL

class FireTankManagementPage extends StatefulWidget {
  const FireTankManagementPage({Key? key}) : super(key: key);

  @override
  _FireTankManagementPageState createState() => _FireTankManagementPageState();
}

class _FireTankManagementPageState extends State<FireTankManagementPage> {
  String? _selectedBuilding;
  String? _selectedFloor;
  String? _selectedType;
  String _searchTankId = '';

  final List<String> _buildings = [
    '10 ชั้น',
    'หลวงปู่ขาว',
    'OPD',
    '114 เตียง',
    'NSU',
    '60 เตียง',
    'เมตตา',
    'โภชนาศาสตร์',
    'จิตเวช',
    'กายภาพ&ธนาคารเลือด',
    'พัฒนากระตุ้นเด็ก',
    'จ่ายกลาง',
    'ซักฟอก',
    'ผลิตงาน & โรงงานช่าง',
  ]; // ตัวอย่างข้อมูลอาคาร
  final List<String> _floors = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11'
  ]; // ตัวอย่างข้อมูลชั้น
  final List<String> _types = [
    'ผงเคมีแห้ง',
    'co2',
    'bf2000'
  ]; // ตัวอย่างข้อมูลประเภท

  // ฟังก์ชันแสดงการยืนยันการลบ
  void _confirmDelete(BuildContext context, String tankId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบถังดับเพลิงนี้?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('firetank_Collection')
                  .doc(tankId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ลบข้อมูลสำเร็จ')),
              );
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Tank Management'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // ตัวกรอง
            Row(
              children: [
                // ตัวกรองอาคาร
                Expanded(
                  child: DropdownButton<String>(
                    hint: const Text('เลือกอาคาร'),
                    value: _selectedBuilding,
                    onChanged: (value) {
                      setState(() {
                        _selectedBuilding = value;
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
                // ตัวกรองชั้น
                Expanded(
                  child: DropdownButton<String>(
                    hint: const Text('เลือกชั้น'),
                    value: _selectedFloor,
                    onChanged: (value) {
                      setState(() {
                        _selectedFloor = value;
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
                const SizedBox(width: 10),
                // ตัวกรองประเภท
                Expanded(
                  child: DropdownButton<String>(
                    hint: const Text('เลือกประเภท'),
                    value: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                    items: _types
                        .map((type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // **ปุ่มรีเซ็ตตัวกรอง**
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedBuilding = null;
                      _selectedFloor = null;
                      _selectedType = null;
                      _searchTankId = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color.fromARGB(255, 118, 36, 212), // สีของปุ่ม
                  ),
                  child: const Text('รีเซ็ตตัวกรองทั้งหมด'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ช่องค้นหา Tank ID
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchTankId = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'ค้นหาจาก Tank ID',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
            const SizedBox(height: 10),
            // แสดงข้อมูลถังดับเพลิง
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('firetank_Collection')
                    .where(
                      'building',
                      isEqualTo: _selectedBuilding == null ||
                              _selectedBuilding!.isEmpty
                          ? null
                          : _selectedBuilding,
                    )
                    .where(
                      'floor',
                      isEqualTo:
                          _selectedFloor == null || _selectedFloor!.isEmpty
                              ? null
                              : _selectedFloor,
                    )
                    .where(
                      'type',
                      isEqualTo: _selectedType == null || _selectedType!.isEmpty
                          ? null
                          : _selectedType,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('กรุณากรองข้อมูลหรือค้นหาใหม่'),
                    );
                  }

                  // ฟิลเตอร์ Tank ID หลังจากดึงข้อมูลจาก Firebase
                  final tanks = snapshot.data!.docs.where((doc) {
                    final tankId = doc['tank_id'] as String;
                    return tankId.contains(_searchTankId);
                  }).toList();

                  if (tanks.isEmpty) {
                    return const Center(
                      child: Text('ไม่พบข้อมูลที่ตรงกับการค้นหา'),
                    );
                  }

                  return ListView.builder(
                    itemCount: tanks.length,
                    itemBuilder: (context, index) {
                      final tank = tanks[index];
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text('Tank ID: ${tank['tank_id']}'),
                          subtitle: Text(
                            'Type: ${tank['type']}, Building: ${tank['building']}, Floor: ${tank['floor']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FireTankDetailPage(tank: tank),
                              ),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FireTankFormPage(editTank: tank),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _confirmDelete(context, tank.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FireTankFormPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}

class FireTankFormPage extends StatefulWidget {
  final QueryDocumentSnapshot<Object?>? editTank;

  const FireTankFormPage({Key? key, this.editTank}) : super(key: key);

  @override
  _FireTankFormPageState createState() => _FireTankFormPageState();
}

class _FireTankFormPageState extends State<FireTankFormPage> {
  final TextEditingController _fireExtinguisherIdController =
      TextEditingController();
  String? _type; // เปลี่ยนจาก TextEditingController เป็น String?
  String? _building; // เปลี่ยนจาก TextEditingController เป็น String?
  String? _floor; // เปลี่ยนจาก TextEditingController เป็น String?
  DateTime _installationDate = DateTime.now();
  String? _qrCode;

  @override
  void initState() {
    super.initState();
    if (widget.editTank != null) {
      // ถ้าเป็นการแก้ไขข้อมูล
      _fireExtinguisherIdController.text = widget.editTank!['tank_id'];
      _type = widget.editTank!['type'];
      _building = widget.editTank!['building'];
      _floor = widget.editTank!['floor'];
      _installationDate =
          (widget.editTank!['installation_date'] as Timestamp).toDate();
    } else {
      // ถ้าเป็นการเพิ่มข้อมูลใหม่
      _getNextId().then((nextId) {
        setState(() {
          _fireExtinguisherIdController.text = nextId;
        });
      });
    }
  }

  Future<void> _selectInstallationDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _installationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (selectedDate != null && selectedDate != _installationDate) {
      setState(() {
        _installationDate = selectedDate;
      });
    }
  }

  Future<String> _getNextId() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .orderBy('tank_id', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final lastId = snapshot.docs.first['tank_id'] as String;
        final number = int.parse(lastId.replaceAll(RegExp(r'\D'), '')) + 1;
        return 'FE${number.toString().padLeft(3, '0')}';
      } else {
        return 'FE001'; // ถ้าไม่มีข้อมูลในฐานข้อมูล
      }
    } catch (e) {
      print('Error getting next ID: $e');
      return 'FE001'; // fallback ID
    }
  }

  Future<void> _saveTankData() async {
    try {
      // บันทึกข้อมูลใหม่ด้วย ID ถัดไป
      await FirebaseFirestore.instance.collection('firetank_Collection').add({
        'status': 'checked', // ข้อมูลอื่นๆ
        'date_checked': Timestamp.now(),
      });

      // อัปเดตค่าในฟอร์มให้แสดง ID ถัดไป
      setState(() {});
    } catch (e) {
      print("Error saving tank data: $e");
    }
  }

  // ฟังก์ชันเพื่อดึง Fire Extinguisher ID ถัดไป

  // ฟังก์ชันคำนวณ ID ถัดไป
  String _generateNextId(String latestId) {
    String numericPart = latestId.substring(2); // ตัด "FE" ออก
    int nextIdNumber = int.parse(numericPart) + 1; // เพิ่ม 1
    String nextId = 'FE' +
        nextIdNumber
            .toString()
            .padLeft(3, '0'); // ใช้ padLeft เพื่อให้ตัวเลขมี 3 หลัก
    return nextId;
  }

  Future<void> _generateQRCode(String tankId) async {
    // ใช้ tankId เป็นข้อมูลในการสร้าง QR Code
    _qrCode =
        'https://fire-check-db.web.app/user?tankId=$tankId'; // URL หรือข้อมูลที่ต้องการสร้าง QR
  }

  // ฟังก์ชันบันทึกข้อมูล
  Future<void> _saveFireTankData() async {
    try {
      final newId = _fireExtinguisherIdController.text;

      // สร้าง QR Code
      await _generateQRCode(newId); // << เพิ่มตรงนี้

      if (widget.editTank == null) {
        // เพิ่มข้อมูลใหม่
        await FirebaseFirestore.instance.collection('firetank_Collection').add({
          'tank_id': newId,
          'type': _type,
          'building': _building,
          'floor': _floor,
          'status': 'ตรวจสอบแล้ว',
          'installation_date': _installationDate, // บันทึกวันที่ติดตั้ง
          'qrcode': _qrCode, // << เพิ่มตรงนี้
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
        );
      } else {
        // แก้ไขข้อมูลเดิม
        await FirebaseFirestore.instance
            .collection('firetank_Collection')
            .doc(widget.editTank!.id)
            .update({
          'tank_id': newId,
          'type': _type,
          'building': _building,
          'floor': _floor,
          'status': 'ตรวจสอบแล้ว',
          'installation_date': _installationDate, // อัปเดตวันที่ติดตั้ง
          'qrcode': _qrCode, // << เพิ่มตรงนี้
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('แก้ไขข้อมูลสำเร็จ')),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editTank == null
            ? 'เพิ่มข้อมูลถังดับเพลิง'
            : 'แก้ไขข้อมูลถังดับเพลิง'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ฟอร์มสำหรับเลือกวันที่ติดตั้ง
            Row(
              children: [
                Text(
                    'วันที่ติดตั้ง: ${DateFormat('dd/MM/yyyy').format(_installationDate)}'),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectInstallationDate(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Fire Extinguisher ID Field (ที่จะแสดง FE + เลข)
            TextField(
              controller: _fireExtinguisherIdController,
              decoration: const InputDecoration(
                labelText: 'Fire Extinguisher ID',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
              enabled: widget.editTank ==
                  null, // ถ้าไม่ได้แก้ไข, สามารถเปลี่ยน ID ได้
            ),

            const SizedBox(height: 10),

            // Dropdown for Type
            DropdownButton<String>(
              value: _type, // ใช้ _type แทน _typeController
              hint: const Text('เลือกประเภท'),
              onChanged: (String? newValue) {
                setState(() {
                  _type = newValue;
                });
              },
              items: [
                'ผงเคมีแห้ง',
                'co2',
                'bf2000',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Dropdown for Building
            DropdownButton<String>(
              value: _building, // ใช้ _building แทน _buildingController
              hint: const Text('เลือกอาคาร'),
              onChanged: (String? newValue) {
                setState(() {
                  _building = newValue;
                });
              },
              items: [
                '10 ชั้น',
                'หลวงปู่ขาว',
                'OPD',
                '114 เตียง',
                'NSU',
                '60 เตียง',
                'เมตตา',
                'โภชนาศาสตร์',
                'จิตเวช',
                'กายภาพ&ธนาคารเลือด',
                'พัฒนากระตุ้นเด็ก',
                'จ่ายกลาง',
                'ซักฟอก',
                'ผลิตงาน & โรงงานช่าง',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Dropdown for Floor
            DropdownButton<String>(
              value: _floor, // ใช้ _floor แทน _floorController
              hint: const Text('เลือกชั้น'),
              onChanged: (String? newValue) {
                setState(() {
                  _floor = newValue;
                });
              },
              items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveFireTankData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.editTank == null ? 'บันทึก' : 'อัปเดต',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// เพิ่มหน้ารายละเอียด
class FireTankDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot<Object?> tank;

  const FireTankDetailPage({Key? key, required this.tank}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // แปลงวันที่จาก Firestore เป็น DateTime
    final DateTime installationDate =
        (tank['installation_date'] as Timestamp).toDate();

    // แปลงวันที่เป็นรูปแบบ "วัน/เดือน/ปี เวลา"
    final formattedDate = DateFormat('dd/MM/yyyy ').format(installationDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดถังดับเพลิง: ${tank['tank_id']}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tank ID: ${tank['tank_id']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'ประเภท: ${tank['type']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'อาคาร: ${tank['building']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'ชั้น: ${tank['floor']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            // แสดงวันที่ติดตั้ง
            Text('วันที่ติดตั้ง: $formattedDate'),

            // แสดง QR Code และลิงก์ที่คลิกได้
            if (tank['qrcode'] != null)
              Column(
                children: [
                  // QR Code Image
                  Center(
                    child: QrImageView(
                      data: tank['qrcode'], // ใช้ข้อมูล qrcode จาก Firestore
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // คลิกเพื่อลิงก์
                  GestureDetector(
                    onTap: () async {
                      final url = tank['qrcode']; // ลิงก์ที่ได้จาก Firestore
                      if (await canLaunch(url)) {
                        await launch(url); // เปิดลิงก์ในเบราว์เซอร์
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('ไม่สามารถเปิดลิงก์นี้ได้: $url')),
                        );
                      }
                    },
                    child: Text(
                      tank['qrcode'],
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('ย้อนกลับ'),
            ),
          ],
        ),
      ),
    );
  }
}
