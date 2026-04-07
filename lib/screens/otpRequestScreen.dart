import 'dart:convert';

import 'package:allenapp/screens/otpValidation.dart';
import 'package:flutter/material.dart';
import '../Env.dart';
import 'package:http/http.dart' as http;
import 'loadingScreen.dart';

class otpRequestFormData {
  String? emailAddress;
  otpRequestFormData({this.emailAddress});
}

class optRequestScreen extends StatefulWidget {

  final bool isEnglishUS;
  final String locale;
  const optRequestScreen({super.key, required this.isEnglishUS, required this.locale});

  @override
  State<optRequestScreen> createState() => _optRequestScreen();
}

class _optRequestScreen extends State<optRequestScreen> {
  bool loading = false;
  bool hasError = false;
  otpRequestFormData formData = otpRequestFormData();
  void initState() {
    super.initState();
    setState(() {
      loading = false;
      hasError = false;
    });
  }

  Future<void> submitOtpRequest(String? emailAddress, BuildContext context) async {
    setState(() {
      loading = true;
      hasError = false;
    });
    final requestResponse = await http.post(
      Uri.parse('https://' + Env.DRUPAL_URL + '/api/otp-reset/request'),
      body: {
        'email': emailAddress,
        'hash': Env.GENERATE_HASH,
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
      else if (requestResponse.statusCode == 429) {
        message = 'Please try again later';
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
        MaterialPageRoute(builder: (context) => otpValidationScreen(emailAddress: emailAddress ?? '', isEnglishUS: widget.isEnglishUS, locale: widget.locale))
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
                          hintText: 'Email Address',
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color.fromRGBO(213, 31, 39, 1)),
                          ),
                        ),
                        onChanged: (value) => formData.emailAddress = value,
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
                            submitOtpRequest(formData.emailAddress, context);
                          },
                          child: const Text(
                            'Request one time code',
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