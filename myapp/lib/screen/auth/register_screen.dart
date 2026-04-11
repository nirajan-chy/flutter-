import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:myapp/screen/auth/login_screen.dart';
import 'package:myapp/core/services/auth_service.dart';

class registerPage extends StatefulWidget {
  const registerPage({super.key});

  @override
  State<registerPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<registerPage> {
  final AuthService _authService = AuthService();
  late TextEditingController fullnameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fullnameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
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
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final name = fullnameController.text.trim();
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (name.isEmpty || email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Name, email and password are required',
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _isSubmitting = true;
                      });

                      try {
                        final response = await _authService.register(
                          name: name,
                          email: email,
                          password: password,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              response['message']?.toString() ??
                                  'Signup successful',
                            ),
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const loginPage(),
                          ),
                        );
                      } on DioException catch (e) {
                        if (!mounted) return;
                        final message = e.response?.data is Map
                            ? (e.response?.data['message']?.toString() ??
                                  'Signup failed')
                            : 'Signup failed';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSubmitting = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text("signup"),
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
