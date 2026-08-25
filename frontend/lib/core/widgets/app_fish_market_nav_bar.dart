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

class FishMarketNavBar extends StatelessWidget {
  final int currentIndex;
  final String role;
  final void Function(int index) onTap;
  final VoidCallback? onBillTap;

  const FishMarketNavBar({
    super.key,
    required this.currentIndex,
    required this.role,
    required this.onTap,
    this.onBillTap,
  });

  List<NavItem> _getItems() {
    switch (role) {
      case 'SUPER_ADMIN':
        return [
          NavItem(
            label: 'Dashboard',
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            route: '/admin/dashboard',
          ),
          NavItem(
            label: 'Harbours',
            icon: Icons.anchor_rounded,
            activeIcon: Icons.anchor_rounded,
            route: '/admin/harbours',
          ),
          NavItem(
            label: 'Users',
            icon: Icons.people_outlined,
            activeIcon: Icons.people,
            route: '/admin/users',
          ),
          NavItem(
            label: 'Packages',
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2_rounded,
            route: '/admin/packages',
          ),
          NavItem(
            label: 'More',
            icon: Icons.more_horiz_rounded,
            activeIcon: Icons.more_horiz_rounded,
            route: '/admin/more',
          ),
        ];
      case 'COMMISSION_AGENT':
        return const [
          NavItem(
            label: 'Home',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            route: '/agent/dashboard',
          ),
          NavItem(
            label: 'Boats',
            icon: Icons.directions_boat_outlined,
            activeIcon: Icons.directions_boat,
            route: '/agent/boats',
          ),
          NavItem(
            label: 'Bill',
            icon: Icons.receipt,
            activeIcon: Icons.receipt,
            route: '/agent/billing',
          ),
          NavItem(
            label: 'Tracking',
            icon: Icons.track_changes_outlined,
            activeIcon: Icons.track_changes,
            route: '/agent/tracking',
          ),
          NavItem(
            label: 'Profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            route: '/agent/profile',
          ),
        ];
      case 'BOAT_OWNER':
        return const [
          NavItem(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            route: '/owner/dashboard',
          ),
          NavItem(
            label: 'Voyages',
            icon: Icons.directions_boat_outlined,
            activeIcon: Icons.directions_boat,
            route: '/owner/voyages',
          ),
          NavItem(
            label: 'Fishing',
            icon: Icons.set_meal_outlined,
            activeIcon: Icons.set_meal,
            route: '/owner/fishing',
          ),
          NavItem(
            label: 'Financial',
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            route: '/owner/financial',
          ),
          NavItem(
            label: 'Menu',
            icon: Icons.menu,
            activeIcon: Icons.menu,
            route: '/owner/menu',
          ),
        ];
      case 'FISH_BUYER':
        return const [
          NavItem(
            label: 'Home',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            route: '/buyer/dashboard',
          ),
          NavItem(
            label: 'Fish',
            icon: Icons.set_meal_outlined,
            activeIcon: Icons.set_meal,
            route: '/buyer/fish-manage',
          ),
          NavItem(
            label: 'Bill',
            icon: Icons.receipt,
            activeIcon: Icons.receipt,
            route: '/buyer/bills',
          ),
          NavItem(
            label: 'Profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            route: '/buyer/profile',
          ),
        ];
      case 'STAFF':
        return const [
          NavItem(
            label: 'Home',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            route: '/staff/dashboard',
          ),
          NavItem(
            label: 'New Bill',
            icon: Icons.receipt,
            activeIcon: Icons.receipt,
            route: '/staff/billing',
          ),
          NavItem(
            label: 'Profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            route: '/staff/profile',
          ),
        ];
      default:
        return const [
          NavItem(
            label: 'Home',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            route: '/staff/dashboard',
          ),
          NavItem(
            label: 'New Bill',
            icon: Icons.receipt,
            activeIcon: Icons.receipt,
            route: '/staff/bills',
          ),
          NavItem(
            label: 'Profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            route: '/staff/profile',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItems();
    final centerFabIndex = role == 'STAFF' ? 1 : 2;

    final hasCenterBillFab = role == 'COMMISSION_AGENT' || role == 'STAFF';
    return Container(
      margin: const EdgeInsets.only(
        left: AppSizes.p12,
        right: AppSizes.p12,
        bottom: AppSizes.p12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.border.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p6,
            vertical: AppSizes.p6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isCenterBill = hasCenterBillFab && index == centerFabIndex;
              final isSelected = currentIndex == index;

              if (isCenterBill) {
                return _BillFab(
                  onTap: onBillTap ?? () => onTap(centerFabIndex),
                  isSelected: isSelected,
                );
              }

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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
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
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
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
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
              child: Text(widget.item.label),
            ),
            const SizedBox(height: 3),
            // Active indicator dot beneath the label
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: widget.isSelected ? 6 : 0,
              height: widget.isSelected ? 6 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillFab extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSelected;

  const _BillFab({required this.onTap, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
