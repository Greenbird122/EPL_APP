// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
import 'app_localizations_compat.dart';

class AppLocalizationsYO extends AppLocalizations with AppLocalizationsCompat {
  AppLocalizationsYO([String locale = 'yo']) : super(locale);

  @override
  String get appTitle => 'Atunṣe-AI';

  @override
  String get login => 'Wo ile';

  @override
  String get loginSubtitle => 'Tẹ awọn alaye rẹ sii lati tẹsiwaju';

  @override
  String get name => 'Oruko';

  @override
  String get nameRequired => 'Orukọ wa ni beere';

  @override
  String get nameTooShort => 'Orukọ ti kuru ju';

  @override
  String get email => 'Imeeli';

  @override
  String get emailRequired => 'Imeeli wa ni ti beere';

  @override
  String get emailInvalid => 'Tẹ imeeli to wulo';

  @override
  String get password => 'Ọrọigbaniwọle';

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
  String get careTab => 'Care';

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
  String get getAIRiskAssessment => 'Get Risk Screening';

  @override
  String get aiRiskAssessment => 'Risk Screening';

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
  String get feelingsMatter =>
      'Your feelings matter. We\'re here to support you.';

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
  String get analyzingSubtitle =>
      'Processing your report securely on this device…';

  @override
  String get analysisFailed => 'Analysis could not complete. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get whyThisResult => 'Why this result?';

  @override
  String get modelConfidenceLabel => 'Screening confidence';

  @override
  String get selectSymptomHint => 'Select at least one symptom to continue';

  @override
  String get gestationalWeekHelper => 'weeks pregnant';

  @override
  String get tryDemo => 'Continue as guest';

  @override
  String get yourPregnancyMatters => 'Your Pregnancy Matters';

  @override
  String get reportSymptomsEarly => 'Report symptoms early. You are not alone.';

  @override
  String get worksOffline => 'Works offline';

  @override
  String get onlineStatus => 'Online';

  @override
  String get noInternetConnection => 'No internet connection';

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
      'The selected verified facility has been notified.';

  @override
  String get viewHistory => 'View history';

  @override
  String get weeksPregnantLabel => 'weeks';

  @override
  String get symptomNote =>
      'This information helps the screening give clearer guidance.';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get facilityDistance => '12.4 km • 28 minutes away';

  @override
  String get mapPlaceholder => 'Facility map';

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
      'Built for Kenyan mothers with guidance support';

  @override
  String get smartCareTagline => 'Smart Care. Better Outcomes.';

  @override
  String get platformDescription =>
      'Early pregnancy support, smart referrals, and explainable risk screening — built for rural Kenya.';

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
  String get explainableAI => 'Explainable screening';

  @override
  String get howItWorksCardTitle => 'How REPAIR-AI works';

  @override
  String get howItWorksCardSubtitle => '4 steps from symptoms to referral';

  @override
  String get step01Title => 'Register';

  @override
  String get step01Description =>
      'Create your profile on mobile or continue as a guest for a quick start.';

  @override
  String get step02Title => 'Report symptoms';

  @override
  String get step02Description =>
      'Select symptoms and gestational age in English or Kiswahili.';

  @override
  String get step03Title => 'Risk screening';

  @override
  String get step03Description =>
      'On-device screening assigns a risk level with clear reasons and next steps.';

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
  String get onboardingPromiseAi => 'AI risk screening';

  @override
  String get onboardingPromiseReferral => 'Verified referrals';

  @override
  String get onboardingPromiseFollowUp => 'Care follow-up';

  @override
  String get onboardingPromiseKenya => 'Built for Kenya';

  @override
  String get featureAiTriage => 'Risk Screening';

  @override
  String get featureGisReferrals => 'GIS Referrals';

  @override
  String get featureWhoGuidance => 'WHO-aligned guidance';

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
      'Data stays on this device until secure backend services are connected. Not a medical diagnosis.';

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
  String get reasonMultiple => 'Multiple symptoms together increase concern.';

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
      'REPAIR-AI provides health screening support. It does not provide medical diagnosis. '
      'In an emergency, call 999 or go to the nearest facility. '
      'Your information stays on your device until secure backend services are connected. By continuing, you accept these terms.';

