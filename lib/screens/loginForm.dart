import 'home.dart';
import 'package:flutter/material.dart';
import 'language.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/auth.dart';
import '../services/query.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'login.dart';

class LoginForm extends StatefulWidget {
  final FormData formData;
  final void Function(BuildContext) submitFunction;
  const LoginForm({super.key, required this.formData, required this.submitFunction});
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    FormData formData = widget.formData;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextFormField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Username',
            ),
            onChanged: (value) {
              formData.username = value;
            },
          ),
          TextFormField(
            obscureText: _obscureText,
            autocorrect: false,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                onPressed: () => {
                  setState(() {
                    _obscureText = !_obscureText;
                  })
                },
                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off)
              )
            ),
            onChanged: (value) {
              formData.password = value;
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero
              ),
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              minimumSize: const Size(40, 40), //////// HERE
            ),
            child: Text('Login'),
            onPressed: () => {
              widget.submitFunction(context)
            }
          )
        ]
      )
    );
  }
}