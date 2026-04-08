# Chi Tiết Tính Năng Tìm Kiếm & Gợi Ý Món Ăn

## 1. ✅ COMPONENT ĐƯỢC TẠO

### A. Models (Mô hình dữ liệu)

#### `lib/models/voucher_model.dart`

- **Mục đích**: Định nghĩa cấu trúc dữ liệu Voucher/Mã giảm giá
- **Các trường chính**:
  - `code`: Mã voucher (VD: SUMMER40)
  - `discountPercent`: % giảm giá
  - `fixedDiscount`: Số tiền giảm cố định
  - `minOrderAmount`: Số tiền tối thiểu để sử dụng
  - `usageLimit`: Tổng hạn sử dụng
  - `currentUsage`: Đã sử dụng bao nhiêu
  - `expiryDate`: Ngày hết hạn
  - `applicableCategories`: Áp dụng cho loại món ăn nào
  - `createdBy`: Admin/Seller tạo voucher
  - `type`: PERCENTAGE hoặc FIXED
- **Methods**:
  - `toMap()`: Chuyển sang Firestore format
  - `fromMap()`: Tạo model từ Firestore
  - `canUse`: Kiểm tra voucher còn dùng được không

---

### B. Services (Dịch vụ xử lý logic)

#### `lib/services/food_service.dart` (Nâng cấp)

**Thêm các phương thức mới**:

1. **`fuzzySearchFoods(query, threshold)`** - Tìm kiếm gần đúng
   - Dùng Levenshtein distance algorithm
   - VD: "piza" → tìm cả "pizza"
   - Threshold = 2 (cho phép 2 ký tự sai)
   - Kết quả sắp xếp theo độ tương tự

2. **`getSearchSuggestions(query, limit)`** - Gợi ý tìm kiếm
   - Tự động hoàn thành khi gõ
   - Gợi ý theo tên món & danh mục
   - Sắp xếp theo thứ tự A-Z

3. **`getFoodsByPriceRange(minPrice, maxPrice)`** - Lọc theo giá
   - Tìm food trong khoảng giá nhất định
   - Có sẵn trong Firestore

4. **`getFoodsByRating(minRating)`** - Lọc theo đánh giá
   - Chỉ hiện food có rating ≥ minRating
   - Sắp xếp theo rating cao nhất

5. **`advancedSearch(query, category, minPrice, maxPrice, minRating)`**
   - Tìm kiếm kết hợp tất cả bộ lọc
   - Được sử dụng trong SearchScreen

**Helper Method**: `_levenshteinDistance()` - Tính độ khác biệt giữa 2 string

---

#### `lib/services/voucher_service.dart` (TẠO MỚI)

**Các chức năng**:

- `createVoucher()` - Tạo voucher mới (Admin/Seller)
- `getActiveVouchers()` - Lấy voucher còn hoạt động
- `getAllVouchersForAdmin()` - Admin xem toàn bộ
- `getSellerVouchers(sellerId)` - Seller xem của mình
- `getVouchersForCategory(category)` - Voucher cho danh mục
- `searchVoucherByCode(code)` - Tìm voucher bằng mã
- `applyVoucher(voucherId)` - Increment lượt sử dụng
- `updateVoucher()` - Cập nhật voucher
- `deleteVoucher()` - Xóa voucher
- `calculateDiscount()` - Tính số tiền giảm
- `getTopVouchers()` - Lấy voucher hot nhất

---

#### `lib/services/search_history_service.dart` (TẠO MỚI)

**Chức năng lưu lịch sử tìm kiếm (Local Storage)**:

- `addSearchQuery(query)` - Lưu search vào lịch sử
  - Tự động di chuyển lên đầu nếu đã tìm trước
  - Giữ max 20 items
- `getSearchHistory()` - Lấy toàn bộ lịch sử
- `removeSearchQuery(query)` - Xóa 1 search
- `clearSearchHistory()` - Xóa toàn bộ
- `getTrendingSearches()` - Top searches được tìm nhiều nhất

---

### C. Screens (Giao diện)

#### `lib/screens/search_screen.dart` (NÂNG CẤP)

**Các tính năng**:

