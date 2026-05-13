//import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:guardian_drive_mobile/pages/reset_pass.dart';
import 'package:guardian_drive_mobile/services/auth_service.dart';

class ForgetPass extends StatefulWidget {
  @override
  _ForgetPassState createState() => _ForgetPassState();
}

class _ForgetPassState extends State<ForgetPass> {
  final _formKey = GlobalKey<FormState>();
  bool isPressed = false;
  final TextEditingController emailController = TextEditingController();
  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text("Forgot Password", style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 1, 21, 51),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
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
                child: Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Column(
                    children: [
                      //SizedBox(height: 150),
                      Text(
                        "We will send you an email to reset your password",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 30),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Email",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 5),
                      SizedBox(
                        child: TextFormField(
                          controller: emailController,

                          keyboardType: TextInputType.emailAddress,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Enter your email",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your email";
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
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPressed
                              ? Colors.transparent
                              : Color(0xFF124169),

                          side: isPressed
                              ? BorderSide(color: Colors.white, width: 2)
                              : BorderSide.none,
                          padding: EdgeInsets.symmetric(
                            horizontal: 100,
                            vertical: 15,
                          ),
                        ),
                        onPressed: () async {
                          setState(() {
                            isPressed = true;
                          });
                          if (_formKey.currentState!.validate()) {
                            //print(emailController.text);
                            setState(() {
                              isPressed = false;
                            });
                            try {
                              final msg = await AuthService.forgetPass(
                                emailController.text.trim(),
                              );

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(msg)));
                              print(emailController.text);

                              /* Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ResetPass(),
                                ),
                              );*/
                            } catch (error) {
                              setState(() {
                                isPressed = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            } finally {
                              setState(() {
                                isPressed = false;
                              });
                            }
                          }
                        },
                        child: Text(
                          "Send",
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
      ),
    );
  }
}
