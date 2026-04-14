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
  resizeToAvoidBottomInset: true,

  appBar: PreferredSize(
    preferredSize: const Size.fromHeight(100),
    child: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromRGBO(213, 31, 39, 1),
      elevation: 0,
      flexibleSpace: SafeArea(
        child: Center(
          child: Image.asset(
            "images/Allen_App_title.png",
            height: 50,
          ),
        ),
      ),
    ),
  ),
  body: SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: 150),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Username
                        TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color.fromRGBO(213, 31, 39, 1),
                            ),
                            hintText: 'Username',
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromRGBO(213, 31, 39, 1),
                              ),
                            ),
                          ),
                          onChanged: (value) =>
                              widget.formData.username = value,
                        ),
                        const SizedBox(height: 20),
                        // Password
                        TextFormField(
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color.fromRGBO(213, 31, 39, 1),
                            ),
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
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromRGBO(213, 31, 39, 1),
                              ),
                            ),
                          ),
                          onChanged: (value) =>
                              widget.formData.password = value,
                        ),
                        const SizedBox(height: 30),
                        // Login button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(213, 31, 39, 1),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
                        ),

                        const SizedBox(height: 20),

                        // Reset Password
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => optRequestScreen(
                                  isEnglishUS: widget.isEnglishUS,
                                  locale: widget.locale,
                                ),
                              ),
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
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
);

  }
}
