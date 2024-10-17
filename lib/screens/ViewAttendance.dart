import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var userId = FirebaseAuth.instance.currentUser!.uid;
    var readableDate = 'N/A';


    return Scaffold(
      appBar: AppBar(
        title: Text('View Attendance'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('attendance')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Show loading spinner
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Show error message
          }

          var documents = snapshot.data?.docs ?? [];
          if (documents.isEmpty) {
            return Center(child: Text('No attendance records found')); // Show no records message
          }

          return ListView.builder(

            padding: EdgeInsets.all(8.0),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              var record = documents[index].data() as Map<String, dynamic>;
              if (record['date'] is Timestamp) {
                var timestamp = record['date'] as Timestamp;
                var date = timestamp.toDate(); // Convert Timestamp to DateTime
                readableDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              } else if (record['readableDate'] is String) {
                readableDate = record['readableDate'];
              }
              var status = record['status'] ?? 'N/A';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 4,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16.0),
                  title: Text(
                    "Date: $readableDate",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Status: $status"),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Optionally trigger a manual refresh if needed
        },
        child: Icon(Icons.refresh),
        tooltip: 'Refresh Attendance',
      ),
    );
  }
}
