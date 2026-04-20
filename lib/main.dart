import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wnc_finder/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  //orientasi portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const WarkopFinderApp());
}

class WarkopFinderApp extends StatelessWidget {
  const WarkopFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WNC Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xffd4722a),
          surface: const Color(0xff1a0a00),
          background: const Color(0xff1a0a00),
        ),
        scaffoldBackgroundColor: const Color(0xff1a0a00),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
