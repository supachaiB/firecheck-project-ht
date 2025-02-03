import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FireTankTypes extends StatefulWidget {
  @override
  _FireTankTypesState createState() => _FireTankTypesState();
}

class _FireTankTypesState extends State<FireTankTypes> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Uint8List? _selectedImage;
  String? _base64Image;

  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((e) {
        final imageBytes = reader.result as Uint8List;
        String base64Image = base64Encode(imageBytes);

        setState(() {
          _selectedImage = imageBytes;
          _base64Image = base64Image;
        });
      });
    });
  }

  Future<void> _saveFireTankType({String? docId}) async {
    if (_nameController.text.isEmpty || _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วนและเลือกภาพ')),
      );
      return;
    }

    try {
      if (docId == null) {
        await _firestore.collection('FE_type').add({
          'type': _nameController.text,
          'description': _descriptionController.text,
          'imageData': _base64Image,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('FE_type').doc(docId).update({
          'type': _nameController.text,
          'description': _descriptionController.text,
          'imageData': _base64Image,
        });
      }

      _nameController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
        _base64Image = null;
      });

      Navigator.of(context).pop();
    } catch (e) {
      print('Error storing FireTankType: $e');
    }
  }

  Future<void> _deleteFireTankType(String docId) async {
    await _firestore.collection('FE_type').doc(docId).delete();
  }

  void _showAddDialog(
      {String? docId, String? name, String? description, String? imageData}) {
    _nameController.text = name ?? '';
    _descriptionController.text = description ?? '';
    _base64Image = imageData;
    _selectedImage = imageData != null ? base64Decode(imageData) : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null
              ? 'เพิ่มประเภทถังดับเพลิง'
              : 'แก้ไขข้อมูลถังดับเพลิง'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'ชื่อประเภทถัง'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'รายละเอียด (ถ้ามี)'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('เลือกภาพ'),
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.memory(
                      _selectedImage!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => _saveFireTankType(docId: docId),
              child: Text(docId == null ? 'บันทึก' : 'อัปเดต'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ยกเลิก'),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _fetchFireTankTypes() {
    return _firestore
        .collection('FE_type')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('จัดการประเภทถังดับเพลิง')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchFireTankTypes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('ไม่มีข้อมูลประเภทถัง'));
          }

          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(12)),
                          child: data['imageData'] != null
                              ? Image.memory(
                                  base64Decode(data['imageData']),
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 150,
                                  color: Colors.grey[300],
                                  child:
                                      Icon(Icons.image_not_supported, size: 50),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              data['type'],
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 5),
                            Text(
                              data['description'] ?? 'ไม่มีรายละเอียด',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showAddDialog(
                                    docId: doc.id,
                                    name: data['name'],
                                    description: data['description'],
                                    imageData: data['imageData'],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteFireTankType(doc.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
