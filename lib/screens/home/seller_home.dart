import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.amber,
              child: Icon(Icons.storefront, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('Shop Owner Dashboard',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Manage your inventory and sales',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 32),
            _buildFeatureCard(
              context,
              'Manage Products',
              'Update stock and prices',
              Icons.inventory_2_outlined,
              Colors.amber,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Recent Sales',
              'Check orders and performance',
              Icons.trending_up,
              AppTheme.accentColor,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Store Analytics',
              'Detailed insights into your business',
              Icons.analytics_outlined,
              Colors.cyanAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: AppTheme.textSecondary, size: 16),
        ],
      ),
    );
  }
}
