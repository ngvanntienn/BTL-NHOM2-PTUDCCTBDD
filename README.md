# FoodExpress - BTL NHOM2 PTUDCCTBDD

Ung dung dat do an xay dung bang Flutter + Firebase.
Tai lieu nay duoc cap nhat de:

- Tong hop day du pham vi tinh nang da lam.
- Mo ta kien truc Flutter + Firebase va thiet ke Firestore.
- Huong dan setup moi truong de clone ve chay on dinh, han che loi.
- Lien ket cac chuong bao cao 1, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, ket luan.

## 1) Tong quan tinh nang he thong

### Nhom Seller

- Seller Dashboard quan ly thong tin cua hang va thong ke co ban.
- Add/Edit Food Screen va CRUD mon an (them, sua, xoa).
- Upload anh mon an qua Cloudinary, fallback sang Firebase Storage.
- Quan ly don hang theo trang thai: pending, accepted, preparing, shipping, delivered, rejected, cancelled.
- Tu dong an mon het hang theo ton kho/trang thai kha dung.
- Xu ly du lieu realtime Firestore cho mon an va don hang.
- Phong van seller moi, xep hang seller, tinh thuong doanh thu ngay/tuan/thang.
- Chinh sua thong tin seller.

### Nhom User

- Login, Register, Home, Cart, Checkout, Notification, Profile.
- Danh muc mon an, Food Detail, Search, Recommended, Favorites.
- Gio hang: them/xoa/cap nhat so luong.
- Tao don hang va luu lien ket user-order trong Firestore.
- Quan ly dia chi: them/sua/xoa.
- Nhan thong bao khi trang thai don hang thay doi.
- Danh gia mon an (them/sua/xoa/hien thi), sap xep theo rating 4 sao den 1 sao.
- Search thong minh: suggestion, gan dung, bo loc nang cao (gia/rating/category).
- Search History va Chat History (luu/xem/xoa).
- Voucher phia seller/user: them/sua/xoa va ap dung.

### Nhom AI Chatbot

- Chatbot ho tro tim mon bang ngon ngu tu nhien.
- Goi y combo mon an dua tren du lieu thuc te.
- Tich hop webhook n8n va fallback OpenAI-compatible.
- Luu lich su chat len Firestore va thao tac quan ly lich su.

### Nhom Admin

- Admin Dashboard.
- Quan ly tai khoan nguoi dung: them/sua/xoa/vo hieu hoa.
- Quan ly danh muc mon an: CRUD + upload anh + dong bo Firestore realtime.
- Quan ly cua hang seller: duyet, kich hoat/khoa.
- Thong ke he thong: tong don, doanh thu, nguoi dung active.

## 2) Kien truc Flutter + Firebase

He thong duoc to chuc theo cac lop chinh:

- Presentation: Screen/Widget cho user, seller, admin.
- State management: Provider cho User, Cart, Favorites, Category, Notification, Voucher.
- Data access: Service/Repository lam viec voi Firebase Auth, Firestore, Storage, Cloud Functions.
- Domain model: Model cho user, food, order, category, review, favorite, voucher.

Luong du lieu tong quat:

1. UI goi Provider/Service.
2. Service thao tac Firebase (Auth/Firestore/Storage/Functions).
3. Firestore stream tra ve du lieu realtime.
4. Provider notifyListeners cap nhat UI.

## 3) Thiet ke Firestore

Collection chinh:

- users
- foods
- orders
- categories
- reviews
- favorites
- seller_interview_attempts
- seller_rewards

Trang thai don hang chuan hoa:

- pending
- accepted
- preparing
- shipping
- delivered
- rejected
- cancelled

Lien ket du lieu:

- users(1) - orders(n) qua truong userId.
- seller(users role=seller)(1) - foods(n) qua truong sellerId.
- categories(1) - foods(n) qua truong categoryId.
- foods(1) - reviews(n) qua truong foodId.
- users(1) - favorites(n) qua truong userId.

Ghi chu:

- So luong mon theo danh muc duoc dong bo theo du lieu foods de tranh lech counter.
- Cac man hinh quan trong dung stream realtime de giam do tre cap nhat.

## 4) Dieu huong ung dung va Widget Tree

Du an su dung Navigator voi named routes cho cac man hinh chinh:

- /
- /login
- /register
- /user-home
- /seller-home
- /admin-home
- /chatbot
- /category
- /food-detail
- /favorites
- /voucher
- /order-history
- /edit-profile

Widget tree duoc tach theo module user/seller/admin giup de mo rong va de test.

## 5) Tai lieu bao cao

Noi dung bao cao duoc tach theo file trong thu muc docs/report:

- [docs/report/CHAPTER_1_INTRO.md](docs/report/CHAPTER_1_INTRO.md)
- [docs/report/SECTION_2_3_USECASE.md](docs/report/SECTION_2_3_USECASE.md)
- [docs/report/SECTION_2_4_NAVIGATION_WIDGET_TREE.md](docs/report/SECTION_2_4_NAVIGATION_WIDGET_TREE.md)
- [docs/report/SECTION_2_5_DATABASE.md](docs/report/SECTION_2_5_DATABASE.md)
- [docs/report/SECTION_3_1_LOGIC.md](docs/report/SECTION_3_1_LOGIC.md)
- [docs/report/SECTION_3_2_UI_GALLERY.md](docs/report/SECTION_3_2_UI_GALLERY.md)
- [docs/report/SECTION_3_3_RESPONSIVE.md](docs/report/SECTION_3_3_RESPONSIVE.md)
- [docs/report/CONCLUSION_AND_REFERENCES.md](docs/report/CONCLUSION_AND_REFERENCES.md)

