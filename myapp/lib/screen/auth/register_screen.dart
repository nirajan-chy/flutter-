import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myapp/screen/auth/login_screen.dart';

class registerPage extends StatefulWidget {
  const registerPage({super.key});

  @override
  State<registerPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<registerPage> {
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:5000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  late TextEditingController fullnameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    dio.options.baseUrl = _baseUrl;
    fullnameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  void fetchUser() async {
    final response = await dio.get('user');
    print(response.data);
  }

  @override
  void dispose() {
    fullnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 120),
            Text(
              "Create your account",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text("Get Started free", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 30),
            TextField(
              controller: fullnameController,
              decoration: InputDecoration(
                labelText: "Fullname",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 45),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await dio.post(
                    '/auth/register',
                    data: {
                      'name': fullnameController.text.trim(),
                      'email': emailController.text.trim(),
                      'password': passwordController.text.trim(),
                    },
                  );

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response.data['message'] ?? 'Signup successful',
                      ),
                    ),
                  );
                } on DioException catch (e) {
                  print("Error message : ${e.message}");
                  print("Error message : ${e.response?.statusCode}");
                  print("Error message : ${e.response?.data}");

                  if (!mounted) return;
                  final message = e.response?.data is Map
                      ? (e.response?.data['message'] ?? 'Signup failed')
                      : 'Signup failed';
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message.toString())));
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("signup"),
            ),
            SizedBox(height: 30),
            Row(
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const loginPage(),
                      ),
                    );
                  },
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ],
        ),  
      ),
    );
  }
}
