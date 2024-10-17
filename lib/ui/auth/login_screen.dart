import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:learner/ui/auth/signup.dart';
import 'package:learner/widgets/round_button.dart';

import '../../screens/admin/admin_screen.dart'; // Import AdminSection
import '../../screens/student_screen.dart'; // Import StudentScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  Future<void> updateLoginStatus(String userId, bool isLoggedIn) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(userId).update({
      'status': isLoggedIn ? 'online' : 'offline',
      'lastLogin': isLoggedIn ? FieldValue.serverTimestamp() : null,
      'isLoggedIn': isLoggedIn,
    });
  }
  Future<void> logout() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update Firestore to set isLoggedIn to false
      await updateLoginStatus(user.uid, false);

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Login'),
          centerTitle: true,
          backgroundColor: Color(0xFF495E7D),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Color(0xFF495E7D)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Enter email';
                        }
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      keyboardType: TextInputType.text,
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: Icon(Icons.lock, color: Color(0xFF495E7D)),
                        fillColor: Colors.grey[200],
                        filled: true,
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Enter Password';
                        }
                        if (value.length < 6) {
                          return 'Password is too short';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50),
              RoundButton(
                loading: loading,
                title: 'Login',
                onTap: () async {
                  await logout();
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      loading = true;
                    });
                    try {
                      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                      // Get user data from Firestore
                      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
                      String role = userDoc.get('role');
                      await updateLoginStatus(userCredential.user!.uid, true);

                      // Navigate based on user role
                      if (role == 'admin') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => AdminSection()),
                        );

                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => UserScreen()),

                        );

                      }
                    } on FirebaseAuthException catch (e) {
                      setState(() {
                        loading = false;
                      });
                      String message;
                      switch (e.code) {
                        case 'user-not-found':
                          message = 'No user found for that email.';
                          break;
                        case 'wrong-password':
                          message = 'Incorrect password.';
                          break;
                        case 'invalid-email':
                          message = 'The email address is not valid.';
                          break;
                        default:
                          message = 'An error occurred: ${e.message}';
                      }
                      Fluttertoast.showToast(
                        msg: message,
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                  }
                },
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have an account? '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen()));
                    },
                    child: Text("Sign up", style: TextStyle(color: Color(0xFF495E7D))),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
