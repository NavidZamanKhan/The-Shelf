/// Sorting options available for library shelves and document lists.
enum SortOption {
  populatedFirst('Populated First', 'Shelves with items first (Default)'),
  alphabeticalAsc('Alphabetical (A to Z)', 'Sort shelves alphabetically from A to Z'),
  alphabeticalDesc('Alphabetical (Z to A)', 'Sort shelves alphabetically from Z to A'),
  mostItems('Most Items First', 'Shelves with highest document count'),
  leastItems('Least Items First', 'Shelves with lowest document count');

  final String label;
  final String description;

  const SortOption(this.label, this.description);
}