  @override
  String get welcomeHome => 'Welcome home';

  @override
  String get signingIn => 'Signing you in…';

  @override
  String get forgotPasswordMock => 'Forgot password';

  @override
  String get routeError => 'Something went wrong';

  @override
  String get routeNotFound => 'Page not found';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get timeoutError =>
      'This is taking longer than expected. Please retry.';

  @override
  String get demoChipLabel => 'Guidance';

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
  String get referralHospitalName => 'Selected verified facility';

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
  String get changePassword => 'Change password';

  @override
  String get changePasswordSubtitle => 'Updating your account password...';

  @override
  String get whatsAppMessage =>
      'Hello REPAIR-AI, I need help with my pregnancy.';

  @override
  String get nearestFacilitySubtitle => 'Bungoma County Hospital • 2.3 km';

  @override
  String get medicationTrackerTitle => 'Treatment & supplement tracker';

  @override
  String get medicationTrackerSubtitle =>
      'Track tablets issued and remaining by date';

  @override
  String get chooseAccessSubtitle =>
      'Choose how you want to access pregnancy support today.';

  @override
  String get carePassportBadge => 'Your care starts here';

  @override
  String get authPrivateChip => 'Private';

  @override
  String get authBackendReadyChip => 'Care-ready';

  @override
  String get authUssdChip => 'USSD *384#';

  @override
  String get signInActionSubtitle => 'Use your registered account';

  @override
  String get usernameCareIdLabel => 'Username / care ID';

  @override
  String get usernameCareIdHelper =>
      'Use the username created for your account.';

  @override
  String get usernameCareIdRequired => 'Enter your username or care ID.';

  @override
  String get usernameCareIdNoSpaces => 'Username cannot contain spaces.';

  @override
  String get usernameCreateHelper =>
      'Used only to sign in; choose something easy to remember.';

  @override
  String get signInPhoneLabel => 'Phone number';

  @override
  String get signInPhoneHelper => 'Use the phone number registered for care.';

  @override
  String get signInPhoneRequired => 'Enter your phone number.';

  @override
  String get signInPhoneInvalid =>
      'Enter a valid Kenyan phone number, for example 0712000001.';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get rememberMePatientSubtitle => 'Keep me signed in on this device.';

  @override
  String get rememberMeStaffSubtitle =>
      'Keep this staff session on this device.';

  @override
  String get authSigningInStatus => 'Signing you in securely...';

  @override
  String get authSignedInStatus => 'You’re signed in. Opening your care space.';

  @override
  String get authCreatingAccountStatus => 'Creating your account...';

  @override
  String get authAccountCreatedStatus =>
      'Account created. Setting up your care space.';

  @override
  String get authCheckingStaffStatus => 'Checking staff access...';

  @override
  String get authStaffSignedInStatus => 'Staff access confirmed.';

  @override
  String get authSomeDetailsNeedChecking => 'Some details need checking.';

  @override
  String get authCannotSignIn =>
      'We could not sign you in. Check your phone number and password.';

  @override
  String get authNoPermission =>
      'This account is not allowed to use this part of the app.';

  @override
  String get authActionUnavailable =>
      'This action is not available yet. Please check setup or contact support.';

  @override
  String get authCareServicesUnavailable =>
      'We could not reach care services. Check your internet or try again shortly.';

  @override
  String get authTryAgainSoon => 'Please try again shortly.';

  @override
  String get staffIdOrUsername => 'Staff ID / username';

  @override
  String get accountDetailsSection => 'Account details';

  @override
  String get contactDetailsSection => 'Contact';

  @override
  String get securitySection => 'Security';

  @override
  String get passwordGuidanceShort =>
      'Use 8+ characters. Avoid common or numbers-only passwords.';

  @override
  String get continueToCare => 'Continue to care';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get continueWithPhoneOtp => 'Continue with phone OTP';

  @override
  String get fastSignInSubtitle =>
      'Fast sign in for mothers and returning users';

  @override
  String get createAccountTitle => 'Create account';

  @override
  String get createAccountSubtitle => 'Set up your pregnancy care profile';

  @override
  String get providerAccess => 'Provider / CHP access';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle =>
      'Use your registered phone number and password to open your care space.';

