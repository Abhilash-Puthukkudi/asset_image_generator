library asset_image_generator;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Main class for generating image asset references
class AssetImageGenerator {
  static const List<String> supportedExtensions = [
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.svg'
  ];

  /// Generate Dart files with image asset references
  Future<void> generate({String? outputDir}) async {
    try {
      print('🚀 Starting asset image generation...');
      
      // Check if pubspec.yaml exists
      final pubspecFile = File('pubspec.yaml');
      if (!pubspecFile.existsSync()) {
        throw Exception('pubspec.yaml not found in current directory');
      }

      // Parse pubspec.yaml to get asset paths
      final pubspecContent = await pubspecFile.readAsString();
      final pubspec = loadYaml(pubspecContent);
      
      final List<String> assetPaths = _extractAssetPaths(pubspec);
      
      if (assetPaths.isEmpty) {
        print('⚠️  No asset paths found in pubspec.yaml');
        return;
      }

      // Find all image files organized by folders
      final Map<String, List<ImageAsset>> organizedAssets = {};
      for (final assetPath in assetPaths) {
        final assets = await _scanForImagesWithFolders(assetPath);
        for (final entry in assets.entries) {
          organizedAssets.putIfAbsent(entry.key, () => []).addAll(entry.value);
        }
      }

      if (organizedAssets.isEmpty) {
        print('⚠️  No image assets found');
        return;
      }

      // Generate separate files for each folder
      final outputDirectory = outputDir ?? path.join('lib', 'generated', 'images');
      final generatedFiles = <String>[];

      for (final entry in organizedAssets.entries) {
        final folderName = entry.key;
        final assets = entry.value;
        
        final fileName = folderName == 'root' 
            ? 'app_images.dart' 
            : '${_toSnakeCase(folderName)}_images.dart';
        final filePath = path.join(outputDirectory, fileName);
        
        await _generateImageFile(folderName, assets, filePath);
        generatedFiles.add(fileName);
        
        print('✅ Generated $fileName with ${assets.length} assets');
      }

      // Generate main index file
      await _generateIndexFile(organizedAssets.keys.toList(), outputDirectory);
      generatedFiles.add('images.dart');

      print('🎉 Generation complete!');
      print('📁 Output directory: $outputDirectory');
      print('📊 Total: ${organizedAssets.values.fold<int>(0, (sum, assets) => sum + assets.length)} assets');
      print('📄 Generated files: ${generatedFiles.join(', ')}');
      
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  List<String> _extractAssetPaths(dynamic pubspec) {
    final List<String> paths = [];
    
    if (pubspec['flutter'] != null && pubspec['flutter']['assets'] != null) {
      final assets = pubspec['flutter']['assets'];
      if (assets is List) {
        for (final asset in assets) {
          if (asset is String) {
            paths.add(asset);
          }
        }
      }
    }
    
    return paths;
  }

  Future<Map<String, List<ImageAsset>>> _scanForImagesWithFolders(String assetPath) async {
    final Map<String, List<ImageAsset>> organizedImages = {};
    final Directory dir = Directory(assetPath.endsWith('/') 
        ? assetPath 
        : path.dirname(assetPath));
    
    if (!dir.existsSync()) {
      print('⚠️  Directory not found: ${dir.path}');
      return organizedImages;
    }

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final extension = path.extension(entity.path).toLowerCase();
        if (supportedExtensions.contains(extension)) {
          final relativePath = path.relative(entity.path);
          final folderName = _getFolderName(entity.path, dir.path);
          final variableName = _generateVariableName(entity.path);
          final fileNameWithExtension = _generateFileNameWithExtension(entity.path);
          
          organizedImages
              .putIfAbsent(folderName, () => [])
              .add(ImageAsset(
                path: relativePath,
                variableName: variableName,
                fileNameWithExtension: fileNameWithExtension,
              ));
        }
      }
    }
    
    return organizedImages;
  }

  String _getFolderName(String filePath, String basePath) {
    final relativePath = path.relative(filePath, from: basePath);
    final parts = path.split(relativePath);
    return parts.length == 1 ? 'root' : _toPascalCase(parts[parts.length - 2]);
  }

  String _generateVariableName(String filePath) {
    String fileName = path.basenameWithoutExtension(filePath);
    fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    fileName = fileName.replaceAll(RegExp(r'_+'), '_');
    fileName = fileName.replaceAll(RegExp(r'^_+|_+$'), '');
    
    if (fileName.isNotEmpty && RegExp(r'^[0-9]').hasMatch(fileName)) {
      fileName = 'img_$fileName';
    }
    
    return _toCamelCase(fileName);
  }

