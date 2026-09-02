import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StitchBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const StitchBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -1))],
        border: Border(top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.2))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(index: 0, icon: Icons.dashboard_rounded, label: 'Home', isActive: currentIndex == 0),
              // _item(index: 1, icon: Icons.history_rounded, label: 'History', isActive: currentIndex == 1),
              // _item(index: 2, icon: Icons.person_rounded, label: 'Profile', isActive: currentIndex == 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({required int index, required IconData icon, required String label, required bool isActive}) {
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: isActive ? AppColors.secondary : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
