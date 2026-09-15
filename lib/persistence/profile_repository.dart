import '../domain/models/focus_profile.dart';
import 'database_helper.dart';

/// Repository for managing reusable Focus Profiles.
class ProfileRepository {
  final DatabaseHelper db;

  ProfileRepository({DatabaseHelper? databaseHelper})
      : db = databaseHelper ?? DatabaseHelper.instance;

  Future<void> initProfiles() async {
    final existing = await getAllProfiles();
    if (existing.isEmpty) {
      for (final preset in FocusProfile.defaultPresets) {
        await saveProfile(preset);
      }
    }
  }

  Future<void> saveProfile(FocusProfile profile) async {
    await db.insertProfile(profile.toMap());
  }

  Future<void> updateProfile(FocusProfile profile) async {
    await db.updateProfile(profile.toMap());
  }

  Future<void> deleteProfile(String id) async {
    await db.deleteProfile(id);
  }

  Future<List<FocusProfile>> getAllProfiles() async {
    final list = await db.getAllProfiles();
    return list.map((m) => FocusProfile.fromMap(m)).toList();
  }

  Future<FocusProfile?> getDefaultProfile() async {
    final list = await getAllProfiles();
    return list.firstWhere((p) => p.isDefault,
        orElse: () => FocusProfile.defaultPresets.first);
  }
}