  @override
  String get providerSignInTitle => 'Provider / CHP sign in';

  @override
  String get providerSignInSubtitle =>
      'Authorized care teams can use their staff account for field workflows.';

  @override
  String get staffIdOrEmail => 'Staff ID or email';

  @override
  String get staffIdRequired => 'Enter your staff ID or email.';

  @override
  String get continueToChpDashboard => 'Continue to CHP dashboard';

  @override
  String get chpAccessHint =>
      'For authorized community health and facility teams only.';

  @override
  String get phoneOtpLabel => 'Phone OTP';

  @override
  String get emailLabel => 'Email';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get useGuestAccessInstead => 'Use guest access instead';

  @override
  String get newToRepairCreateAccount => 'New to REPAIR-AI? Create an account';

  @override
  String get createAccountIntro =>
      'This prepares the app for safe care coordination.';

  @override
  String get careAreaLabel => 'County / care area';

  @override
  String get consentText =>
      'I consent to pregnancy support, referral coordination, and safe data use.';

  @override
  String get continueToPhoneVerification => 'Continue to phone verification';

  @override
  String get alreadyHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get otpCodeLabel => 'OTP code';

  @override
  String get verifyAndContinue => 'Verify and continue';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get recoverAccountTitle => 'Recover account';

  @override
  String get recoverAccountSubtitle =>
      'Use your phone number or email to get back in.';

  @override
  String get recoveryInstructions =>
      'When reset support is enabled, instructions can be sent to your phone or email.';

  @override
  String get sendRecoveryInstructions => 'Send recovery instructions';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get useUssdTitle => 'No internet? Use USSD';

  @override
  String get useUssdSubtitle => 'Symptom help and referral guidance by phone.';

  @override
  String get copyUssdCode => 'Copy USSD code';

  @override
  String get dialUssd => 'Dial USSD';

  @override
  String get ussdCopied => 'USSD code copied: *384#';

  @override
  String get homeSupportChannelsSuffix => 'Use the app, USSD, or phone.';

  @override
  String homeGreeting(String name) => 'Good ${_dayPart()}, $name';

  @override
  String get careIdentityUnknown => 'Care profile syncing';

  @override
  String get locationNotSet => 'Location not set';

  @override
  String get careCompassTitle => 'Care Compass';

  @override
  String get compassNoCheckTitle => 'Start with AI risk screening';

  @override
  String get compassCheckedTitle => 'Your last check is saved';

  @override
  String get compassReferralTitle => 'Verified care may be needed';

  @override
  String get compassFollowUpTitle => 'A care follow-up needs attention';

  @override
  String get compassStableTitle => 'Your care looks steady today';

  @override
  String get compassProfileTitle => 'Complete your care profile';

  @override
  String get compassOfflineTitle => 'Saved care is available';

  @override
  String get compassNoCheckMessage =>
      'Tell REPAIR-AI what you are feeling. Screening is not a diagnosis, but it helps guide your next safe step.';

  @override
  String get compassCheckedMessage =>
      'Your latest screening is saved. You can review care updates or run another check if anything changes.';

  @override
  String get compassReferralMessage =>
      'A referral step is ready. Use verified facilities and keep support channels close.';

  @override
  String get compassFollowUpMessage =>
      'You have follow-up activity to check. Open Care to see what needs attention.';

  @override
  String get compassStableMessage =>
      'No urgent care signal is showing right now. Keep checking in when symptoms change.';

  @override
  String get compassProfileMessage =>
      'Add a few care details so referrals and follow-ups can be matched better.';

  @override
  String get compassOfflineMessage =>
      'Care services are not reachable right now. You can still use saved care, USSD, or report symptoms.';

  @override
  String get aiSignalLabel => 'AI screening';

  @override
  String get referralSignalLabel => 'Referral';

  @override
  String get followUpSignalLabel => 'Follow-up';

  @override
  String get signalReady => 'Ready';

  @override
  String get signalNeedsAttention => 'Check';

  @override
  String get signalUrgent => 'Urgent';

  @override
  String get signalComplete => 'Done';

  @override
  String get signalSaved => 'Saved';

  @override
  String get signalNotYet => 'Not yet';

  @override
  String get homeSupportStripTitle => 'Need help quickly?';

