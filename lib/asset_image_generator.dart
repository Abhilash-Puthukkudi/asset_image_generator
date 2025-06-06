library asset_image_generator;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Main class for generating separate image files for each folder
class AssetImageGenerator {
  static const List<String> supportedExtensions = [
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.svg'
  ];

  /// Generate separate dart files for each folder from assets in pubspec.yaml
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
          if (organizedAssets.containsKey(entry.key)) {
            organizedAssets[entry.key]!.addAll(entry.value);
          } else {
            organizedAssets[entry.key] = entry.value;
          }
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
        
        final fileName = folderName == 'root' ? 'app_images.dart' : '${_toSnakeCase(folderName)}_images.dart';
        final filePath = path.join(outputDirectory, fileName);
        
        await _generateImageFile(folderName, assets, filePath);
        generatedFiles.add(fileName);
        
        print('✅ Generated $fileName with ${assets.length} assets');
      }

      // Generate main index file that exports all image files
      await _generateIndexFile(organizedAssets.keys.toList(), outputDirectory);
      generatedFiles.add('images.dart');

      // Calculate total assets across all folders (null-safe)
      int totalAssets = 0;
      for (final assetList in organizedAssets.values) {
        if (assetList != null) {
          totalAssets += assetList.length;
        }
      }
      
      // Alternative null-safe approaches:
      // final totalAssets = organizedAssets.values.where((list) => list != null).fold<int>(0, (int sum, List<ImageAsset> list) => sum + list.length);
      // final totalAssets = organizedAssets.values.whereType<List<ImageAsset>>().fold<int>(0, (int sum, List<ImageAsset> list) => sum + list.length);
      print('🎉 Generation complete!');
      print('📁 Output directory: $outputDirectory');
      print('📊 Total: $totalAssets assets across ${organizedAssets.length} files');
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
    final Directory dir = Directory(assetPath.endsWith('/') ? assetPath : path.dirname(assetPath));
    
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
          
          final asset = ImageAsset(
            path: relativePath,
            variableName: variableName,
            imageName: _generateImageName(entity.path),
          );
          
          if (organizedImages.containsKey(folderName)) {
            organizedImages[folderName]!.add(asset);
          } else {
            organizedImages[folderName] = [asset];
          }
        }
      }
    }
    
    return organizedImages;
  }

  String _getFolderName(String filePath, String basePath) {
    final relativePath = path.relative(filePath, from: basePath);
    final parts = path.split(relativePath);
    
    if (parts.length == 1) {
      // File is in root of assets directory
      return 'root';
    }
    
    // Get the immediate parent folder name
    final folderName = parts[parts.length - 2];
    return _toPascalCase(folderName);
  }

  String _generateImageName(String filePath) {
    // Get filename without extension for image name only
    String fileName = path.basenameWithoutExtension(filePath);
    
    // Replace special characters and spaces with underscores
    fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    
    // Remove consecutive underscores
    fileName = fileName.replaceAll(RegExp(r'_+'), '_');
    
    // Remove leading/trailing underscores
    fileName = fileName.replaceAll(RegExp(r'^_+|_+$'), '');
    
    // Ensure it starts with a letter or underscore
    if (fileName.isNotEmpty && RegExp(r'^[0-9]').hasMatch(fileName)) {
      fileName = 'img_$fileName';
    }
    
    // Convert to camelCase
    return _toCamelCase(fileName);
  }

  String _generateVariableName(String filePath) {
    // Get filename without extension
    String fileName = path.basenameWithoutExtension(filePath);
    
    // Replace special characters and spaces with underscores
    fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    
    // Remove consecutive underscores
    fileName = fileName.replaceAll(RegExp(r'_+'), '_');
    
    // Remove leading/trailing underscores
    fileName = fileName.replaceAll(RegExp(r'^_+|_+$'), '');
    
    // Ensure it starts with a letter or underscore
    if (fileName.isNotEmpty && RegExp(r'^[0-9]').hasMatch(fileName)) {
      fileName = 'img_$fileName';
    }
    
    // Convert to camelCase
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
    
    // Sort assets alphabetically
    assets.sort((a, b) => a.variableName.compareTo(b.variableName));
    
    // File header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by asset_image_generator');
    buffer.writeln('// Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln('// Folder: $folderName');
    buffer.writeln();
    
    final className = folderName == 'root' ? 'AppImages' : '${folderName}Images';
    final classDescription = folderName == 'root' 
        ? 'Root level image assets' 
        : '$folderName folder image assets';
    
    // Generate class
    buffer.writeln('/// $classDescription');
    buffer.writeln('class $className {');
    buffer.writeln('  $className._();');
    buffer.writeln();
    
    // Generate static constants with full paths
    for (final asset in assets) {
      buffer.writeln('  /// Full path: ${asset.path}');
      buffer.writeln('  static const String ${asset.variableName} = \'${asset.path}\';');
      buffer.writeln();
      buffer.writeln('  /// Image name only: ${asset.imageName}');
      buffer.writeln('  static const String ${asset.imageName}Name = \'${asset.imageName}\';');
      buffer.writeln();
    }
    
    // Generate list of all asset paths
    buffer.writeln('  /// List of all image asset paths in this ${folderName == 'root' ? 'root directory' : 'folder'}');
    buffer.writeln('  static const List<String> allPaths = [');
    for (final asset in assets) {
      buffer.writeln('    ${asset.variableName},');
    }
    buffer.writeln('  ];');
    buffer.writeln();
    
    // Generate list of all image names
    buffer.writeln('  /// List of all image names in this ${folderName == 'root' ? 'root directory' : 'folder'}');
    buffer.writeln('  static const List<String> allNames = [');
    for (final asset in assets) {
      buffer.writeln('    ${asset.imageName}Name,');
    }
    buffer.writeln('  ];');
    buffer.writeln();
    
    // Generate helper method to get path by name
    buffer.writeln('  /// Get image path by name');
    buffer.writeln('  static String? getPathByName(String name) {');
    buffer.writeln('    switch (name) {');
    for (final asset in assets) {
      buffer.writeln('      case \'${asset.imageName}\':');
      buffer.writeln('        return ${asset.variableName};');
    }
    buffer.writeln('      default:');
    buffer.writeln('        return null;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    
    buffer.writeln('}');
    
    // Ensure output directory exists
    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    
    // Write the file
    await outputFile.writeAsString(buffer.toString());
  }

  Future<void> _generateIndexFile(List<String> folderNames, String outputDirectory) async {
    final buffer = StringBuffer();
    
    // File header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by asset_image_generator');
    buffer.writeln('// Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln('// Main export file for all image assets');
    buffer.writeln();
    
    // Sort folder names
    final sortedFolders = folderNames.toList()..sort();
    
    // Generate exports
    buffer.writeln('// Export all image asset classes');
    for (final folderName in sortedFolders) {
      final fileName = folderName == 'root' ? 'app_images.dart' : '${_toSnakeCase(folderName)}_images.dart';
      buffer.writeln('export \'$fileName\';');
    }
    buffer.writeln();
    
    // Generate main Images class that provides access to all folders
    buffer.writeln('/// Main Images class providing access to all image asset categories');
    buffer.writeln('class Images {');
    buffer.writeln('  Images._();');
    buffer.writeln();
    
    for (final folderName in sortedFolders) {
      if (folderName == 'root') {
        buffer.writeln('  /// Access root level images');
        buffer.writeln('  static const AppImages root = AppImages._();');
      } else {
        buffer.writeln('  /// Access ${folderName.toLowerCase()} images');
        buffer.writeln('  static const ${folderName}Images ${_toCamelCase(folderName)} = ${folderName}Images._();');
      }
      buffer.writeln();
    }
    
    // Generate method to get all paths from all folders
    buffer.writeln('  /// Get all image paths from all folders');
    buffer.writeln('  static List<String> getAllPaths() {');
    buffer.writeln('    return [');
    for (final folderName in sortedFolders) {
      if (folderName == 'root') {
        buffer.writeln('      ...AppImages.allPaths,');
      } else {
        buffer.writeln('      ...${folderName}Images.allPaths,');
      }
    }
    buffer.writeln('    ];');
    buffer.writeln('  }');
    
    buffer.writeln('}');
    
    // Write the index file
    final indexFile = File(path.join(outputDirectory, 'images.dart'));
    await indexFile.writeAsString(buffer.toString());
  }
}

/// Represents an image asset with its path, variable name, and image name
class ImageAsset {
  final String path;
  final String variableName;
  final String imageName;
  
  ImageAsset({
    required this.path,
    required this.variableName,
    required this.imageName,
  });
}