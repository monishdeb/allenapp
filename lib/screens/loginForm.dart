import 'home.dart';
import 'package:flutter/material.dart';
import 'language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/auth.dart';
import '../services/query.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'login.dart';
import 'otpRequestScreen.dart';
import 'loadingScreen.dart';

class LoginForm extends StatefulWidget {
  final FormData formData;
  final void Function(BuildContext, bool) submitFunction;
  final bool isEnglishUS;
  final String locale;
  const LoginForm({super.key, required this.formData, required this.submitFunction, required this.locale, required this.isEnglishUS});
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool loading = false;

  @override @override
  void initState() {
    super.initState();
    loading = false;
  }

  @override
  Widget build(BuildContext context) {
    FormData formData = widget.formData;
    if (loading) {
      return loadingScreen(locale: widget.locale, isEnglishUS: widget.isEnglishUS);
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              color: Color.fromRGBO(213, 31, 39, 1),
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Image(image: AssetImage("images/Allen_App_title.png"), height: 50),
                ],
              ),
            ),
            const SizedBox(height: 300),
            // Login form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Form(
                key: _formKey,
                child: Column(

                  children: [
                    // Username
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Color.fromRGBO(213, 31, 39, 1)),
                        hintText: 'Username',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color.fromRGBO(213, 31, 39, 1)),
                        ),
                      ),
                      onChanged: (value) => formData.username = value,
                    ),
                    const SizedBox(height: 20),
                    // Password
                    TextFormField(
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color.fromRGBO(213, 31, 39, 1)),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                        ),
                        hintText: 'Password',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color.fromRGBO(213, 31, 39, 1)),
                        ),
                      ),
                      onChanged: (value) => formData.password = value,
                    ),
                    const SizedBox(height: 30),
                    // Login button
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(213, 31, 39, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                        onPressed: () async {
                          setState(() {
                            loading = true;
                          });
                          widget.submitFunction(context, true);
                        },
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    // Reset Password
                    TextButton(
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => optRequestScreen(isEnglishUS: widget.isEnglishUS, locale: widget.locale))
                        );
                      },
                      child: const Text(
                        'Reset your password',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
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
