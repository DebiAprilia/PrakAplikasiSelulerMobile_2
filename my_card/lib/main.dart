import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.teal,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 100,
                color: Colors.white,
                child: Text("Container 1"),
              ),
              SizedBox(width: 20),
              Container(
                height: 100,
                color: Colors.red,
                child: Text("Container 2"),
              ),
              Container(
                height: 100,
                color: Colors.blue,
                child: Text("Container 3"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
