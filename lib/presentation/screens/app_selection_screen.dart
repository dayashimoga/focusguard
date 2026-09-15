import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/app_info.dart';
import '../../domain/models/enums.dart';

/// Screen allowing users to inspect installed applications, filter by category, and configure blocked/allowed sets.
class AppSelectionScreen extends StatefulWidget {
  final List<AppInfo> installedApps;
  final Set<String> initialBlockedPackages;
  final ValueChanged<Set<String>> onSaveBlockedPackages;

  const AppSelectionScreen({
    super.key,
    required this.installedApps,
    required this.initialBlockedPackages,
    required this.onSaveBlockedPackages,
  });

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  late Set<String> _blockedPackages;
  String _searchQuery = '';
  AppCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _blockedPackages = Set.from(widget.initialBlockedPackages);
  }

  @override
  Widget build(BuildContext context) {
    final filteredApps = widget.installedApps.where((app) {
      final matchesSearch = app.appName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == null || app.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Blocked Apps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppConstants.accent),
            tooltip: 'Save Selection',
            onPressed: () {
              widget.onSaveBlockedPackages(_blockedPackages);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search,
                    color: AppConstants.textSecondaryDark),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                ),
                ...AppCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name.toUpperCase()),
                      selected: isSelected,
                      onSelected: (_) => setState(
                          () => _selectedCategory = isSelected ? null : cat),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Selection Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: AppConstants.darkCard,
            child: Row(
              children: [
                Text(
                  '${_blockedPackages.length} Apps Selected to Block',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 13),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _blockedPackages.clear();
                    });
                  },
                  child:
                      const Text('Clear All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // App List
          Expanded(
            child: filteredApps.isEmpty
                ? const Center(
                    child: Text(
                      'No matching applications found',
                      style: TextStyle(color: AppConstants.textSecondaryDark),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredApps.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: AppConstants.darkBorder),
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      final isBlocked =
                          _blockedPackages.contains(app.packageName);

                      return CheckboxListTile(
                        value: isBlocked,
                        enabled: !app
                            .isEssential, // Essential apps cannot be blocked
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _blockedPackages.add(app.packageName);
                            } else {
                              _blockedPackages.remove(app.packageName);
                            }
                          });
                        },
                        title: Row(
                          children: [
                            Text(app.appName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            if (app.isEssential) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppConstants.accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ESSENTIAL',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppConstants.accent),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          app.packageName,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppConstants.textSecondaryDark),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppConstants.darkCard,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_getCategoryIcon(app.category),
                              size: 20, color: AppConstants.primaryLight),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(AppCategory category) {
    switch (category) {
      case AppCategory.social:
        return Icons.people_outline;
      case AppCategory.entertainment:
        return Icons.movie_outlined;
      case AppCategory.gaming:
        return Icons.sports_esports_outlined;
      case AppCategory.shopping:
        return Icons.shopping_bag_outlined;
      case AppCategory.news:
        return Icons.newspaper_outlined;
      case AppCategory.communication:
        return Icons.chat_bubble_outline;
      case AppCategory.productivity:
        return Icons.work_outline;
      case AppCategory.education:
        return Icons.school_outlined;
      case AppCategory.utility:
      case AppCategory.system:
        return Icons.build_outlined;
    }
  }
}
