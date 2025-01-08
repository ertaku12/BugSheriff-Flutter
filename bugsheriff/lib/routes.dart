import 'package:flutter/material.dart';
import 'package:bugsheriff/screens/login_screen.dart';
import 'package:bugsheriff/screens/signup_screen.dart';
import 'package:bugsheriff/screens/forgot_password_screen.dart';
import 'package:bugsheriff/screens/profile_screen.dart';
import 'package:bugsheriff/screens/home_screen.dart';
import 'package:bugsheriff/screens/programs_screen.dart';
import 'package:bugsheriff/screens/reports_screen.dart';

import 'package:bugsheriff/ascreens/ahome_screen.dart';
import 'package:bugsheriff/ascreens/aprofile_screen.dart';
import 'package:bugsheriff/ascreens/aprograms_screen.dart';
import 'package:bugsheriff/ascreens/areports_screen.dart';



// Bu fonksiyon rotaları döner
Map<String, WidgetBuilder> getApplicationRoutes() {
  return <String, WidgetBuilder>{
    '/login': (BuildContext context) => LoginPage(),
    '/signup': (BuildContext context) => SignupPage(),
    '/forgot-password': (BuildContext context) => ForgotPasswordPage(),
    '/profile': (BuildContext context) => ProfilePage(),
    '/programs': (BuildContext context) => ProgramsPage(),
    '/reports': (BuildContext context) => ReportsPage(),
    '/home': (BuildContext context) => HomePage(),

    '/ahome': (BuildContext context) => aHomePage(),
    '/aprofile': (BuildContext context) => aProfilePage(),
    '/aprograms': (BuildContext context) => aProgramsPage(),
    '/areports': (BuildContext context) => aReportsPage(),

    
  };
  
}
