import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/services/medical_info_service.dart';
import 'package:guardian_drive_mobile/services/storage_service.dart';

class SideBarDrawer extends StatefulWidget {
  const SideBarDrawer({super.key});

  @override
  State<SideBarDrawer> createState() => _SideBarDrawerState();
}

class _SideBarDrawerState extends State<SideBarDrawer> {
  String? imageUrl;
  String? driverName; // start as null, fill it after async loads

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFF393939),
      child: ListView(
        padding: EdgeInsets.zero, // removes default top padding
        children: [
          SizedBox(
            height: 170,
            child: DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF141931)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        driverName ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        // row personal information navigation
                        children: [
                          Text(
                            'Personal Info',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 14,
                            ),
                            onPressed: () {
                              Navigator.pop(context); // close the drawer first
                              Navigator.pushNamed(context, '/profile');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEDF4FA),
                    radius: 30,
                    child: ClipOval(
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              // shows default icon if image fails to load
                              errorBuilder: (context, error, stackTrace) {
                                return _defaultAvatar(); // ← case 1: URL exists but FAILED to load
                              },
                              // shows loading spinner while image loads
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.black,
                                    );
                                  },
                            )
                          : _defaultAvatar(), // ← case 2: URL is null, show default avatar
                    ),
                  ),
                ],
              ),
            ),
          ),
          // menu items
          ListTile(
            leading: const Icon(Icons.home_outlined, color: Colors.white),
            title: const Text('Home', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // closes the drawer
              Navigator.pushReplacementNamed(context, '/home');
              // pushReplacementNamed is used to prevent stacking, therefore when user presses Back, the app itself exits
              // pushNamed is used to stack multiple pages, so when user presses back button, it goes back to the previous page instead of exiting the app
            },
          ),
          ListTile(
            leading: const Icon(Icons.car_crash_outlined, color: Colors.white),
            title: const Text('Trips', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/trips');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.warning_amber_outlined,
              color: Colors.white,
            ),
            title: const Text('Alerts', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/alerts');
            },
          ),
          /*      <--- settings menu commented
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.white),
            title: const Text(
              'Settings',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),*/
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Icon _defaultAvatar() {
    return const Icon(Icons.person_outline, size: 40, color: Color(0xFF141931));
  }

  Future<void> _loadUser() async {
    final name = await StorageService.getUsername();
    setState(() {
      driverName = name; // triggers rebuild once value is loaded
    });
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    // this is used because below Navigator.pushNamedAndRemove(context, '/login', (route) => false) and context navigation here causes problems with async and await functionalities
    // Next,Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Navigate to login screen and clear stack
      await StorageService.clearSession();
      MedicalInfoService().clear(); // clear cached medical-info in app
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
