import 'package:flutter/material.dart';
import 'login.dart'; // Importing the file containing LoginPage class

void main() {
  runApp(
    MaterialApp(
      initialRoute: 'login',
      debugShowCheckedModeBanner: false,
      routes: {'login': (context) => LoginPage()}
    ),
  );
}
