#!/usr/bin/env dart
import 'package:asset_image_generator/asset_image_generator.dart';


void main(List<String> arguments) async {
  final generator = AssetImageGenerator();
  await generator.generate();
}

