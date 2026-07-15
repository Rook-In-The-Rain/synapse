import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';
import '../utils/signup_login_manager.dart';


class SignupPage extends StatelessWidget{
  SignupPage({super.key});

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up!")
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Enter a username...",
                  filled: true,
                  fillColor: colorScheme.surface
                )
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Enter your email....",
                  filled: true,
                  fillColor: colorScheme.surface
                )
              ),
            const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: "Enter your password....",
                  filled: true,
                  fillColor: colorScheme.surface
                )
              ),
            const SizedBox(height: 15),
              ElevatedButton(onPressed: () {
                AuthManager().signUp(_emailController.text.trim(), _passwordController.text.trim(), _usernameController.text.trim());
                }, child: Text("Sign Up!!")),
            const SizedBox(height:15),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                  children: [
                    const TextSpan(text: "Already have an account? "),
                    TextSpan(
                      text: "Log In!",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          context.go('/login');
                        },
                    ),
                  ],
                ),
              )
            ],
          )
        )
      )
    );
  }
}