  @override
  String get homeSupportStripSubtitle =>
      'Use WhatsApp, USSD, or emergency calling when you need support.';

  @override
  String get todayCareTitle => 'Today\'s Care';

  @override
  String get todayCareSavedTitle => 'Your last check was saved';

  @override
  String get todayCareEmptyTitle => 'Today, start with one simple check';

  @override
  String get pregnancyWeek => 'Pregnancy week';

  @override
  String get noCheckYet => 'No check yet';

  @override
  String get followReferral => 'Follow referral';

  @override
  String get getHelp => 'Get help';

  @override
  String get checkCare => 'Check care';

  @override
  String get useUssd => 'Use USSD';

  @override
  String get todayCareEmptyMessage =>
      'Tell us what you are feeling. You can still use USSD without internet.';

  @override
  String get todayCareReachedMessage =>
      'Good. Your care journey shows you reached care. Keep checking in when anything changes.';

  @override
  String get todayCareNeedsHelpMessage =>
      'Support is ready. Seek care now if symptoms feel severe.';

  @override
  String get todayCareCompletedMessage =>
      'Your referral is marked complete. Your reports remain saved for follow-up.';

  @override
  String get todayCareDefaultMessage =>
      'Here is the next step: follow your referral or contact support if you feel worried.';

  @override
  String get referralDraft => 'Referral draft';

  @override
  String get careFound => 'Care found';

  @override
  String get accepted => 'Accepted';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get careTimelineTitle => 'Care Timeline';

  @override
  String get careTimelineEmptyMessage =>
      'Your care journey will appear here after your first check.';

  @override
  String get careTimelineSavedMessage =>
      'Your recent steps are saved here for follow-up.';

  @override
  String get noCareStepsYet => 'No care steps yet';

  @override
  String get startWithSymptomCheck =>
      'Start with a symptom check whenever you feel ready.';

  @override
  String get symptomCheckSaved => 'Symptom check saved';

  @override
  String get facilityReadyFindCare =>
      'Your selected verified facility is ready in Find Care.';

  @override
  String get referralDrafted => 'Referral drafted';

  @override
  String get facilityRecommended => 'Facility recommended';

  @override
  String get referralSentStatus => 'Referral sent';

  @override
  String get facilityAccepted => 'Facility accepted';

  @override
  String get careCompleted => 'Care completed';

  @override
  String get referralCancelled => 'Referral cancelled';

  @override
  String get reachedCare => 'Reached care';

  @override
  String get careNotReachedYet => 'Care not reached yet';

  @override
  String get helpRequested => 'Help requested';

  @override
  String get journeyMarkedFollowedUp =>
      'Your journey is marked as followed up.';

  @override
  String get keepReferralClose =>
      'Keep the referral close and seek help if symptoms worsen.';

  @override
  String get supportChannelsReady => 'Support channels are ready.';

  @override
  String get didYouReachCare => 'Did you reach care?';

  @override
  String get yesReachedCare => 'Yes, I reached care';

  @override
  String get notYet => 'Not yet';

  @override
  String get needHelp => 'I need help';

  @override
  String get reached => 'Reached';

  @override
  String get pending => 'Pending';

  @override
  String get needsHelp => 'Needs help';

  @override
  String get followUpReachedMessage =>
      'Good. Your care journey is marked as reached care.';

  @override
  String get followUpNotYetMessage =>
      'That is okay. Keep this referral close and seek help if symptoms worsen.';

  @override
  String get followUpNeedsHelpMessage =>
      'Support options are ready below. Do not wait if symptoms feel severe.';

  @override
  String get followUpUnknownMessage =>
      'A quick check-in helps keep your next step clear.';

  @override
  String get careSupportTitle => 'REPAIR-AI Care Support';

  @override
  String get careSupportSubtitle =>
      'You can reach support through WhatsApp, USSD, or emergency call when symptoms feel severe.';

  @override
  String get emergency => 'Emergency';

  @override
  String get transport => 'Transport';

  @override
  String get website => 'Website';

  @override
  String get phone => 'Phone';

  @override
  String get mobileApp => 'Mobile App';

  @override
  String get findCareTitle => 'Find Care';

  @override
  String get openFacilityDirections => 'Open facility directions';

