import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar Header with Logo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fastfood, color: AppTheme.primaryColor, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'FoodExpress',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: AppTheme.textPrimary, size: 28),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),

            // Location Selector
            Row(
              children: const [
                Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 4),
                Text('Giao đến:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                SizedBox(width: 4),
                Text('Chọn vị trí hiện tại', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar Placeholder
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                children: const [
                   Icon(Icons.search, color: AppTheme.textSecondary),
                   SizedBox(width: 8),
                   Text('Tìm món ăn, quán ăn...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Banners Carousel Placeholder
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Trống quảng cáo / Sự kiện', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Categories Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Danh Mục', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('Xem tất cả', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16, 
              runSpacing: 16, 
              alignment: WrapAlignment.start,
              children: [
                _buildEmptyCategory(),
                _buildEmptyCategory(),
                _buildEmptyCategory(),
                _buildEmptyCategory(),
              ],
            ),
            const SizedBox(height: 32),

            // Trending Placeholder
            const Text('Xu Hướng Mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: const Text('Đang tải...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // AI Suggestion Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 10)]
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy, color: AppTheme.primaryColor, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Trợ lý AI Gợi ý món', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Bấm vào biểu tượng Robot nổi ở dưới cùng để AI đưa ra những gợi ý phù hợp nhất.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 100), // padding bottom for fab
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCategory() {
    return SizedBox(
      width: 70, 
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: const Icon(Icons.category, color: Colors.grey, size: 24),
          ),
          const SizedBox(height: 8),
          const Text('Đang tải', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
