import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learner/screens/ViewAttendance.dart';
import 'package:learner/ui/utils/utils.dart';
import 'package:learner/widgets/round_button.dart';
import '../ui/auth/login_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final auth = FirebaseAuth.instance;
  User? user;
  File? _image;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    checkAndUpdateAttendance();
    _loadProfilePicture();
  }

  Future<void> checkAndUpdateAttendance() async {
    if (user == null) {
      print("No user is currently signed in.");
      return;
    }

    var userId = user!.uid;
    var now = DateTime.now();
    var today = DateTime(now.year, now.month, now.day);
    var yesterday = today.subtract(Duration(days: 1));

    // Retrieve the account creation date
    var creationDate = user!.metadata.creationTime!;

    // Check if the account was created before yesterday
    if (creationDate.isBefore(yesterday)) {
      var attendanceRef = FirebaseFirestore.instance
          .collection('attendance')
          .doc(userId)
          .collection('days')
          .doc(yesterday.toIso8601String());

      var docSnapshot = await attendanceRef.get();

      if (!docSnapshot.exists) {
        await attendanceRef.set({
          'date': yesterday,
          'status': 'Absent',
        });
        print("Attendance marked as Absent for $yesterday");
      }
    } else {
      print("Account was created after $yesterday; no attendance marked.");
    }
  }

  Future<void> _loadProfilePicture() async {
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref('user_images/${user!.uid}/profilePictureUrl');

    try {
      final snapshot = await ref.get();

      if (snapshot.exists) {
        setState(() {
          _imageUrl = snapshot.value as String;
        });
      } else {
        setState(() {
          _imageUrl = null; // Or use a placeholder image URL
        });
      }
    } catch (e) {
      print('Error loading profile picture: $e');
      setState(() {
        _imageUrl = null; // Or use a placeholder image URL
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await uploadProfilePicture();
    }
  }

  Future<void> uploadProfilePicture() async {
    if (user == null) {
      utils().toastMessage("User not authenticated");
      return;
    }

    if (_image == null) {
      utils().toastMessage("No image selected");
      return;
    }

    try {
      final ref = firebase_storage.FirebaseStorage.instance.ref('/user_profile/${user!.uid}.jpg');
      final uploadTask = ref.putFile(_image!);

      await uploadTask.whenComplete(() async {
        final newURL = await ref.getDownloadURL();

        await FirebaseDatabase.instance.ref('user_images/${user!.uid}').set({
          'profilePictureUrl': newURL,
        });

        setState(() {
          _imageUrl = newURL;
        });

        utils().toastMessage('Profile picture updated successfully');
      });

    } on FirebaseException catch (e) {
      utils().toastMessage('Upload failed: ${e.message}');
    } catch (e) {
      utils().toastMessage('An error occurred: $e');
    }
  }

  Future<void> updateLoginStatus(String userId, bool isLoggedIn) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(userId).update({
      'status': isLoggedIn ? 'online' : 'offline',
      'lastLogin': isLoggedIn ? FieldValue.serverTimestamp() : null,
      'isLoggedIn': isLoggedIn,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4C9F70),
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("User Screen", style: TextStyle(color: Colors.green[1400])),
        actions: [
          IconButton(
            onPressed: () async {
              if (user != null) {
                // Update Firestore to set isLoggedIn to false
                await updateLoginStatus(user!.uid, false);
              }
              try {
                await auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              } catch (error) {
                utils().toastMessage(error.toString());
              }
            },
            icon: Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 100,
                backgroundImage: _imageUrl != null
                    ? NetworkImage(_imageUrl!)
                    : AssetImage('assets/profile_placeholder.png') as ImageProvider,
              ),
              SizedBox(height: 10),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  margin: EdgeInsets.all(15),
                  height: 40,
                  width: 230,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xFF4C9F70),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Update Profile Picture',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: RoundButton(
                  onTap: () async {
                    if (user == null) return;

                    var userName = user?.displayName ?? 'Anonymous';
                    var userId = user?.uid;
                    var now = DateTime.now();
                    var today = DateTime(now.year, now.month, now.day);

                    var leaveRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('leave_requests')
                        .doc(today.toIso8601String());

                    var attendanceRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('attendance')
                        .doc(today.toIso8601String());

                    var leaveDocSnapshot = await leaveRef.get();
                    var attendanceDocSnapshot = await attendanceRef.get();

                    if (leaveDocSnapshot.exists) {
                      utils().toastMessage("Leave request already sent; cannot mark attendance");
                      return;
                    }

                    if (attendanceDocSnapshot.exists) {
                      utils().toastMessage("Attendance already marked for today");
                      return;
                    }

                    await attendanceRef.set({
                      'date': today,
                      'status': 'Present',
                      'name': userName,
                    });

                    utils().toastMessage("Attendance marked as Present for today");
                  },
                  title: 'Mark Attendance',
                ),
              ),
              SizedBox(height: 35),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: RoundButton(
                  onTap: () async {
                    if (user == null) return;

                    var userName = user?.displayName ?? 'Anonymous';
                    var userId = user?.uid;
                    var now = DateTime.now();
                    var today = DateTime(now.year, now.month, now.day);

                    var leaveRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('leave_requests')
                        .doc(today.toIso8601String());

                    var attendanceRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('attendance')
                        .doc(today.toIso8601String());

                    var leaveRequestSnapshot = await leaveRef.get();
                    var attendanceDocSnapshot = await attendanceRef.get();

                    if (leaveRequestSnapshot.exists) {
                      utils().toastMessage("Leave request has already been sent for today");
                      return;
                    }

                    if (attendanceDocSnapshot.exists) {
                      utils().toastMessage("Attendance has already been marked for today");
                      return;
                    }

                    await leaveRef.set({
                      'date': today,
                      'reason': 'Sick Leave',
                      'status': 'Pending',
                      'name': userName,
                    });

                    await attendanceRef.set({
                      'date': today,
                      'status': 'Pending',
                      'name': userName,
                    });

                    utils().toastMessage("Leave request sent successfully");
                  },
                  title: 'Request Leave',
                ),
              ),
              SizedBox(height: 35),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: RoundButton(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceScreen()));
                  },
                  title: 'View Attendance',
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.all(12.0),
              //   child: RoundButton(
              //     onTap: () {
              //       Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceScreen()));
              //     },
              //     title: 'Online Students',
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