  @override
  String get transportRequestQueued => 'Transport request queued.';

  @override
  String get referralAlreadyCompleted => 'Referral already completed.';

  @override
  String get referralStatusUpdated => 'Referral status updated.';

  @override
  String get markAccepted => 'Mark accepted';

  @override
  String get markCompleted => 'Mark completed';

  @override
  String get restartReferral => 'Restart referral';

  @override
  String get viewReportsTimeline => 'View reports timeline';

  @override
  String get chpWorkspaceTitle => 'CHP field workspace';

  @override
  String get chpWorkspaceSubtitle =>
      'Review active mothers, follow referrals, and keep urgent cases moving.';

  @override
  String get activeCases => 'Active cases';

  @override
  String get highPriority => 'High priority';

  @override
  String get pendingFollowUps => 'Pending follow-ups';

  @override
  String get caseQueue => 'Case queue';

  @override
  String get allCases => 'All';

  @override
  String get noCasesMatchFilter => 'No cases match this filter.';

  @override
  String get callMother => 'Call mother';

  @override
  String get message => 'Message';

  @override
  String get markContacted => 'Mark contacted';

  @override
  String get drugRegistry => 'Drug registry';

  @override
  String get contacted => 'Contacted';

  @override
  String get assignedArea => 'Assigned area';

  @override
  String get lastUpdate => 'Last update';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get backendOfflineTitle => 'Using saved care data';

  @override
  String get backendOfflineMessage =>
      'Care services are not reachable right now. Saved reports remain available.';

  @override
  String get backendConnectedTitle => 'Connected to care services';

  @override
  String get backendConnectedMessage =>
      'Reports, follow-ups, prescriptions, and alerts can sync here.';

  @override
  String get completeCareProfile => 'Complete care profile';

  @override
  String get completeCareProfileSubtitle =>
      'Add health and location details when ready so referrals and follow-ups work better.';

  @override
  String get careReports => 'Reports';

  @override
  String get careFollowUps => 'Follow-ups';

  @override
  String get carePrescriptions => 'Prescriptions';

  @override
  String get careAlerts => 'Alerts';

  @override
  String get noFollowUpsYet => 'No follow-ups are scheduled yet.';

  @override
  String get noPrescriptionsYet => 'No prescriptions have been shared yet.';

  @override
  String get noAlertsYet => 'No alerts right now.';

  @override
  String get verifiedFacility => 'Verified facility';

  @override
  String get verifiedReferralSource =>
      'Referral options come from the verified REPAIR-AI facility registry.';

  @override
  String get nearbyVerifiedFacilities => 'Nearby verified facilities';

  @override
  String get noVerifiedNearbyFacilities =>
      'No verified nearby facilities found. Try county search or contact support.';

  @override
  String get locationOffFacilityFallback =>
      'Location is off. We can still show verified facilities from your county.';

  @override
  String get facilitiesLoadError =>
      'Facilities could not be loaded. Check connection and try again.';

  @override
  String get showingCurrentLocationFacilities =>
      'Showing verified facilities near your current location.';

  @override
  String get mapDataAttribution => '© OpenStreetMap contributors';

  @override
  String get aiScreeningReferralChecked =>
      'AI screening has checked your symptoms and referral need.';

  @override
  String get findVerifiedCareNow => 'Find verified care now';

  @override
  String get viewVerifiedCareOptions => 'View verified care options';

  @override
  String get nearbyMapResults => 'Nearby map results';

  @override
  String get unverifiedMapResult => 'Map result, not clinically verified';

  @override
  String get mapResultsNotClinical =>
      'These extra map results come from OpenStreetMap. Use verified facilities for clinical referral decisions.';

  @override
  String get verifiedCareNearYou => 'Verified care near you';

  @override
  String verifiedFacilitiesCount(int count) => 'Verified facilities: $count';

  @override
  String mapResultsCount(int count) => 'Map results: $count';

  @override
  String get viewMoreMapResults => 'View more map results';

  @override
  String get showFewerMapResults => 'Show fewer map results';

  @override
  String get submitForAiRiskScreening => 'Submit for AI risk screening';

  @override
  String get reviewForAiScreening => 'Review for AI screening';

  @override
  String get runAiRiskScreening => 'Run AI risk screening';

