import 'package:flutter/material.dart';
import '../../../domain/entities/profile_entity.dart';

class AppTheme {
  static ThemeData getTheme(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return ThemeData(
            primarySwatch: Colors.amber, brightness: Brightness.light);
      case Emotion.sad:
        return ThemeData(
            primarySwatch: Colors.blue, brightness: Brightness.dark);
      case Emotion.angry:
        return ThemeData(
            primarySwatch: Colors.red, brightness: Brightness.dark);
      case Emotion.disgusted:
        return ThemeData(
            primarySwatch: Colors.green, brightness: Brightness.light);
      case Emotion.fear:
        return ThemeData(
            primarySwatch: Colors.purple, brightness: Brightness.dark);
    }
  }
}
