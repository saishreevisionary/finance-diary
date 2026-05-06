import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';
import 'providers/finance_provider.dart';
import 'screens/dashboard_screen.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase - Replace with your valid credentials in constants.dart
  // or via environment variables.
  try {
    if (AppConstants.supabaseUrl != 'YOUR_SUPABASE_URL') {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
    } else {
      debugPrint("Warning: Supabase credentials not set in constants.dart");
    }
  } catch (e) {
    debugPrint("Failed to initialize Supabase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
      ],
      child: MaterialApp(
        title: 'Finance Diary',
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
