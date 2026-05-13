import 'package:flutter/material.dart';

class OngoingTripPage extends StatefulWidget {
  const OngoingTripPage({super.key});

  @override
  State<OngoingTripPage> createState() => _OnGoingTripState();
}

class _OnGoingTripState extends State<OngoingTripPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("OnGoing Trip", style: TextStyle(color: Colors.white)),
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
        child: Column(
          children: [
            Text("ONGOING TRIP"),
            ElevatedButton(
              onPressed: _showConfirmSOSDialog, // button calls the method
              child: Text("Show Dialog"),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmSOSDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(child: const Text("Request Help ?")),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.green, // button background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'NO',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade200,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red, // button background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'YES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade200,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showFirstAidGuidanceDialog();
              // TODO : trigger SOS Alert + create a loading widget or something till alert is triggered
            },
          ),
        ],
      ),
    );
  }

  void _showFirstAidGuidanceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(child: Text('HELP IS ON THE WAY!')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          // shrinks to content height, doesn't fill screen
          children: [
            Text(
              //'Emergency services have been notified '
              //'and are on their way to your location.'
              'Please follow the following instructions for your safety',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              // TODO : put first aid guidance instructions here
              'ETA: 10 minutes',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 1, 21, 51),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
