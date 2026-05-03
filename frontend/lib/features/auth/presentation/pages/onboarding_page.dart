import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/features/auth/presentation/pages/map_picker_page.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/presentation/widgets/location_picker_field.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

final _onboardingProvider =
    AsyncNotifierProvider.autoDispose<_OnboardingNotifier, void>(
      _OnboardingNotifier.new,
    );

class _OnboardingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String name,
    required int age,
    required String gender,
    required String streetAddress,
    required double latitude,
    required double longitude,
  }) async {
    final source = ref.read(profileRemoteSourceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cwsn = await source.getCwsnProfile();
      final caregiver = await source.getCaregiverProfile();

      final data = <String, dynamic>{
        'name': name,
        'age': age,
        'gender': gender,
        'street_address': streetAddress,
        'latitude': double.parse(latitude.toStringAsFixed(6)),
        'longitude': double.parse(longitude.toStringAsFixed(6)),
      };

      await Future.wait([
        source.updateCwsnProfile(cwsn.id, data),
        source.updateCaregiverProfile(caregiver.id, data),
      ]);
    });
  }
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Male';
  LocationPickerResult? _location;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: _location?.latitude,
          initialLng: _location?.longitude,
        ),
      ),
    );
    if (result != null) setState(() => _location = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick your location on the map.')),
      );
      return;
    }

    await ref.read(_onboardingProvider.notifier).submit(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _gender,
      streetAddress: _location!.displayLocation,
      latitude: _location!.latitude,
      longitude: _location!.longitude,
    );

    if (mounted) {
      ref.read(_onboardingProvider).when(
        data: (_) async {
          await ref.read(authProvider.notifier).completeOnboarding();
          if (mounted) context.go(AppRoutes.categories);
        },
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        ),
        loading: () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_onboardingProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Welcome!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us a bit about yourself to get started.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                Text('Full Name', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 24),
                Text('Age', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter your age',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Age is required';
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0 || n > 120) return 'Enter a valid age';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text('Gender', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: _genders
                      .map((g) => ButtonSegment(value: g, label: Text(g)))
                      .toList(),
                  selected: {_gender},
                  onSelectionChanged: (val) =>
                      setState(() => _gender = val.first),
                ),
                const SizedBox(height: 24),
                Text('Your Area', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                LocationPickerField(
                  location: _location,
                  onTap: _openMapPicker,
                ),
                const SizedBox(height: 6),
                Text(
                  'Move the pin to your neighbourhood — exact address not needed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Get Started',
                            style: TextStyle(fontSize: 16),
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
