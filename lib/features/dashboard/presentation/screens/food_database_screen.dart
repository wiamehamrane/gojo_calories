import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class FoodDatabaseScreen extends StatelessWidget {
  const FoodDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Food Database", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          Padding(
             padding: const EdgeInsets.all(16.0),
             child: Container(
               decoration: BoxDecoration(
                 color: AppColors.surface,
                 borderRadius: BorderRadius.circular(999),
                 border: Border.all(color: AppColors.border),
               ),
               padding: const EdgeInsets.symmetric(horizontal: 16),
               child: const TextField(
                 decoration: InputDecoration(
                   icon: Icon(LucideIcons.search, color: AppColors.textSecondary, size: 20),
                   hintText: 'Search nutritional database...',
                   hintStyle: TextStyle(color: AppColors.textPlaceholder),
                   border: InputBorder.none,
                 ),
               ),
             ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.database, size: 48, color: AppColors.inactive),
                  const SizedBox(height: 24),
                  const Text(
                    "Search USDA Database",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Type above to query millions of global foods safely.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
