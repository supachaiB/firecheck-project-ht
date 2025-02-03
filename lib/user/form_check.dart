import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // สำหรับฟอร์แมตวันที่
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Firestore
import 'firetank_details.dart'; // นำเข้าไฟล์ที่แสดงประวัติการตรวจสอบ
import 'dart:convert'; // สำหรับการแปลง Base64
import 'dart:typed_data'; // สำหรับ Uint8List
import 'package:url_launcher/url_launcher.dart';

class FormCheckPage extends StatefulWidget {
  final String tankId;

  const FormCheckPage({Key? key, required this.tankId}) : super(key: key);

  @override
  _FormCheckPageState createState() => _FormCheckPageState();
}

class _FormCheckPageState extends State<FormCheckPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _inspectorController = TextEditingController();
  final TextEditingController _weightController =
      TextEditingController(); // สำหรับกรอกน้ำหนัก

  Map<String, String> equipmentStatus = {};
  List<String> staffList = [];
  List<String> filteredStaffList = [];
  String? selectedStaff;
  String? userType;
  String? latestCheckDate; // สำหรับวันที่ตรวจสอบล่าสุด
  String? latestCheckTime; // สำหรับเวลา
  String? fireTankType; // เพิ่มตัวแปรเพื่อเก็บค่า type
  Uint8List? imageBytes; // ตัวแปรเพื่อเก็บข้อมูลภาพ Base64 ที่แปลงแล้ว

  @override
  void initState() {
    super.initState();
    filteredStaffList = staffList;
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _timeController.text =
        DateFormat('HH:mm').format(DateTime.now()); // เวลาปัจจุบัน
    fetchLatestCheckDate(); // ดึงข้อมูลวันที่ล่าสุด
    fetchFireTankType(); // ดึงข้อมูล type ของ firetank_Collection
  }

  // ฟังก์ชันดึงข้อมูล type และภาพ Base64 จาก Firestore
  Future<void> fetchFireTankType() async {
    CollectionReference firetankCollection =
        FirebaseFirestore.instance.collection('firetank_Collection');
    try {
      QuerySnapshot querySnapshot = await firetankCollection
          .where('tank_id', isEqualTo: widget.tankId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          fireTankType = querySnapshot.docs.first['type'];
          _updateEquipmentStatus(); // ปรับเปลี่ยนรายการตรวจสอบตาม type
        });
        fetchImageData(); // ดึงข้อมูลภาพเมื่อได้ fireTankType
      }
    } catch (e) {
      //print("Error fetching firetank type: $e");
    }
  }

  // ฟังก์ชันปรับรายการตรวจสอบตามประเภท
  void _updateEquipmentStatus() {
    if (fireTankType == 'BF2000' || fireTankType == 'ผงเคมีแห้ง') {
      equipmentStatus = {
        'มาตรวัด': 'ปกติ',
        'สภาพผงเคมี': 'ปกติ',
      };
    } else if (fireTankType == 'CO2') {
      equipmentStatus = {
        'สภาพแรงดัน': 'ปกติ',
        'น้ำหนัก(กก.)': '', // กรอกข้อความ
      };
    }
  }

  Future<void> fetchImageData() async {
    if (fireTankType == null) return;

    CollectionReference feTypeCollection =
        FirebaseFirestore.instance.collection('FE_type');

    try {
      QuerySnapshot querySnapshot =
          await feTypeCollection.where('type', isEqualTo: fireTankType).get();

      if (querySnapshot.docs.isNotEmpty) {
        String base64Image = querySnapshot.docs.first['imageData'];
        Uint8List bytes = base64Decode(base64Image);

        setState(() {
          imageBytes = bytes;
        });
      }
    } catch (e) {
      print("Error fetching image data: $e");
    }
  }

  Future<void> fetchLatestCheckDate() async {
    CollectionReference formChecks =
        FirebaseFirestore.instance.collection('form_checks');

    try {
      QuerySnapshot querySnapshot = await formChecks
          .where('tank_id', isEqualTo: widget.tankId)
          .orderBy('date_checked', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // ดึงข้อมูลวันที่ตรวจสอบล่าสุดที่เป็น String
        String dateString = querySnapshot.docs.first['date_checked'];
        String timeString = querySnapshot.docs.first['time_checked'];

        setState(() {
          latestCheckDate = dateString; // วันที่
          latestCheckTime = timeString; // เวลา
        });
      } else {
        setState(() {
          latestCheckDate = 'ไม่มีข้อมูล';
          latestCheckTime = '';
        });
      }
    } catch (e) {
      print("Error fetching latest check date: $e");
      setState(() {
        latestCheckDate = 'เกิดข้อผิดพลาด';
        latestCheckTime = '';
      });
    }
  }

  void _filterStaff(String query) {
    if (query.isNotEmpty) {
      setState(() {
        filteredStaffList = staffList
            .where((staff) => staff.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  Future<void> saveDataToFirestore() async {
    // อัปเดตเวลาเป็นปัจจุบันก่อนบันทึก
    final currentDateTime = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(currentDateTime);
    _timeController.text = DateFormat('HH:mm').format(currentDateTime);

    /*// ตรวจสอบว่า date_checked, time_checked, equipment_status และ user_type ได้รับการกรอกหรือเลือก
    if (_dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        equipmentStatus.values.any((status) => status.isEmpty) ||
        userType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return; // หยุดการบันทึกข้อมูลถ้าข้อมูลไม่ครบ
    }*/

    CollectionReference formChecks =
        FirebaseFirestore.instance.collection('form_checks');
    String docId =
        '${_dateController.text}_${widget.tankId}_${_inspectorController.text}';

    // ตรวจสอบสถานะทั้งหมดของ equipmentStatus
    String newStatus = 'ตรวจสอบแล้ว'; // ค่าเริ่มต้นเป็น 'ตรวจสอบแล้ว'
    if (equipmentStatus.values.contains('ชำรุด')) {
      newStatus = 'ชำรุด'; // ถ้ามี "ชำรุด" ให้เปลี่ยนสถานะเป็น "ชำรุด"
    }

    try {
      // เตรียมข้อมูลที่ต้องการบันทึก
      Map<String, dynamic> formCheckData = {
        'date_checked': _dateController.text,
        'time_checked': _timeController.text, // บันทึกเวลา
        'inspector': selectedStaff ?? _inspectorController.text,
        'user_type': userType,
        'equipment_status': equipmentStatus,
        'remarks': _remarkController.text,
        'tank_id': widget.tankId,
      };

      // ถ้าเป็น CO2 ให้บันทึกข้อมูลในลักษณะพิเศษ
      if (fireTankType == 'CO2') {
        formCheckData['equipment_status'] = {
          'สภาพแรงดัน': equipmentStatus['สภาพแรงดัน'],
        };
        formCheckData['Weight_tank'] = _weightController.text; // น้ำหนัก
      }
      // ถ้าเป็น BF2000 หรือ ผงเคมี จะบันทึกเป็นค่าว่างใน Weight_tank
      else if (fireTankType == 'BF2000' || fireTankType == 'ผงเคมี') {
        formCheckData['equipment_status'] = {
          'มาตรวัด': equipmentStatus['มาตรวัด'],
          'สภาพผงเคมี': equipmentStatus['สภาพผงเคมี'],
        };
        formCheckData['Weight_tank'] = ''; // น้ำหนักจะเป็นค่าว่าง
      }

      // บันทึกข้อมูลลงใน collection 'form_checks'
      await formChecks.doc(docId).set(formCheckData).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
        );
      });

      // อัปเดตฟิลด์ 'status' ใน firetank_Collection
      CollectionReference firetankCollection =
          FirebaseFirestore.instance.collection('firetank_Collection');

      await firetankCollection
          .where('tank_id', isEqualTo: widget.tankId)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          // ถ้าพบ tank_id ที่ตรงกัน
          querySnapshot.docs.first.reference.update({
            'status': newStatus, // อัปเดตฟิลด์ 'status' เป็นค่าใหม่
          });
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize = 16; // กำหนดฟอนต์แบบคงที่
    final EdgeInsets padding = const EdgeInsets.symmetric(vertical: 8.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Form Check',
          style: TextStyle(fontSize: fontSize * 1.2),
        ),
        automaticallyImplyLeading: false, // ไม่แสดงลูกศรด้านซ้าย
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // แสดงภาพเมื่อได้ข้อมูลแล้ว
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('form_checks')
                          .where('tank_id', isEqualTo: widget.tankId)
                          .orderBy('date_checked', descending: true)
                          .orderBy('time_checked',
                              descending:
                                  true) // อ้างอิงจากเวลาเพื่อให้ได้ข้อมูลล่าสุด
                          .limit(1)
                          .snapshots(), // ใช้ snapshots() เพื่ออัปเดตข้อมูลแบบเรียลไทม์
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                            'วันที่ตรวจสอบล่าสุด: กำลังโหลด...',
                            style: TextStyle(fontSize: fontSize),
                          );
                        }

                        if (snapshot.hasError) {
                          print(
                              'เกิดข้อผิดพลาด: ${snapshot.error}'); // พิมพ์ข้อผิดพลาดที่เกิดขึ้นใน Console
                          return Text(
                            'วันที่ตรวจสอบล่าสุด: เกิดข้อผิดพลาด',
                            style: TextStyle(fontSize: fontSize),
                          );
                        }

                        if (snapshot.hasData &&
                            snapshot.data!.docs.isNotEmpty) {
                          final latestCheck = snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                          final dateString =
                              latestCheck['date_checked'] ?? 'ไม่มีข้อมูล';
                          final timeString = latestCheck['time_checked'] ?? '';

                          return Text(
                            'วันที่ตรวจสอบล่าสุด: $dateString เวลา: $timeString',
                            style: TextStyle(fontSize: fontSize),
                          );
                        } else {
                          return Text(
                            'วันที่ตรวจสอบล่าสุด: ไม่มีข้อมูล',
                            style: TextStyle(fontSize: fontSize),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('firetank_Collection')
                          .where('tank_id', isEqualTo: widget.tankId)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                            'สถานะล่าสุด: กำลังโหลด...',
                            style: TextStyle(fontSize: fontSize),
                          );
                        }

                        if (snapshot.hasError) {
                          return Text(
                            'สถานะล่าสุด: เกิดข้อผิดพลาด',
                            style: TextStyle(fontSize: fontSize),
                          );
                        }

                        if (snapshot.hasData &&
                            snapshot.data!.docs.isNotEmpty) {
                          final latestStatus = snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                          final status =
                              latestStatus['status'] ?? 'ไม่มีข้อมูล';

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'สถานะล่าสุด: ',
                                    style: TextStyle(fontSize: fontSize),
                                  ),
                                  Icon(
                                    Icons.circle,
                                    color: status == 'ชำรุด'
                                        ? Colors.red
                                        : status == 'ส่งซ่อม'
                                            ? Colors.orange
                                            : Colors
                                                .green, // สีส้มสำหรับสถานะ "ส่งซ่อม"
                                    size: 12,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    status,
                                    style: TextStyle(fontSize: fontSize),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FireTankDetailsPage(
                                        tankId: widget.tankId,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'ดูทั้งหมด',
                                  style: TextStyle(fontSize: fontSize),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Text(
                            'สถานะล่าสุด: ไม่มีข้อมูล',
                            style: TextStyle(fontSize: fontSize),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            if (imageBytes != null)
              Center(
                child: Container(
                  width: 150, // กำหนดความกว้าง
                  height: 150, // กำหนดความสูง
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0), // ทำมุมให้โค้ง
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3), // การย้ายเงา
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0), // ทำให้มุมโค้ง
                    child: Image.memory(
                      imageBytes!,
                      width: double.infinity, // ให้ขนาดภาพยืดตามที่ตั้งไว้
                      height: double.infinity, // ให้ขนาดภาพยืดตามที่ตั้งไว้
                      fit: BoxFit.cover, // ให้ภาพเต็มภายในกรอบ
                    ),
                  ),
                ),
              ),

            SizedBox(height: 20),
            Text(
              'Tank ID: ${widget.tankId}',
              style: TextStyle(fontSize: fontSize),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: 'วันที่ตรวจสอบ',
                        labelStyle: TextStyle(fontSize: fontSize),
                      ),
                      readOnly: true,
                      style: TextStyle(fontSize: fontSize),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'รายการตรวจสอบ',
                      style: TextStyle(fontSize: fontSize),
                    ),
                    // แสดงรายการตรวจสอบตามประเภท
                    Column(
                      children: equipmentStatus.keys.map((String key) {
                        return Padding(
                          padding: padding,
                          child: key == 'น้ำหนัก(กก.)'
                              ? TextField(
                                  controller: _weightController,
                                  decoration: InputDecoration(
                                    labelText: key,
                                    labelStyle: TextStyle(fontSize: fontSize),
                                  ),
                                  style: TextStyle(fontSize: fontSize),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      key,
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: equipmentStatus[key] == 'ปกติ',
                                          onChanged: (bool? value) {
                                            setState(() {
                                              equipmentStatus[key] =
                                                  value! ? 'ปกติ' : 'ชำรุด';
                                            });
                                          },
                                        ),
                                        Text(
                                          'ปกติ',
                                          style: TextStyle(fontSize: fontSize),
                                        ),
                                        Checkbox(
                                          value:
                                              equipmentStatus[key] == 'ชำรุด',
                                          onChanged: (bool? value) {
                                            setState(() {
                                              equipmentStatus[key] =
                                                  value! ? 'ชำรุด' : 'ปกติ';
                                            });
                                          },
                                        ),
                                        Text(
                                          'ไม่ปกติ',
                                          style: TextStyle(fontSize: fontSize),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _inspectorController,
                      onChanged: _filterStaff,
                      decoration: InputDecoration(
                        hintText: 'ผู้ตรวจสอบ',
                        hintStyle: TextStyle(fontSize: fontSize),
                      ),
                      style: TextStyle(fontSize: fontSize),
                    ),
                    if (filteredStaffList.isNotEmpty)
                      Container(
                        height: 100,
                        child: ListView.builder(
                          itemCount: filteredStaffList.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                filteredStaffList[index],
                                style: TextStyle(fontSize: fontSize),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedStaff = filteredStaffList[index];
                                  _inspectorController.text = selectedStaff!;
                                  filteredStaffList.clear();
                                });
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'ประเภทผู้ใช้',
                      style: TextStyle(fontSize: fontSize),
                    ),
                    DropdownButton<String>(
                      value: userType,
                      items: [
                        DropdownMenuItem(
                          value: 'ผู้ใช้ทั่วไป',
                          child: Text(
                            'ผู้ใช้ทั่วไป',
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ช่างเทคนิค',
                          child: Text(
                            'ช่างเทคนิค',
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          userType = newValue;
                        });
                      },
                      hint: Text(
                        'เลือกประเภทผู้ใช้',
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _remarkController,
                      decoration: InputDecoration(
                        labelText: 'หมายเหตุ',
                        labelStyle: TextStyle(fontSize: fontSize),
                      ),
                      style: TextStyle(fontSize: fontSize),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: saveDataToFirestore,
                      child: Text(
                        'บันทึก',
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // เพิ่มกล่องใหม่สำหรับ YouTube link
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การระงับอัคคีภัย',
                      style: TextStyle(fontSize: fontSize),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        // เปิดลิงค์ YouTube ในเบราว์เซอร์
                        launch('https://www.youtube.com/watch?v=JTUcb7CNP60');
                      },
                      child: Text(
                        'ดูวิดีโอการระงับอัคคีภัย',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
