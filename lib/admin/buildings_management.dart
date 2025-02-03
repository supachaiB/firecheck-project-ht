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

  bool _isFormVisible = false;

  Future<void> _addBuilding() async {
    String name = _nameController.text;
    int totalFloors = int.tryParse(_floorsController.text) ?? 0;
    String description = _descriptionController.text;

    if (name.isEmpty || totalFloors <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกชื่ออาคารและจำนวนชั้นทั้งหมด')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('buildings').add({
        'name': name,
        'totalFloors': totalFloors.toString(),
        'description': description.isEmpty ? '' : description,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เพิ่มอาคารเรียบร้อย')),
      );
      _clearInputs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  void _clearInputs() {
    _nameController.clear();
    _floorsController.clear();
    _descriptionController.clear();
  }

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

  Future<void> _editBuilding(String id) async {
    final buildingRef =
        FirebaseFirestore.instance.collection('buildings').doc(id);
    final snapshot = await buildingRef.get();
    final buildingData = snapshot.data();

    if (buildingData != null) {
      _nameController.text = buildingData['name'];
      _floorsController.text = buildingData['totalFloors'];
      _descriptionController.text = buildingData['description'];

      setState(() {
        _isFormVisible = true;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('แก้ไขข้อมูลอาคาร'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'ชื่ออาคาร'),
              ),
              TextField(
                controller: _floorsController,
                decoration: InputDecoration(labelText: 'จำนวนชั้นทั้งหมด'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'รายละเอียด'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String name = _nameController.text;
                int totalFloors = int.tryParse(_floorsController.text) ?? 0;
                String description = _descriptionController.text;

                if (name.isEmpty || totalFloors <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
                  );
                } else {
                  await buildingRef.update({
                    'name': name,
                    'totalFloors': totalFloors.toString(),
                    'description': description,
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('บันทึกการแก้ไข'),
            ),
            TextButton(
              onPressed: () async {
                await buildingRef.delete();
                Navigator.of(context).pop();
              },
              child: Text('ลบอาคาร'),
            ),
          ],
        ),
      );
    }
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _editBuilding(
                                    building['id']); // เรียกฟังก์ชันแก้ไข
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                final buildingRef = FirebaseFirestore.instance
                                    .collection('buildings')
                                    .doc(building['id']);
                                await buildingRef.delete();
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          _editBuilding(building['id']);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isFormVisible = !_isFormVisible;
          });
        },
        child: Icon(_isFormVisible ? Icons.close : Icons.add),
      ),
    );
  }
}
