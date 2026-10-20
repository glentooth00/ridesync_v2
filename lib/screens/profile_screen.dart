
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../core/theme/app_theme.dart';
import '../models/motorcycle.dart';
import '../models/ride.dart';
import '../models/rider_profile.dart';
import '../services/app_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.onClearLocalData,
  });

  final Future<void> Function() onClearLocalData;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  RiderProfile _profile = const RiderProfile();
  List<Motorcycle> _motorcycles = [];
  List<RideRecord> _rides = [];
  int _selectedMotorcycleId = 0;
  bool _loading = true;

  static const Color orange = AppTheme.orange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        AppStorage.loadRiderProfile(),
        AppStorage.loadMotorcycles(),
        AppStorage.loadRides(),
        AppStorage.loadSelectedMotorcycleId(),
      ]);

      if (!mounted) return;

      setState(() {
        _profile = results[0] as RiderProfile;
        _motorcycles = results[1] as List<Motorcycle>;
        _rides = (results[2] as List<RideRecord>)
          ..sort((a, b) => b.date.compareTo(a.date));
        _selectedMotorcycleId = results[3] as int;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Motorcycle? get _activeMotorcycle {
    for (final motorcycle in _motorcycles) {
      if (motorcycle.id == _selectedMotorcycleId) {
        return motorcycle;
      }
    }

    return _motorcycles.isEmpty ? null : _motorcycles.first;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) return '${hours}h';

    return '${hours}h ${remainingMinutes}m';
  }

  Future<String?> _saveProfileImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
      );

      if (image == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final profileDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}profile',
      );

      if (!await profileDirectory.exists()) {
        await profileDirectory.create(recursive: true);
      }

      final extension = image.path.contains('.')
          ? image.path.split('.').last.toLowerCase()
          : 'jpg';

      final destination = File(
        '${profileDirectory.path}${Platform.pathSeparator}'
        'rider_profile.$extension',
      );

      await File(image.path).copy(destination.path);

      return destination.path;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to select the profile photo.'),
          ),
        );
      }

      return null;
    }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _profile.fullName);
    final phoneController =
        TextEditingController(text: _profile.contactNumber);
    final emailController = TextEditingController(text: _profile.email);

    String gender = _profile.gender;
    String dateOfBirth = _profile.dateOfBirth;
    String? imagePath = _profile.profileImagePath;

    final formKey = GlobalKey<FormState>();

    final updatedProfile = await showDialog<RiderProfile>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            ImageProvider? imageProvider;

            if (imagePath != null && File(imagePath!).existsSync()) {
              imageProvider = FileImage(File(imagePath!));
            }

            return AlertDialog(
              title: const Text('Edit rider profile'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final picked = await _saveProfileImage();

                            if (picked != null) {
                              setDialogState(() => imagePath = picked);
                            }
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: AppTheme.surfaceRaised,
                                backgroundImage: imageProvider,
                                child: imageProvider == null
                                    ? const Icon(
                                        Icons.person_rounded,
                                        color: orange,
                                        size: 45,
                                      )
                                    : null,
                              ),
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: orange,
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.black,
                                  size: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: gender.isEmpty ? null : gender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            prefixIcon: Icon(Icons.wc_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Male',
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: 'Female',
                              child: Text('Female'),
                            ),
                            DropdownMenuItem(
                              value: 'Prefer not to say',
                              child: Text('Prefer not to say'),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() => gender = value ?? '');
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isNotEmpty &&
                                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(email)) {
                              return 'Enter a valid email address';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();

                            final initialDate =
                                DateTime.tryParse(dateOfBirth) ??
                                DateTime(now.year - 18, now.month, now.day);

                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: initialDate.isAfter(now)
                                  ? DateTime(now.year - 18, now.month, now.day)
                                  : initialDate,
                              firstDate: DateTime(1900),
                              lastDate: now,
                            );

                            if (picked != null) {
                              setDialogState(() {
                                dateOfBirth =
                                    '${picked.year.toString().padLeft(4, '0')}-'
                                    '${picked.month.toString().padLeft(2, '0')}-'
                                    '${picked.day.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(
                            dateOfBirth.isEmpty
                                ? 'Select date of birth'
                                : 'Date of birth: $dateOfBirth',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    Navigator.pop(
                      dialogContext,
                      RiderProfile(
                        fullName: nameController.text.trim(),
                        gender: gender,
                        contactNumber: phoneController.text.trim(),
                        email: emailController.text.trim(),
                        dateOfBirth: dateOfBirth,
                        profileImagePath: imagePath,
                      ),
                    );
                  },
                  child: const Text('Save profile'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();

    if (updatedProfile != null) {
      await AppStorage.saveRiderProfile(updatedProfile);

      if (!mounted) return;

      setState(() => _profile = updatedProfile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rider profile saved.')),
      );
    }
  }

  Widget _sectionHeader(String title, {String? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: orange,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }

  Widget _profileAvatar({double radius = 38}) {
    final path = _profile.profileImagePath;
    final hasImage = path != null && File(path).existsSync();

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.surfaceRaised,
      backgroundImage: hasImage ? FileImage(File(path)) : null,
      child: hasImage
          ? null
          : Icon(
              Icons.person_rounded,
              color: orange,
              size: radius * 1.15,
            ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _profile.fullName.trim().isEmpty
        ? 'Your Rider Profile'
        : _profile.fullName.trim();

    final motorcycle = _activeMotorcycle;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: orange.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: orange, width: 2),
                ),
                child: _profileAvatar(radius: 39),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            motorcycle == null
                ? 'Personal motorcycle companion'
                : 'Riding ${motorcycle.displayName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.two_wheeler_rounded,
                  value: '${_motorcycles.length}',
                  label: 'MOTORCYCLES',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.route_rounded,
                  value: '${_rides.length}',
                  label: 'RECORDED RIDES',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _editProfile,
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                'Edit Rider Profile',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: orange, size: 21),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: orange, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not added' : value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    final date = DateTime.tryParse(_profile.dateOfBirth);
    final formattedDate = date == null ? '' : _formatDate(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _infoRow(Icons.badge_outlined, 'Full name', _profile.fullName),
          _infoRow(Icons.wc_outlined, 'Gender', _profile.gender),
          _infoRow(Icons.calendar_month_outlined, 'Date of birth', formattedDate),
          _infoRow(Icons.phone_outlined, 'Contact number', _profile.contactNumber),
          _infoRow(Icons.mail_outline_rounded, 'Email address', _profile.email),
        ],
      ),
    );
  }

  Widget _buildGarage() {
    if (_motorcycles.isEmpty) {
      return _emptyCard(
        Icons.two_wheeler_rounded,
        'Your garage is empty',
        'Add a motorcycle in the Garage screen and it will appear here.',
      );
    }

    return Column(
      children: _motorcycles.map((motorcycle) {
        final isActive = motorcycle.id == _selectedMotorcycleId;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isActive
                  ? orange.withValues(alpha: 0.65)
                  : AppTheme.muted.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRaised,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: orange,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      motorcycle.displayName.isEmpty
                          ? motorcycle.name
                          : motorcycle.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${motorcycle.year} • ${motorcycle.odometerKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                    if (motorcycle.engineCc.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${motorcycle.engineCc} cc',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isActive)
                const Icon(
                  Icons.check_circle_rounded,
                  color: orange,
                  size: 21,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentRides() {
    if (_rides.isEmpty) {
      return _emptyCard(
        Icons.route_rounded,
        'No rides recorded yet',
        'Your completed rides will appear here after you save your first ride.',
      );
    }

    final recentRides = _rides.take(5).toList();

    return Column(
      children: recentRides.map((ride) {
        Motorcycle? motorcycle;

        for (final item in _motorcycles) {
          if (item.id == ride.motorcycleId) {
            motorcycle = item;
            break;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceRaised,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: orange,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          motorcycle?.displayName ??
                              'Motorcycle no longer available',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(ride.date),
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${ride.distanceKm.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      color: orange,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDuration(ride.durationMinutes),
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                    ),
                  ),
                  if (ride.note.trim().isNotEmpty) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.notes_rounded,
                      size: 15,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        ride.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyCard(IconData icon, String title, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Icon(icon, color: orange, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              height: 1.45,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
    IconData icon,
    String title,
    String subtitle, {
    String? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                color: orange,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear local data?'),
        content: const Text(
          'This permanently removes your saved rider profile, '
          'motorcycles, and ride records from this device. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.onClearLocalData();

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local data cleared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: orange),
      );
    }

    return RefreshIndicator(
      color: orange,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
        children: [
          const Text(
            'RIDER ACCOUNT',
            style: TextStyle(
              color: orange,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'My Profile',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 20),

          _buildProfileHeader(),

          const SizedBox(height: 25),
          _sectionHeader('PERSONAL INFORMATION'),
          const SizedBox(height: 12),
          _buildPersonalInformation(),

          const SizedBox(height: 25),
          _sectionHeader(
            'MY GARAGE',
            trailing: '${_motorcycles.length} MOTORCYCLES',
          ),
          const SizedBox(height: 12),
          _buildGarage(),

          const SizedBox(height: 25),
          _sectionHeader(
            'RECENT RIDES',
            trailing: '${_rides.length} TOTAL',
          ),
          const SizedBox(height: 12),
          _buildRecentRides(),

          const SizedBox(height: 25),
          _sectionHeader('PREFERENCES'),
          const SizedBox(height: 12),

          _settingsTile(
            Icons.storage_outlined,
            'Offline-first storage',
            'Your data is saved on this device.',
          ),
          _settingsTile(
            Icons.palette_outlined,
            'Racing dark theme',
            'Matte black, charcoal and racing orange.',
          ),
          _settingsTile(
            Icons.cloud_outlined,
            'Cloud sync',
            'Planned for a future release.',
            trailing: 'LATER',
          ),
          _settingsTile(
            Icons.groups_outlined,
            'Rider community',
            'Planned for a future release.',
            trailing: 'LATER',
          ),

          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: _confirmClear,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: BorderSide(
                color: Colors.redAccent.withValues(alpha: 0.4),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Clear all local data'),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'RIDESYNC • FOUNDATION 1.0.0',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
