import 'package:flutter/material.dart';
//import 'package:qr_flutter/qr_flutter.dart';
import 'form_check.dart'; // นำเข้าไฟล์ FormCheckPage

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Page'),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'เมนู',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('หน้าแรก'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/user');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: const MyHomePage(
          title: 'หน้าแรก'), // เรียก MyHomePage ใน body ของ UserPage
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> tankIds = ["fire001", "fire002", "fire003", "fire004"];
  String? selectedTank; // เก็บถังที่เลือก

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'เมนู',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('หน้าแรก'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/user');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'เลือกถัง',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              hint: const Text("เลือกถัง"),
              value: selectedTank,
              items: tankIds.map((String tankId) {
                int tankNumber =
                    int.parse(tankId.replaceAll(RegExp(r'\D'), ''));
                return DropdownMenuItem<String>(
                  value: tankId,
                  child: Text("ถัง $tankNumber"),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedTank = newValue;
                });
                // เมื่อเลือกถังแล้วเปิดหน้า FormCheckPage พร้อม tankId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormCheckPage(tankId: newValue!),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FireTankDetailsPage extends StatelessWidget {
  final String tankId;

  const FireTankDetailsPage({Key? key, required this.tankId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FireTankDetails $tankId'),
      ),
      body: Center(
        child: Text('FireTankDetailsID: $tankId'),
      ),
    );
  }
}
