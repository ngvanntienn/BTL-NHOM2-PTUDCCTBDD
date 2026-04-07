# BTL NHOM2 PTUDCCTBDD

Ung dung Flutter/Firebase cho bai tap lon mon PTUDCCTBDD.

## Yeu cau moi truong

- Flutter SDK 3.10.x tro len
- Dart SDK theo Flutter
- Android Studio hoac VS Code
- Trinh duyet Chrome (neu chay web)
- Tai khoan Firebase (neu muon cau hinh project rieng)

Luu y Windows (bat buoc voi project co plugin):

- Bat Developer Mode de Flutter tao symbolic links khi `flutter pub get`.
- Mo nhanh Settings bang lenh:

```powershell
start ms-settings:developers
```

- Sau do bat `Developer Mode` roi chay lai `flutter pub get`.

Kiem tra moi truong:

```bash
flutter doctor -v
```

## Clone va chay du an

```bash
git clone <repo-url>
cd BTL-NHOM2-PTUDCCTBDD
flutter pub get
flutter run
```

Neu `flutter pub get` bao loi `Building with plugins requires symlink support`,
hay bat `Developer Mode` nhu huong dan tren roi chay lai.

## Cau hinh Firebase

Du an hien da co:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Neu ban su dung dung Firebase project hien tai cua nhom, co the chay ngay tren Android/Web.

Neu ban muon dung Firebase project cua rieng ban:

1. Cai FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

2. Dang nhap Firebase:

```bash
firebase login
```

3. Cau hinh lai:

```bash
flutterfire configure
```

Lenh tren se cap nhat lai `lib/firebase_options.dart` va cac file platform can thiet.

## File khong nen commit

Repo da ignore cac file sinh tu dong va local machine config, vi du:

- `.dart_tool/`
- `build/`
- `android/local.properties`
- `ios/Flutter/Generated.xcconfig`
- `ios/Flutter/flutter_export_environment.sh`
- `*/Flutter/ephemeral/`

Neu lo commit nham file local/generated, bo tracking bang:

```bash
git rm -r --cached .dart_tool build android/local.properties ios/Flutter/Generated.xcconfig ios/Flutter/flutter_export_environment.sh
git commit -m "chore: remove generated/local files from git tracking"
```

## Lenh huu ich

Phan tich loi:

```bash
flutter analyze
```

Chay test:

```bash
flutter test
```

Neu gap loi cache sau khi clone:

```bash
flutter clean
flutter pub get
```

## Luu y de tranh loi khi nguoi khac clone

- Khong sua tay file trong `.dart_tool/`, `build/`, `ephemeral/`.
- Chi commit source code trong `lib/`, cau hinh du an va tai lieu.
- Neu doi Firebase project, can thong bao ca nhom va cap nhat huong dan trong README.
