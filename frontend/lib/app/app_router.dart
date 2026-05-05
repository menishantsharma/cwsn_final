import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/pages/otp_verify_page.dart';
import 'package:frontend/features/auth/presentation/pages/phone_input_page.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/categories/presentation/pages/categories_page.dart';
import 'package:frontend/features/categories/presentation/pages/subcategories_page.dart';
import 'package:frontend/features/notifications/presentation/pages/notifications_page.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/presentation/pages/create_service_page.dart';
import 'package:frontend/features/services/presentation/pages/editable_service_detail_page.dart';
import 'package:frontend/features/services/presentation/pages/service_detail_page.dart';
import 'package:frontend/features/services/presentation/pages/search_listings_page.dart';
import 'package:frontend/features/services/presentation/pages/search_results_page.dart';
import 'package:frontend/features/services/presentation/pages/services_page.dart';
import 'package:frontend/features/profile/presentation/pages/profile_page.dart';
import 'package:frontend/features/profile/presentation/pages/edit_personal_info_page.dart';
import 'package:frontend/features/profile/presentation/pages/edit_caregiver_info_page.dart';
import 'package:frontend/features/auth/presentation/pages/onboarding_page.dart';

import 'package:go_router/go_router.dart';

class AppRoutes {
  static const splash = '/';
  static const String phoneInput = '/phone-input';
  static const String otpVerify = '/otp-verify';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String subcategories = '/subcategories';
  static const String services = '/services';
  static const String notifications = '/notifications';
  static const String serviceDetail = '/service-detail';
  static const String editableServiceDetail = '/my-service';
  static const String profile = '/profile';
  static const String createService = '/create-service';
  static const String editPersonalInfo = '/edit-personal-info';
  static const String editCaregiverInfo = '/edit-caregiver-info';
  static const String onboarding = '/onboarding';
  static const String searchResults = '/search';
  static const String searchListings = '/search-listings';
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
        return authState.isNewUser
            ? AppRoutes.onboarding
            : AppRoutes.categories;
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
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.serviceDetail,
        builder: (_, state) =>
            ServiceDetailPage(service: state.extra as ServiceModel),
      ),
      GoRoute(
        path: AppRoutes.editableServiceDetail,
        builder: (_, state) =>
            EditableServiceDetailPage(service: state.extra as ServiceModel),
      ),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: AppRoutes.editPersonalInfo,
        builder: (_, _) => const EditPersonalInfoPage(),
      ),
      GoRoute(
        path: AppRoutes.editCaregiverInfo,
        builder: (_, _) => const EditCaregiverInfoPage(),
      ),
      GoRoute(
        path: AppRoutes.createService,
        builder: (_, state) =>
            CreateServicePage(subcategory: state.extra as SubcategoryModel),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.searchResults,
        builder: (_, _) => const SearchResultsPage(),
      ),
      GoRoute(
        path: AppRoutes.searchListings,
        builder: (_, state) =>
            SearchListingsPage(query: state.extra as String),
      ),
    ],
  );
});
