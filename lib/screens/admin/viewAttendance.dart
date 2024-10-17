import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learner/screens/admin/admin_screen.dart';

import '../../ui/utils/utils.dart';

class ViewAttendance extends StatefulWidget {
  const ViewAttendance({super.key});

  @override
  State<ViewAttendance> createState() => _ViewAttendanceState();
}

class _ViewAttendanceState extends State<ViewAttendance> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<Map<String, List<Map<String, dynamic>>>> _groupedAttendanceData;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String? selectedDate; // To store the selected date for viewing detailed attendance

  @override
  void initState() {
    super.initState();
    _groupedAttendanceData = fetchGroupedAttendanceData();
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchGroupedAttendanceData() async {
    try {
      QuerySnapshot userSnapshot = await _firestore.collection('users').get();
      Map<String, List<Map<String, dynamic>>> attendanceByDate = {};

      for (var userDoc in userSnapshot.docs) {
        var userId = userDoc.id;
        var attendanceSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('attendance')
            .get();

        for (var attendanceDoc in attendanceSnapshot.docs) {
          var attendanceData = attendanceDoc.data();
          String date = formatDate(attendanceData['date']); // Format the date

          if (!attendanceByDate.containsKey(date)) {
            attendanceByDate[date] = [];
          }

          attendanceByDate[date]!.add({
            'userId': userId,
            'name': attendanceData['name'],
            'status': attendanceData['status'],
            'docId': attendanceDoc.id, // Store the document ID for updating
          });
        }
      }

      return attendanceByDate;
    } catch (e) {
      print('Error fetching attendance data: $e');
      // Return an empty map in case of error
      return {};
    }
  }

  Future<void> updateStatus(String userId, String date, String docId, String newStatus) async {
    // Same as before
  }
  String formatDate(dynamic date) {
    if (date is Timestamp) {
      DateTime parsedDate = date.toDate();
      return DateFormat('dd MMM yyyy').format(parsedDate); // Formats to "day month year"
    } else {
      return "Invalid Date";
    }}
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedDate != null) {
          setState(() {
            selectedDate = null;
          });
          return false; // Prevents popping the current screen
        } else {
          // Navigate back to AdminSection if no date is selected
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminSection()),
          );
          return false; // Prevents default back button behavior
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: true,
          title: const Text('Admin Attendance View'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminSection()),
              );
            },
          ),
        ),
        body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _groupedAttendanceData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No attendance data available.'));
            }

            var attendanceByDate = snapshot.data!;

            if (selectedDate != null) {
              var attendanceForDate = attendanceByDate[selectedDate!] ?? [];

              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedDate = null;
                      });
                    },
                    child: const Text('Back to dates'),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: attendanceForDate.length,
                      itemBuilder: (context, index) {
                        var item = attendanceForDate[index];
                        return ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item['name']}',
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (item['userId'] != null && selectedDate != null && item['docId'] != null) {
                                    updateStatus(item['userId']!, selectedDate!, item['docId']!, value);
                                  } else {
                                    utils().toastMessage('Error: Missing userId, selectedDate, or docId');
                                  }
                                },
                                itemBuilder: (context) {
                                  return ['Present', 'Absent', 'Leave'].map((status) {
                                    return PopupMenuItem<String>(
                                      value: status,
                                      child: Text(status),
                                    );
                                  }).toList();
                                },
                                child: Text(
                                  '${item['status'] ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                    color: item['status'] == 'Present' ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              itemCount: attendanceByDate.keys.length,
              itemBuilder: (context, index) {
                String date = attendanceByDate.keys.elementAt(index);
                return ListTile(
                  title: Text(
                    date,
                    style: TextStyle(
                      fontSize: selectedDate == date ? 24.0 : 18.0,
                      fontWeight: selectedDate == date ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  tileColor: selectedDate == date ? Colors.blue.shade100 : null,
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
