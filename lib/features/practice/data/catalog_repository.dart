import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/services/api_client.dart';
import '../../tutors/tutor.dart';
import 'practice_models.dart';

abstract interface class CatalogRepository {
  Future<List<Tutor>> getTutors();
  Future<List<PracticeCategory>> getCategories();
}

class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Tutor>> getTutors() async {
    try {
      final res = await _dio.get<Map<String, Object?>>('/api/v1/tutors');
      return (res.data!['tutors']! as List).map((e) => Tutor.fromJson((e as Map).cast<String, Object?>())).toList();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  @override
  Future<List<PracticeCategory>> getCategories() async {
    try {
      final res = await _dio.get<Map<String, Object?>>('/api/v1/practice/categories');
      return (res.data!['categories']! as List)
          .map((e) => PracticeCategory.fromJson((e as Map).cast<String, Object?>()))
          .toList();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) => ApiCatalogRepository(ref.watch(apiClientProvider)));

/// Catalogue data is not user-specific; keep it for the session.
final tutorsProvider = FutureProvider<List<Tutor>>((ref) => ref.watch(catalogRepositoryProvider).getTutors());
final practiceCategoriesProvider =
    FutureProvider<List<PracticeCategory>>((ref) => ref.watch(catalogRepositoryProvider).getCategories());

/// Tutor by id from the loaded catalogue, or a placeholder while loading/unknown.
final tutorByIdProvider = Provider.family<Tutor, String>((ref, id) {
  final tutors = ref.watch(tutorsProvider).value;
  return tutors?.where((t) => t.id == id).firstOrNull ?? Tutor.placeholder(id);
});

/// Scenario by id with its category, or null.
final scenarioByIdProvider = Provider.family<(PracticeCategory, Scenario)?, String>((ref, id) {
  for (final c in ref.watch(practiceCategoriesProvider).value ?? const <PracticeCategory>[]) {
    for (final s in c.scenarios) {
      if (s.id == id) return (c, s);
    }
  }
  return null;
});
