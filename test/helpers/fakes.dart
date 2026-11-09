import 'dart:async';

import 'package:speakdaily/core/auth/auth_repository.dart';
import 'package:speakdaily/core/errors/app_failure.dart';
import 'package:speakdaily/features/practice/data/catalog_repository.dart';
import 'package:speakdaily/features/practice/data/practice_models.dart';
import 'package:speakdaily/features/profile/data/profile_models.dart';
import 'package:speakdaily/features/profile/data/profile_repository.dart';
import 'package:speakdaily/features/tutors/tutor.dart';

class FakeAuthRepository implements AuthRepository {
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
    _setUser(AuthUser(uid: 'uid-1', email: email));
  }

  @override
  Future<void> sendPasswordReset(String email) async => resetCalls.add(email);

  @override
  Future<void> signOut() async => _setUser(null);
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
