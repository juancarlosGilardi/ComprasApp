import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:compras_app/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fijar orientación preferida
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Facturas',
      debugShowCheckedModeBanner: false, // Quita el banner de debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          // Estilo consistente para los inputs
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}