import 'package:flutter/material.dart';
import 'package:the_shelf/screens/classifier_debug_screen.dart';
import 'package:the_shelf/services/shelf_classifier_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _ShelfView(),
    _CollectionsView(),
    _InsightsView(),
    _SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shelves),
            selectedIcon: Icon(Icons.shelves),
            label: 'Shelf',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark),
            label: 'Collections',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showImportModal(context);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showImportModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: FutureBuilder<void>(
              future: ShelfClassifierService.instance.ensureInitialized(),
              builder: (context, snapshot) {
                final bool isReady = snapshot.connectionState == ConnectionState.done;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    if (!isReady)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Loading classifier model...'),
                          ],
                        ),
                      ),
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: const Text('Import PDF / Document'),
                      subtitle: const Text('Add files from your device storage'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.center_focus_weak_outlined),
                      title: const Text('Scan Book or Document'),
                      subtitle: const Text('Use camera to scan physical pages'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.link_outlined),
                      title: const Text('Add Web Article'),
                      subtitle: const Text('Save articles or URL documents'),
                      onTap: () => Navigator.pop(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.bug_report_outlined),
                      title: const Text('Classifier Verification Debugger'),
                      subtitle: const Text('Test on-device text classifier predictions'),
                      trailing: isReady
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                          : const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ClassifierDebugScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ShelfView extends StatelessWidget {
  const _ShelfView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('The Shelf'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () {},
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Items'),
                  selected: true,
                  onSelected: (val) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Books'),
                  selected: false,
                  onSelected: (val) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('PDFs'),
                  selected: false,
                  onSelected: (val) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Articles'),
                  selected: false,
                  onSelected: (val) {},
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your shelf is empty',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first book or document.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionsView extends StatelessWidget {
  const _CollectionsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_special_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No collections created yet',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Classification & Insights'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'On-device AI Classifier Ready',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Imported documents will be automatically categorized here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('Appearance'),
            subtitle: Text('Theme and display settings'),
          ),
          ListTile(
            leading: Icon(Icons.memory_outlined),
            title: Text('On-Device Classification'),
            subtitle: Text('Configure local machine learning models'),
          ),
          ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Storage & Indexing'),
            subtitle: Text('Manage cached documents and search indexes'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About The Shelf'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }
}
