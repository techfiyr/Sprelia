// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionBack => 'Back';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String stepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get welcomeContinueWithEmail => 'Continue with Email';

  @override
  String get welcomeSignInUnavailable =>
      'Sign-in isn\'t set up in this build yet.';

  @override
  String get authSignInTitle => 'Welcome back';

  @override
  String get authSignInSubtitle => 'Sign in to continue your practice.';

  @override
  String get authCreateTitle => 'Create your account';

  @override
  String get authCreateSubtitle => 'It only takes a minute.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authSignInAction => 'Sign in';

  @override
  String get authCreateAction => 'Create account';

  @override
  String get authSwitchToCreate => 'New here? Create an account';

  @override
  String get authSwitchToSignIn => 'Already have an account? Sign in';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String authResetSent(String email) {
    return 'If an account exists for $email, we\'ve sent a link to reset your password.';
  }

  @override
  String get authEmailInvalid => 'Please enter a valid email address.';

  @override
  String get authPasswordTooShort => 'Use at least 8 characters.';

  @override
  String get splashLoading => 'Getting things ready…';

  @override
  String get onboardingInterfaceLanguageTitle =>
      'Which language should the app use?';

  @override
  String get onboardingInterfaceLanguageSubtitle =>
      'You can change this later in your profile.';

  @override
  String get onboardingMoreLanguagesSoon =>
      'More app languages are coming soon.';

  @override
  String get onboardingNativeLanguageTitle => 'What\'s your first language?';

  @override
  String get onboardingNativeLanguageSubtitle =>
      'We\'ll use it to make explanations clearer for you.';

  @override
  String get onboardingSearchLanguages => 'Search languages';

  @override
  String get onboardingNoLanguageMatch => 'No languages match your search.';

  @override
  String get onboardingGoalsTitle => 'What would you like to practice?';

  @override
  String get onboardingGoalsSubtitle => 'Choose all that apply.';

  @override
  String get goalEveryday => 'Everyday English';

  @override
  String get goalEverydayDescription => 'Daily conversations and routines';

  @override
  String get goalCareer => 'Career and interviews';

  @override
  String get goalCareerDescription =>
      'Job interviews and talking about your work';

  @override
  String get goalBusiness => 'Business communication';

  @override
  String get goalBusinessDescription => 'Meetings, presentations and clients';

  @override
  String get goalTravelSocial => 'Travel and social life';

  @override
  String get goalTravelSocialDescription =>
      'Trips, new places and making friends';

  @override
  String get goalAcademic => 'Academic English';

  @override
  String get goalAcademicDescription =>
      'Class discussions and explaining ideas';

  @override
  String get goalConfidence => 'Speaking confidence';

  @override
  String get goalConfidenceDescription => 'Feel relaxed when you speak';

  @override
  String get onboardingLevelTitle =>
      'How would you describe your English today?';

  @override
  String get onboardingLevelSubtitle =>
      'This is a starting point, not a test. You can change it anytime.';

  @override
  String get levelA1 => 'Beginner';

  @override
  String get levelA1Description => 'I can use simple words and phrases.';

  @override
  String get levelA2 => 'Elementary';

  @override
  String get levelA2Description =>
      'I can talk about familiar, everyday topics.';

  @override
  String get levelB1 => 'Intermediate';

  @override
  String get levelB1Description =>
      'I can handle most daily situations and share opinions.';

  @override
  String get levelB2 => 'Upper intermediate';

  @override
  String get levelB2Description =>
      'I can discuss many topics and speak fairly fluently.';

  @override
  String get levelC1 => 'Advanced';

  @override
  String get levelC1Description =>
      'I can express myself fluently on complex topics.';

  @override
  String get levelNotSure => 'I\'m not sure';

  @override
  String get levelNotSureDescription =>
      'No problem. We\'ll start gently and adjust as you practice.';

  @override
  String get onboardingDailyGoalTitle =>
      'How long would you like to practice each day?';

  @override
  String get onboardingDailyGoalSubtitle =>
      'A small daily habit makes a big difference.';

  @override
  String dailyGoalMinutes(int minutes) {
    return '$minutes minutes a day';
  }

  @override
  String get dailyGoal5 => 'A quick daily warm-up';

  @override
  String get dailyGoal10 => 'A great everyday habit';

  @override
  String get dailyGoal15 => 'Steady, noticeable progress';

  @override
  String get onboardingAccentTitle => 'Which accent would you like to hear?';

  @override
  String get onboardingAccentSubtitle =>
      'Every accent is correct English. This only changes how your tutor sounds.';

  @override
  String get accentAmerican => 'American English';

  @override
  String get accentBritish => 'British English';

  @override
  String get accentAustralian => 'Australian English';

  @override
  String get accentInternational => 'International / no preference';

  @override
  String get onboardingCreatePlan => 'Create my plan';

  @override
  String get onboardingSaving => 'Saving your answers…';

  @override
  String get planTitle => 'Your learning plan is ready';

  @override
  String get planSubtitle =>
      'Here\'s how we\'ll start. Your plan adapts as you practice.';

  @override
  String get planGoals => 'Your goals';

  @override
  String get planLevel => 'Starting point';

  @override
  String get planDailyTarget => 'Daily target';

  @override
  String get planSuggestedPractice => 'Suggested practice';

  @override
  String get planRecommendedTutor => 'Recommended tutor';

  @override
  String get planStartPracticing => 'Start practicing';

  @override
  String get homeGreetingMorning => 'Good morning!';

  @override
  String get homeGreetingAfternoon => 'Good afternoon!';

  @override
  String get homeGreetingEvening => 'Good evening!';

  @override
  String homeGreetingMorningName(String name) {
    return 'Good morning, $name!';
  }

  @override
  String homeGreetingAfternoonName(String name) {
    return 'Good afternoon, $name!';
  }

  @override
  String homeGreetingEveningName(String name) {
    return 'Good evening, $name!';
  }

  @override
  String get homeSubtitle => 'Ready to practice your English?';

  @override
  String get homeTodayGoal => 'Today\'s goal';

  @override
  String homeTodayProgress(int done, int goal) {
    return '$done of $goal minutes';
  }

  @override
  String homeTodayMinutes(int minutes) {
    return '$minutes minutes today';
  }

  @override
  String homeFreeTimeLeft(int minutes) {
    return '$minutes min of free speaking time left today';
  }

  @override
  String get homeStartSpeaking => 'Start Speaking';

  @override
  String get homeRecommended => 'Recommended for you';

  @override
  String get homeReview => 'Review';

  @override
  String get homeMistakeVault => 'Mistake Vault';

  @override
  String get homeMistakeVaultEmpty =>
      'Your corrections will appear here after practice.';

  @override
  String get homeVocabulary => 'Vocabulary';

  @override
  String get homeVocabularyEmpty =>
      'Useful new words will appear here after practice.';

  @override
  String get homeYourProgress => 'Your progress';

  @override
  String homeStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
      zero: 'No streak yet',
    );
    return '$_temp0';
  }

  @override
  String homeWeeklyMinutes(int minutes) {
    return '$minutes min this week';
  }

  @override
  String homeWeeklySessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions this week',
      one: '1 session this week',
      zero: 'No sessions this week',
    );
    return '$_temp0';
  }

  @override
  String get practiceTitle => 'Practice';

  @override
  String get practiceSubtitle => 'Choose a real-life situation to practice.';

  @override
  String get practiceFreeConversation => 'Free conversation';

  @override
  String get practiceFreeConversationDescription =>
      'Talk about anything with a tutor of your choice.';

  @override
  String practiceScenarioCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scenarios',
      one: '1 scenario',
    );
    return '$_temp0';
  }

  @override
  String practiceAboutMinutes(int minutes) {
    return 'About $minutes min';
  }

  @override
  String practiceLevels(String range) {
    return 'Levels $range';
  }

  @override
  String get tutorsTitle => 'Choose your tutor';

  @override
  String get tutorsVoiceSoon => 'Voice coming soon';

  @override
  String get tutorsRecommended => 'Recommended';

  @override
  String get prepareTitle => 'Get ready';

  @override
  String get prepareObjectives => 'What you\'ll practice';

  @override
  String get prepareVocabulary => 'Useful words and phrases';

  @override
  String get prepareFreeConversationObjective =>
      'Speak naturally about a topic you choose.';

  @override
  String get prepareDuration => 'Recommended duration';

  @override
  String get prepareFreeTime => 'Free speaking time left today';

  @override
  String prepareMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get prepareChangeTutor => 'Change tutor';

  @override
  String get prepareStart => 'Start conversation';

  @override
  String prepareVoiceComingSoon(String name) {
    return 'Voice practice with $name is coming soon.';
  }

  @override
  String get prepareMicrophoneNote =>
      'When you start, we\'ll ask to use your microphone so you can talk with your tutor.';

  @override
  String get preparePrivacyNote =>
      'Your voice is streamed to our AI provider to power the conversation. We save the text transcript to create your feedback. Raw audio is not stored.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileLearningPreferences => 'Learning preferences';

  @override
  String get profileAccent => 'Preferred accent';

  @override
  String get profileNativeLanguage => 'First language';

  @override
  String get practicePremium => 'Premium';

  @override
  String get preparePremiumNote =>
      'This is a Premium scenario. Premium plans are coming soon.';

  @override
  String prepareTutorNotSuited(String name) {
    return '$name isn\'t set up for this scenario. Choose another tutor.';
  }

  @override
  String get tutorsForScenario => 'Tutors who can help with this scenario';

  @override
  String get feedbackAnalyzing => 'Analyzing your conversation…';

  @override
  String get feedbackPracticeNext => 'Practice next';

  @override
  String get practiceChooseAnotherCategory =>
      'Choose another category to practice.';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authOrDivider => 'or';

  @override
  String get authGoogleUnavailable => 'Google sign-in will be available soon.';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String verifyEmailBody(String email) {
    return 'We sent a verification link to $email. Open it on this device, then come back here.';
  }

  @override
  String get verifyEmailCheck => 'I\'ve verified my email';

  @override
  String get verifyEmailResend => 'Resend email';

  @override
  String verifyEmailResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get verifyEmailSent =>
      'Verification email sent. Check your inbox and spam folder.';

  @override
  String get verifyEmailNotYet =>
      'Your email isn\'t verified yet. Open the link in the email we sent, then try again.';

  @override
  String get verifyEmailUseAnotherAccount => 'Use a different account';

  @override
  String get profileAccountSection => 'Account';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your Sprelia account, profile, preferences and learning progress. This can\'t be undone.';

  @override
  String get deleteAccountConfirm => 'Delete permanently';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get reauthTitle => 'Confirm it\'s you';

  @override
  String get reauthPasswordBody =>
      'For your security, enter your password to continue.';

  @override
  String get reauthGoogleBody =>
      'For your security, sign in with Google again to continue.';

  @override
  String get reauthContinue => 'Continue';

  @override
  String get deleteAccountInProgress => 'Deleting your account…';

  @override
  String get commonSave => 'Save';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get profileSaved => 'Saved.';

  @override
  String get profileDisplayName => 'Display name';

  @override
  String get profileDisplayNameHint => 'Shown on your home screen. Leave empty to remove it.';

  @override
  String get profileTimeZone => 'Time zone';

  @override
  String profileUseDeviceTimeZone(String zone) {
    return 'Use this device\'s time zone (${zone})';
  }

  @override
  String get profileTimeZoneNote => 'Your daily practice time resets at midnight in this time zone. You can change it once a day.';

  @override
  String get profilePracticeSection => 'Practice';

  @override
  String get profilePreferredTutor => 'Preferred tutor';

  @override
  String get profileTutorAutomatic => 'Choose for me';

  @override
  String get profileReminders => 'Practice reminders';

  @override
  String get profileRemindersNote => 'Reminders will start once notifications are available in the app.';

  @override
  String get profilePrivacySection => 'Privacy and data';

  @override
  String get profileExportData => 'Copy my data (JSON)';

  @override
  String get profileExportDone => 'Your data was copied to the clipboard.';

  @override
  String get profileInterfaceLanguage => 'App language';

  @override
  String get profilePolicies => 'Privacy Policy and Terms are available on the Sprelia website.';
}
