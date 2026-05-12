import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/login_widgets.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.onLogin});
  final Function(String name, String email) onLogin;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Test User
    _nameController.text = 'Mela LA';
    _emailController.text = 'Mela.LA@ipsos.com';
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LoginSurface(
              padding: const EdgeInsets.all(26),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ipsos',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    LoginTextField(
                      controller: _nameController,
                      label: 'Name',
                      validator: _required,
                    ),
                    const SizedBox(height: 6),
                    LoginTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (_required(value) != null) return _required(value);
                        return value!.contains('@')
                            ? null
                            : 'Enter a valid email address';
                      },
                    ),
                    const SizedBox(height: 14),
                    LoginActionButton(
                      label: 'Sign In',
                      icon: Icons.login,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onLogin(
                            _nameController.text.trim(),
                            _emailController.text.trim(),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
