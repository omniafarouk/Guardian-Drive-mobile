import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';
import 'package:guardian_drive_mobile/widgets/custom_app_bar.dart';
import 'package:guardian_drive_mobile/widgets/side_bar_drawer.dart';
import 'package:guardian_drive_mobile/models/user.dart';
import 'package:guardian_drive_mobile/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  UserProfile? user;

  get SharedPreferences => null;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      //final prefs = await SharedPreferences.getInstance();

      //final token = prefs.getString('token');
      //final userId = prefs.getInt('userId');
      final token =
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjMsInJvbGUiOiJEUklWRVIiLCJpYXQiOjE3Nzg2MjgzNTEsImV4cCI6MTc3ODcxNDc1MX0.VBbQ38vF5STkLkS5Flv80NTEQA2U4NVMnbWofqba6k0";
      final userId = 3;
      /* if (token == null || userId == null)
       return;*/

      final fetchedUser = await UserService.getUserById();

      setState(() {
        user = fetchedUser;
      });
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B21),
      appBar: const CustomAppBar(title: "Profile"),
      drawer: const SideBarDrawer(),

      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : GradientBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(
                    color: const Color(0xEE323658),
                    width: 2,
                  ),
                ),
                child: const ClipOval(
                  child: Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Color(0xFF141931),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "User Profile",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    _buildField(label: "Email", value: user!.email),
                    _buildField(label: "Phone", value: user!.phone),
                    _buildField(label: "License", value: user!.license),
                    _buildField(
                      label: "Medications",
                      value: user!.medications.toString() ?? '',
                    ),
                    _buildField(
                      label: "Medical Conditions",
                      value: user!.medicalConditions.toString() ?? '',
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            label: "Heart Rate",
                            value: user?.avgHeartRate.toString() ?? '',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildField(
                            label: "Temperature",
                            value: user?.avgTemperature.toString() ?? '',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            label: "SpO2",
                            value: user?.avgSpo2.toString() ?? '',
                          ),
                        ),
                        const SizedBox(width: 20),
                        /*Expanded(
                                child: _buildField(
                                  label: "Blood Type",
                                  //value: user!.bloodType,
                                ),
                              ),*/
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
        ),
        const SizedBox(height: 6),

        TextFormField(
          initialValue: value,
          readOnly: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xEE323658),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}