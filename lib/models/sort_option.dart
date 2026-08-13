/// Sorting options available for library shelves and document lists.
enum SortOption {
  recentlyAdded('Recently Modified', 'Shelves that received items most recently first'),
  populatedFirst('Populated First', 'Shelves with items first (Default)'),
  alphabeticalAsc('Alphabetical (A to Z)', 'Sort shelves alphabetically from A to Z'),
  alphabeticalDesc('Alphabetical (Z to A)', 'Sort shelves alphabetically from Z to A'),
  mostItems('Most Items First', 'Shelves with highest document count'),
  leastItems('Least Items First', 'Shelves with lowest document count');

  final String label;
  final String description;

  const SortOption(this.label, this.description);

  static SortOption fromName(String? name) {
    if (name == null) return SortOption.populatedFirst;
    return SortOption.values.firstWhere(
      (e) => e.name == name,
      orElse: () => SortOption.populatedFirst,
    );
  }
}
