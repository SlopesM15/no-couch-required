import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false; // toggle between login/register

  final _formKey = GlobalKey<FormState>(); // For validations

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRegister) {
      // Registration logic
      if (_emailController.text.trim() != _confirmEmailController.text.trim()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Emails do not match")));
        return;
      }
      try {
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (response.user != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Registration successful!')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Registration failed')));
        }
        // Success
      } on AuthApiException catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } else {
      // Login logic
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign in failed')));
      }
    }
  }

  InputDecoration roundedDecoration({required String label}) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //gradient background
      appBar: AppBar(
        title: Text(_isRegister ? "Register" : "Sign In"),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              _isRegister
                  ? Color.fromARGB(255, 139, 86, 238)
                  : Color.fromARGB(255, 247, 134, 241),

              // Add more colors if needed
            ], // Example colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 400),
                  transitionBuilder:
                      (child, animation) =>
                          FadeTransition(opacity: animation, child: child),

                  child: Column(
                    key: ValueKey(_isRegister),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/ncn.png', // Update the path if needed
                        height: 350,
                      ),
                      //move to bottom
                      TextFormField(
                        style: TextStyle(
                          color: _isRegister ? Colors.black : Colors.white,
                        ),
                        controller: _emailController,
                        decoration: roundedDecoration(label: 'Email'),
                        validator:
                            (val) =>
                                val != null && val.contains('@')
                                    ? null
                                    : 'Enter a valid email',
                      ),
                      SizedBox(height: 12),
                      if (_isRegister)
                        TextFormField(
                          controller: _confirmEmailController,
                          decoration: roundedDecoration(label: 'Confirm Email'),
                          validator:
                              (val) =>
                                  val != null && val == _emailController.text
                                      ? null
                                      : "Emails do not match",
                        ),
                      if (_isRegister) SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: roundedDecoration(label: 'Password'),
                        obscureText: true,
                        validator:
                            (val) =>
                                (val == null || val.length < 6)
                                    ? 'Password too short'
                                    : null,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(shape: StadiumBorder()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical: 16,
                          ),
                          child: Text(_isRegister ? 'Register' : 'Sign In'),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegister = !_isRegister;
                            _confirmEmailController.clear();
                          });
                        },
                        child: Text(
                          _isRegister
                              ? "Already have an account? Login"
                              : "Don't have an account? Register",
                          style: TextStyle(
                            color:
                                _isRegister
                                    ? Color.fromARGB(255, 247, 134, 241)
                                    : Color.fromARGB(255, 139, 86, 238),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