1. **Search Bar**
   - Autocomplete bằng `getSearchSuggestions()`
   - Clear button để xóa text
   - Lưu search history lúc gửi

2. **Category Filters** (7 loại)
   - Tất cả, Food, Drink, Dessert, Healthy, Coffee, Snack
   - Lọc động theo category được chọn

3. **Bộ Lọc Nâng Cao** (Advanced Filters)
   - **Khoảng Giá**: Min - Max (đ)
   - **Đánh giá tối thiểu**: 1⭐ - 5⭐
   - Có thể bật/tắt bằng icon filter

4. **Search History** (Lịch sử tìm kiếm)
   - Hiển thị 20 search gần nhất
   - Click để tìm lại
   - Xóa từng item hoặc clear all

5. **Search Results**
   - Grid 2 cột
   - Hiện food name, rating, review count, giá
   - Empty state nếu không tìm thấy

6. **Tích hợp `advancedSearch()`**
   - Combine query + category + price + rating
   - Kết quả real-time

---

#### `lib/screens/admin/admin_voucher_screen.dart` (TẠO MỚI)

**Dành cho Admin (Quản trị viên)**

**Tính năng**:

- ➕ **Tạo Voucher**: Dialog form để tạo mã giảm giá mới
- 📋 **Danh sách Voucher**: Hiển thị toàn bộ vouchers
  - Hiển thị: Mã code, mô tả, % giảm
  - Status badge: "Hoạt động" / "Hết hạn"
  - Chi tiết: Đơn tối thiểu, lượt sử dụng, ngày hết hạn
- ✏️ **Sửa Voucher**: Edit form
  - Thay đổi % giảm, mô tả, ngày hết hạn, v.v
- 🗑️ **Xóa Voucher**: Confirm trước khi xóa

**Form Tạo/Sửa Include**:

- Mã voucher (bắt buộc)
- Mô tả
- % giảm
- Số tiền giảm tối đa
- Đơn tối thiểu
- Lượt sử dụng tối đa
- Ngày hết hạn (date picker)

---

#### `lib/screens/seller/seller_voucher_screen.dart` (TẠO MỚI)

**Dành cho Seller (Cửa hàng)**

**Tính năng**:

- ➕ **Tạo Voucher Cửa hàng**: Form đơn giản hơn admin
- 📊 **Thống kê Sử dụng**:
  - Lượt sử dụng: X/Y
  - Tỉ lệ sử dụng: X%
  - Progress bar color: Xanh (bình thường), Cam (>80%)
- ✏️ **Sửa Voucher**
- 🗑️ **Xóa Voucher**

**Khác với Admin**:

- Chỉ thấy vouchers của chính mình (`getSellerVouchers(sellerId)`)
- Form đơn giản hơn (không có maxDiscount field)
- Có progress bar theo dõi lượt sử dụng
- Có warning khi gần hết lượt

---

## 2. 🔄 LUỒNG HOẠT ĐỘNG

### A. Tìm Kiếm Thông Minh

```
User nhập text → SearchScreen.onChanged()
    ↓
Gợi ý popup (SearchSuggestions từ FoodService.getSearchSuggestions())
    ↓
User chọn category filter
    ↓
User bật Advanced Filters (price, rating)
    ↓
User nhấn Enter/Search → addSearchQuery() vào SearchHistoryService
    ↓
Gọi FoodService.advancedSearch(query, category, minPrice, maxPrice, minRating)
    ↓
Hiện kết quả grid 2 cột
```

### B. Lịch Sử Tìm Kiếm

```
Mỗi lần search → SearchHistoryService.addSearchQuery(query)
    ↓
Lưu vào SharedPreferences (local device storage)
    ↓
Khi mở SearchScreen trống → Hiện SearchHistory top items
    ↓
User click history item → Điền vào search box + tìm lại
    ↓
Có option "Xóa tất cả" hoặc xóa từng item
```

### C. Quản Lý Voucher - Admin

```
Admin vào AdminVoucherScreen
    ↓
Nhấn "+" → Mở form tạo voucher
    ↓
Điền: Code, %, min order, lượt sử dụng, ngày hết hạn
    ↓
Save → VoucherService.createVoucher()
    ↓
Lưu vào Firestore → Hiện trong danh sách
    ↓
Có option Edit hoặc Delete
```

