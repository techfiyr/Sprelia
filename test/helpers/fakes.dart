import 'dart:async';

import 'package:speakdaily/core/auth/auth_repository.dart';
import 'package:speakdaily/core/errors/app_failure.dart';
import 'package:speakdaily/features/account/account_repository.dart';
import 'package:speakdaily/features/practice/data/catalog_repository.dart';
import 'package:speakdaily/features/practice/data/practice_models.dart';
import 'package:speakdaily/features/profile/data/profile_models.dart';
import 'package:speakdaily/features/profile/data/profile_repository.dart';
import 'package:speakdaily/features/tutors/tutor.dart';

class FakeAuthRepository implements AuthRepository, AccountAuth {
  FakeAuthRepository({AuthUser? signedIn}) : _user = signedIn;

  AuthUser? _user;
  final _controller = StreamController<AuthUser?>.broadcast();
  final signInCalls = <(String, String)>[];
  final createCalls = <(String, String)>[];
  final resetCalls = <String>[];
  AuthFailure? nextFailure;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async => _user == null ? null : 'fake-token';

  void _setUser(AuthUser? u) {
    _user = u;
    _controller.add(u);
  }

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    signInCalls.add((email, password));
    if (nextFailure != null) throw nextFailure!;
    _setUser(AuthUser(uid: 'uid-1', email: email));
  }

  @override
  Future<void> createAccountWithEmail({required String email, required String password}) async {
    createCalls.add((email, password));
    if (nextFailure != null) throw nextFailure!;
    // Like Firebase: a new email/password account starts unverified.
    _setUser(AuthUser(uid: 'uid-1', email: email, providerIds: const ['password']));
  }

  @override
  Future<void> sendPasswordReset(String email) async => resetCalls.add(email);

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _setUser(null);
  }

  // --- AccountAuth -----------------------------------------------------------
  int signOutCalls = 0;
  bool googleAvailable = false;
  AuthFailure? nextGoogleFailure;
  int googleCalls = 0;
  int verificationSends = 0;

  /// What the server says on the next [refreshUser] (the user clicked the link).
  bool verifiedOnServer = false;
  final reauthPasswords = <String>[];
  int reauthGoogleCalls = 0;
  AuthFailure? nextReauthFailure;

  @override
  bool get googleSignInAvailable => googleAvailable;

  @override
  Future<void> signInWithGoogle() async {
    googleCalls++;
    if (nextGoogleFailure != null) throw nextGoogleFailure!;
    _setUser(const AuthUser(uid: 'uid-1', email: 'learner@gmail.com', emailVerified: true, providerIds: ['google.com']));
  }

  @override
  Future<void> sendEmailVerification() async => verificationSends++;

  @override
  Future<AuthUser?> refreshUser() async {
    final u = _user;
    if (u == null) return null;
    if (verifiedOnServer && !u.emailVerified) {
      _setUser(AuthUser(uid: u.uid, email: u.email, emailVerified: true, providerIds: u.providerIds));
    }
    return _user;
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    reauthPasswords.add(password);
    if (nextReauthFailure != null) throw nextReauthFailure!;
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    reauthGoogleCalls++;
    if (nextReauthFailure != null) throw nextReauthFailure!;
  }
}

class FakeAccountRepository implements AccountRepository {
  int deleteCalls = 0;
  Object? error;

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    if (error != null) throw error!;
  }
}