  @override
  String get aiAssistedScreening => 'AI-assisted screening';

  @override
  String get guidedAiCheck => 'Guided AI check';

  @override
  String get guidedAiCheckTitle => 'Tell us what is happening';

  @override
  String get guidedAiCheckSubtitle =>
      'AI screening uses your symptoms and description to estimate risk and referral need. It supports care decisions; it is not a diagnosis.';

  @override
  String get describeSymptomsNaturally => 'Describe it in your own words';

  @override
  String get describeSymptomsNaturallyHint =>
      'You can type or speak. Mention bleeding, pain, dizziness, fever, movement changes, or anything that worries you.';

  @override
  String get triageTextMode => 'Text';

  @override
  String get triageTextModeSubtitle => 'Type symptoms in your own words.';

  @override
  String get triageVoiceRecordingMode => 'Voice recording';

  @override
  String get triageVoiceRecordingSubtitle =>
      'Record symptoms and let REPAIR-AI transcribe them.';

  @override
  String get triageVoiceCallMode => 'Call voice assistant';

  @override
  String get triageVoiceCallSubtitle =>
      'Call the REPAIR-AI voice line when it is available.';

  @override
  String get startVoiceRecording => 'Start recording';

  @override
  String get stopVoiceRecording => 'Stop and transcribe';

  @override
  String get transcribingVoice => 'Transcribing your voice...';

  @override
  String get voiceRecordingReady =>
      'Voice transcript is ready. Review it before AI screening.';

  @override
  String get voiceRecordingUnavailable =>
      'Voice recording is not ready yet. You can type your symptoms.';

  @override
  String get voiceAssistantUnavailable =>
      'The voice assistant number is not set up yet. You can type or record symptoms here.';

  @override
  String get callRepairAiVoiceAssistant => 'Call REPAIR-AI voice assistant';

  @override
  String get aiReady => 'AI ready';

  @override
  String get aiUnavailable => 'AI unavailable';

  @override
  String get aiTimedOut => 'AI took too long';

  @override
  String get aiReadinessChecking => 'Checking AI';

  @override
  String get aiStagePreparing => 'Preparing your report';

  @override
  String get aiStagePreparingSubtitle =>
      'We are checking your care profile and symptom details.';

  @override
  String get aiStagePreparingShort => 'Prepare';

  @override
  String get aiStageSending => 'Sending symptoms securely';

  @override
  String get aiStageSendingSubtitle =>
      'Your symptoms are being saved for this care check.';

  @override
  String get aiStageSendingShort => 'Send';

  @override
  String get aiStageAnalyzing => 'AI screening in progress';

  @override
  String get aiStageAnalyzingSubtitle =>
      'REPAIR-AI is checking risk level, urgency, and what to do next.';

  @override
  String get aiStageAnalyzingShort => 'Screen';

  @override
  String get aiStageReferral => 'Checking referral need';

  @override
  String get aiStageReferralSubtitle =>
      'We are looking for signs that verified care may be needed.';

  @override
  String get aiStageReferralShort => 'Referral';

  @override
  String get aiStageSaving => 'Saving your care record';

  @override
  String get aiStageSavingSubtitle =>
      'Your result is being prepared for your care timeline.';

  @override
  String get aiStageSavingShort => 'Save';

  @override
  String get aiUnavailableActionsTitle => 'AI screening is not ready yet';

  @override
  String get aiUnavailableActionsSubtitle =>
      'We will not guess a risk result. You can retry, edit your symptoms, contact support, or find verified care.';

  @override
  String get editSymptoms => 'Edit symptoms';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get typeInstead => 'Type instead';

  @override
  String get retryVoiceUpload => 'Retry voice upload';

  @override
  String get voiceRequestingMic => 'Checking microphone access...';

  @override
  String get voiceRecordingNow => 'Recording now. Speak naturally.';

  @override
  String get voiceStopping => 'Stopping recording...';

  @override
  String get voiceUploading => 'Sending voice recording...';

  @override
  String get patientStatedAge => 'Patient-stated age';

  @override
  String get ageNotProvided =>
      'Age was not provided. We will not guess it from symptoms.';

  @override
  String get noAgeGuessingSafety =>
      'If you mention your age, we treat it as patient-stated context. The app does not guess age from symptoms.';

