import 'package:flutter/material.dart';
import 'package:myapp/screen/auth/login_screen.dart';

class registerPage extends StatelessWidget {
  const registerPage({super.key});

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
              decoration: InputDecoration(
                labelText: "Fullname",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            TextField(
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            TextField(
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 45),
            ElevatedButton(
              onPressed: () {},
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
