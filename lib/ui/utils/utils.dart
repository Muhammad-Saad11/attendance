import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class utils {
  void toastMessage(String message) {
    Fluttertoast.showToast(
      msg: message, // The message is passed dynamically
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.blue, // You can make this dynamic as well
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