### D. Quản Lý Voucher - Seller

```
Seller vào SellerVoucherScreen
    ↓
Nhấn "+" → Form tạo voucher (simplified)
    ↓
Điền: Code, %, min order, lượt sử dụng tối đa
    ↓
Save → VoucherService.createVoucher(createdBy: sellerId)
    ↓
Chỉ thấy vouchers của mình
    ↓
Có progress bar theo dõi lượt sử dụng
    ↓
Edit/Delete
```

---

## 3. 📊 DATABASE FIRESTORE STRUCTURE

### Collection: `foods`

```json
{
  "id": "doc1",
  "name": "Pizza Thịt Nguội",
  "category": "Food",
  "price": 89000,
  "description": "Pizza...",
  "imageUrl": "https://...",
  "rating": 4.5,
  "reviewCount": 125,
  "available": true,
  "createdAt": Timestamp
}
```

### Collection: `vouchers`

```json
{
  "id": "doc2",
  "code": "SUMMER40",
  "description": "Giảm 40% tất cả food",
  "discountPercent": 40,
  "type": "PERCENTAGE",
  "minOrderAmount": 100000,
  "usageLimit": 500,
  "currentUsage": 145,
  "maxDiscountAmount": 50000,
  "expiryDate": Timestamp,
  "isActive": true,
  "createdBy": "admin_id_123",
  "createdAt": Timestamp,
  "applicableCategories": ["Food", "Drink"]
}
```

---

## 4. 🎯 CÁCH SỬ DỤNG

### Integrasi trong App

**Trong HomeTab hoặc Main Navigation:**

```dart
// Mở SearchScreen
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const SearchScreen(),
));

// Mở Admin Voucher Screen
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const AdminVoucherScreen(),
));

// Mở Seller Voucher Screen
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const SellerVoucherScreen(),
));
```

---

## 5. ✨ TÍNH NĂNG NỔI BẬT

| Tính năng              | Mô tả                       | Công nghệ                 |
| ---------------------- | --------------------------- | ------------------------- |
| **Fuzzy Search**       | Tìm gần đúng (pizza → piza) | Levenshtein distance      |
| **Search Suggestions** | Autocomplete khi gõ         | Firestore query           |
| **Search History**     | Lưu lịch sử tìm             | SharedPreferences         |
| **Advanced Filters**   | Lọc theo giá + rating       | Client-side filtering     |
| **Voucher Management** | Tạo/sửa/xóa mã giảm giá     | Firestore CRUD            |
| **Role-based Access**  | Admin vs Seller screens     | Firebase Auth + createdBy |
| **Usage Tracking**     | Theo dõi lượt sử dụng       | Progress bar + stats      |

---

## 6. 📱 FILE ĐƯỢC TẠO/CẬP NHẬT

### Tạo mới:

- ✅ `lib/models/voucher_model.dart`
- ✅ `lib/services/voucher_service.dart`
- ✅ `lib/services/search_history_service.dart`
- ✅ `lib/screens/admin/admin_voucher_screen.dart`
- ✅ `lib/screens/seller/seller_voucher_screen.dart`

### Nâng cấp:

- ✅ `lib/services/food_service.dart` (+5 methods)
- ✅ `lib/screens/search_screen.dart` (add history + advanced filters)
- ✅ `pubspec.yaml` (thêm shared_preferences dependency)

---

## 7. 🧪 TEST CHECKLIST

- [ ] SearchScreen load without errors
- [ ] Advanced filters (price, rating) work correctly
- [ ] Search history saves and displays
- [ ] Clear history button works
- [ ] Admin Voucher Screen shows all vouchers
- [ ] Seller Voucher Screen shows only seller's vouchers
- [ ] Create new voucher saves to Firestore
- [ ] Edit voucher updates in Firestore
- [ ] Delete voucher removes from Firestore
- [ ] Fuzzy search finds approximate matches

---

## 8. 🚀 READY TO RUN

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

**All files compile without errors!** ✅
