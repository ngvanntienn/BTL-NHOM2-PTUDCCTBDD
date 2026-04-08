# Hướng Dẫn Khắc Phục Lỗi Firebase Google Sign-In (Error Code 10)

## 🔴 Nguyên Nhân Lỗi

- SHA-1 fingerprint chưa được đăng ký trong Firebase Console
- OAuth 2.0 consent screen chưa được cấu hình
- Package name hoặc OAuth credentials không khớp

---

## ✅ BƯỚC 1: Lấy SHA-1 Fingerprint

### Cách 1: Sử dụng Flutter cli (Khuyến Khích)

```bash
cd d:\baicuoiky\BTL-NHOM2-PTUDCCTBDD
flutter run
```

Khi ứng dụng khởi chạy, hãy kiểm tra Logcat hoặc đầu ra console, tìm dòng:

```
D/GoogleSignIn: SHA-1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

### Cách 2: Sử dụng Gradle signingReport (Cần set JAVA_HOME)

1. Tìm đường dẫn Java:
   - Tìm kiếm "jdk" hoặc "java" trên máy (nếu cài Android Studio)
   - Thường ở: `C:\Program Files\Java\jdk-17.0.x` hoặc trong Android Studio folder

2. Set JAVA_HOME và chạy:

```powershell
$env:JAVA_HOME="C:\Program Files\Java\jdk-17"  # Thay đúng đường dẫn
cd d:\baicuoiky\BTL-NHOM2-PTUDCCTBDD\android
.\gradlew signingReport
```

### Cách 3: Sử dụng keytool trực tiếp

```bash
# Tìm keytool trong JDK installation
"C:\Program Files\Java\jdk-17\bin\keytool" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Kết quả sẽ giống như:**

```
Certificate fingerprints:
     SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```

---

## ✅ BƯỚC 2: Đăng Ký SHA-1 trong Firebase Console

1. Truy cập: https://console.firebase.google.com/

2. Chọn project **"btl-nhom2-ptudcctbdd"**

3. Vào **Settings** (⚙️ icon) → **Project Settings**

4. Tab **Android apps** → Tìm app `com.example.btl_nhom2_ptudcctbdd`

5. Scroll down tìm **"SHA-1 certificate fingerprints"**

6. Click **"Add fingerprint"** → Dán SHA-1 mà bạn lấy được từ trên

7. Click **"Save"**

8. Download **google-services.json** lại (nếu cần)

---

## ✅ BƯỚC 3: Cấu Hình OAuth Consent Screen

1. Truy cập: https://console.cloud.google.com/

2. Chọn project **"btl-nhom2-ptudcctbdd"**

3. Vào **APIs & Services** → **OAuth 2.0 Consent Screen** (bên trái)

4. Nếu là **External** app:
   - Click **"EDIT APP"**
   - Scroll xuống **"Authorized domains"**
   - Thêm: `firebaseapp.com` (nếu chưa có)
   - Click **"Save and Continue"**

5. Nếu chưa có OAuth client:
   - Vào **Credentials**
   - Click **"Create Credentials"** → **OAuth 2.0 Client ID**
   - Chọn **"Android"**
   - Điền:
     - Package name: `com.example.btl_nhom2_ptudcctbdd`
     - SHA-1: (SHA-1 bạn vừa lấy)
   - Click **"Create"**

---

## ✅ BƯỚC 4: Kiểm Tra Code (AndroidManifest.xml)

Đảm bảo file `android/app/src/main/AndroidManifest.xml` có:

```xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:label="FoodExpress"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

---

## ✅ BƯỚC 5: Build lại ứng dụng

```bash
cd d:\baicuoiky\BTL-NHOM2-PTUDCCTBDD
flutter clean
flutter pub get
flutter run
```

---

## 🆘 Nếu Vẫn Lỗi

Thử các giải pháp:

### 1️⃣ Xóa & Tạo lại OAuth Client

- Vào Cloud Console → Credentials
- Xóa OAuth client cũ
- Tạo mới với SHA-1 chính xác

### 2️⃣ Chắc chắn Package Name đúng

```dart
// Kiểm tra via:
// android/app/build.gradle.kts → applicationId
// Phải là: com.example.btl_nhom2_ptudcctbdd
```

### 3️⃣ Xóa Debug Keystore

```bash
# Xóa keystore cũ để tạo mới
rm "%USERPROFILE%\.android\debug.keystore"

# Flutter sẽ tạo lại nó
flutter run
```

### 4️⃣ Firebase Emulator (Test Local)

```bash
firebase login
firebase emulators:start --only=auth
```

### 5️⃣ Enable Google Sign-In API

- Vào: https://console.cloud.google.com/apis/dashboard
- Tìm **"Google+ API"**
- Click **"Enable"**

---

## ✅ Công Thức Tóm Tắt

| Bước | Hành Động                            |
| ---- | ------------------------------------ |
| 1    | Lấy SHA-1 fingerprint                |
| 2    | Đăng ký SHA-1 trong Firebase Console |
| 3    | Cấu hình OAuth Consent Screen        |
| 4    | Kiểm tra AndroidManifest.xml         |
| 5    | `flutter clean` → `flutter run`      |

---

## 📝 Thông Tin Project Hiện Tại

- **Package Name**: `com.example.btl_nhom2_ptudcctbdd`
- **Firebase Project**: `btl-nhom2-ptudcctbdd`
- **OAuth Client ID**: `569977301187-m57rdt43q24oqj4nmgqjdmf2isjua3cq.apps.googleusercontent.com`
- **API Key**: `AIzaSyCPmOEyTIPgmo9mHeG9WWx6ccQ0jrdtlyU`

---

**Sau khi hoàn thành các bước trên, đăng nhập Google sẽ thành công! 🎉**
