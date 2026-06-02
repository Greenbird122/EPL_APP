// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'REPAIR-AI';

  @override
  String get login => 'Login';

  @override
  String get loginSubtitle => 'Enter your details to continue';

  @override
  String get name => 'Name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get nameTooShort => 'Name is too short';

  @override
  String get email => 'Email';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get loginButton => 'Login';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get reportSymptoms => 'Report Symptoms';

  @override
  String get reportSymptomsSubtitle => 'Bleeding • Pain • Others';

  @override
  String get myReferrals => 'My Referrals';

  @override
  String get myReferralsSubtitle => 'Track & Navigate';

  @override
  String get chatWithRepairAI => 'Chat with REPAIR-AI';

  @override
  String get chatSubtitle => 'WhatsApp Assistant (24/7)';

  @override
  String get myReports => 'My Reports';

  @override
  String get myReportsSubtitle => 'View previous symptom reports';

  @override
  String get savedFacilities => 'Saved Facilities';

  @override
  String get savedFacilitiesSubtitle => 'Quick access to preferred hospitals';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Alerts & Reminders';

  @override
  String get language => 'Language';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get helpSupportSubtitle => 'FAQs and Contact';

  @override
  String get logout => 'Logout';

  @override
  String get home => 'Home';

  @override
  String get triage => 'Triage';

  @override
  String get profile => 'Profile';

  @override
  String get myProfile => 'My Profile';

  @override
  String get mentalHealth => 'Mental Health';

  @override
  String get mentalHealthSupport => 'Mental Health Support';

  @override
  String get mentalHealthSubtitle => 'How are you feeling today?';

  @override
  String get nearestFacility => 'Nearest Facility';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get chpDashboard => 'CHP Dashboard';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get pendingCases => 'Pending Cases';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get reportSymptomsTitle => 'Report Symptoms';

  @override
  String get weeksPregnant => 'How many weeks pregnant?';

  @override
  String get selectSymptoms => 'Select Symptoms';

  @override
  String get getAIRiskAssessment => 'Get AI Risk Assessment';

  @override
  String get aiRiskAssessment => 'AI Risk Assessment';

  @override
  String get basedOnSymptoms => 'Based on your symptoms:';

  @override
  String get recommendation => 'Recommendation';

  @override
  String get triageBack => 'Triage';

  @override
  String get startReferral => 'Start Referral';

  @override
  String get smartReferrals => 'Smart Referrals';

  @override
  String get recommendedFacility => 'Recommended Facility';

  @override
  String get otherNearbyOptions => 'Other Nearby Options';

  @override
  String get sendReferral => 'Send Referral';

  @override
  String get referralSent => 'Referral request sent to facility';

  @override
  String get noReportsYet => 'No reports yet.';

  @override
  String get close => 'Close';

  @override
  String get riskLevel => 'Risk Level';

  @override
  String get howAreYouFeeling => 'How are you feeling today?';

  @override
  String get feelingsMatter => 'Your feelings matter. We\'re here to support you.';

  @override
  String get thankYouForSharing => 'Thank you for sharing';

  @override
  String get talkToCounselor => 'Talk to Counselor';

  @override
  String get joinSupportGroup => 'Join Support Group';

  @override
  String get loginSavedMock => 'Login saved (mock)';

  @override
  String get loginSuccess => 'Login successful';

  @override
  String get loggedOutSuccess => 'Logged out successfully';

  @override
  String get analyzingStep1 => 'Checking symptoms';

  @override
  String get analyzingStep2 => 'Gestational context';

  @override
  String get analyzingStep3 => 'Risk classification';

  @override
  String get onDeviceAnalysis => 'On-device analysis';

  @override
  String get analyzingSubtitle => 'Processing your report securely on this device…';

  @override
  String get analysisFailed => 'Analysis could not complete. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get whyThisResult => 'Why this result?';

  @override
  String get modelConfidenceLabel => 'Model confidence (demo)';

  @override
  String get selectSymptomHint => 'Select at least one symptom to continue';

  @override
  String get gestationalWeekHelper => 'weeks pregnant';

  @override
  String get tryDemo => 'Try demo';

  @override
  String get yourPregnancyMatters => 'Your Pregnancy Matters';

  @override
  String get reportSymptomsEarly => 'Report symptoms early. You are not alone.';

  @override
  String get worksOffline => 'Works offline';

  @override
  String get lastReport => 'Last report';

  @override
  String get viewReport => 'View report';

  @override
  String get goNowUrgency => 'Go now — urgent care recommended';

  @override
  String get within24Hours => 'Visit within 24 hours';

  @override
  String get referralSuccessTitle => 'Referral sent';

  @override
  String get referralSuccessMessage =>
      'Bungoma County Referral Hospital has been notified.';

  @override
  String get viewHistory => 'View history';

  @override
  String get weeksPregnantLabel => 'weeks';

  @override
  String get symptomNote =>
      'This information helps our AI provide better guidance.';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get facilityDistance => '12.4 km • 28 minutes away';

  @override
  String get mapPlaceholder => 'Facility map (demo)';

  @override
  String get appearance => 'Appearance';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get continueButton => 'Continue';

  @override
  String get getStartedButton => 'Get Started';

  @override
  String get builtForKenyaTrust =>
      'Built for Kenyan mothers • Demo assessment only';

  @override
  String get smartCareTagline => 'Smart Care. Better Outcomes.';

  @override
  String get platformDescription =>
      'Early pregnancy support, smart referrals, and explainable AI triage — built for rural Kenya.';

  @override
  String get howItWorksTitle => 'How REPAIR-AI works';

  @override
  String get howItWorksSubtitle =>
      'From symptom report to facility referral in four steps.';

  @override
  String get seeHowItWorks => 'See how it works';

  @override
  String get learnMoreWebsite => 'Learn more at repairai.co.ke';

  @override
  String get fullPlatform => 'Full platform';

  @override
  String get explainableAI => 'Explainable AI';

  @override
  String get howItWorksCardTitle => 'How REPAIR-AI works';

  @override
  String get howItWorksCardSubtitle => '4 steps from symptoms to referral';

  @override
  String get step01Title => 'Register';

  @override
  String get step01Description =>
      'Create your profile on mobile. Use Try demo for a quick start.';

  @override
  String get step02Title => 'Report symptoms';

  @override
  String get step02Description =>
      'Select symptoms and gestational age in English or Kiswahili.';

  @override
  String get step03Title => 'AI triage';

  @override
  String get step03Description =>
      'On-device analysis assigns risk level with clear reasons and next steps.';

  @override
  String get step04Title => 'Smart referral';

  @override
  String get step04Description =>
      'Get directed to the nearest suitable facility and track your reports.';

  @override
  String get onboarding1Title => 'Early Detection';

  @override
  String get onboarding1Description =>
      'Report symptoms easily using simple pictures and icons';

  @override
  String get onboarding2Title => 'Smart Referrals';

  @override
  String get onboarding2Description =>
      'Get instantly connected to the nearest suitable facility';

  @override
  String get onboarding3Title => 'Continuous Care';

  @override
  String get onboarding3Description =>
      'Receive follow-up support for your physical and mental health';

  @override
  String get onboarding4Title => 'Built for Kenya';

  @override
  String get onboarding4Description =>
      'Made with love for Kenyan mothers and community health workers';

  @override
  String get featureAiTriage => 'AI Triage';

  @override
  String get featureGisReferrals => 'GIS Referrals';

  @override
  String get featureWhoGuidance => 'WHO-aligned (demo)';

  @override
  String get feature247 => '24/7';

  @override
  String get platformImpactTitle => 'Platform impact';

  @override
  String get platformImpactSource => 'Source: REPAIR-AI Kenya deployment';

  @override
  String get statReferralTime => 'Faster referrals';

  @override
  String get statAncAttendance => 'ANC attendance';

  @override
  String get statHighRiskDetected => 'High-risk detected early';

  @override
  String get privacyNotice =>
      'Demo app: data stays on this device. Not a medical diagnosis.';

  @override
  String get callEmergency => 'Call emergency (999)';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get symptomBleeding => 'Vaginal Bleeding';

  @override
  String get symptomSeverePain => 'Severe Abdominal Pain';

  @override
  String get symptomCramping => 'Cramping';

  @override
  String get symptomDizziness => 'Dizziness / Fainting';

  @override
  String get symptomFever => 'Fever';

  @override
  String get symptomNausea => 'Nausea & Vomiting';

  @override
  String get symptomReducedMovement => 'Reduced Fetal Movement';

  @override
  String get symptomSpotting => 'Spotting';

  @override
  String get riskLow => 'Low';

  @override
  String get riskModerate => 'Moderate';

  @override
  String get riskHigh => 'High';

  @override
  String get reasonBleeding =>
      'Vaginal bleeding during pregnancy needs prompt clinical evaluation.';

  @override
  String get reasonSeverePain =>
      'Severe abdominal pain can signal a serious complication.';

  @override
  String get reasonDizziness =>
      'Dizziness or fainting may indicate low blood pressure or blood loss.';

  @override
  String get reasonReducedMovement =>
      'Reduced fetal movement after 20 weeks should be assessed urgently.';

  @override
  String get reasonFever =>
      'Fever can affect both mother and baby and needs review.';

  @override
  String get reasonSpotting =>
      'Spotting should be monitored and may need a check-up.';

  @override
  String get reasonCramping =>
      'Cramping can be normal but matters more with other symptoms.';

  @override
  String get reasonNausea =>
      'Persistent nausea and vomiting can lead to dehydration—seek advice if severe.';

  @override
  String get reasonMultiple =>
      'Multiple symptoms together increase concern.';

  @override
  String get reasonDefault =>
      'Based on the symptoms and gestational age you reported.';

  @override
  String get recHigh =>
      'Seek care immediately. Go to the nearest facility or call emergency services.';

  @override
  String get recModerate =>
      'Visit your nearest health facility within 24 hours for examination and monitoring.';

  @override
  String get recLow =>
      'Continue monitoring symptoms. Contact a provider if anything worsens.';

  @override
  String get trimesterFirst => 'First trimester';

  @override
  String get trimesterSecond => 'Second trimester';

  @override
  String get trimesterThird => 'Third trimester';

  @override
  String get motherQuote1 =>
      'You are stronger than you know, and your baby feels your love every day.';

  @override
  String get motherQuote2 =>
      'Taking one small step for your health today protects two lives tomorrow.';

  @override
  String get motherQuote3 =>
      'Every mother deserves gentle care—ask for help when something feels wrong.';

  @override
  String get motherQuoteAuthor => 'REPAIR-AI';

  @override
  String get agreeTermsPrefix => 'I agree to the ';

  @override
  String get agreeTermsLink => 'Terms & Conditions';

  @override
  String get mustAgreeTerms =>
      'Please accept the Terms & Conditions to continue.';

  @override
  String get termsTitle => 'Terms & Conditions';

  @override
  String get termsBody =>
      'REPAIR-AI is a demonstration app. It does not provide medical diagnosis. '
      'In an emergency, call 999 or go to the nearest facility. '
      'Data in this demo stays on your device. By continuing, you accept these terms.';

  @override
  String get welcomeHome => 'Welcome home';

  @override
  String get signingIn => 'Signing you in…';

  @override
  String get forgotPasswordMock => 'Forgot password (demo only)';

  @override
  String get routeError => 'Something went wrong';

  @override
  String get routeNotFound => 'Page not found';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get timeoutError => 'This is taking longer than expected. Please retry.';

  @override
  String get demoChipLabel => 'Demo';

  @override
  String get feelingGood => 'Good';

  @override
  String get feelingOkay => 'Okay';

  @override
  String get feelingSad => 'Sad';

  @override
  String get feelingVerySad => 'Very Sad';

  @override
  String get feelingAnxious => 'Anxious';

  @override
  String get feelingGuidance =>
      'Your feelings matter. A counselor can listen without judgment—reach out anytime.';

  @override
  String get supportGroupComingSoon =>
      'Community support groups coming soon. Use WhatsApp for help now.';

  @override
  String get referralHospitalName => 'Bungoma County Referral Hospital';

  @override
  String get facilityChip247 => '24/7';

  @override
  String get facilityChipUltrasound => 'Ultrasound';

  @override
  String get facilityChipBloodBank => 'Blood Bank';

  @override
  String get facilitySecondary => 'Nearby facility';

  @override
  String get facilityDistanceSample => '18.7 km • 45 mins';

  @override
  String get voiceListen => 'Tap to speak';

  @override
  String get voiceStop => 'Listening… tap to stop';

  @override
  String get voiceNotAvailable =>
      'Voice input is not available on this device. Type your symptoms instead.';

  @override
  String get symptomNotesHint => 'Describe how you feel (optional)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSwahili => 'Kiswahili';

  @override
  String get languageChangedEn => 'Language changed to English';

  @override
  String get languageChangedSw => 'Language changed to Kiswahili';

  @override
  String get whatsAppMessage =>
      'Hello REPAIR-AI, I need help with my pregnancy.';

  @override
  String get nearestFacilitySubtitle => 'Bungoma County Hospital • 2.3 km';
}
