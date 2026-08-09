enum HomeLoadStatus { loading, empty, valid, partial, failure }

/// Règles d'autorisation calculées en un seul endroit à partir des lectures.
class HomeActionAvailability {
  const HomeActionAvailability({
    required this.trainingMutationsAllowed,
    required this.sessionStartAllowed,
  });

  final bool trainingMutationsAllowed;
  final bool sessionStartAllowed;
}
