// lib/presentation/screens/profile/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sosyal_halisaha/data/models/city_model.dart';
import 'package:sosyal_halisaha/data/models/enums.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart';
import 'package:sosyal_halisaha/data/services/city_service.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';
import 'package:sosyal_halisaha/presentation/providers/auth_provider.dart';
import 'package:sosyal_halisaha/presentation/widgets/app_scaffold.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // Bu state yönetimi, önceki ProfileScreen'den neredeyse birebir aynı.
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late final TextEditingController _fullNameController;
  City? _selectedCity;
  PlayerPosition? _selectedPosition;

  @override
  void initState() {
    super.initState();
    // Mevcut kullanıcı verisini alıp controller'ları dolduruyoruz.
    final user = ref.read(currentUserProvider).value;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    // ... Diğer alanları da burada doldurabiliriz ...
  }

  // Kaydetme metodu da çok benzer, sadece sonunda geri gidiyoruz.
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final userId = ref.read(currentUserProvider).value!.id;
      try {
        final dataToUpdate = {
          'fullName': _fullNameController.text,
          'preferredPosition': _selectedPosition!.value,
          'city': _selectedCity!.id,
        };
        await ref.read(userServiceProvider).updateUser(userId, dataToUpdate);
        ref.invalidate(currentUserProvider);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profil güncellendi!')));
          context
              .pop(); // <-- EN ÖNEMLİ DEĞİŞİKLİK: Bir önceki sayfaya geri dön
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bu kod da, önceki ProfileScreen'in _buildEditView metodunun neredeyse aynısı.
    return AppScaffold(
      // Tab menüsü olmayacağı için AppScaffold kullanıyoruz.
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: ref
          .watch(currentUserProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) =>
                const Center(child: Text("Kullanıcı verisi yüklenemedi")),
            data: (user) {
              // Form ve içindeki alanlar... (Önceki _buildEditView kodunu buraya taşıyabiliriz)
              // Bu kısım, daha önceki ProfileScreen'in düzenleme moduyla aynı olacak.
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildEditView(user), // Düzenleme arayüzünü göster
                ),
              );
            },
          ),
    );
  }

  Widget _buildEditView(User user) {
    final citiesAsyncValue = ref.watch(citiesProvider);
    return Column(
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(labelText: 'Ad Soyad'),
          validator: (value) => value!.isEmpty ? 'Boş bırakılamaz' : null,
        ),
        const SizedBox(height: 20),
        citiesAsyncValue.when(
          data: (cities) => DropdownButtonFormField<City>(
            value: _selectedCity,
            items: cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (val) => setState(() => _selectedCity = val),
            decoration: const InputDecoration(labelText: 'Şehir'),
            validator: (value) => value == null ? 'Lütfen şehir seçin' : null,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => const Text('Şehirler yüklenemedi'),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<PlayerPosition>(
          value: _selectedPosition,
          items: PlayerPosition.values
              .map((p) => DropdownMenuItem(value: p, child: Text(p.value)))
              .toList(),
          onChanged: (val) => setState(() => _selectedPosition = val),
          decoration: const InputDecoration(labelText: 'Mevki'),
          validator: (value) => value == null ? 'Lütfen mevki seçin' : null,
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
