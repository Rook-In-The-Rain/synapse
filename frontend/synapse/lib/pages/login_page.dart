import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';
import '../utils/signup_login_manager.dart';


class LoginPage extends StatelessWidget{
  LoginPage({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Login!")
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                AuthManager().logIn(_emailController.text.trim(), _passwordController.text.trim());
              }, child: Text("Login!")),
            const SizedBox(height:15),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                  children: [
                    const TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: "Sign up!",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          context.go('/signup');
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