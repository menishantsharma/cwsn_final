import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/pages/otp_verify_page.dart';
import 'package:frontend/features/auth/presentation/pages/phone_input_page.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/categories/presentation/pages/categories_page.dart';
import 'package:frontend/features/categories/presentation/pages/subcategories_page.dart';
import 'package:frontend/features/services/presentation/pages/services_page.dart';
import 'package:frontend/home_page.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  static const splash = '/';
  static const String phoneInput = '/phone-input';
  static const String otpVerify = '/otp-verify';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String subcategories = '/subcategories';
  static const String services = '/services';

  AppRoutes._();
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState?>(null);

  ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
    authNotifier.value = next.value;
  });

  ref.onDispose(() {
    authNotifier.dispose();
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = authNotifier.value;
      if (authState == null) return AppRoutes.splash;

      final isVerified = authState.status == AuthStatus.verified;
      final isOnAuth =
          state.matchedLocation == AppRoutes.phoneInput ||
          state.matchedLocation == AppRoutes.otpVerify;

      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      final isOtpSent = authState.status == AuthStatus.otpSent;
      final isOnOtpPage = state.matchedLocation == AppRoutes.otpVerify;

      if (isOtpSent && !isOnOtpPage) {
        return AppRoutes.otpVerify;
      }

      if (isVerified && (isOnAuth || isOnSplash)) {
        return AppRoutes.categories;
      }

      if (!isVerified && !isOnAuth && !isOtpSent) {
        return AppRoutes.phoneInput;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) =>
            Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: AppRoutes.phoneInput,
        builder: (_, _) => const PhoneInputPage(),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (_, _) => const OtpVerifyPage(),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: AppRoutes.categories,
        builder: (_, _) => const CategoriesPage(),
      ),
      GoRoute(
        path: AppRoutes.subcategories,
        builder: (_, state) =>
            SubcategoriesPage(category: state.extra as CategoryModel),
      ),
      GoRoute(
        path: AppRoutes.services,
        builder: (_, state) =>
            ServicesPage(subcategory: state.extra as SubcategoryModel),
      ),
    ],
  );
});
