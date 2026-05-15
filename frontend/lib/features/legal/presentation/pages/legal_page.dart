import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/app_bar.dart';

enum LegalMode { terms, privacy }

class LegalPage extends StatelessWidget {
  final LegalMode mode;
  final ScrollController? scrollController;
  const LegalPage({super.key, required this.mode, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final isTerms = mode == LegalMode.terms;
    return Scaffold(
      appBar: AppTopBar(title: isTerms ? 'Terms of Service' : 'Privacy Policy'),
      body: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        children: isTerms ? _termsContent() : _privacyContent(),
      ),
    );
  }

  // ── Terms of Service ──────────────────────────────────────────────────────

  List<Widget> _termsContent() => [
    _effectiveDate('1 June 2025'),
    _body(
      'Welcome to CWSN Connect ("the App"). By creating an account or using the App, '
      'you agree to these Terms of Service ("Terms"). Please read them carefully. '
      'If you do not agree, do not use the App.',
    ),
    _h2('1. Who Can Use the App'),
    _body(
      'The App is intended for adults (18+) who are parents or caregivers of children '
      'with special needs ("CWSN"), and for individuals who offer caregiving or support '
      'services to CWSN. By registering, you confirm that you are at least 18 years old '
      'and that all information you provide is accurate and truthful.',
    ),
    _h2('2. Account Responsibilities'),
    _body(
      'You are responsible for maintaining the confidentiality of your account and for '
      'all activity that occurs under it. You agree to notify us immediately if you '
      'suspect unauthorised use of your account. We are not liable for any loss or '
      'damage arising from your failure to safeguard your credentials.',
    ),
    _h2('3. Acceptable Use'),
    _body('You agree NOT to:'),
    _bullets([
      'Post false, misleading, or fraudulent information about yourself or your services.',
      'Impersonate any person or entity.',
      'Use the App to harass, abuse, or harm any user.',
      'Share contact details of third parties without their consent.',
      'Scrape, copy, or redistribute App content for commercial purposes.',
      'Attempt to gain unauthorised access to any part of the App or its infrastructure.',
      'Use the App for any illegal purpose.',
    ]),
    _h2('4. Service Listings'),
    _body(
      'Caregivers who list services on the App represent that they have the necessary '
      'qualifications, certifications, and legal authorisation to provide those services. '
      'CWSN Connect does not verify credentials and is not responsible for the quality, '
      'safety, or legality of any service listed. Families engage caregivers entirely at '
      'their own risk.',
    ),
    _h2('5. No Professional Advice'),
    _body(
      'Nothing in the App constitutes medical, therapeutic, legal, or professional '
      'advice. Always consult a qualified professional before making decisions related '
      'to the health, education, or welfare of a child.',
    ),
    _h2('6. Intellectual Property'),
    _body(
      'All content, branding, and software in the App are the property of CWSN Connect '
      'or its licensors. You may not reproduce, distribute, or create derivative works '
      'without our written permission.',
    ),
    _h2('7. Termination'),
    _body(
      'We may suspend or terminate your account at any time, with or without notice, '
      'if we believe you have violated these Terms or if continued access poses a risk '
      'to other users or the App.',
    ),
    _h2('8. Disclaimer of Warranties'),
    _body(
      'The App is provided "as is" and "as available" without warranties of any kind, '
      'express or implied. We do not warrant that the App will be uninterrupted, '
      'error-free, or free of harmful components.',
    ),
    _h2('9. Limitation of Liability'),
    _body(
      'To the maximum extent permitted by law, CWSN Connect shall not be liable for '
      'any indirect, incidental, special, or consequential damages arising from your '
      'use of the App, including but not limited to damages arising from interactions '
      'between users.',
    ),
    _h2('10. Changes to Terms'),
    _body(
      'We may update these Terms at any time. Continued use of the App after changes '
      'are posted constitutes acceptance of the revised Terms. We will notify you of '
      'material changes via the App.',
    ),
    _h2('11. Governing Law'),
    _body(
      'These Terms are governed by the laws of India. Any disputes shall be subject to '
      'the exclusive jurisdiction of the courts of Mumbai, Maharashtra.',
    ),
    _h2('12. Contact'),
    _body('For questions about these Terms, contact us at: support@cwsnconnect.in'),
  ];

