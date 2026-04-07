import 'dart:convert';

import 'package:allenapp/screens/passwordReset.dart';
import 'package:flutter/material.dart';
import '../Env.dart';
import 'package:http/http.dart' as http;
import 'loadingScreen.dart';

class otpValidationFormData {
  String? otp;
  otpValidationFormData({this.otp});
}

class otpValidationScreen extends StatefulWidget {

  const otpValidationScreen({super.key, required this.emailAddress, required this.isEnglishUS, required this.locale});

  final String emailAddress;
  final bool isEnglishUS;
  final String locale;
  @override
  State<otpValidationScreen> createState() => _otpValidationScreen();
}

class _otpValidationScreen extends State<otpValidationScreen> {
  bool loading = false;
  bool hasError = false;
  otpValidationFormData formData = otpValidationFormData();
  void initState() {
    super.initState();
    setState(() {
      loading = false;
      hasError = false;
    });
  }
  Future<void> submitOtpValidation(String otp, BuildContext context) async {
    setState(() {
      loading = true;
      hasError = false;
    });
    final requestResponse = await http.post(
        Uri.parse('https://' + Env.DRUPAL_URL + '/api/otp-reset/request'),
        body: {
          'email': widget.emailAddress,
          'otp': otp,
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
      else if (requestResponse.statusCode == 422) {
        message = 'The OTP has expired';
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
      final decodedBody = jsonDecode(requestResponse.body);
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => passwordResetScreen(reset_token: decodedBody['reset_token'] ?? '', emailAddress: widget.emailAddress, isEnglishUS: widget.isEnglishUS, locale: widget.locale))
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
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Address
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Color.fromRGBO(213, 31, 39, 1)),
                          hintText: 'One Time Code',
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color.fromRGBO(213, 31, 39, 1)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || value.length < 6) {
                            return 'One Time Code is not value';
                          }
                          return null;
                        },
                        onChanged: (value) => formData.otp = value,
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
                            submitOtpValidation(formData.otp ?? '', context);
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