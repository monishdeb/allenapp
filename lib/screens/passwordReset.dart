import 'dart:convert';

import 'package:flutter/material.dart';
import '../Env.dart';
import 'package:http/http.dart' as http;
import 'loadingScreen.dart';
import 'login.dart';

class passwordResetFormData {
  String? newPassword;
  passwordResetFormData({this.newPassword});
}

class passwordResetScreen extends StatefulWidget {

  const passwordResetScreen({super.key, required this.reset_token, required this.emailAddress, required this.isEnglishUS, required this.locale});

  final String reset_token;
  final String emailAddress;
  final bool isEnglishUS;
  final String locale;
  @override
  State<passwordResetScreen> createState() => _passwordResetScreen();
}

class _passwordResetScreen extends State<passwordResetScreen> {
  bool loading = false;
  bool hasError = false;
  void initState() {
    super.initState();
    setState(() {
      loading = false;
      hasError = false;
    });
  }
  passwordResetFormData formData = passwordResetFormData();

  Future<void> submitPassword(String password, String resetToken, String emailAddress, BuildContext context) async {
    setState(() {
      loading = true;
      hasError = false;
    });
    final requestResponse = await http.post(
        Uri.parse('https://' + Env.DRUPAL_URL + '/api/otp-reset/complete'),
        body: {
          'reset_token': resetToken,
          'password': password,
        });
    if (requestResponse.statusCode != 200) {
      setState(() {
        loading = false;
        hasError = true;
      });
      String message = '';
      if (requestResponse.statusCode == 400 && requestResponse.body.contains('User')) {
        message = 'The email address supplied is not associated with a user account';
      }
      else if (requestResponse.statusCode == 400 && requestResponse.body.contains('OTP')) {
        message = 'Please review the code and try again';
      }
      final snackBar = SnackBar(content: Text(message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Helvetica, sans-serif',
        ),
      ),
          backgroundColor: Color.fromRGBO(213, 31, 39, 1));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    else {
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage(title: 'Allen App', authenticated: true, forceLogin: false))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    if (loading) {
      return loadingScreen(isEnglishUS: widget.isEnglishUS, locale: widget.locale);
    }
    else {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                color: Color.fromRGBO(213, 31, 39, 1),
                padding: const EdgeInsets.only(top: 60, bottom: 20),
                width: double.infinity,
                alignment: Alignment.center,
                child: Column(
                  children: const [
                    Image(image: AssetImage("images/Allen_App_title.png"), height: 50),
                  ],
                ),
              ),
              const SizedBox(height: 80),
              // Login form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Form(
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Address
                      TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Color.fromRGBO(213, 31, 39, 1)),
                          hintText: 'New Password',
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color.fromRGBO(213, 31, 39, 1)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          // Example: Minimum 8 characters
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters long';
                          }
                          // Example: At least one uppercase letter
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return 'Password must contain at least one uppercase letter';
                          }
                          // Example: At least one digit
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return 'Password must contain at least one digit';
                          }
                          if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                            return 'Password must contain a special character';
                          }
                          return null;
                        },
                        onChanged: (value) => formData.newPassword = value,
                      ),
                      const SizedBox(height: 20),
                      // Login button
                      SizedBox(
                        width: 100,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(213, 31, 39, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ),
                          onPressed: () async {
                            submitPassword(formData.newPassword ?? '', widget.reset_token, widget.emailAddress, context);
                          },
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}