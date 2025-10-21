import 'package:flutter/material.dart';
import 'screens/appointment_home.dart';
import 'screens/ProfilePage.dart';
import 'screens/RegisterPage.dart';
import 'screens/LoginPage.dart';

class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    home: (context) => const AppointmentHomePage(),
    profile: (context) => const ProfilePage(),
  };
}
