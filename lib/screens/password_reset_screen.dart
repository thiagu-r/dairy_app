
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class PasswordResetScreen extends StatefulWidget {
  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetSent = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.requestPasswordReset(_emailController.text);
    
    if (success && mounted) {
      setState(() {
        _resetSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_resetSent)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Password Reset Email Sent',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check your email for instructions to reset your password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Forgot your password?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enter your email address and we\'ll send you instructions to reset your password.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Error message
                    if (authProvider.errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red.shade800, size: 16),
                              onPressed: authProvider.clearError,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    if (authProvider.errorMessage != null) SizedBox(height: 16),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    
                    // Reset button
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _requestReset,
                      child: authProvider.isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Sending...'),
                              ],
                            )
                          : Text('Send Reset Link'),
                    ),
                  ],
                ),
              
              SizedBox(height: 16),
              // Back to login button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}