  String _generateFileNameWithExtension(String filePath) {
    String fileName = path.basename(filePath);
    fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.]'), '_');
    fileName = fileName.replaceAll(RegExp(r'_+'), '_');
    fileName = fileName.replaceAll(RegExp(r'^_+|_+$'), '');
    fileName = fileName.replaceAll('.', '_');
    
    if (fileName.isNotEmpty && RegExp(r'^[0-9]').hasMatch(fileName)) {
      fileName = 'img_$fileName';
    }
    
    return _toCamelCase(fileName);
  }

  String _toCamelCase(String input) {
    final parts = input.split('_');
    if (parts.isEmpty) return 'image';
    
    String result = parts.first.toLowerCase();
    for (int i = 1; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        result += parts[i][0].toUpperCase() + parts[i].substring(1).toLowerCase();
      }
    }
    
    return result.isEmpty ? 'image' : result;
  }

  String _toPascalCase(String input) {
    final parts = input.split(RegExp(r'[^a-zA-Z0-9]'));
    if (parts.isEmpty) return 'Images';
    
    String result = '';
    for (final part in parts) {
      if (part.isNotEmpty) {
        result += part[0].toUpperCase() + part.substring(1).toLowerCase();
      }
    }
    
    return result.isEmpty ? 'Images' : result;
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}')
        .replaceAll(RegExp(r'^_'), '')
        .toLowerCase();
  }

  Future<void> _generateImageFile(String folderName, List<ImageAsset> assets, String outputPath) async {
    final buffer = StringBuffer();
    
    assets.sort((a, b) => a.variableName.compareTo(b.variableName));
    
    // Header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by asset_image_generator');
    buffer.writeln('// Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln('// Folder: $folderName');
    buffer.writeln();
    
    final className = folderName == 'root' ? 'AppImages' : '${folderName}Images';
    
    // Class definition
    buffer.writeln('class $className {');
    buffer.writeln('  $className._();');
    buffer.writeln();
    
    // Generate constants
    for (final asset in assets) {
      final basename = path.basename(asset.path);
      
      // Path-based reference
      buffer.writeln('  /// Path: ${asset.path}');
      buffer.writeln('  static const String ${asset.variableName} = \'${asset.path}\';');
      buffer.writeln();
      
      // Filename-with-extension reference
      buffer.writeln('  /// Filename: $basename');
      buffer.writeln('  static const String ${asset.fileNameWithExtension} = \'$basename\';');
      buffer.writeln();
    }
    
    // All paths list
    buffer.writeln('  /// List of all image paths in this folder');
    buffer.writeln('  static const List<String> allPaths = [');
    for (final asset in assets) {
      buffer.writeln('    ${asset.variableName},');
    }
    buffer.writeln('  ];');
    buffer.writeln();
    
    // All filenames list
    buffer.writeln('  /// List of all filenames in this folder');
    buffer.writeln('  static const List<String> allFileNames = [');
    for (final asset in assets) {
      buffer.writeln('    ${asset.fileNameWithExtension},');
    }
    buffer.writeln('  ];');
    
    buffer.writeln('}');
    
    // Write file
    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(buffer.toString());
  }

Future<void> _generateIndexFile(List<String> folderNames, String outputDirectory) async {
  final buffer = StringBuffer();
  
  // File header
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// Generated by asset_image_generator');
  buffer.writeln('// Generated on: ${DateTime.now().toIso8601String()}');
  buffer.writeln();
  
  // Sort folder names alphabetically
  final sortedFolders = folderNames.toList()..sort();
  
  // Generate exports only - no wrapper class
  for (final folderName in sortedFolders) {
    final fileName = folderName == 'root' 
        ? 'app_images.dart' 
        : '${_toSnakeCase(folderName)}_images.dart';
    buffer.writeln('export \'$fileName\';');
  }
  
  // Write the index file
  await File(path.join(outputDirectory, 'images.dart'))
      .writeAsString(buffer.toString());
}
}

class ImageAsset {
  final String path;
  final String variableName;
  final String fileNameWithExtension;
  
  ImageAsset({
    required this.path,
    required this.variableName,
    required this.fileNameWithExtension,
  });
}