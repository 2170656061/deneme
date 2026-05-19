import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/providers.dart';
import '../widgets/app_layout.dart';

class LoginPage extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const LoginPage({super.key, this.onNavigate});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giriş başarılı!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onNavigate?.call(0);
      }
    } catch (e) {
      if (mounted) {
        // Strip the "Exception:" prefix for cleaner display
        String msg = e.toString().replaceFirst('Exception: ', '');
        // Catch common raw HTTP error payloads like {"detail":"..."}
        if (msg.contains('"detail"')) {
          final match = RegExp(r'"detail"\s*:\s*"([^"]+)"').firstMatch(msg);
          if (match != null) msg = match.group(1)!;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş başarısız: $msg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Giriş Yap',
      onNavigate: widget.onNavigate,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'SahaTakip',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hesabınıza giriş yapın',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Kullanıcı adı gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _isLoading ? null : _login(),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre gerekli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            _isLoading ? 'Giriş yapılıyor...' : 'Giriş Yap',
                            style: const TextStyle(fontSize: 16),
                          ),
                          onPressed: _isLoading ? null : _login,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Hesabınız yok mu?'),
                          TextButton(
                            onPressed: () => widget.onNavigate?.call(6),
                            child: const Text('Kayıt Olun'),
                          ),
                        ],
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
