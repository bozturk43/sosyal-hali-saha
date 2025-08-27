import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sosyal_halisaha/data/models/team_model.dart';
import 'package:sosyal_halisaha/data/services/match_service.dart';
import 'package:sosyal_halisaha/data/services/team_service.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';
import 'package:sosyal_halisaha/presentation/widgets/app_scaffold.dart';

class CreateMatchScreen extends ConsumerStatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  Team? _selectedOpponent;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _showOpponentSearch() async {
    final selectedTeam = await showModalBottomSheet<Team>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _OpponentSearchSheet(),
    );
    if (selectedTeam != null) {
      setState(() => _selectedOpponent = selectedTeam);
    }
  }

  Future<void> _submitForm({required Team homeTeam}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedDate == null ||
        _startTime == null ||
        _endTime == null ||
        _selectedOpponent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları eksiksiz doldurun.')),
      );
      return;
    }

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (startDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçmiş bir tarih veya saate maç ayarlanamaz.'),
        ),
      );
      return;
    }

    if (!endDateTime.isAfter(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitiş saati, başlangıç saatinden sonra olmalıdır.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(matchServiceProvider)
          .createMatchOffer(
            location: _locationController.text,
            startTime: startDateTime,
            endTime: endDateTime,
            homeTeamId: homeTeam.id,
            awayTeamId: _selectedOpponent!.id,
          );
      ref.invalidate(myMatchesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maç teklifi başarıyla gönderildi!')),
        );
        context.pop();
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

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(currentUserProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Maç Ayarla'),
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          tooltip: "Geri Dön",
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: userAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) =>
            const Center(child: Text("Kaptan bilgileri yüklenemedi.")),
        data: (user) {
          if (user.team == null) {
            return const Center(
              child: Text(
                "Maç ayarlamak için bir takımın kaptanı olmalısınız.",
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Halı Saha Adı',
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Bu alan boş olamaz' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    label: Text(
                      _selectedDate == null
                          ? 'Maç Tarihi Seç'
                          : DateFormat(
                              'dd MMMM yyyy',
                              'tr_TR',
                            ).format(_selectedDate!),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.access_time_outlined),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) setState(() => _startTime = time);
                          },
                          label: Text(
                            _startTime == null
                                ? 'Başlangıç Saati'
                                : _startTime!.format(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _startTime ?? TimeOfDay.now(),
                            );
                            if (time != null) setState(() => _endTime = time);
                          },
                          label: Text(
                            _endTime == null
                                ? 'Bitiş Saati'
                                : _endTime!.format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text('Rakip Takım'),
                    subtitle: Text(
                      _selectedOpponent?.name ?? 'Henüz seçilmedi',
                    ),
                    trailing: const Icon(Icons.search),
                    onTap: _showOpponentSearch,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _submitForm(homeTeam: user.team!),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Maç Teklifi Gönder'),
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

// RAKİP ARAMA MODAL'I
class _OpponentSearchSheet extends ConsumerStatefulWidget {
  const _OpponentSearchSheet();
  @override
  ConsumerState<_OpponentSearchSheet> createState() =>
      _OpponentSearchSheetState();
}

class _OpponentSearchSheetState extends ConsumerState<_OpponentSearchSheet> {
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsyncValue = ref.watch(allTeamsProvider(_searchQuery));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Wrap(
        children: [
          TextField(
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              labelText: 'Takım Adı Ara',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: teamsAsyncValue.when(
              data: (teams) => teams.isEmpty
                  ? const Center(
                      child: Text('Aramanızla eşleşen takım bulunamadı.'),
                    )
                  : ListView.builder(
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        return ListTile(
                          title: Text(team.name),
                          trailing: ElevatedButton(
                            child: const Text('Davet Et'),
                            onPressed: () {
                              Navigator.of(context).pop(team);
                            },
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  const Center(child: Text('Takımlar yüklenemedi')),
            ),
          ),
        ],
      ),
    );
  }
}
