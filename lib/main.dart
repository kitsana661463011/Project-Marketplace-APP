import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/announcement_screen.dart';
import 'screens/vendor_registration_screen.dart';
import 'screens/shop_detail_screen.dart';
import 'screens/shop_reviews_screen.dart';
import 'screens/report_comment_screen.dart';
import 'screens/write_review_screen.dart';
import 'screens/report_problem_screen.dart';
import 'screens/problem_history_screen.dart';
import 'screens/problem_detail_screen.dart';
import 'screens/my_shop_list_screen.dart';
import 'screens/create_shop_screen.dart';
import 'screens/manage_shop_screen.dart';
import 'screens/add_menu_screen.dart';
import 'screens/manage_menu_category_screen.dart';
import 'screens/market_map_screen.dart';
import 'screens/book_stall_screen.dart';
import 'screens/booking_history_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarketPlace',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        primaryColor: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2563EB),
          secondary: Color(0xFF3B82F6),
          surface: Colors.white,
          error: Color(0xFFEF4444),
          onPrimary: Colors.white,
          onSurface: Color(0xFF0F172A),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
          contentTextStyle: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
          ),
          labelStyle: GoogleFonts.outfit(color: const Color(0xFF64748B)),
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.light().textTheme,
        ).apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map?;
          final initialIndex = (args?['initialIndex'] as int?) ?? 0;
          return HomeScreen(initialIndex: initialIndex);
        },
        '/announcements': (context) => const AnnouncementScreen(),
        '/vendor_register': (context) => const VendorRegistrationScreen(),
        '/shop_detail': (context) => const ShopDetailScreen(),
        '/shop_reviews': (context) => const ShopReviewsScreen(),
        '/report_comment': (context) => const ReportCommentScreen(),
        '/write_review': (context) => const WriteReviewScreen(),
        '/report_problem': (context) => const ReportProblemScreen(),
        '/problem_history': (context) => const ProblemHistoryScreen(),
        '/problem_detail': (context) => const ProblemDetailScreen(),
        '/my_shops': (context) => const MyShopListScreen(),
        '/create_shop': (context) => const CreateShopScreen(),
        '/manage_shop': (context) => const ManageShopScreen(),
        '/add_menu': (context) => const AddMenuScreen(),
        '/manage_menu_category': (context) => const ManageMenuCategoryScreen(),
        '/market_map': (context) => const MarketMapScreen(),
        '/book_stall': (context) => const BookStallScreen(),
        '/booking_history': (context) => const BookingHistoryScreen(),
      },
    );
  }
}
