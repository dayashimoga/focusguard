import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Navigation destination model for adaptive navigation.
class AdaptiveDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Responsive scaffold providing bottom navigation on phones and side rail navigation on tablets/foldables.
class AdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveDestination> destinations;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 720;

    if (isTablet) {
      return Scaffold(
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppConstants.darkSurface,
              selectedIconTheme:
                  const IconThemeData(color: AppConstants.primary),
              unselectedIconTheme:
                  const IconThemeData(color: AppConstants.textSecondaryDark),
              selectedLabelTextStyle: const TextStyle(
                color: AppConstants.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AppConstants.textSecondaryDark,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              destinations: destinations.map((d) {
                return NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(
                width: 1, thickness: 1, color: AppConstants.darkBorder),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: AppConstants.darkSurface,
        indicatorColor: AppConstants.primary.withOpacity(0.2),
        destinations: destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon, color: AppConstants.textSecondaryDark),
            selectedIcon: Icon(d.selectedIcon, color: AppConstants.primary),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }
}
