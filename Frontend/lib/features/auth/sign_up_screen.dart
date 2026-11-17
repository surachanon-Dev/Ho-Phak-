import 'package:flutter/material.dart';
import '../../../../ho_phak/lib/core/theme/app_colors.dart';
import '../../../../ho_phak/lib/navigation/main_nav_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _role = 'ผู้เช่า (Tenant)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: AppColors.textPrimary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Sign Up', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // เลือกประเภทผู้ใช้ตามแถบด้านบนใน Figma
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ผู้เช่า (Tenant)', label: Text('User')),
                  ButtonSegment(value: 'เจ้าของหอ (Owner)', label: Text('Owner')),
                ],
                selected: {_role},
                onSelectionChanged: (val) => setState(() => _role = val.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Username', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v!.isEmpty ? 'Please enter your username' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                decoration: InputDecoration(labelText: 'Telephone number', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => !v!.contains('@') ? 'Correct the phone number' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v!.length < 9 ? 'The password must be at least 6 characters long' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm password', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => v!.length < 6 ? 'Please confirm your password' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainNavScreen()), (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Sign Up', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}