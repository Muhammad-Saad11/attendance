import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this for date formatting
import 'package:learner/screens/admin/OnlineStudents.dart';
import 'package:learner/screens/admin/viewAttendance.dart';
import 'package:learner/widgets/round_button.dart';

import '../../ui/auth/login_screen.dart';
import '../../ui/utils/utils.dart';

class AdminSection extends StatefulWidget {
  @override
  _AdminSectionState createState() => _AdminSectionState();
}

class _AdminSectionState extends State<AdminSection> {
  final FirebaseAuth auth = FirebaseAuth.instance;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Admin Section'),
        actions: [
          IconButton(
            onPressed: () {
              auth.signOut().then((value) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }).onError((error, stackTrace) {
                utils().toastMessage(error.toString());
              });
            },
            icon: Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 30,),
          Center(

            child:

            RoundButton(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ViewAttendance()),
                );
              },
              title: 'View Attendance',
            ),


          ),
          SizedBox(height: 30,),
          RoundButton(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => OnlineStudentsScreen()),
              );
            },
            title: 'Online Students',
          ),

        ],
      ),
    );
  }
}
