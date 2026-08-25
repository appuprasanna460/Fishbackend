import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_sizes.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String route;

  const NavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.route,
  });
}

class AppRoleNavBar extends StatelessWidget {
  final int currentIndex;
  final String role;
  final void Function(int index) onTap;

  const AppRoleNavBar({
    super.key,
    required this.currentIndex,
    required this.role,
    required this.onTap,
  });

  List<NavItem> _getItems() {
    if (role == 'SUPER_ADMIN') {
      return const [
        NavItem(label: 'Home', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, route: ''),
        NavItem(label: 'Users', icon: Icons.people_outline, activeIcon: Icons.people, route: ''),
        NavItem(label: 'Boats', icon: Icons.directions_boat_outlined, activeIcon: Icons.directions_boat, route: ''),
        NavItem(label: 'Reports', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, route: ''),
        NavItem(label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person, route: ''),
      ];
    } else if (role == 'COMMISSION_AGENT') {
      return const [
        NavItem(label: 'Home', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, route: ''),
        NavItem(label: 'Bills', icon: Icons.receipt_outlined, activeIcon: Icons.receipt, route: ''),
        NavItem(label: 'Fish', icon: Icons.set_meal_outlined, activeIcon: Icons.set_meal, route: ''),
        NavItem(label: 'Track', icon: Icons.map_outlined, activeIcon: Icons.map, route: ''),
        NavItem(label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person, route: ''),
      ];
    } else {
      return const [
        NavItem(label: 'Home', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, route: ''),
        NavItem(label: 'Invoices', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, route: ''),
        NavItem(label: 'Ledger', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, route: ''),
        NavItem(label: 'Track', icon: Icons.map_outlined, activeIcon: Icons.map, route: ''),
        NavItem(label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person, route: ''),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItems();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p8,
            vertical: AppSizes.p8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;
              return _NavBarItem(
                item: item,
                isSelected: isSelected,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    if (widget.isSelected) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p12,
                vertical: AppSizes.p6,
              ),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.primarySurface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.radius24),
              ),
              child: Icon(
                widget.isSelected
                    ? (widget.item.activeIcon ?? widget.item.icon)
                    : widget.item.icon,
                size: 22,
                color: widget.isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.labelSmall.copyWith(
                color: widget.isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}
