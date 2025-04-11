import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/auth/models/user_model.dart';
import 'package:roofgrid_uk/app/auth/providers/auth_provider.dart';
import 'package:roofgrid_uk/app/auth/services/permissions_service.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/app/tiles/models/tile_model.dart';
import 'package:roofgrid_uk/app/tiles/services/tile_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:roofgridk_app/screens/auth/subscription_screen.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isVertical = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _isVertical = _tabController.index == 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roofing Calculator'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.straighten),
              text: 'Vertical',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.grid_4x4),
              text: 'Horizontal',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showCalculatorInfo(context);
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => _buildCalculatorContent(context, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading user data: $error',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Execute calculation
          if (_isVertical) {
            _calculateVertical();
          } else {
            _calculateHorizontal();
          }
        },
        label: const Text('Calculate'),
        icon: const Icon(Icons.calculate),
      ),
    );
  }

  Widget _buildCalculatorContent(BuildContext context, UserModel? user) {
    if (user == null) {
      return const Center(
        child: Text('User data not found. Please sign in again.'),
      );
    }

    // Use PermissionsService to check permissions
    final canUseMultipleRafters =
        PermissionsService.getMaxAllowedRafters(user) > 1;
    final canUseAdvancedOptions =
        PermissionsService.canUseAdvancedOptions(user);
    final canExport = PermissionsService.canExportResults(user);

    // Show trial expiration warning if applicable
    if (PermissionsService.isTrialAboutToExpire(user)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTrialExpirationWarning(context, user);
      });
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // Vertical Calculator (Batten Gauge)
        VerticalCalculatorTab(
          user: user,
          canUseMultipleRafters: canUseMultipleRafters,
          canUseAdvancedOptions: canUseAdvancedOptions,
          canExport: canExport,
        ),

        // Horizontal Calculator (Tile Spacing)
        HorizontalCalculatorTab(
          user: user,
          canUseMultipleWidths: canUseMultipleRafters,
          canUseAdvancedOptions: canUseAdvancedOptions,
          canExport: canExport,
        ),
      ],
    );
  }

  void _showTrialExpirationWarning(BuildContext context, UserModel user) {
    final remainingDays = PermissionsService.getRemainingTrialDays(user);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro Trial Expiring Soon'),
        content: Text(
          'Your Pro trial will expire in $remainingDays ${remainingDays == 1 ? 'day' : 'days'}. '
          'Upgrade now to keep access to all Pro features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _calculateVertical() {
    if (_tabController.index == 0) {
      final verticalTabState =
          context.findAncestorStateOfType<_VerticalCalculatorTabState>();
      if (verticalTabState != null) {
        verticalTabState.calculate();
      }
    }
  }

  void _calculateHorizontal() {
    if (_tabController.index == 1) {
      final horizontalTabState =
          context.findAncestorStateOfType<_HorizontalCalculatorTabState>();
      if (horizontalTabState != null) {
        horizontalTabState.calculate();
      }
    }
  }

  void _showCalculatorInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isVertical ? 'Vertical Calculator' : 'Horizontal Calculator',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isVertical
                    ? 'The Vertical Calculator helps determine batten gauge (spacing) based on rafter height.'
                    : 'The Horizontal Calculator helps determine tile spacing based on width measurements.',
              ),
              const SizedBox(height: 16),
              Text(
                'How to use:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _isVertical
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Enter your rafter height(s)'),
                        Text('2. Select your tile type'),
                        Text('3. Tap Calculate'),
                        Text('4. View your batten gauge and results'),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Enter your width measurement(s)'),
                        Text('2. Select your tile type'),
                        Text('3. Tap Calculate'),
                        Text('4. View your tile spacing and results'),
                      ],
                    ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class VerticalCalculatorTab extends ConsumerStatefulWidget {
  final bool isPro;

  const VerticalCalculatorTab({
    super.key,
    required this.isPro,
  });

  @override
  ConsumerState<VerticalCalculatorTab> createState() =>
      _VerticalCalculatorTabState();
}

class _VerticalCalculatorTabState extends ConsumerState<VerticalCalculatorTab> {
  final List<TextEditingController> _rafterControllers = [
    TextEditingController()
  ];
  final List<String> _rafterNames = ['Rafter 1'];
  double _gutterOverhang = 50.0;
  String _useDryRidge = 'NO';

