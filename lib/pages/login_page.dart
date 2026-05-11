import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/role.dart';
import 'package:guardian_drive_mobile/services/auth_service.dart';
import 'package:guardian_drive_mobile/services/storage_service.dart';
import 'forget_pass.dart'; // make sure this file exists
import 'dashboard.dart'; // make sure this file exists

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage()));
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool isPressed = false;

  Future<void> _handleLogin() async {
    // Validates all form fields at once
    if (!_formKey.currentState!.validate()) return;

    try {
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // result has login response

      // ToDo : ensure if role not driver , don't enter
      if (result.role != Role.driver.toString()) {
        throw Exception("Invalid User");
      }

      // Save token + role + name securely
      await StorageService.saveSession(
        token: result.token,
        id: result.id,
        username: '${result.fName} ${result.lName}',
      );

      if (!mounted) return; // widget might be gone after await

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Dashboard()),
      );
      // will remove login from stack completely
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 1, 21, 51),
              Color.fromARGB(255, 7, 17, 26),
            ],
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: screenWidth * 0.85,

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔹 LOGO
                    Image.asset("assets/logo.png", height: screenHeight * 0.25),

                    SizedBox(height: screenHeight * 0.03),

                    Text(
                      "GUARDIAN DRIVE",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.06),

                    // 🔹 EMAIL
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Email",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    SizedBox(height: 5),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Enter email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter email";
                        }

                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );

                        if (!emailRegex.hasMatch(value)) {
                          return "Enter a valid email";
                        }

                        return null;
                      },
                    ),

                    SizedBox(height: screenHeight * 0.025),

                    // 🔹 PASSWORD
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Password",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    SizedBox(height: 5),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Enter password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter password";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // 🔹 LOGIN BUTTON
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPressed
                            ? Colors.transparent
                            : Color(0xFF124169),

                        side: isPressed
                            ? BorderSide(color: Colors.white, width: 2)
                            : BorderSide.none,

                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.25,
                          vertical: 15,
                        ),
                      ),

                      onPressed: () {
                        setState(() {
                          isPressed = true;
                        });
                        _handleLogin();
                      },

                      child: Text(
                        "Login",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // 🔹 FORGOT PASSWORD
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ForgetPass()),
                        );
                      },
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
