/// Riverpod providers for the repository and the Hive-derived lists.
///
/// The repository is created lazily and shared app-wide. After each mutation
/// it calls the `onChange` hook, which bumps a revision counter; list
/// providers watch that counter so History/Saved rebuild automatically.
library;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/translation_record.dart';
import '../data/repositories/translation_repository.dart';

final translationRepositoryProvider =
    FutureProvider<TranslationRepository>((ref) async {
  final repo = await TranslationRepository.create();
  // Bump revision on every mutation so dependent list providers refresh.
  repo.onChange = () => ref.read(_historyRevisionProvider.notifier).update((state) => state + 1);
  ref.onDispose(repo.close);
  return repo;
});

/// Private revision marker — bumped on any change.
final _historyRevisionProvider = StateProvider<int>((ref) => 0);

/// Synchronous accessor that returns the repo if ready, else null. Use this in
/// widgets that already guard for the loading state elsewhere.
TranslationRepository? repositoryOrNull(Ref ref) {
  return ref.read(translationRepositoryProvider).valueOrNull;
}

// ---- Live list providers (history + favorites) ----

final historyProvider = Provider<List<TranslationRecord>>((ref) {
  ref.watch(_historyRevisionProvider);
  final repo = ref.watch(translationRepositoryProvider).valueOrNull;
  return repo?.history() ?? const [];
});

final favoritesProvider = Provider<List<TranslationRecord>>((ref) {
  ref.watch(_historyRevisionProvider);
  final repo = ref.watch(translationRepositoryProvider).valueOrNull;
  return repo?.favorites() ?? const [];
});

final foldersProvider = Provider<List<String>>((ref) {
  ref.watch(_historyRevisionProvider);
  final repo = ref.watch(translationRepositoryProvider).valueOrNull;
  return repo?.folders() ?? const [];
});