  @override
  void dispose() {
    for (final controller in _rafterControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(calculatorProvider);
    final defaultTiles = ref.watch(defaultTilesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tile selection section
          Text(
            'Select Tile',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildTileSelector(defaultTiles),

          const SizedBox(height: 16),

          // Additional options
          Text(
            'Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // Gutter overhang
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Gutter Overhang:'),
              ),
              Expanded(
                flex: 5,
                child: Slider(
                  value: _gutterOverhang,
                  min: 25.0,
                  max: 75.0,
                  divisions: 10,
                  label: '${_gutterOverhang.round()} mm',
                  onChanged: (value) {
                    setState(() {
                      _gutterOverhang = value;
                    });
                    ref
                        .read(calculatorProvider.notifier)
                        .setGutterOverhang(value);
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text('${_gutterOverhang.round()} mm'),
              ),
            ],
          ),

          // Dry Ridge Option
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Use Dry Ridge:'),
              ),
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'YES',
                      groupValue: _useDryRidge,
                      onChanged: (value) {
                        setState(() {
                          _useDryRidge = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseDryRidge(value!);
                      },
                    ),
                    const Text('Yes'),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: 'NO',
                      groupValue: _useDryRidge,
                      onChanged: (value) {
                        setState(() {
                          _useDryRidge = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseDryRidge(value!);
                      },
                    ),
                    const Text('No'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Rafter height input section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rafter Height',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.isPro)
                TextButton.icon(
                  onPressed: _addRafter,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Rafter'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          ..._buildRafterInputs(),

          // Pro feature notice for free users
          if (!widget.isPro)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pro Feature',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const Text(
                          'Upgrade to Pro to calculate multiple rafters at once',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to upgrade screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Upgrade feature coming soon!'),
                        ),
                      );
                    },
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),

          // Results section
          if (calcState.verticalResult != null) _buildResultsCard(calcState),

          // Error display
          if (calcState.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      calcState.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(CalculatorState calcState) {
    final result = calcState.verticalResult!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vertical Calculation Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  result.solution,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),

            // Results grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                _resultItem('Input Rafter', '${result.inputRafter} mm'),
                _resultItem('Total Courses', result.totalCourses.toString()),
                _resultItem('Ridge Offset', '${result.ridgeOffset} mm'),
                if (result.underEaveBatten != null)
                  _resultItem(
                      'Under Eave Batten', '${result.underEaveBatten} mm'),
                if (result.eaveBatten != null)
                  _resultItem('Eave Batten', '${result.eaveBatten} mm'),
                _resultItem('1st Batten', '${result.firstBatten} mm'),
                if (result.cutCourse != null)
                  _resultItem('Cut Course', '${result.cutCourse} mm'),
                _resultItem('Gauge', result.gauge),
                if (result.splitGauge != null)
                  _resultItem('Split Gauge', result.splitGauge!),
              ],
            ),

            // Warning message if any
            if (result.warning != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(result.warning!)),
                  ],
                ),
              ),

            // Action buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Save calculation
                  },
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Share calculation
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _resultItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Text(value),
        ),
      ],
    );
  }

  List<Widget> _buildRafterInputs() {
    final List<Widget> rafterInputs = [];

    // Only show one input for free users
    final int displayCount = widget.isPro ? _rafterControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      rafterInputs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              if (widget.isPro) ...[
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: TextEditingController(text: _rafterNames[i]),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _rafterNames[i] = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: widget.isPro ? 5 : 8,
                child: TextField(
                  controller: _rafterControllers[i],
                  decoration: InputDecoration(
                    labelText: widget.isPro ? null : 'Rafter height in mm',
                    hintText: 'e.g., 6000',
                    suffixText: 'mm',
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              if (widget.isPro && _rafterControllers.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeRafter(i),
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Remove rafter',
                ),
              ],
            ],
          ),
        ),
      );
    }

    return rafterInputs;
  }

  Widget _buildTileSelector(List<TileModel> tiles) {
    final calculatorNotifier = ref.read(calculatorProvider.notifier);
    final selectedTile = ref.watch(calculatorProvider).selectedTile;

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      value: selectedTile?.id,
      hint: const Text('Select tile type'),
      items: tiles.map((tile) {
        return DropdownMenuItem(
          value: tile.id,
          child: Text('${tile.name} (${tile.materialTypeString})'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          final selected = tiles.firstWhere((tile) => tile.id == value);
          calculatorNotifier.setTile(selected);
        }
      },
    );
  }

  void _addRafter() {
    if (!widget.isPro) return;

    setState(() {
      _rafterControllers.add(TextEditingController());
      _rafterNames.add('Rafter ${_rafterControllers.length}');
    });
  }

  void _removeRafter(int index) {
    if (!widget.isPro) return;
    if (_rafterControllers.length <= 1) return;

    setState(() {
      _rafterControllers[index].dispose();
      _rafterControllers.removeAt(index);
      _rafterNames.removeAt(index);
    });
  }

  void calculate() {
    final calculatorState = ref.read(calculatorProvider);
    if (calculatorState.selectedTile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a tile type first'),
        ),
      );
      return;
    }

    // Get rafter heights from controllers
    final List<double> rafterHeights = [];
    final displayCount = widget.isPro ? _rafterControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      final heightText = _rafterControllers[i].text.trim();
      if (heightText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Please enter a height for ${widget.isPro ? _rafterNames[i] : 'the rafter'}'),
          ),
        );
        return;
      }

      final double? height = double.tryParse(heightText);
      if (height == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Invalid height value for ${widget.isPro ? _rafterNames[i] : 'the rafter'}'),
          ),
        );
        return;
      }

      rafterHeights.add(height);
    }

    // Calculate
    ref.read(calculatorProvider.notifier).calculateVertical(rafterHeights);
  }
}

