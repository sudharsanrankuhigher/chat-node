# Flutter Chat App

This Flutter client connects to the existing Node.js Socket.IO backend in this repository.

## Before running

1. Replace `http://YOUR_IP:5000` in `lib/app/app_constants.dart` with your backend IP.
2. Run `flutter pub get`.
3. If you want native platform folders generated in your local environment, run:

```bash
flutter create .
```

That command will generate `android/`, `ios/`, `web/`, `linux/`, `macos/`, and `windows/` around the provided source files without changing the app logic.
