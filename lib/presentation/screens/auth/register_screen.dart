import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sosyal_halisaha/data/models/city_model.dart';
import 'package:sosyal_halisaha/data/models/enums.dart';
import 'package:sosyal_halisaha/data/services/auth_service.dart';
import 'package:sosyal_halisaha/data/services/city_service.dart';
import 'package:sosyal_halisaha/presentation/providers/auth_provider.dart';
import 'package:sosyal_halisaha/presentation/widgets/app_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Formu yönetmek için bir GlobalKey. Bu, formun durumunu kontrol etmemizi sağlar.
  final _formKey = GlobalKey<FormState>();

  // TextField'lardan verileri okumak için TextEditingController'lar.
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  // Dropdown menülerde seçilen değerleri tutacak değişkenler.
  City? _selectedCity;
  PlayerPosition? _selectedPosition;

  // Kayıt işlemi sırasında yükleme göstergesi (loading indicator) için.
  bool _isLoading = false;

  // Kayıt işlemini tetikleyecek metot.
  void _submit() async {
    // Formun geçerli olup olmadığını kontrol et.
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // AuthService'i kullanarak kayıt isteği gönder.
        final token = await ref
            .read(authServiceProvider)
            .register(
              username: _usernameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              fullName: _fullNameController.text,
              cityId: _selectedCity!.id,
              position: _selectedPosition!,
            );

        // Kayıt başarılıysa, AuthProvider'ı güncelle ve ana sayfaya yönlendir.
        await ref.read(authNotifierProvider.notifier).login(token);
        if (mounted) context.go('/');
      } catch (e) {
        // Hata durumunda kullanıcıya bir uyarı göster.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kayıt Başarısız: ${e.toString()}')),
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

  // Widget'lar temizlendiğinde controller'ları da temizle.
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Şehirleri API'den çeken citiesProvider'ı dinle.
    final citiesAsyncValue = ref.watch(citiesProvider);
    return AppScaffold(
      appBar: AppBar(title: const Text('Yeni Hesap Oluştur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Metin Giriş Alanları ---
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Ad Soyad'),
                validator: (value) =>
                    value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
                validator: (value) =>
                    value!.isEmpty ? 'Bu alan boş bırakılamaz' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-posta'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value!.isEmpty || !value.contains('@'))
                    ? 'Geçerli bir e-posta girin'
                    : null,
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
              const SizedBox(height: 20),

              // --- Şehirler Dropdown ---
              // citiesProvider'ın durumuna göre UI'ı oluştur.
              citiesAsyncValue.when(
                data: (cities) => DropdownButtonFormField<City>(
                  value: _selectedCity,
                  hint: const Text('Şehir Seçin'),
                  items: cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCity = value),
                  validator: (value) =>
                      value == null ? 'Lütfen bir şehir seçin' : null,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Hata: $err'),
              ),
              const SizedBox(height: 20),

              // --- Mevkiler Dropdown ---
              DropdownButtonFormField<PlayerPosition>(
                value: _selectedPosition,
                hint: const Text('Mevki Seçin'),
                items: PlayerPosition.values.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(position.value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPosition = value),
                validator: (value) =>
                    value == null ? 'Lütfen bir mevki seçin' : null,
              ),
              const SizedBox(height: 24),

              // --- Kayıt Ol Butonu ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Kayıt Ol'),
              ),

              // --- Giriş Yap Sayfasına Yönlendirme ---
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Zaten bir hesabın var mı? Giriş Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
