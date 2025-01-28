import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BuildingManagementScreen extends StatefulWidget {
  @override
  _BuildingManagementScreenState createState() =>
      _BuildingManagementScreenState();
}

class _BuildingManagementScreenState extends State<BuildingManagementScreen> {
  final _nameController = TextEditingController();
  final _floorsController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isFormVisible = false; // ควบคุมการแสดงผลของฟอร์มกรอกข้อมูล

  // ฟังก์ชันสำหรับการเพิ่มอาคารลง Firestore
  Future<void> _addBuilding() async {
    String name = _nameController.text;
    int totalFloors = int.tryParse(_floorsController.text) ?? 0;
    String description = _descriptionController.text;

    // ตรวจสอบว่ามีการกรอกชื่ออาคารและจำนวนชั้นทั้งหมด
    if (name.isEmpty || totalFloors <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกชื่ออาคารและจำนวนชั้นทั้งหมด')),
      );
      return;
    }

    try {
      // เพิ่มข้อมูลใน Firestore โดยไม่สนใจว่า "รายละเอียด" จะกรอกหรือไม่
      await FirebaseFirestore.instance.collection('buildings').add({
        'name': name,
        'totalFloors': totalFloors,
        'description': description.isEmpty
            ? ''
            : description, // ถ้าไม่มีรายละเอียดใส่ข้อความ 'ไม่มีรายละเอียด'
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เพิ่มอาคารเรียบร้อย')),
      );
      _clearInputs(); // เคลียร์ฟอร์มหลังการเพิ่มอาคาร
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // ฟังก์ชันสำหรับการเคลียร์ข้อมูลหลังจากเพิ่มอาคาร
  void _clearInputs() {
    _nameController.clear();
    _floorsController.clear();
    _descriptionController.clear();
  }

  // ฟังก์ชันดึงข้อมูลอาคารจาก Firestore
  Stream<List<Map<String, dynamic>>> _getBuildings() {
    return FirebaseFirestore.instance
        .collection('buildings')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'totalFloors': doc['totalFloors'],
          'description': doc['description'],
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Building Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // แสดงฟอร์มกรอกข้อมูลเมื่อ _isFormVisible เป็น true
            Visibility(
              visible: _isFormVisible,
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'ชื่ออาคาร',
                    ),
                  ),
                  TextField(
                    controller: _floorsController,
                    decoration: InputDecoration(
                      labelText: 'จำนวนชั้นทั้งหมด',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'รายละเอียด',
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addBuilding,
                    child: Text('เพิ่มอาคาร'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // ส่วนแสดงรายชื่ออาคาร
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getBuildings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('ยังไม่มีข้อมูลอาคาร'));
                  }

                  List<Map<String, dynamic>> buildings = snapshot.data!;
                  return ListView.builder(
                    itemCount: buildings.length,
                    itemBuilder: (context, index) {
                      final building = buildings[index];
                      return ListTile(
                        title: Text(building['name']),
                        subtitle: Text(
                            'จำนวนทั้งหมด: ${building['totalFloors']} ชั้น'),
                        onTap: () {
                          // เปิดรายละเอียดอาคาร
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(building['name']),
                              content: Text(building['description']),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('ปิด'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // ปุ่มเพิ่มอาคาร (FloatingActionButton)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isFormVisible = !_isFormVisible; // สลับสถานะการแสดงฟอร์ม
          });
        },
        child: Icon(_isFormVisible ? Icons.close : Icons.add), // เปลี่ยนไอคอน
      ),
    );
  }
}
