import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection_container.dart' as di;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrapper());
}

class AppBootstrapper extends StatefulWidget {
  final Future<void> Function()? initializeApp;

  const AppBootstrapper({super.key, this.initializeApp});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    // Start DI container initialization immediately without blocking the UI thread
    _initFuture = (widget.initializeApp ?? di.initDI)();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const TradingApp();
        }

        // Zero-jank minimal splash/loading state
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF121212)),
          home: const Scaffold(),
        );
      },
    );
  }
}
