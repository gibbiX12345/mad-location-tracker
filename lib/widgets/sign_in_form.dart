import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInForm extends StatelessWidget {
  final User? user;
  final void Function() onSignOut;
  final void Function() onSignIn;

  const SignInForm({
    super.key,
    required this.onSignOut,
    required this.onSignIn,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        signedIn
            ? Text("Signed in as ${user?.displayName}")
            : const Text("Not signed in"),
        ElevatedButton(
          onPressed: signedIn ? onSignOut : onSignIn,
          child: signedIn
              ? const Text("Sign out")
              : const Text("Sign in with Google"),
        ),
      ],
    );
  }

  bool get signedIn => user != null;
}
