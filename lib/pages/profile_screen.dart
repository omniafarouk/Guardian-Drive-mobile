import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/widgets/background.dart';
import 'package:guardian_drive_mobile/widgets/custom_app_bar.dart';
import 'package:guardian_drive_mobile/widgets/side_bar_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String? imageUrl = null;
  // 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRXu0L3tItmhTVzyOr0PUJFluxXK8sJi41xvw&s'; // Example image URL, can be null for default avatar
  String name = 'Omnia Farouk';
  String email = 'omnia@example.com';
  String phone = '+1234567890';
  String license = 'D1234567';
  String allergies = 'None';
  String medicalConditions = 'None';
  int avgHeartRate = 72;
  int avgTemperature = 98;
  int avgBloodPressure = 120;
  String bloodType = 'O+';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF060B21),
      appBar: CustomAppBar(title: "Profile"),
      drawer:
          const SideBarDrawer(), // add sidebar, but note: that would remove the back button
      body: GradientBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 40, 0, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xEE323658), // ← stroke color
                              width: 2, // ← stroke thickness
                            ),
                          ),
                          child: ClipOval(
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    // shows default icon if image fails to load
                                    errorBuilder: (context, error, stackTrace) {
                                      return _defaultAvatar(); // ← case 1: URL exists but FAILED to load
                                    },
                                    // shows loading spinner while image loads
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white,
                                          );
                                        },
                                  )
                                : _defaultAvatar(), // ← case 2: URL is null, show default avatar
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xEE323658), // ← badge background
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Colors.white, // ← white ring around badge
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              iconSize: 18,
                              icon: const Icon(Icons.edit_outlined, size: 25),
                              color: Colors.white,
                              onPressed: () {
                                print("Edit avatar pressed!");
                                // TODO: open image picker <--------------
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade200,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          _buildField(label: "Email", value: email),
                          _buildField(label: "Phone", value: phone),
                          _buildField(label: "License", value: license),
                          _buildField(label: "Allergies", value: allergies),
                          _buildField(
                            label: "Medical Conditions",
                            value: medicalConditions,
                          ),
                          Row(
                            children: [
                              Expanded(
                                /*Without Expanded, each _buildField tries to be as wide as it wants inside the Row — Flutter can't resolve that and throws an overflow exception.
                                Expanded tells each child "take exactly your fair share of the available width" — so two Expanded widgets in a Row each get exactly 50%.*/
                                child: _buildField(
                                  label: "Average Heart Rate",
                                  value: avgHeartRate.toString(),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildField(
                                  label: "Average Temperature",
                                  value: avgTemperature.toString(),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  label: "Average Blood Pressure",
                                  value: avgBloodPressure.toString(),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildField(
                                  label: "Blood Type",
                                  value: bloodType,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Icon _defaultAvatar() {
    return const Icon(Icons.person_outline, size: 80, color: Color(0xFF141931));
  }

  Widget _buildField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade200, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          readOnly: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            fillColor: Color(0xEE323658),
            filled: true,
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