  @override
  String get aiServiceUnavailable =>
      'AI screening is unavailable right now. Please retry, edit symptoms, contact support, or seek care if symptoms feel severe.';

  @override
  String get patientProfileRequiredForAi =>
      'Please sign in and complete your care profile before backend AI screening.';

  @override
  String get symptomStrengthQuestion => 'How strong are the symptoms?';

  @override
  String get symptomStartQuestion => 'When did this start?';

  @override
  String get symptomSeverityMild => 'Mild';

  @override
  String get symptomSeverityModerate => 'Moderate';

  @override
  String get symptomSeveritySevere => 'Severe';

  @override
  String get symptomDurationToday => 'Today';

  @override
  String get symptomDurationTwoDays => '1-2 days';

  @override
  String get symptomDurationThreePlus => '3+ days';

  @override
  String get screeningSafetyCopy =>
      'Screening is not a diagnosis. Seek care if symptoms feel severe or worsening.';

  @override
  String get ancSpecialCases => 'ANC special cases';

  @override
  String get ancSpecialCasesSubtitle =>
      'Rh factor, anaemia, BP checks, infections, and next ANC action';

  @override
  String get ancProfileEmpty =>
      'No ANC special-case profile has been recorded yet.';

  @override
  String get ancProfileRecordedByCareTeam =>
      'Recorded by your care team. Use this to ask clear questions during ANC visits.';

  @override
  String get askProviderToUpdateAnc =>
      'Ask your provider or CHP to update this after your next ANC check.';

  @override
  String get ancContextForReferral =>
      'ANC context that may affect referral planning';

  @override
  String get ancContextForRisk =>
      'ANC context considered alongside this screening';

  // -- Risk result screen labels
  @override
  String get yourAssessment => 'Your Assessment';

  @override
  String get riskCallToActionHigh => 'Seek Care Now';

  @override
  String get riskCallToActionModerate => 'Monitor Closely';

  @override
  String get riskCallToActionLow => 'Continue Check-ups';

  @override
  String confidenceLabel(String pct) => 'Confidence: $pct%';

  @override
  String get riskUrgentInstructions =>
      'Do not wait. Go to a health facility now or call for help.';

  @override
  String get whatYouReported => 'What you reported';

  @override
  String get whatYouShouldDo => 'What you should do';

  @override
  String get newCheck => 'New Check';

  @override
  String get findFacility => 'Find Facility';

  @override
  String get viewCare => 'View Care';

  @override
  String get discussResultWithAi => 'Discuss this result with AI';

  @override
  String get screeningSourceAiAssisted => 'AI Assisted';

  @override
  String get screeningSourceQuickCheck => 'Quick Check';

  @override
  String get riskSubtitleHigh => 'This needs urgent medical attention';

  @override
  String get riskSubtitleModerate => 'This needs a check-up soon';

  @override
  String get riskSubtitleLow => 'Keep up with your regular visits';

  @override
  String weeksPregnantWithTrimester(String weeks, String trimester) =>
      '$weeks weeks pregnant • $trimester';

  // -- Chat / case list labels
  @override
  String get aiAnalyzingYourCase => 'AI is analyzing your case...';

  @override
  String get submitSymptomsForFirstCase =>
      'Submit symptoms below to create your first case.';

  @override
  String get chatWithCareAssistantHint =>
      'Your chat with the Care Assistant will appear here.';

  @override
  String get chatSenderYou => 'You';

  @override
  String get chatSenderCareAssistant => 'Care Assistant';

  @override
  String get caseRiskHigh => 'High Risk';

  @override
  String get caseRiskModerate => 'Moderate Risk';

  @override
  String get caseRiskLow => 'Low Risk';

  @override
  String get caseStatusActive => 'Active';

  @override
  String get caseStatusAnalyzing => 'Analyzing';

  @override
  String get caseStatusReferred => 'Referred';

  // -- Referral / action labels
  @override
  String get whatsApp => 'WhatsApp';

  // -- Video splash
  @override
  String get appMaternalHealthPlatform => 'Maternal Health Platform';
}

String _dayPart() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'morning';
  if (hour < 17) return 'afternoon';
  return 'evening';
}
