export 'languages/app_localizations_en.dart';
export 'languages/app_localizations_sw.dart';

import 'languages/app_localizations_en.dart' as en;
import 'languages/app_localizations_sw.dart' as sw;

/// Base API for app localizations.
///
/// IMPORTANT: The generated classes `AppLocalizationsEn` and `AppLocalizationsSw`
/// extend this type.
import 'package:flutter/material.dart';

abstract class AppLocalizations {
  const AppLocalizations([this.locale = 'en']);

  final String locale;

  /// Used by app-localization delegates wiring in `main.dart`.
  static const Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[];

  /// Used by app-localization delegates wiring in `main.dart`.
  static const Iterable<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw'),
  ];

  static AppLocalizations of(BuildContext context) {
    // AppLocalizations is not a Flutter widget; it's stored in Localizations.
    final loc = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    // During early startup (e.g. hot restart), delegates might not be
    // resolved yet. Fall back to English rather than crashing.
    return loc ??
        switch (localeFromContext(context)) {
          'sw' => sw.AppLocalizationsSw('sw'),
          _ => en.AppLocalizationsEn('en'),
        };
  }

  static String localeFromContext(BuildContext context) {
    final lc = Localizations.localeOf(context);
    return lc.languageCode.toLowerCase();
  }

  String get appTitle;

  String get login;
  String get loginSubtitle;

  String get name;
  String get nameRequired;
  String get nameTooShort;

  String get email;
  String get emailRequired;
  String get emailInvalid;

  String get password;
  String get passwordRequired;
  String get passwordMinLength;

  String get loginButton;
  String get forgotPassword;

  String get reportSymptoms;
  String get reportSymptomsSubtitle;

  String get myReferrals;
  String get myReferralsSubtitle;

  String get chatWithRepairAI;
  String get chatSubtitle;

  String get myReports;
  String get myReportsSubtitle;

  String get savedFacilities;
  String get savedFacilitiesSubtitle;

  String get notifications;
  String get notificationsSubtitle;

  String get language;
  String get helpSupport;
  String get helpSupportSubtitle;

  String get logout;

  String get home;
  String get triage;
  String get profile;
  String get myProfile;

  String get mentalHealth;
  String get mentalHealthSupport;
  String get mentalHealthSubtitle;

  String get nearestFacility;

  String get dashboard;
  String get chpDashboard;
  String get welcomeBack;
  String get pendingCases;

  String get quickActions;
  String get reportSymptomsTitle;
  String get weeksPregnant;
  String get selectSymptoms;
  String get getAIRiskAssessment;
  String get aiRiskAssessment;
  String get basedOnSymptoms;
  String get recommendation;
  String get triageBack;
  String get startReferral;
  String get smartReferrals;
  String get recommendedFacility;
  String get otherNearbyOptions;
  String get sendReferral;
  String get referralSent;
  String get noReportsYet;
  String get close;

  String get riskLevel;
  String get howAreYouFeeling;
  String get feelingsMatter;
  String get thankYouForSharing;
  String get talkToCounselor;
  String get joinSupportGroup;

  String get loginSavedMock;
  String get loginSuccess;
  String get loggedOutSuccess;

  String get analyzingStep1;
  String get analyzingStep2;
  String get analyzingStep3;
  String get onDeviceAnalysis;
  String get analyzingSubtitle;
  String get analysisFailed;
  String get retry;
  String get whyThisResult;
  String get modelConfidenceLabel;
  String get selectSymptomHint;
  String get gestationalWeekHelper;
  String get tryDemo;
  String get yourPregnancyMatters;
  String get reportSymptomsEarly;
  String get worksOffline;
  String get lastReport;
  String get viewReport;
  String get goNowUrgency;
  String get within24Hours;
  String get referralSuccessTitle;
  String get referralSuccessMessage;
  String get viewHistory;
  String get weeksPregnantLabel;
  String get symptomNote;
  String get skip;
  String get getStarted;
  String get facilityDistance;
  String get mapPlaceholder;

  String get appearance;
  String get lightMode;
  String get darkMode;
  String get continueButton;
  String get getStartedButton;
  String get builtForKenyaTrust;

  String get smartCareTagline;
  String get platformDescription;
  String get howItWorksTitle;
  String get howItWorksSubtitle;
  String get seeHowItWorks;
  String get learnMoreWebsite;
  String get fullPlatform;
  String get explainableAI;
  String get howItWorksCardTitle;
  String get howItWorksCardSubtitle;

  String get step01Title;
  String get step01Description;
  String get step02Title;
  String get step02Description;
  String get step03Title;
  String get step03Description;
  String get step04Title;
  String get step04Description;

  String get onboarding1Title;
  String get onboarding1Description;
  String get onboarding2Title;
  String get onboarding2Description;
  String get onboarding3Title;
  String get onboarding3Description;
  String get onboarding4Title;
  String get onboarding4Description;

  String get featureAiTriage;
  String get featureGisReferrals;
  String get featureWhoGuidance;
  String get feature247;

  String get platformImpactTitle;
  String get platformImpactSource;
  String get statReferralTime;
  String get statAncAttendance;
  String get statHighRiskDetected;

  String get privacyNotice;
  String get callEmergency;
  String get openInMaps;

  String get symptomBleeding;
  String get symptomSeverePain;
  String get symptomCramping;
  String get symptomDizziness;
  String get symptomFever;
  String get symptomNausea;
  String get symptomReducedMovement;
  String get symptomSpotting;

  String get riskLow;
  String get riskModerate;
  String get riskHigh;

  String get reasonBleeding;
  String get reasonSeverePain;
  String get reasonDizziness;
  String get reasonReducedMovement;
  String get reasonFever;
  String get reasonSpotting;
  String get reasonCramping;
  String get reasonNausea;
  String get reasonMultiple;
  String get reasonDefault;

  String get recHigh;
  String get recModerate;
  String get recLow;

  String get trimesterFirst;
  String get trimesterSecond;
  String get trimesterThird;

  String get motherQuote1;
  String get motherQuote2;
  String get motherQuote3;
  String get motherQuoteAuthor;

  String get agreeTermsPrefix;
  String get agreeTermsLink;
  String get mustAgreeTerms;
  String get termsTitle;
  String get termsBody;
  String get welcomeHome;
  String get signingIn;

  String get forgotPasswordMock;
  String get routeError;
  String get routeNotFound;
  String get genericError;
  String get timeoutError;
  String get demoChipLabel;

  String get feelingGood;
  String get feelingOkay;
  String get feelingSad;
  String get feelingVerySad;
  String get feelingAnxious;
  String get feelingGuidance;
  String get supportGroupComingSoon;

  String get referralHospitalName;
  String get facilityChip247;
  String get facilityChipUltrasound;
  String get facilityChipBloodBank;
  String get facilitySecondary;
  String get facilityDistanceSample;

  String get voiceListen;
  String get voiceStop;
  String get voiceNotAvailable;
  String get symptomNotesHint;

  String get languageEnglish;
  String get languageSwahili;
  String get languageChangedEn;
  String get languageChangedSw;

  String get whatsAppMessage;
  String get nearestFacilitySubtitle;

  String get chooseAccessSubtitle;
  String get continueAsGuest;
  String get continueWithPhoneOtp;
  String get fastSignInSubtitle;
  String get createAccountTitle;
  String get createAccountSubtitle;
  String get providerAccess;
  String get signInTitle;
  String get signInSubtitle;
  String get providerSignInTitle;
  String get providerSignInSubtitle;
  String get staffIdOrEmail;
  String get staffIdRequired;
  String get continueToChpDashboard;
  String get chpAccessHint;
  String get phoneOtpLabel;
  String get emailLabel;
  String get phoneNumberLabel;
  String get sendOtp;
  String get useGuestAccessInstead;
  String get newToRepairCreateAccount;
  String get createAccountIntro;
  String get careAreaLabel;
  String get consentText;
  String get continueToPhoneVerification;
  String get alreadyHaveAccountSignIn;
  String get otpCodeLabel;
  String get verifyAndContinue;
  String get resendOtp;
  String get recoverAccountTitle;
  String get recoverAccountSubtitle;
  String get recoveryInstructions;
  String get sendRecoveryInstructions;
  String get backToSignIn;
  String get useUssdTitle;
  String get useUssdSubtitle;
  String get copyUssdCode;
  String get dialUssd;
  String get ussdCopied;

  String get homeSupportChannelsSuffix;
  String get todayCareTitle;
  String get todayCareSavedTitle;
  String get todayCareEmptyTitle;
  String get pregnancyWeek;
  String get noCheckYet;
  String get followReferral;
  String get getHelp;
  String get checkCare;
  String get useUssd;
  String get todayCareEmptyMessage;
  String get todayCareReachedMessage;
  String get todayCareNeedsHelpMessage;
  String get todayCareCompletedMessage;
  String get todayCareDefaultMessage;
  String get referralDraft;
  String get careFound;
  String get accepted;
  String get completed;
  String get cancelled;
  String get careTimelineTitle;
  String get careTimelineEmptyMessage;
  String get careTimelineSavedMessage;
  String get noCareStepsYet;
  String get startWithSymptomCheck;
  String get symptomCheckSaved;
  String get facilityReadyFindCare;
  String get referralDrafted;
  String get facilityRecommended;
  String get referralSentStatus;
  String get facilityAccepted;
  String get careCompleted;
  String get referralCancelled;
  String get reachedCare;
  String get careNotReachedYet;
  String get helpRequested;
  String get journeyMarkedFollowedUp;
  String get keepReferralClose;
  String get supportChannelsReady;
  String get didYouReachCare;
  String get yesReachedCare;
  String get notYet;
  String get needHelp;
  String get reached;
  String get pending;
  String get needsHelp;
  String get followUpReachedMessage;
  String get followUpNotYetMessage;
  String get followUpNeedsHelpMessage;
  String get followUpUnknownMessage;
  String get careSupportTitle;
  String get careSupportSubtitle;
  String get emergency;
  String get transport;
  String get findCareTitle;
  String get openFacilityDirections;
  String get transportRequestQueued;
  String get referralAlreadyCompleted;
  String get referralStatusUpdated;
  String get markAccepted;
  String get markCompleted;
  String get restartReferral;
  String get viewReportsTimeline;
  String get chpWorkspaceTitle;
  String get chpWorkspaceSubtitle;
  String get activeCases;
  String get highPriority;
  String get pendingFollowUps;
  String get caseQueue;
  String get allCases;
  String get noCasesMatchFilter;
  String get callMother;
  String get message;
  String get markContacted;
  String get contacted;
  String get assignedArea;
  String get lastUpdate;
  String get today;
  String get yesterday;
}
