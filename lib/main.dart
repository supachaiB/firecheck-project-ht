import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// นำเข้าหน้าต่าง ๆ ที่ต้องใช้
import 'admin/inspection_history.dart';
import 'admin/dashboard.dart';
import 'admin/fire_tank_status.dart';
import 'user/form_check.dart';
import 'admin/Fire_tank_management.dart';
import 'admin/buildings_management.dart';
import 'admin/fire_tank_types.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ใช้ PathUrlStrategy เพื่อให้ URL ไม่มีเครื่องหมาย #
  setUrlStrategy(PathUrlStrategy());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firecheck System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/', // กำหนดเส้นทางเริ่มต้นเป็นหน้า Dashboard
      onGenerateRoute: (RouteSettings settings) {
        final uri = Uri.parse(settings.name ?? '/');

        // ตรวจสอบเส้นทาง (Route) และ query parameters
        if (uri.path == '/user') {
          final tankId = uri.queryParameters['tankId'];
          if (tankId == null) {
            // กรณีไม่มี tankId ส่งกลับข้อความแสดงข้อผิดพลาด
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('ข้อผิดพลาด')),
                body: const Center(
                  child: Text('Tank ID ไม่ถูกต้องหรือไม่ได้ระบุ.'),
                ),
              ),
            );
          }
          // ส่ง tankId ไปยังหน้า FormCheckPage
          return MaterialPageRoute(
            builder: (context) => FormCheckPage(tankId: tankId),
          );
        }

        // จัดการเส้นทางอื่น ๆ
        switch (uri.path) {
          case '/firetankstatus':
            return MaterialPageRoute(
                builder: (context) => FireTankStatusPage());
          case '/inspectionhistory':
            return MaterialPageRoute(
                builder: (context) => InspectionHistoryPage());
          case '/fire_tank_management':
            return MaterialPageRoute(
                builder: (context) => FireTankManagementPage());
          case '/BuildingManagement':
            return MaterialPageRoute(
                builder: (context) => BuildingManagementScreen());
          case '/FireTankTypes':
            return MaterialPageRoute(builder: (context) => FireTankTypes());
          case '/FireTankStatusPage':
            return MaterialPageRoute(
                builder: (context) => FireTankStatusPage());
          default:
            // เส้นทางเริ่มต้น
            return MaterialPageRoute(
                builder: (context) => const DashboardPage());
        }
      },
    );
  }
}