/// In-memory stand-in for the backend profile API.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.profile});

  UserProfile? profile;
  final saveCalls = <(LearningPreferences, bool)>[];
  final createdTimezones = <String>[];
  Object? saveError;
  Object? dashboardError;
  Dashboard dashboard = const Dashboard(
    displayName: 'Rahim',
    dailyGoalMinutes: 10,
    todaySpeakingSeconds: 240,
    freeAllowanceSeconds: 600,
    remainingFreeSeconds: 360,
    streakDays: 3,
    weeklySpeakingSeconds: 1800,
    weeklySessions: 4,
    recommendation: LearningPlan(tutorId: 'emma', scenarioId: 'introductions', categoryIds: ['everyday']),
  );

  @override
  Future<UserProfile?> getProfile() async => profile;

  @override
  Future<UserProfile> createProfile({required String timezone, String? displayName}) async {
    createdTimezones.add(timezone);
    return profile ??= UserProfile(uid: 'uid-1', timezone: timezone, onboardingStatus: OnboardingStatus.notStarted);
  }

  @override
  Future<(UserProfile, LearningPlan?)> saveOnboarding(LearningPreferences preferences, {required bool complete}) async {
    saveCalls.add((preferences, complete));
    if (saveError != null) throw saveError!;
    profile = UserProfile(
      uid: profile!.uid,
      email: profile!.email,
      timezone: profile!.timezone,
      onboardingStatus: complete ? OnboardingStatus.completed : OnboardingStatus.inProgress,
      preferences: preferences,
    );
    return (profile!, complete ? const LearningPlan(tutorId: 'alex', scenarioId: 'job-interviews', categoryIds: ['professional']) : null);
  }

  @override
  Future<Dashboard> getDashboard() async {
    if (dashboardError != null) throw dashboardError!;
    return dashboard;
  }

  final profileUpdates = <Map<String, Object?>>[];
  final preferenceUpdates = <Map<String, Object?>>[];
  Object? updateError;
  int exports = 0;

  UserProfile _copy({
    String? displayName,
    bool clearDisplayName = false,
    String? timezone,
    String? preferredTutorId,
    bool clearPreferredTutor = false,
    bool? practiceReminders,
    LearningPreferences? preferences,
  }) {
    final p = profile!;
    return UserProfile(
      uid: p.uid,
      email: p.email,
      displayName: clearDisplayName ? null : displayName ?? p.displayName,
      timezone: timezone ?? p.timezone,
      onboardingStatus: p.onboardingStatus,
      preferences: preferences ?? p.preferences,
      preferredTutorId: clearPreferredTutor ? null : preferredTutorId ?? p.preferredTutorId,
      practiceReminders: practiceReminders ?? p.practiceReminders,
    );
  }

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async {
    profileUpdates.add(update.toJson());
    if (updateError != null) throw updateError!;
    return profile = _copy(
      displayName: update.displayName,
      clearDisplayName: update.clearDisplayName,
      timezone: update.timezone,
      preferredTutorId: update.preferredTutorId,
      clearPreferredTutor: update.clearPreferredTutor,
      practiceReminders: update.practiceReminders,
    );
  }

  @override
  Future<UserProfile> updatePreferences(LearningPreferences preferences) async {
    preferenceUpdates.add(preferences.toJson());
    if (updateError != null) throw updateError!;
    final current = profile!.preferences;
    return profile = _copy(
      preferences: LearningPreferences(
        interfaceLanguage: preferences.interfaceLanguage ?? current.interfaceLanguage,
        nativeLanguage: preferences.nativeLanguage ?? current.nativeLanguage,
        goals: preferences.goals.isNotEmpty ? preferences.goals : current.goals,
        level: preferences.level ?? current.level,
        dailyGoalMinutes: preferences.dailyGoalMinutes ?? current.dailyGoalMinutes,
        accent: preferences.accent ?? current.accent,
      ),
    );
  }

  @override
  Future<String> exportData() async {
    exports++;
    return '{"format":"sprelia-export-v1","profile":{"uid":"${profile!.uid}"}}';
  }
}

class FakeCatalogRepository implements CatalogRepository {
  Object? error;

  static const tutors = [
    Tutor(
      id: 'emma',
      name: 'Emma',
      title: 'Friendly English Coach',
      personality: ['Warm', 'Patient'],
      description: 'A patient coach.',
      minLevel: 'A1',
      maxLevel: 'B1',
      categoryIds: ['everyday'],
      tone: TutorTone.primary,
      voiceAvailable: true,
    ),
    Tutor(
      id: 'alex',
      name: 'Alex',
      title: 'Professional Communication Coach',
      personality: ['Professional'],
      description: 'Interviews and meetings.',
      minLevel: 'A2',
      maxLevel: 'C1',
      categoryIds: ['professional'],
      tone: TutorTone.primaryDark,
    ),
  ];

  static const categories = [
    PracticeCategory(
      id: 'everyday',
      title: 'Everyday',
      description: 'Talk about your daily life.',
      icon: 'everyday',
      scenarios: [
        Scenario(
          id: 'introductions',
          title: 'Introductions',
          description: 'Introduce yourself.',
          minLevel: 'A1',
          maxLevel: 'B1',
          objectives: ['Say who you are'],
          estimatedMinutes: 5,
          suggestedTutorId: 'emma',
          vocabulary: ['nice to meet you'],
          compatibleTutorIds: ['emma'],
        ),
      ],
    ),
    PracticeCategory(
      id: 'professional',
      title: 'Professional',
      description: 'Communicate at work.',
      icon: 'professional',
      scenarios: [
        Scenario(
          id: 'job-interviews',
          title: 'Job interviews',
          description: 'Answer interview questions.',
          minLevel: 'A2',
          maxLevel: 'C1',
          objectives: ['Introduce your experience', 'Give examples'],
          estimatedMinutes: 8,
          suggestedTutorId: 'alex',
          vocabulary: ['strengths'],
          compatibleTutorIds: ['alex'],
        ),
        Scenario(
          id: 'presentations',
          title: 'Presentations',
          description: 'Guide your listeners.',
          minLevel: 'B1',
          maxLevel: 'C1',
          objectives: ['Open a talk', 'Handle a question'],
          estimatedMinutes: 10,
          suggestedTutorId: 'alex',
          vocabulary: ['to sum up'],
          compatibleTutorIds: ['alex'],
          premium: true,
        ),
      ],
    ),
  ];

  @override
  Future<List<Tutor>> getTutors() async {
    if (error != null) throw error!;
    return tutors;
  }

  @override
  Future<List<PracticeCategory>> getCategories() async {
    if (error != null) throw error!;
    return categories;
  }
}

const networkFailure = NetworkFailure();
