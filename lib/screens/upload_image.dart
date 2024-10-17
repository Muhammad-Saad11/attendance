import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learner/screens/student_screen.dart';
import 'package:learner/ui/utils/utils.dart';
import 'package:learner/widgets/round_button.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _image;
  bool loading = false;
  final picker = ImagePicker();
  final auth = FirebaseAuth.instance;
  final databaseRef = FirebaseDatabase.instance.ref('user_images');
  final firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;

  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        showToast('No image selected');
      }
    });
  }

  Future<void> uploadImage() async {
    if (_image == null) {
      showToast('Please select an image first');
      return;
    }

    setState(() {
      loading = true;
    });

    final user = auth.currentUser;
    if (user == null) {
      showToast('User not authenticated');
      setState(() {
        loading = false;
      });
      return;
    }

    try {
      final ref = storage.ref('/user_profile/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = ref.putFile(_image!);

      await uploadTask.whenComplete(() async {
        final newURL = await ref.getDownloadURL();
        await databaseRef.child(user.uid).set({
          'profilePictureUrl': newURL,
        });

        showToast('Updated successfully');
      });

    } on FirebaseException catch (e) {
      showToast('Upload failed: ${e.message}');
    } catch (e) {
      showToast('An error occurred: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate back to the previous page
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => UserScreen()));
            }
        ),
        title: Text('Upload Image'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: getImage,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey[200],
                child: _image != null
                    ? ClipOval(
                  child: Image.file(
                    _image!,
                    fit: BoxFit.cover,
                    width: 160,
                    height: 160,
                  ),
                )
                    : Icon(
                  Icons.image_search,
                  size: 60,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: 20),
            RoundButton(
              onTap: uploadImage,
              title: loading ? 'Uploading...' : 'Upload Image',
              loading: loading,
            ),
          ],
        ),
      ),
    );
  }
}
