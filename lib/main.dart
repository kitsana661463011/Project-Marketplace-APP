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
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        primaryColor: const Color(0xFF00BFA5),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00BFA5),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1B2838),
          error: Colors.redAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1B2838),
          indicatorColor: const Color(0xFF00BFA5).withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
