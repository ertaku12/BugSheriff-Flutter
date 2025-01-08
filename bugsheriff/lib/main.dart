import 'package:flutter/material.dart';
import 'routes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bugsheriff',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/home',  // Başlangıç rotası
      routes: getApplicationRoutes(),  // Rotayı burada tanımlıyoruz
    );
    
  }
}
