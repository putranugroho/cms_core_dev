import 'package:accounting_kantor_gl_useraccess/module/auth/login_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/utils/button_custom.dart';
import 'package:accounting_kantor_gl_useraccess/utils/colors.dart';
import 'package:accounting_kantor_gl_useraccess/utils/images_path.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginNotifier(context: context),
      child: Consumer<LoginNotifier>(
        builder: (context, value, child) => SafeArea(
          child: Scaffold(
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(64),
                    decoration: const BoxDecoration(color: colorPrimary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          ImageAssets.accounting,
                          height: 72,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'CMS Core',
                          style: TextStyle(
                            fontSize: 42,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kantor, GL / COA, Login User, dan User Access.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 560,
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: Center(
                    child: SingleChildScrollView(
                      child: FocusTraversalGroup(
                        child: Form(
                          key: value.keyForm,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Masuk untuk mengakses aplikasi.',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'User ID',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                textInputAction: TextInputAction.next,
                                controller: value.username,
                                maxLines: 1,
                                validator: (e) {
                                  if (e == null || e.isEmpty) {
                                    return 'Wajib diisi';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'User ID',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Password',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                obscureText: value.obscure,
                                textInputAction: TextInputAction.done,
                                controller: value.password,
                                maxLines: 1,
                                onFieldSubmitted: (_) => value.cek(),
                                validator: (e) {
                                  if (e == null || e.isEmpty) {
                                    return 'Wajib diisi';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  suffixIcon: IconButton(
                                    onPressed: value.gantiObscure,
                                    icon: Icon(value.obscure ? Icons.visibility : Icons.visibility_off),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ButtonPrimary(
                                onTap: () => value.cek(),
                                name: 'Sign In',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