  // ── Privacy Policy ────────────────────────────────────────────────────────

  List<Widget> _privacyContent() => [
    _effectiveDate('1 June 2025'),
    _body(
      'CWSN Connect ("we", "our", "us") is committed to protecting your privacy. '
      'This Privacy Policy explains what information we collect, how we use it, '
      'and your rights regarding it.',
    ),
    _h2('1. Information We Collect'),
    _body('We collect the following information when you use the App:'),
    _bullets([
      'Phone number (used for authentication via OTP).',
      'Profile information: name, age, gender, location (area on map).',
      'Child profile information: name, age, gender (provided by parents).',
      'Caregiver information: about me, qualifications, spoken languages.',
      'Service listing details: title, description, service type, pricing.',
      'Request and interaction data: requests sent, status updates.',
      'Device information: platform type, app version (for diagnostics).',
      'Usage data: pages visited, features used (aggregated and anonymised).',
    ]),
    _h2('2. How We Use Your Information'),
    _bullets([
      'To create and manage your account.',
      'To display your profile and services to other users.',
      'To facilitate contact requests between families and caregivers.',
      'To send OTPs for login and phone verification.',
      'To investigate reports and enforce our Terms of Service.',
      'To improve App performance and fix issues.',
      'To comply with legal obligations.',
    ]),
    _h2('3. Information Sharing'),
    _body(
      'We do not sell your personal information. We may share it only in these '
      'circumstances:',
    ),
    _bullets([
      'With other users, to the extent necessary for the App\'s core functionality '
          '(e.g. your service listing is visible to families in your area).',
      'With service providers who help us operate the App (e.g. cloud hosting, '
          'SMS gateway), under confidentiality obligations.',
      'If required by law, court order, or government authority.',
      'In connection with a merger, acquisition, or sale of assets, with appropriate '
          'notice to you.',
    ]),
    _h2('4. Children\'s Privacy'),
    _body(
      'The App is not directed at children under 13. Child profile data entered by '
      'parents (name, age, gender) is used solely to facilitate service requests and '
      'is never shared publicly or used for profiling.',
    ),
    _h2('5. Location Data'),
    _body(
      'We collect the approximate area you select on the map to help match you with '
      'nearby services. We do not track your real-time location or store precise GPS '
      'coordinates beyond what you explicitly provide.',
    ),
    _h2('6. Data Retention'),
    _body(
      'We retain your data for as long as your account is active. If you delete your '
      'account, we will delete your personal data within 30 days, except where '
      'retention is required by law.',
    ),
    _h2('7. Security'),
    _body(
      'We use industry-standard security measures including encrypted connections '
      '(HTTPS/TLS) and access controls. However, no system is completely secure and '
      'we cannot guarantee absolute security.',
    ),
    _h2('8. Your Rights'),
    _body('You have the right to:'),
    _bullets([
      'Access the personal data we hold about you.',
      'Request correction of inaccurate data.',
      'Request deletion of your account and data.',
      'Withdraw consent at any time (by deleting your account).',
    ]),
    _body(
      'To exercise these rights, contact us at: support@cwsnconnect.in',
    ),
    _h2('9. Third-Party Links'),
    _body(
      'The App may contain links to third-party websites or services. We are not '
      'responsible for the privacy practices of those third parties.',
    ),
    _h2('10. Changes to This Policy'),
    _body(
      'We may update this Privacy Policy periodically. We will notify you of '
      'significant changes via the App. Continued use after changes are posted '
      'constitutes acceptance.',
    ),
    _h2('11. Contact'),
    _body(
      'If you have questions or concerns about this Privacy Policy, please contact us '
      'at: support@cwsnconnect.in',
    ),
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _effectiveDate(String date) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spacing20),
    child: Text(
      'Effective date: $date',
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
    ),
  );

  Widget _h2(String text) => Padding(
    padding: const EdgeInsets.only(top: AppDimensions.spacing24, bottom: AppDimensions.spacing8),
    child: Text(
      text,
      style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
    ),
  );

  Widget _body(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
    child: Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        height: 1.6,
      ),
    ),
  );

  Widget _bullets(List<String> items) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 10),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}