## 6) Yeu cau moi truong de clone va chay on dinh

Toi thieu:

- Flutter SDK 3.41.x hoac moi hon.
- Dart SDK 3.11.x (di kem Flutter tren).
- Android Studio (SDK + Emulator + cmdline tools).
- JDK 17+ (khuyen nghi JDK bundled cua Android Studio).
- Chrome/Edge neu chay Web.
- Firebase CLI + FlutterFire CLI neu can doi project Firebase.

Windows bat buoc:

- Bat Developer Mode de cho phep symlink plugin.

```powershell
start ms-settings:developers
```

## 7) Setup nhanh sau khi clone

```bash
git clone <repo-url>
cd BTL-NHOM2-PTUDCCTBDD
flutter doctor -v
flutter pub get
flutter run -d emulator-5554
```

Neu chay web:

```bash
flutter run -d chrome
```

## 8) Cau hinh Firebase dung cho clone moi

Du an dang su dung:

- lib/firebase_options.dart
- android/app/google-services.json

Neu doi sang Firebase project rieng:

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

Google Sign-In loi code 10:

- Xem huong dan chi tiet tai [FIREBASE_GOOGLE_FIX_GUIDE.md](FIREBASE_GOOGLE_FIX_GUIDE.md)

## 9) Bien moi truong runtime (chatbot + image upload)

Du an su dung dart-define cho chatbot va Cloudinary.

Gia tri co the cau hinh khi run:

- N8N_CHATBOT_WEBHOOK
- OPENAI_API_KEY
- OPENAI_MODEL
- OPENAI_BASE_URL
- CLOUDINARY_CLOUD_NAME
- CLOUDINARY_UPLOAD_PRESET
- CLOUDINARY_FOLDER

Vi du:

```bash
flutter run -d chrome \
	--dart-define=N8N_CHATBOT_WEBHOOK=https://your-n8n-webhook \
	--dart-define=OPENAI_API_KEY=your_key \
	--dart-define=OPENAI_MODEL=gpt-4o-mini \
	--dart-define=OPENAI_BASE_URL=https://api.openai.com/v1 \
	--dart-define=CLOUDINARY_CLOUD_NAME=your_cloud \
	--dart-define=CLOUDINARY_UPLOAD_PRESET=your_preset \
	--dart-define=CLOUDINARY_FOLDER=foodexpress
```

Neu khong cau hinh Cloudinary, he thong se fallback sang Firebase Storage.

## 10) Android build note quan trong

Plugin thong bao can core library desugaring. Cau hinh da duoc bat san trong:

- android/app/build.gradle.kts

Khong can sua them khi clone moi (chi can flutter pub get va run).

## 11) Kiem thu va kiem soat chat luong

Lenh can chay truoc khi merge:

```bash
flutter analyze
flutter test
```

Kiem tra phien ban package:

```bash
flutter pub outdated
```

## 12) Troubleshooting de clone khong vo loi

1. Loi symlink plugin tren Windows

- Nguyen nhan: chua bat Developer Mode.
- Cach sua: bat Developer Mode, sau do flutter pub get lai.

2. Emulator khong vao duoc Firestore (UnknownHost firestore.googleapis.com)

- Nguyen nhan: DNS/Private DNS tren may ao loi.
- Cach sua nhanh tren emulator:

```bash
adb -s emulator-5554 shell settings put global private_dns_mode off
adb -s emulator-5554 shell settings put global private_dns_specifier ""
adb -s emulator-5554 shell svc wifi disable
adb -s emulator-5554 shell svc wifi enable
```

3. Build cache loi sau khi doi nhanh nhieu branch

```bash
flutter clean
flutter pub get
flutter run
```

4. Firebase Functions deploy that bai tren Spark

- Mot so callable yeu cau goi dich vu bi gioi han boi goi Spark.
- Neu can deploy full backend, nang cap Blaze hoac dung local emulator cho test.

## 13) Quy tac commit de nguoi clone sau khong loi

- Khong commit file local/generated:
	- .dart_tool/
	- build/
	- android/local.properties
	- ios/Flutter/Generated.xcconfig
	- ios/Flutter/flutter_export_environment.sh
	- */Flutter/ephemeral/
- Neu lo commit, bo tracking truoc khi merge.

## 14) Tom tat

README nay da tong hop:

- Seller Dashboard, Add/Edit Food, Order Management.
- Kien truc Flutter + Firebase va Firestore schema.
- CRUD mon an, upload anh, xu ly don hang realtime.
- Usecase, Database, Navigation Flow, Widget Tree, Logic, UI Gallery, Responsive, ket luan.
- Setup clone, bien moi truong, troubleshooting de giam toi da loi khi chay.
