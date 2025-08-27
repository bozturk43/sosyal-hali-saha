import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sosyal_halisaha/presentation/providers/auth_provider.dart';
import 'package:sosyal_halisaha/data/services/auth_service.dart';
import 'package:sosyal_halisaha/presentation/widgets/app_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController =
      TextEditingController(); // E-posta veya Kullanıcı Adı
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // AuthService'i kullanarak giriş isteği gönder.
        final token = await ref
            .read(authServiceProvider)
            .login(
              identifier: _identifierController.text,
              password: _passwordController.text,
            );

        // Giriş başarılıysa, AuthProvider'ı güncelle.
        // GoRouter bu değişikliği dinleyip bizi otomatik olarak ana sayfaya yönlendirecek.
        await ref.read(authNotifierProvider.notifier).login(token);
      } catch (e) {
        // Hata durumunda kullanıcıya bir uyarı göster.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Giriş Başarısız: ${e.toString()}')),
          );
        }
      } finally {
        // İşlem bittiğinde yükleme göstergesini kaldır.
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _identifierController,
                decoration: const InputDecoration(
                  labelText: 'E-posta veya Kullanıcı Adı',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Şifre'),
                obscureText: true,
                validator: (value) => (value!.length < 6)
                    ? 'Şifre en az 6 karakter olmalı'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Giriş Yap'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Henüz bir hesabın yok mu?"),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Kayıt Ol'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
