import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepProgress(int current, int total);

  /// No description provided for @welcomeContinueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get welcomeContinueWithEmail;

  /// No description provided for @welcomeSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign-in isn\'t set up in this build yet.'**
  String get welcomeSignInUnavailable;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your practice.'**
  String get authSignInSubtitle;

  /// No description provided for @authCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateTitle;

  /// No description provided for @authCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It only takes a minute.'**
  String get authCreateSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInAction;

  /// No description provided for @authCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAction;

  /// No description provided for @authSwitchToCreate.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authSwitchToCreate;

  /// No description provided for @authSwitchToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authSwitchToSignIn;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, we\'ve sent a link to reset your password.'**
  String authResetSent(String email);

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get authPasswordTooShort;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting things ready…'**
  String get splashLoading;

  /// No description provided for @onboardingInterfaceLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Which language should the app use?'**
  String get onboardingInterfaceLanguageTitle;

  /// No description provided for @onboardingInterfaceLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in your profile.'**
  String get onboardingInterfaceLanguageSubtitle;

  /// No description provided for @onboardingMoreLanguagesSoon.
  ///
  /// In en, this message translates to:
  /// **'More app languages are coming soon.'**
  String get onboardingMoreLanguagesSoon;

  /// No description provided for @onboardingNativeLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your first language?'**
  String get onboardingNativeLanguageTitle;

  /// No description provided for @onboardingNativeLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use it to make explanations clearer for you.'**
  String get onboardingNativeLanguageSubtitle;

  /// No description provided for @onboardingSearchLanguages.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get onboardingSearchLanguages;

  /// No description provided for @onboardingNoLanguageMatch.
  ///
  /// In en, this message translates to:
  /// **'No languages match your search.'**
  String get onboardingNoLanguageMatch;

  /// No description provided for @onboardingGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to practice?'**
  String get onboardingGoalsTitle;

  /// No description provided for @onboardingGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose all that apply.'**
  String get onboardingGoalsSubtitle;

  /// No description provided for @goalEveryday.
  ///
  /// In en, this message translates to:
  /// **'Everyday English'**
  String get goalEveryday;

  /// No description provided for @goalEverydayDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily conversations and routines'**
  String get goalEverydayDescription;

  /// No description provided for @goalCareer.
  ///
  /// In en, this message translates to:
  /// **'Career and interviews'**
  String get goalCareer;

  /// No description provided for @goalCareerDescription.
  ///
  /// In en, this message translates to:
  /// **'Job interviews and talking about your work'**
  String get goalCareerDescription;

  /// No description provided for @goalBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business communication'**
  String get goalBusiness;

  /// No description provided for @goalBusinessDescription.
  ///
  /// In en, this message translates to:
  /// **'Meetings, presentations and clients'**
  String get goalBusinessDescription;

  /// No description provided for @goalTravelSocial.
  ///
  /// In en, this message translates to:
  /// **'Travel and social life'**
  String get goalTravelSocial;

  /// No description provided for @goalTravelSocialDescription.
  ///
  /// In en, this message translates to:
  /// **'Trips, new places and making friends'**
  String get goalTravelSocialDescription;

  /// No description provided for @goalAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic English'**
  String get goalAcademic;

  /// No description provided for @goalAcademicDescription.
  ///
  /// In en, this message translates to:
  /// **'Class discussions and explaining ideas'**
  String get goalAcademicDescription;

  /// No description provided for @goalConfidence.
  ///
  /// In en, this message translates to:
  /// **'Speaking confidence'**
  String get goalConfidence;

  /// No description provided for @goalConfidenceDescription.
  ///
  /// In en, this message translates to:
  /// **'Feel relaxed when you speak'**
  String get goalConfidenceDescription;

  /// No description provided for @onboardingLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you describe your English today?'**
  String get onboardingLevelTitle;

  /// No description provided for @onboardingLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is a starting point, not a test. You can change it anytime.'**
  String get onboardingLevelSubtitle;

  /// No description provided for @levelA1.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelA1;

  /// No description provided for @levelA1Description.
  ///
  /// In en, this message translates to:
  /// **'I can use simple words and phrases.'**
  String get levelA1Description;

  /// No description provided for @levelA2.
  ///
  /// In en, this message translates to:
  /// **'Elementary'**
  String get levelA2;

  /// No description provided for @levelA2Description.
  ///
  /// In en, this message translates to:
  /// **'I can talk about familiar, everyday topics.'**
  String get levelA2Description;

  /// No description provided for @levelB1.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelB1;

  /// No description provided for @levelB1Description.
  ///
  /// In en, this message translates to:
  /// **'I can handle most daily situations and share opinions.'**
  String get levelB1Description;

  /// No description provided for @levelB2.
  ///
  /// In en, this message translates to:
  /// **'Upper intermediate'**
  String get levelB2;

  /// No description provided for @levelB2Description.
  ///
  /// In en, this message translates to:
  /// **'I can discuss many topics and speak fairly fluently.'**
  String get levelB2Description;

  /// No description provided for @levelC1.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelC1;

  /// No description provided for @levelC1Description.
  ///
  /// In en, this message translates to:
  /// **'I can express myself fluently on complex topics.'**
  String get levelC1Description;

  /// No description provided for @levelNotSure.
  ///
  /// In en, this message translates to:
  /// **'I\'m not sure'**
  String get levelNotSure;

  /// No description provided for @levelNotSureDescription.
  ///
  /// In en, this message translates to:
  /// **'No problem. We\'ll start gently and adjust as you practice.'**
  String get levelNotSureDescription;

  /// No description provided for @onboardingDailyGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'How long would you like to practice each day?'**
  String get onboardingDailyGoalTitle;

  /// No description provided for @onboardingDailyGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A small daily habit makes a big difference.'**
  String get onboardingDailyGoalSubtitle;

  /// No description provided for @dailyGoalMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes a day'**
  String dailyGoalMinutes(int minutes);

  /// No description provided for @dailyGoal5.
  ///
  /// In en, this message translates to:
  /// **'A quick daily warm-up'**
  String get dailyGoal5;

  /// No description provided for @dailyGoal10.
  ///
  /// In en, this message translates to:
  /// **'A great everyday habit'**
  String get dailyGoal10;

  /// No description provided for @dailyGoal15.
  ///
  /// In en, this message translates to:
  /// **'Steady, noticeable progress'**
  String get dailyGoal15;

  /// No description provided for @onboardingAccentTitle.
  ///
  /// In en, this message translates to:
  /// **'Which accent would you like to hear?'**
  String get onboardingAccentTitle;

  /// No description provided for @onboardingAccentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every accent is correct English. This only changes how your tutor sounds.'**
  String get onboardingAccentSubtitle;

  /// No description provided for @accentAmerican.
  ///
  /// In en, this message translates to:
  /// **'American English'**
  String get accentAmerican;

  /// No description provided for @accentBritish.
  ///
  /// In en, this message translates to:
  /// **'British English'**
  String get accentBritish;

  /// No description provided for @accentAustralian.
  ///
  /// In en, this message translates to:
  /// **'Australian English'**
  String get accentAustralian;

  /// No description provided for @accentInternational.
  ///
  /// In en, this message translates to:
  /// **'International / no preference'**
  String get accentInternational;

  /// No description provided for @onboardingCreatePlan.
  ///
  /// In en, this message translates to:
  /// **'Create my plan'**
  String get onboardingCreatePlan;

  /// No description provided for @onboardingSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving your answers…'**
  String get onboardingSaving;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Your learning plan is ready'**
  String get planTitle;

  /// No description provided for @planSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s how we\'ll start. Your plan adapts as you practice.'**
  String get planSubtitle;

  /// No description provided for @planGoals.
  ///
  /// In en, this message translates to:
  /// **'Your goals'**
  String get planGoals;

  /// No description provided for @planLevel.
  ///
  /// In en, this message translates to:
  /// **'Starting point'**
  String get planLevel;

  /// No description provided for @planDailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get planDailyTarget;

  /// No description provided for @planSuggestedPractice.
  ///
  /// In en, this message translates to:
  /// **'Suggested practice'**
  String get planSuggestedPractice;

  /// No description provided for @planRecommendedTutor.
  ///
  /// In en, this message translates to:
  /// **'Recommended tutor'**
  String get planRecommendedTutor;

  /// No description provided for @planStartPracticing.
  ///
  /// In en, this message translates to:
  /// **'Start practicing'**
  String get planStartPracticing;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get homeGreetingEvening;

  /// No description provided for @homeGreetingMorningName.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}!'**
  String homeGreetingMorningName(String name);

  /// No description provided for @homeGreetingAfternoonName.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}!'**
  String homeGreetingAfternoonName(String name);

  /// No description provided for @homeGreetingEveningName.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}!'**
  String homeGreetingEveningName(String name);

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to practice your English?'**
  String get homeSubtitle;

  /// No description provided for @homeTodayGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal'**
  String get homeTodayGoal;

  /// No description provided for @homeTodayProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {goal} minutes'**
  String homeTodayProgress(int done, int goal);

  /// No description provided for @homeTodayMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes today'**
  String homeTodayMinutes(int minutes);

  /// No description provided for @homeFreeTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min of free speaking time left today'**
  String homeFreeTimeLeft(int minutes);

  /// No description provided for @homeStartSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Start Speaking'**
  String get homeStartSpeaking;

  /// No description provided for @homeRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get homeRecommended;

  /// No description provided for @homeReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get homeReview;

  /// No description provided for @homeMistakeVault.
  ///
  /// In en, this message translates to:
  /// **'Mistake Vault'**
  String get homeMistakeVault;

  /// No description provided for @homeMistakeVaultEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your corrections will appear here after practice.'**
  String get homeMistakeVaultEmpty;

  /// No description provided for @homeVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get homeVocabulary;

  /// No description provided for @homeVocabularyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Useful new words will appear here after practice.'**
  String get homeVocabularyEmpty;

  /// No description provided for @homeYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get homeYourProgress;

  /// No description provided for @homeStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No streak yet} =1{1-day streak} other{{count}-day streak}}'**
  String homeStreak(int count);

  /// No description provided for @homeWeeklyMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min this week'**
  String homeWeeklyMinutes(int minutes);

  /// No description provided for @homeWeeklySessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sessions this week} =1{1 session this week} other{{count} sessions this week}}'**
  String homeWeeklySessions(int count);

  /// No description provided for @practiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceTitle;

  /// No description provided for @practiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a real-life situation to practice.'**
  String get practiceSubtitle;

  /// No description provided for @practiceFreeConversation.
  ///
  /// In en, this message translates to:
  /// **'Free conversation'**
  String get practiceFreeConversation;

  /// No description provided for @practiceFreeConversationDescription.
  ///
  /// In en, this message translates to:
  /// **'Talk about anything with a tutor of your choice.'**
  String get practiceFreeConversationDescription;

  /// No description provided for @practiceScenarioCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scenario} other{{count} scenarios}}'**
  String practiceScenarioCount(int count);

  /// No description provided for @practiceAboutMinutes.
  ///
  /// In en, this message translates to:
  /// **'About {minutes} min'**
  String practiceAboutMinutes(int minutes);

  /// No description provided for @practiceLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels {range}'**
  String practiceLevels(String range);

  /// No description provided for @tutorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your tutor'**
  String get tutorsTitle;

  /// No description provided for @tutorsVoiceSoon.
  ///
  /// In en, this message translates to:
  /// **'Voice coming soon'**
  String get tutorsVoiceSoon;

  /// No description provided for @tutorsRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get tutorsRecommended;

  /// No description provided for @prepareTitle.
  ///
  /// In en, this message translates to:
  /// **'Get ready'**
  String get prepareTitle;

  /// No description provided for @prepareObjectives.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll practice'**
  String get prepareObjectives;

  /// No description provided for @prepareVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Useful words and phrases'**
  String get prepareVocabulary;

  /// No description provided for @prepareFreeConversationObjective.
  ///
  /// In en, this message translates to:
  /// **'Speak naturally about a topic you choose.'**
  String get prepareFreeConversationObjective;

  /// No description provided for @prepareDuration.
  ///
  /// In en, this message translates to:
  /// **'Recommended duration'**
  String get prepareDuration;

  /// No description provided for @prepareFreeTime.
  ///
  /// In en, this message translates to:
  /// **'Free speaking time left today'**
  String get prepareFreeTime;

  /// No description provided for @prepareMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String prepareMinutes(int minutes);

  /// No description provided for @prepareChangeTutor.
  ///
  /// In en, this message translates to:
  /// **'Change tutor'**
  String get prepareChangeTutor;

  /// No description provided for @prepareStart.
  ///
  /// In en, this message translates to:
  /// **'Start conversation'**
  String get prepareStart;

  /// No description provided for @prepareVoiceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Voice practice with {name} is coming soon.'**
  String prepareVoiceComingSoon(String name);

  /// No description provided for @prepareMicrophoneNote.
  ///
  /// In en, this message translates to:
  /// **'When you start, we\'ll ask to use your microphone so you can talk with your tutor.'**
  String get prepareMicrophoneNote;

  /// No description provided for @preparePrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your voice is streamed to our AI provider to power the conversation. We save the text transcript to create your feedback. Raw audio is not stored.'**
  String get preparePrivacyNote;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileLearningPreferences.
  ///
  /// In en, this message translates to:
  /// **'Learning preferences'**
  String get profileLearningPreferences;

  /// No description provided for @profileAccent.
  ///
  /// In en, this message translates to:
  /// **'Preferred accent'**
  String get profileAccent;

  /// No description provided for @profileNativeLanguage.
  ///
  /// In en, this message translates to:
  /// **'First language'**
  String get profileNativeLanguage;

  /// No description provided for @practicePremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get practicePremium;

  /// No description provided for @preparePremiumNote.
  ///
  /// In en, this message translates to:
  /// **'This is a Premium scenario. Premium plans are coming soon.'**
  String get preparePremiumNote;

  /// No description provided for @prepareTutorNotSuited.
  ///
  /// In en, this message translates to:
  /// **'{name} isn\'t set up for this scenario. Choose another tutor.'**
  String prepareTutorNotSuited(String name);

  /// No description provided for @tutorsForScenario.
  ///
  /// In en, this message translates to:
  /// **'Tutors who can help with this scenario'**
  String get tutorsForScenario;

  /// No description provided for @feedbackAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your conversation…'**
  String get feedbackAnalyzing;

  /// No description provided for @feedbackPracticeNext.
  ///
  /// In en, this message translates to:
  /// **'Practice next'**
  String get feedbackPracticeNext;

  /// No description provided for @practiceChooseAnotherCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose another category to practice.'**
  String get practiceChooseAnotherCategory;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOrDivider;

  /// No description provided for @authGoogleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in will be available soon.'**
  String get authGoogleUnavailable;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to {email}. Open it on this device, then come back here.'**
  String verifyEmailBody(String email);

  /// No description provided for @verifyEmailCheck.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified my email'**
  String get verifyEmailCheck;

  /// No description provided for @verifyEmailResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get verifyEmailResend;

  /// No description provided for @verifyEmailResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String verifyEmailResendIn(int seconds);

  /// No description provided for @verifyEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Check your inbox and spam folder.'**
  String get verifyEmailSent;

  /// No description provided for @verifyEmailNotYet.
  ///
  /// In en, this message translates to:
  /// **'Your email isn\'t verified yet. Open the link in the email we sent, then try again.'**
  String get verifyEmailNotYet;

  /// No description provided for @verifyEmailUseAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get verifyEmailUseAnotherAccount;

  /// No description provided for @profileAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountSection;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your Sprelia account, profile, preferences and learning progress. This can\'t be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteAccountConfirm;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @reauthTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you'**
  String get reauthTitle;

  /// No description provided for @reauthPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'For your security, enter your password to continue.'**
  String get reauthPasswordBody;

  /// No description provided for @reauthGoogleBody.
  ///
  /// In en, this message translates to:
  /// **'For your security, sign in with Google again to continue.'**
  String get reauthGoogleBody;

  /// No description provided for @reauthContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get reauthContinue;

  /// No description provided for @deleteAccountInProgress.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get deleteAccountInProgress;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get commonNotSet;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get profileSaved;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayName;

  /// No description provided for @profileDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on your home screen. Leave empty to remove it.'**
  String get profileDisplayNameHint;

  /// No description provided for @profileTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get profileTimeZone;

  /// No description provided for @profileUseDeviceTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Use this device\'s time zone ({zone})'**
  String profileUseDeviceTimeZone(String zone);

  /// No description provided for @profileTimeZoneNote.
  ///
  /// In en, this message translates to:
  /// **'Your daily practice time resets at midnight in this time zone. You can change it once a day.'**
  String get profileTimeZoneNote;

  /// No description provided for @profilePracticeSection.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get profilePracticeSection;

  /// No description provided for @profilePreferredTutor.
  ///
  /// In en, this message translates to:
  /// **'Preferred tutor'**
  String get profilePreferredTutor;

  /// No description provided for @profileTutorAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Choose for me'**
  String get profileTutorAutomatic;

  /// No description provided for @profileReminders.
  ///
  /// In en, this message translates to:
  /// **'Practice reminders'**
  String get profileReminders;

  /// No description provided for @profileRemindersNote.
  ///
  /// In en, this message translates to:
  /// **'Reminders will start once notifications are available in the app.'**
  String get profileRemindersNote;

  /// No description provided for @profilePrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy and data'**
  String get profilePrivacySection;

  /// No description provided for @profileExportData.
  ///
  /// In en, this message translates to:
  /// **'Copy my data (JSON)'**
  String get profileExportData;

  /// No description provided for @profileExportDone.
  ///
  /// In en, this message translates to:
  /// **'Your data was copied to the clipboard.'**
  String get profileExportDone;

  /// No description provided for @profileInterfaceLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get profileInterfaceLanguage;

  /// No description provided for @profilePolicies.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy and Terms are available on the Sprelia website.'**
  String get profilePolicies;

  /// No description provided for @prepareNoTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s free speaking time. It resets at midnight in your time zone.'**
  String get prepareNoTimeLeft;

  /// No description provided for @conversationTryAgainTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow for more free practice.'**
  String get conversationTryAgainTomorrow;

  /// No description provided for @learnTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learnTitle;

  /// No description provided for @learnMistakeVault.
  ///
  /// In en, this message translates to:
  /// **'Mistake Vault'**
  String get learnMistakeVault;

  /// No description provided for @learnMistakesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Great! No saved corrections yet. Your feedback will appear here after practice.'**
  String get learnMistakesEmpty;

  /// No description provided for @learnVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get learnVocabulary;

  /// No description provided for @learnVocabularyEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved any vocabulary yet. Start a conversation to discover useful new words.'**
  String get learnVocabularyEmpty;

  /// No description provided for @learnMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get learnMastered;

  /// No description provided for @learnLearned.
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get learnLearned;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @progressEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No progress yet'**
  String get progressEmptyTitle;

  /// No description provided for @progressEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your progress will appear here after your first conversations.'**
  String get progressEmptyMessage;

  /// No description provided for @progressMinutes30.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min spoken in the last 30 days'**
  String progressMinutes30(int minutes);

  /// No description provided for @progressSessions30.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions in the last 30 days'**
  String progressSessions30(int count);

  /// No description provided for @progressLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get progressLast7Days;

  /// No description provided for @progressDayMinutes.
  ///
  /// In en, this message translates to:
  /// **'{day}: {minutes} min'**
  String progressDayMinutes(String day, int minutes);

  /// No description provided for @progressMistakes.
  ///
  /// In en, this message translates to:
  /// **'Corrections to review: {open} · mastered: {mastered}'**
  String progressMistakes(int open, int mastered);

  /// No description provided for @progressVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Words saved: {total} · learned: {learned}'**
  String progressVocabulary(int total, int learned);

  /// No description provided for @progressRecentSessions.
  ///
  /// In en, this message translates to:
  /// **'Recent sessions'**
  String get progressRecentSessions;

  /// No description provided for @progressSessionMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String progressSessionMinutes(int minutes);

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Sprelia Premium'**
  String get premiumTitle;

  /// No description provided for @premiumHeadline.
  ///
  /// In en, this message translates to:
  /// **'Practice more, learn faster.'**
  String get premiumHeadline;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'You have Premium. Thank you!'**
  String get premiumActive;

  /// No description provided for @premiumBenefitTime.
  ///
  /// In en, this message translates to:
  /// **'More speaking time every day'**
  String get premiumBenefitTime;

  /// No description provided for @premiumBenefitScenarios.
  ///
  /// In en, this message translates to:
  /// **'Advanced and professional scenarios'**
  String get premiumBenefitScenarios;

  /// No description provided for @premiumBenefitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Detailed feedback after every session'**
  String get premiumBenefitFeedback;

  /// No description provided for @premiumBenefitHistory.
  ///
  /// In en, this message translates to:
  /// **'Your full learning history'**
  String get premiumBenefitHistory;

  /// No description provided for @premiumBenefitNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get premiumBenefitNoAds;

  /// No description provided for @premiumMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly: \$5.99'**
  String get premiumMonthly;

  /// No description provided for @premiumAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual: \$39.99'**
  String get premiumAnnual;

  /// No description provided for @premiumPricesNotFinal.
  ///
  /// In en, this message translates to:
  /// **'Test prices, not final. Your app store shows the actual price before you pay.'**
  String get premiumPricesNotFinal;

  /// No description provided for @premiumUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Premium purchases are not available yet.'**
  String get premiumUnavailable;

  /// No description provided for @premiumSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get premiumSubscribe;

  /// No description provided for @premiumRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get premiumRestore;

  /// No description provided for @premiumManageNote.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions renew automatically and are managed and canceled in your app store account.'**
  String get premiumManageNote;

  /// No description provided for @premiumSee.
  ///
  /// In en, this message translates to:
  /// **'See Premium'**
  String get premiumSee;

  /// No description provided for @profileSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get profileSubscription;

  /// No description provided for @profilePlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get profilePlanFree;

  /// No description provided for @profilePlanPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get profilePlanPremium;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
