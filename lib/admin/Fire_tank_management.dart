import 'package:firecheck_setup/admin/EditFireTank.dart';
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

  List<String> _buildings = [];
  List<String> _floors = [];

  List<String> _types = [];

  @override
  void initState() {
    super.initState();
    fetchBuildings();
    _fetchTypes();
  }

  Future<void> _fetchTypes() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('FE_type').get();
      setState(() {
        _types = snapshot.docs
            .map((doc) => doc['type'].toString())
            .toList(); // ดึงข้อมูลประเภทและเพิ่มลงใน _typeList
      });
    } catch (e) {
      print('Error fetching types: $e');
    }
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
      _selectedFloor = null;
    });
  }

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
                        _selectedFloor = null;
                        fetchFloors(value!); // อัปเดตรายชื่อชั้นเมื่อเลือกอาคาร
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
                    final tankId = (doc['tank_id'] as String)
                        .toLowerCase(); // แปลงเป็นพิมพ์เล็ก
                    return tankId.contains(
                        _searchTankId.toLowerCase()); // ค้นหาแบบไม่สนตัวพิมพ์
                  }).toList();

                  if (tanks.isEmpty) {
                    return const Center(
                      child: Text('ไม่พบข้อมูลที่ตรงกับการค้นหา'),
                    );
                  }

                  return ListView.builder(
                    itemCount: tanks.length,
                    itemBuilder: (context, index) {
                      // เรียงลำดับ tanks ตาม tank_id โดยการแปลงเป็นตัวเลข
                      tanks.sort((a, b) {
                        final idA = a['tank_id'].replaceAll(
                            RegExp(r'\D'), ''); // ดึงตัวเลขออกจาก tank_id
                        final idB = b['tank_id'].replaceAll(RegExp(r'\D'), '');
                        return int.parse(idA)
                            .compareTo(int.parse(idB)); // เปรียบเทียบตัวเลข
                      });

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
                            'ประเภทถัง: ${tank['type']}\nอาคาร: ${tank['building']}\nชั้น: ${tank['floor']}',
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
                                      builder: (context) => EditFireTankPage(
                                        tankIdToEdit:
                                            tank.id, // ส่ง tank_id ของเอกสารไป
                                      ),
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
  const FireTankFormPage({Key? key}) : super(key: key);

  @override
  _FireTankFormPageState createState() => _FireTankFormPageState();
}

class _FireTankFormPageState extends State<FireTankFormPage> {
  final TextEditingController _fireExtinguisherIdController =
      TextEditingController();
  String? _type; // ตัวแปร _type อาจจะเป็น String
  String? _building;
  String? _floor;
  DateTime _installationDate = DateTime.now();
  String? _qrCode;

  List<String> _buildingList = [];
  List<String> _typeList = [];
  int _totalFloors = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBuildings();
    _fetchTypes(); // ดึงข้อมูลประเภทจาก FE_type

    // ดึงหมายเลขถังสำหรับการเพิ่มใหม่
    _getNextId().then((nextId) {
      setState(() {
        _fireExtinguisherIdController.text = nextId;
      });
    });
  }

  // ฟังก์ชันดึงข้อมูลประเภทจาก collection 'FE_type'
  Future<void> _fetchTypes() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('FE_type').get();
      setState(() {
        _typeList = snapshot.docs
            .map((doc) => doc['type'].toString())
            .toList(); // ดึงข้อมูลประเภทและเพิ่มลงใน _typeList
      });
    } catch (e) {
      print('Error fetching types: $e');
    }
  }

  Future<void> _fetchBuildings() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('buildings').get();
      setState(() {
        _buildingList =
            snapshot.docs.map((doc) => doc['name'].toString()).toList();
      });
    } catch (e) {
      print('Error fetching buildings: $e');
    }
  }

  Future<void> _fetchTotalFloors(String buildingName) async {
    setState(() {
      _isLoading = true;
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('buildings')
          .where('name', isEqualTo: buildingName)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _totalFloors = int.parse(snapshot.docs.first['totalFloors']);
          _floor = null;
        });
      }
    } catch (e) {
      print('Error fetching total floors: $e');
    } finally {
      setState(() {
        _isLoading = false;
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
          .orderBy('tank_id')
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<int> usedIds = [];

        // ดึงหมายเลขถังดับเพลิงที่ใช้งานแล้ว
        for (var doc in snapshot.docs) {
          final lastId = doc['tank_id'] as String;
          final number = int.parse(lastId.replaceAll(RegExp(r'\D'), ''));
          usedIds.add(number);
        }

        // หาหมายเลขที่ยังไม่มี
        int nextId = 1;
        while (usedIds.contains(nextId)) {
          nextId++;
        }

        return 'FE${nextId.toString().padLeft(3, '0')}';
      } else {
        return 'FE001';
      }
    } catch (e) {
      print('Error getting next ID: $e');
      return 'FE001';
    }
  }

  Future<void> _generateQRCode(String tankId) async {
    _qrCode = 'https://fire-check-db.web.app/user?tankId=$tankId';
  }

  Future<void> _saveFireTankData() async {
    try {
      final newId = _fireExtinguisherIdController.text;

      // แสดงค่าตัวแปรที่ใช้ในการบันทึกข้อมูล
      print('newId: $newId');
      print('type: $_type');
      print('building: $_building');
      print('floor: $_floor');
      print('installationDate: $_installationDate');

      //กรอกให้ครบ
      if (_type == null || _building == null || _floor == null) {
        print('ข้อมูลไม่ครบ');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
        );
        return;
      }

      await _generateQRCode(newId);

      print('กำลังบันทึกข้อมูลไปยัง Firestore...');
      try {
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('firetank_Collection')
            .add({
          'tank_id': newId,
          'type': _type,
          'building': _building,
          'floor': _floor,
          'status': 'ตรวจสอบแล้ว',
          'installation_date': _installationDate,
          'qrcode': _qrCode,
        });

        print('บันทึกข้อมูลสำเร็จ: ${docRef.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
        );

        // เพิ่มการหน่วงเวลาก่อนเปลี่ยนหน้า
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        print("Error saving document: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } catch (e) {
      print("Error saving document: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มข้อมูลถังดับเพลิง'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            Row(
              children: [
                Text(
                    'วันที่ติดตั้ง: ${DateFormat('dd/MM/yyyy').format(_installationDate)}'),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectInstallationDate(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fireExtinguisherIdController,
              decoration: const InputDecoration(
                labelText: 'Fire Extinguisher ID',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _type,
              onChanged: (value) {
                setState(() {
                  _type = value;
                });
              },
              items: _typeList.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'ประเภทถังดับเพลิง',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _building,
              hint: const Text('เลือกอาคาร'),
              onChanged: (String? newValue) {
                setState(() {
                  _building = newValue;
                  _fetchTotalFloors(newValue!);
                });
              },
              items: _buildingList.map((String value) {
                return DropdownMenuItem<String>(
                    value: value, child: Text(value));
              }).toList(),
            ),
            const SizedBox(height: 10),
            if (_building != null)
              DropdownButton<String>(
                value: _floor,
                hint: const Text('เลือกชั้น'),
                onChanged: (String? newValue) {
                  setState(() {
                    _floor = newValue;
                  });
                },
                items: List.generate(_totalFloors, (index) => '${index + 1}')
                    .map((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
              ),
            const SizedBox(height: 20),
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
                child: const Text('บันทึก', style: TextStyle(fontSize: 16)),
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
