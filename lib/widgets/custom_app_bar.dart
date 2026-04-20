import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const CustomAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading:
          false, // disables Flutter's default back/drawer button
      iconTheme: IconThemeData(color: Colors.white, size: 45),
      backgroundColor: Color.fromARGB(255, 1, 21, 51),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.menu, color: Colors.white),
        onPressed: () => Scaffold.of(
          // NOTE THIS WILL THROW ERROR IF BUILD WASN'T Scaffold -
          // otherwise the logic must be handled page by page
          // by adding a contoller that acts as variable to open the drawer on click
          context,
        ).openDrawer(), // ADDED to open drawer on pressed (only for Scaffold Screens)
      ),
      actions: [
        Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: Image.asset("assets/logo.png", height: 50),
        ),
      ],
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(6),
        child: Container(height: 1, color: Color(0xFF393939)),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 6);
}
