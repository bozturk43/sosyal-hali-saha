import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart';
import 'package:sosyal_halisaha/data/services/team_service.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';
import 'package:sosyal_halisaha/presentation/widgets/app_scaffold.dart';
import 'dart:developer' as developer;

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  File? _selectedLogoFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedLogoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm({required User currentUser}) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Artık ref.read'e ihtiyacımız yok, ID'yi doğrudan parametreden alıyoruz.
      final currentUserId = currentUser.id;

      try {
        await ref
            .read(teamServiceProvider)
            .createTeam(
              name: _teamNameController.text,
              captainId: currentUserId,
              logoFile: _selectedLogoFile,
            );

        ref.invalidate(currentUserProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Takımın başarıyla oluşturuldu!')),
          );
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(currentUserProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Takımını Oluştur')),
      body: userAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text("Kullanıcı bilgileri yüklenemedi")),
        data: (user) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      backgroundImage: _selectedLogoFile != null
                          ? FileImage(_selectedLogoFile!)
                          : null,
                      child: _selectedLogoFile == null
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Takım Logosu Seç (İsteğe Bağlı)",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _teamNameController,
                    decoration: const InputDecoration(labelText: 'Takım Adı'),
                    validator: (value) =>
                        value!.isEmpty ? 'Takım adı boş bırakılamaz' : null,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _submitForm(currentUser: user),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Takımı Oluştur'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
