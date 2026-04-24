import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  debugPrint("main: Starting app...");
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TradingApp());
}
