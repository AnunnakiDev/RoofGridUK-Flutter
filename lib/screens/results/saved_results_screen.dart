import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:roofgrid_uk/app/auth/providers/auth_provider.dart';
import 'package:roofgrid_uk/app/auth/services/permissions_service.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';

class SavedResultsScreen extends ConsumerStatefulWidget {
  const SavedResultsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SavedResultsScreen> createState() => _SavedResultsScreenState();
}

class _SavedResultsScreenState extends ConsumerState<SavedResultsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    // Check if user can access this feature
    if (user == null || !PermissionsService.canSaveCalculationResults(user)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Results')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium,
                size: 64,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                'Pro Feature',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Saving and managing calculation results\nis available to Pro users only.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to upgrade screen
                  context.push('/upgrade');
                },
                child: const Text('Upgrade to Pro'),
              ),
            ],
          ),
        ),
      );
    }

    // Pro user view
    final resultsAsync = _searchQuery.isEmpty
        ? ref.watch(savedResultsProvider)
        : ref.watch(searchResultsProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Results'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by project name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No saved results yet'
                        : 'No results found for "$_searchQuery"',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Your saved calculations will appear here'
                        : 'Try a different search term',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: results.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final result = results[index];
              return _buildResultCard(context, result, index);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSortFilterOptions,
        tooltip: 'Sort and Filter',
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  void _showSortFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Sort by'),
              subtitle: const Text('Date (newest first)'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () {
                // TODO: Show sort options dialog
                Navigator.pop(context);
                _showSortOptions();
              },
            ),
            ListTile(
              title: const Text('Filter by Calculation Type'),
              trailing: const Icon(Icons.filter_alt),
              onTap: () {
                // TODO: Show filter options dialog
                Navigator.pop(context);
                _showFilterOptions();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sort By'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              // TODO: Implement sorting by date (newest first)
              Navigator.pop(context);
            },
            child: const Text('Date (newest first)'),
          ),
          SimpleDialogOption(
            onPressed: () {
              // TODO: Implement sorting by date (oldest first)
              Navigator.pop(context);
            },
            child: const Text('Date (oldest first)'),
          ),
          SimpleDialogOption(
            onPressed: () {
              // TODO: Implement sorting by name (A-Z)
              Navigator.pop(context);
            },
            child: const Text('Project name (A-Z)'),
          ),
          SimpleDialogOption(
            onPressed: () {
              // TODO: Implement sorting by name (Z-A)
              Navigator.pop(context);
            },
            child: const Text('Project name (Z-A)'),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter By Type'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              // TODO: Show all results
              Navigator.pop(context);
            },
            child: const Text('All Results'),
          ),
          SimpleDialogOption(
            onPressed: () {
              // TODO: Filter to show only vertical calculations
              Navigator.pop(context);
            },
            child: const Text('Vertical Calculations'),
          ),
          SimpleDialogOption(
            onPressed: () {
              // TODO: Filter to show only horizontal calculations
              Navigator.pop(context);
            },
            child: const Text('Horizontal Calculations'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, SavedResult result, int index) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final formattedDate = dateFormat.format(result.timestamp);

    final isVertical = result.type == CalculationType.vertical;
    final tileInfo = result.tile;

    return Dismissible(
      key: Key(result.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Result?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        final user = ref.read(currentUserProvider).valueOrNull;
        if (user != null) {
          await ref
              .read(resultsServiceProvider)
              .deleteResult(user.uid, result.id);

          // Show confirmation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Result deleted'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: null, // TODO: Implement undo functionality
                ),
              ),
            );
          }
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to details
            ref.read(selectedResultProvider.notifier).state = result;
            context.push('/results/detail');
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isVertical ? Icons.straighten : Icons.grid_4x4,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.projectName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildFavoriteButton(result),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tile: ${tileInfo['name']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Date: $formattedDate',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      onPressed: () {
                        // Navigate to edit screen
                        ref.read(selectedResultProvider.notifier).state =
                            result;
                        ref.read(editedResultProvider.notifier).state = result;
                        context.push('/results/edit');
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Export'),
                      onPressed: () {
                        ref.read(selectedResultProvider.notifier).state =
                            result;
                        context.push('/results/detail');
                        // Show export options after a short delay
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            _showExportOptions(context, result);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.2, end: 0),
    );
  }

  Widget _buildFavoriteButton(SavedResult result) {
    // TODO: Implement favorite functionality
    return IconButton(
      icon: const Icon(Icons.star_border),
      onPressed: () {
        // Mark as favorite
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorite functionality coming soon!')),
        );
      },
      tooltip: 'Add to favorites',
    );
  }

  void _showExportOptions(BuildContext context, SavedResult result) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement PDF export
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Export as Image'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement image export
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image export coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send via Email'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement email sharing
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email sharing coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
