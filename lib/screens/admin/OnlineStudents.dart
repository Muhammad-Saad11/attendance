import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_screen.dart'; // Import your AdminSection here

class OnlineStudentsScreen extends StatefulWidget {
  @override
  _OnlineStudentsScreenState createState() => _OnlineStudentsScreenState();
}

class _OnlineStudentsScreenState extends State<OnlineStudentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Student>> _fetchOnlineStudents() async {
    try {
      // Firestore query to fetch online students
      final snapshot = await _firestore
          .collection('users')
          .where('status', isEqualTo: 'online')
          .get();

      // Map the documents and create a Student instance for each one
      final students = snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();

      // Filter out students with the role 'admin' after fetching
      return students.where((student) => student.role != 'admin').toList();
    } catch (e) {
      print("Error fetching online students: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate back to AdminSection when back button is pressed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminSection()),
        );
        return false; // Prevents the default back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Online Students"),
          backgroundColor: Color(0xFF4C9F70),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate back to AdminSection when back button is pressed
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminSection()),
              );
            },
          ),
        ),
        body: FutureBuilder<List<Student>>(
          future: _fetchOnlineStudents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("No online students found"));
            } else {
              final students = snapshot.data!;
              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color: Colors.white, // Set a clear background color
                      elevation: 4, // Increase elevation for more noticeable effect
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0), // More pronounced rounding of edges
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0), // Add more padding inside the card
                        leading: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.blueGrey,
                        ),
                        title: Text(
                          student.name,
                          style: TextStyle(
                            fontSize: 20, // Slightly larger font for the name
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          student.status,
                          style: TextStyle(
                            fontSize: 16,
                            color: student.status == 'online' ? Colors.green : Colors.red, // Color based on status
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class Student {
  final String id;
  final String name;
  final String status;
  final String role; // Added role to filter out admins

  Student({
    required this.id,
    required this.name,
    required this.status,
    required this.role, // Role is now passed as part of the Student model
  });

  // Factory method to create a Student from Firestore DocumentSnapshot
  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Student(
      id: doc.id, // Assuming userId is the document ID
      name: data['name'] ?? 'Unknown', // Access the name field from the document
      status: data['status'] ?? 'offline', // Access the status field from the document
      role: data['role'] ?? 'student', // Access the role field from the document
    );
  }
}
