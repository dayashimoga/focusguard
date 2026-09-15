import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/focus_profile.dart';
import '../../persistence/profile_repository.dart';

/// Screen for managing reusable Focus Profiles.
class ProfilesScreen extends StatefulWidget {
  final ProfileRepository profileRepository;

  const ProfilesScreen({super.key, required this.profileRepository});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  List<FocusProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final list = await widget.profileRepository.getAllProfiles();
    setState(() {
      _profiles = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Profiles'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primary,
        onPressed: () => _showCreateProfileDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final profile = _profiles[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppConstants.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shield,
                                  color: AppConstants.primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        profile.name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (profile.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppConstants.accent
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'DEFAULT',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppConstants.accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Strength: ${profile.restrictionStrength.name.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppConstants.primaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!profile.isPreset)
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppConstants.error),
                                onPressed: () async {
                                  await widget.profileRepository
                                      .deleteProfile(profile.id);
                                  await _loadProfiles();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile.description,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppConstants.textSecondaryDark),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ...profile.blockedCategories.map((c) {
                              return Chip(
                                label: Text(c.name,
                                    style: const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                              );
                            }),
                            if (profile.blockedPackageNames.isNotEmpty)
                              Chip(
                                label: Text(
                                    '+${profile.blockedPackageNames.length} apps',
                                    style: const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCreateProfileDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    RestrictionStrength strength = RestrictionStrength.focus;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppConstants.darkCard,
            title: const Text('Create Focus Profile',
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                        labelText: 'Profile Name', hintText: 'e.g. Exam Prep'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Goal of this profile'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Restriction Strength:',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RestrictionStrength>(
                    value: strength,
                    items: RestrictionStrength.values.map((s) {
                      return DropdownMenuItem(
                          value: s,
                          child: Text(s.name,
                              style: const TextStyle(color: Colors.white)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => strength = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    final newProfile = FocusProfile(
                      id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      iconName: 'tune',
                      restrictionStrength: strength,
                      blockedCategories: [
                        AppCategory.social,
                        AppCategory.entertainment
                      ],
                      isPreset: false,
                    );
                    await widget.profileRepository.saveProfile(newProfile);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    await _loadProfiles();
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}
