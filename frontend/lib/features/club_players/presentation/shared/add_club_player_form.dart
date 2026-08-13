import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../player/application/lookup_providers.dart';
import '../../../player/domain/entities/player_enums.dart';
import '../../application/club_players_controller.dart';
import '../../domain/entities/create_club_player_input.dart';
import '../../domain/entities/dial_codes.dart';
import 'whatsapp_send_button.dart';

/// Full player-creation form — the club fills in everything on the
/// player's behalf, including phone (used as the generated account's
/// username). Shared verbatim between Desktop and Mobile; only the
/// surrounding scroll/width container differs (see the two page files).
class AddClubPlayerForm extends ConsumerStatefulWidget {
  const AddClubPlayerForm({super.key});

  @override
  ConsumerState<AddClubPlayerForm> createState() => _AddClubPlayerFormState();
}

class _AddClubPlayerFormState extends ConsumerState<AddClubPlayerForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _nationality = TextEditingController();
  final _city = TextEditingController();
  final _position = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _bio = TextEditingController();

  String? _countryIsoCode;
  String? _sport;
  PreferredFoot? _preferredFoot;
  DateTime? _dateOfBirth;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _nationality.dispose();
    _city.dispose();
    _position.dispose();
    _height.dispose();
    _weight.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(now.year - 60),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_countryIsoCode == null) {
      setState(() => _error = 'اختر الدولة.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final input = CreateClubPlayerInput(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        countryIsoCode: _countryIsoCode!,
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        dateOfBirth: _dateOfBirth,
        nationality: _emptyToNull(_nationality.text),
        city: _emptyToNull(_city.text),
        sport: _sport,
        position: _emptyToNull(_position.text),
        preferredFoot: _preferredFoot,
        height: num.tryParse(_height.text),
        weight: num.tryParse(_weight.text),
        bio: _emptyToNull(_bio.text),
      );
      final credentials = await ref
          .read(clubPlayersControllerProvider.notifier)
          .addPlayer(input);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('تم إنشاء حساب اللاعب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اسم المستخدم: ${credentials.username}'),
              const SizedBox(height: 4),
              Text('كلمة المرور: ${credentials.password}'),
              const SizedBox(height: 16),
              SendCredentialsWhatsAppButton(
                firstName: input.firstName,
                credentials: credentials,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/club/players');
              },
              child: const Text('تم'),
            ),
          ],
        ),
      );
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);
    final sports = ref.watch(sportsProvider);
    final dialCode = _countryIsoCode != null ? kDialCodes[_countryIsoCode] : null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _firstName,
            decoration: const InputDecoration(labelText: 'الاسم الأول'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastName,
            decoration: const InputDecoration(labelText: 'اسم العائلة'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          countries.when(
            data: (options) => DropdownButtonFormField<String>(
              initialValue: _countryIsoCode,
              decoration: const InputDecoration(labelText: 'الدولة'),
              items: options
                  .where((o) => o.code != null)
                  .map((o) => DropdownMenuItem(value: o.code, child: Text(o.name)))
                  .toList(),
              onChanged: (value) => setState(() => _countryIsoCode = value),
              validator: (v) => v == null ? 'مطلوب' : null,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'رقم الموبايل',
              prefixText: dialCode != null ? '$dialCode ' : null,
              hintText: 'بدون صفر في البداية',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'مطلوب'
                : (!RegExp(r'^\d{6,14}$').hasMatch(v.trim()) ? 'رقم غير صحيح' : null),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني (اختياري)'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _dateOfBirth != null
                  ? 'تاريخ الميلاد: ${_dateOfBirth!.year}-${_dateOfBirth!.month}-${_dateOfBirth!.day}'
                  : 'تاريخ الميلاد (اختياري)',
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDateOfBirth,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nationality,
            decoration: const InputDecoration(labelText: 'الجنسية (اختياري)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'المدينة (اختياري)'),
          ),
          const SizedBox(height: 12),
          sports.when(
            data: (options) => DropdownButtonFormField<String>(
              initialValue: _sport,
              decoration: const InputDecoration(labelText: 'الرياضة (اختياري)'),
              items: options
                  .map((o) => DropdownMenuItem(value: o.name, child: Text(o.name)))
                  .toList(),
              onChanged: (value) => setState(() => _sport = value),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _position,
            decoration: const InputDecoration(labelText: 'المركز (اختياري)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PreferredFoot>(
            initialValue: _preferredFoot,
            decoration: const InputDecoration(labelText: 'القدم المفضلة (اختياري)'),
            items: PreferredFoot.values
                .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                .toList(),
            onChanged: (value) => setState(() => _preferredFoot = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _height,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الطول (سم)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الوزن (كجم)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bio,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'نبذة (اختياري)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('إنشاء الحساب'),
          ),
        ],
      ),
    );
  }
}
