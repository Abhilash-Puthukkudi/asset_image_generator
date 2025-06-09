
# Asset Image Generator for Flutter

[![Pub Version](https://img.shields.io/pub/v/asset_image_generator)](https://pub.dev/packages/asset_image_generator)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://github.com/Abhilash-Puthukkudi/asset_image_generator/actions/workflows/dart.yml/badge.svg)](https://github.com/Abhilash-Puthukkudi/asset_image_generator/actions)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/Abhilash-Puthukkudi/asset_image_generator/pulls)

A Flutter plugin that automatically generates type-safe Dart references for all your asset images — **now with folder-based class generation in `v3.1.0`**.

---

## 🎉 What's New in v3.1.1

- 📂 Generates **separate Dart files** for each asset folder
- 🔠 Class names based on folder structure (e.g., `IconsImages`, `BackgroundsImages`)
- 📛 Variables for both full paths and image names: `home` and `homeName`




---

## ✨ Features

- 🔍 Scans `pubspec.yaml` for asset paths automatically
- 🏗 Generates clean, type-safe Dart constants
- 🖼 Supports PNG, JPG, JPEG, GIF, BMP, WEBP, and SVG formats
- 🔠 Converts filenames to consistent camelCase variables
- 📁 Works across Windows, macOS, and Linux
- 📊 Lists all assets and names for dynamic use
- ⚙️ Customizable output location
- 🧩 Folder-based organization with tree-shakable structure

---

## 🚀 Installation

Add to your project's `pubspec.yaml` under `dev_dependencies`:

```yaml
dev_dependencies:
  asset_image_generator: ^3.1.1
```

Then run:

```bash
flutter pub get
```

---

## ⚙️ Usage

### 🔧 Command Line

From your project root:

```bash
flutter pub run asset_image_generator:generate_images
```

---

### 🧑‍💻 Programmatic Usage

```dart
import 'package:asset_image_generator/asset_image_generator.dart';

void main() async {
  await AssetImageGenerator().generate();

  // OR with custom output path
  // await AssetImageGenerator().generate(
  //   outputPath: 'lib/generated/images/'
  // );
}
```

---

## 📁 Example Output Structure

```
lib/generated/images/
├── images.dart              # Main export file
├── app_images.dart          # Root level images
├── icons_images.dart        # From assets/icons/
├── backgrounds_images.dart  # From assets/backgrounds/
```

---

## 🔍 Accessing Assets

### Option 1: Through `Images` main class

```dart
import 'package:your_app/generated/images/images.dart';

Image.asset(Images.icons.home);             // Full path
print(Images.icons.homeName);               // Just the name
```

### Option 2: Direct import from specific class

```dart
import 'package:your_app/generated/images/icons_images.dart';

Image.asset(IconsImages.home);
print(IconsImages.getPathByName('home'));
```

---

## ✅ Configuration

Ensure your `pubspec.yaml` has proper asset declarations:

```yaml
flutter:
  assets:
    - assets/icons/
    - assets/images/
    - assets/backgrounds/
```

---

## 🛠 Best Practices

- ✅ Add this to your CI build process
- ✅ Commit generated files to version control
- 🔁 Regenerate assets after adding new files
- 🧹 Keep assets organized in folders

---

## 📄 Supported Extensions

- `.png`, `.jpg`, `.jpeg`, `.gif`, `.bmp`, `.webp`, `.svg`

---

## 🐛 Troubleshooting

### No assets found?
- Check that folders exist and are listed in `pubspec.yaml`
- Only supported image extensions are picked up

### Paths not working on Windows?
- Generator normalizes paths with forward slashes (`/`)

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repo
2. Create a feature branch
3. Open a pull request

---

## 📜 License

MIT © Abhilash Puthukkudi

---

## 📦 Pub.dev

👉 [View on pub.dev →](https://pub.dev/packages/asset_image_generator)
