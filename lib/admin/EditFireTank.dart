import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditFireTankPage extends StatefulWidget {
  final String tankIdToEdit;

  const EditFireTankPage({Key? key, required this.tankIdToEdit})
      : super(key: key);

  @override
  _EditFireTankPageState createState() => _EditFireTankPageState();
}

class _EditFireTankPageState extends State<EditFireTankPage> {
  final TextEditingController _tankIdController = TextEditingController();
  String? _type;
  String? _building;
  String? _floor;
  int _totalFloors = 0;

  List<String> _typeOptions = [];
  List<String> _buildingOptions = [];
  List<String> _floorOptions = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    _fetchTankData();
  }

  // ดึงข้อมูล dropdown (ประเภทถัง & อาคาร)
  Future<void> _fetchDropdownData() async {
    try {
      var typeSnapshot =
          await FirebaseFirestore.instance.collection('FE_type').get();
      _typeOptions =
          typeSnapshot.docs.map((doc) => doc['type'] as String).toList();

      var buildingSnapshot =
          await FirebaseFirestore.instance.collection('buildings').get();
      _buildingOptions =
          buildingSnapshot.docs.map((doc) => doc['name'] as String).toList();

      setState(() {
        _isLoading = false; // เปลี่ยนเป็น false เมื่อโหลดข้อมูลเสร็จ
      });
    } catch (e) {
      print('🔥 Error fetching dropdown data: $e');
    }
  }

  Future<void> _fetchTankData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .doc(widget.tankIdToEdit)
          .get();

      if (doc.exists && doc.data() != null) {
        String? fetchedBuilding = doc['building'];
        String? fetchedFloor = doc['floor']?.toString(); // แปลงเป็น String
        String? fetchedType = doc['type'];
        String? fetchedTankId = doc['tank_id'];

        setState(() {
          _tankIdController.text = fetchedTankId ?? widget.tankIdToEdit;
          _type = _typeOptions.contains(fetchedType) ? fetchedType : null;
          _building = fetchedBuilding; // ดึงค่าอาคาร
          _floor = null; // เคลียร์ค่าเพื่อป้องกันปัญหา
          _isLoading = false;
        });

        // ✅ โหลดชั้นหลังจากดึงข้อมูลอาคาร
        if (_building != null) {
          await _fetchFloors(_building!, fetchedFloor);
        }
      } else {
        print("⚠️ ไม่มีข้อมูล: ${widget.tankIdToEdit}");
      }
    } catch (e) {
      print('🔥 Error fetching tank data: $e');
    }
  }

  // ดึงจำนวนชั้นจาก buildings.totalFloors
  Future<void> _fetchFloors(String buildingName,
      [String? selectedFloor]) async {
    try {
      var buildingDoc = await FirebaseFirestore.instance
          .collection('buildings')
          .where('name', isEqualTo: buildingName)
          .limit(1)
          .get();

      if (buildingDoc.docs.isNotEmpty) {
        var totalFloors = buildingDoc.docs.first['totalFloors'];

        if (totalFloors is String) {
          _totalFloors = int.tryParse(totalFloors) ?? 0;
        } else if (totalFloors is int) {
          _totalFloors = totalFloors;
        } else {
          _totalFloors = 0;
        }

        List<String> newFloorOptions =
            List.generate(_totalFloors, (index) => (index + 1).toString());

        setState(() {
          _floorOptions = newFloorOptions;

          // ✅ ถ้าชั้นที่โหลดมายังอยู่ในรายการ ให้กำหนดค่า
          if (selectedFloor != null && _floorOptions.contains(selectedFloor)) {
            _floor = selectedFloor;
          }
        });
      }
    } catch (e) {
      print('🔥 Error fetching floors: $e');
    }
  }

  // อัปเดตข้อมูล Firestore
  Future<void> _updateTankData() async {
    try {
      await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .doc(widget.tankIdToEdit)
          .update({
        'type': _type,
        'building': _building,
        'floor': _floor,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
      );
      Navigator.pop(context); // ปิดหน้าแก้ไข
    } catch (e) {
      print('🔥 Error updating tank data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลถังดับเพลิง'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷️ Input: เลขที่ถังดับเพลิง
                  TextField(
                    controller: _tankIdController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'เลขที่ถังดับเพลิง',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔥 Dropdown: ประเภทถังดับเพลิง
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(
                      labelText: 'ประเภทถังดับเพลิง',
                      border: OutlineInputBorder(),
                    ),
                    items: _typeOptions.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _type = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 🏢 Dropdown: อาคาร
                  DropdownButtonFormField<String>(
                    value: _building,
                    decoration: const InputDecoration(
                      labelText: 'อาคาร',
                      border: OutlineInputBorder(),
                    ),
                    items: _buildingOptions.map((building) {
                      return DropdownMenuItem(
                          value: building, child: Text(building));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _building = newValue;
                        _floor = null; // เคลียร์ค่า floor เมื่อเปลี่ยนอาคาร
                      });
                      _fetchFloors(newValue!);
                    },
                  ),
                  const SizedBox(height: 16),

                  // 🏬 Dropdown: ชั้น (ขึ้นอยู่กับอาคาร)
                  DropdownButtonFormField<String>(
                    value: _floor,
                    decoration: const InputDecoration(
                      labelText: 'ชั้น',
                      border: OutlineInputBorder(),
                    ),
                    items: _floorOptions.map((floor) {
                      return DropdownMenuItem(value: floor, child: Text(floor));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _floor = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // ✅ ปุ่มบันทึกข้อมูล
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateTankData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('บันทึกข้อมูล'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