class HorizontalCalculatorTab extends StatefulWidget {
  final bool isPro;

  const HorizontalCalculatorTab({
    super.key,
    required this.isPro,
  });

  @override
  State<HorizontalCalculatorTab> createState() =>
      _HorizontalCalculatorTabState();
}

class _HorizontalCalculatorTabState extends State<HorizontalCalculatorTab> {
  final List<TextEditingController> _widthControllers = [
    TextEditingController()
  ];
  final List<String> _widthNames = ['Width 1'];

  @override
  void dispose() {
    for (final controller in _widthControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tile selection section
          Text(
            'Select Tile',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildTileSelector(),

          const SizedBox(height: 24),

          // Width input section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Width Measurement',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.isPro)
                TextButton.icon(
                  onPressed: _addWidth,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Width'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          ..._buildWidthInputs(),

          // Pro feature notice for free users
          if (!widget.isPro)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pro Feature',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const Text(
                          'Upgrade to Pro to calculate multiple widths at once',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to upgrade screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Upgrade feature coming soon!'),
                        ),
                      );
                    },
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildWidthInputs() {
    final List<Widget> widthInputs = [];

    // Only show one input for free users
    final int displayCount = widget.isPro ? _widthControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      widthInputs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              if (widget.isPro) ...[
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: TextEditingController(text: _widthNames[i]),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _widthNames[i] = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: widget.isPro ? 5 : 8,
                child: TextField(
                  controller: _widthControllers[i],
                  decoration: InputDecoration(
                    labelText: widget.isPro ? null : 'Width in mm',
                    hintText: 'e.g., 5000',
                    suffixText: 'mm',
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              if (widget.isPro && _widthControllers.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeWidth(i),
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Remove width',
                ),
              ],
            ],
          ),
        ),
      );
    }

    return widthInputs;
  }

  Widget _buildTileSelector() {
    // Placeholder for tile selector - will be expanded in future implementations
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      hint: const Text('Select tile type'),
      items: const [
        DropdownMenuItem(
          value: 'standard',
          child: Text('Standard UK Plain Tile'),
        ),
        DropdownMenuItem(
          value: 'double_roman',
          child: Text('Double Roman'),
        ),
        DropdownMenuItem(
          value: 'slate',
          child: Text('Slate'),
        ),
      ],
      onChanged: (value) {
        // Tile selection logic
      },
    );
  }

  void _addWidth() {
    if (!widget.isPro) return;

    setState(() {
      _widthControllers.add(TextEditingController());
      _widthNames.add('Width ${_widthControllers.length}');
    });
  }

  void _removeWidth(int index) {
    if (!widget.isPro) return;
    if (_widthControllers.length <= 1) return;

    setState(() {
      _widthControllers[index].dispose();
      _widthControllers.removeAt(index);
      _widthNames.removeAt(index);
    });
  }

  void calculate() {
    // Add implementation or call appropriate method
  }
}
