import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgriduk/models/user_model.dart';
import 'package:roofgriduk/providers/auth_provider.dart';
import 'package:roofgriduk/models/tile_model.dart';
import 'package:roofgriduk/app/calculator/providers/calculator_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:roofgriduk/screens/subscription_screen.dart';
import 'package:roofgriduk/services/permissions_service.dart';
import 'package:flutter/material.dart' as material;

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen>
    with material.TickerProviderStateMixin {
  late material.TabController _tabController;
  bool _isVertical = true;

  @override
  void initState() {
    super.initState();
    _tabController = material.TabController(length: 2, vsync: this);
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
  material.Widget build(material.BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return material.Scaffold(
      appBar: material.AppBar(
        title: const material.Text('Roofing Calculator'),
        bottom: material.TabBar(
          controller: _tabController,
          tabs: const [
            material.Tab(
              icon: material.Icon(material.Icons.straighten),
              text: 'Vertical',
              iconMargin: material.EdgeInsets.only(bottom: 4),
            ),
            material.Tab(
              icon: material.Icon(material.Icons.grid_4x4),
              text: 'Horizontal',
              iconMargin: material.EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
        actions: [
          material.IconButton(
            icon: const material.Icon(material.Icons.info_outline),
            onPressed: () {
              _showCalculatorInfo(context);
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => _buildCalculatorContent(context, user),
        loading: () =>
            const material.Center(child: material.CircularProgressIndicator()),
        error: (error, stackTrace) => material.Center(
          child: material.Text(
            'Error loading user data: $error',
            style: material.Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: material.Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ),
      floatingActionButton: material.FloatingActionButton.extended(
        onPressed: () {
          if (_isVertical) {
            _calculateVertical();
          } else {
            _calculateHorizontal();
          }
        },
        label: const material.Text('Calculate'),
        icon: const material.Icon(material.Icons.calculate),
      ),
    );
  }

  material.Widget _buildCalculatorContent(
      material.BuildContext context, UserModel? user) {
    if (user == null) {
      return const material.Center(
        child: material.Text('User data not found. Please sign in again.'),
      );
    }

    // Use UserModel directly for permissions (stub PermissionsService)
    final canUseMultipleRafters = user.isPro;
    final canUseAdvancedOptions = user.isPro;
    final canExport = user.isPro;
    final canAccessDatabase = user.isPro;

    if (user.isTrialAboutToExpire) {
      material.WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTrialExpirationWarning(context, user);
      });
    }

    return material.TabBarView(
      controller: _tabController,
      children: [
        VerticalCalculatorTab(
          user: user,
          canUseMultipleRafters: canUseMultipleRafters,
          canUseAdvancedOptions: canUseAdvancedOptions,
          canExport: canExport,
          canAccessDatabase: canAccessDatabase,
        ),
        HorizontalCalculatorTab(
          user: user,
          canUseMultipleWidths: canUseMultipleRafters,
          canUseAdvancedOptions: canUseAdvancedOptions,
          canExport: canExport,
          canAccessDatabase: canAccessDatabase,
        ),
      ],
    );
  }

  void _showTrialExpirationWarning(
      material.BuildContext context, UserModel user) {
    final remainingDays = user.remainingTrialDays;

    material.showDialog(
      context: context,
      builder: (context) => material.AlertDialog(
        title: const material.Text('Pro Trial Expiring Soon'),
        content: material.Text(
          'Your Pro trial will expire in $remainingDays ${remainingDays == 1 ? 'day' : 'days'}. '
          'Upgrade now to keep access to all Pro features.',
        ),
        actions: [
          material.TextButton(
            onPressed: () => material.Navigator.of(context).pop(),
            child: const material.Text('Later'),
          ),
          material.FilledButton(
            onPressed: () {
              material.Navigator.of(context).pop();
              context.go('/subscription');
            },
            child: const material.Text('Upgrade Now'),
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

  void _showCalculatorInfo(material.BuildContext context) {
    material.showDialog(
      context: context,
      builder: (context) => material.AlertDialog(
        title: material.Text(
          _isVertical ? 'Vertical Calculator' : 'Horizontal Calculator',
          style: const material.TextStyle(fontWeight: material.FontWeight.bold),
        ),
        content: material.SingleChildScrollView(
          child: material.Column(
            crossAxisAlignment: material.CrossAxisAlignment.start,
            mainAxisSize: material.MainAxisSize.min,
            children: [
              material.Text(
                _isVertical
                    ? 'The Vertical Calculator helps determine batten gauge (spacing) based on rafter height.'
                    : 'The Horizontal Calculator helps determine tile spacing based on width measurements.',
              ),
              const material.SizedBox(height: 16),
              material.Text(
                'How to use:',
                style:
                    material.Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: material.FontWeight.bold,
                        ),
              ),
              const material.SizedBox(height: 8),
              _isVertical
                  ? const material.Column(
                      crossAxisAlignment: material.CrossAxisAlignment.start,
                      children: [
                        material.Text('1. Enter your rafter height(s)'),
                        material.Text('2. Select your tile type'),
                        material.Text('3. Tap Calculate'),
                        material.Text('4. View your batten gauge and results'),
                      ],
                    )
                  : const material.Column(
                      crossAxisAlignment: material.CrossAxisAlignment.start,
                      children: [
                        material.Text('1. Enter your width measurement(s)'),
                        material.Text('2. Select your tile type'),
                        material.Text('3. Tap Calculate'),
                        material.Text('4. View your tile spacing and results'),
                      ],
                    ),
            ],
          ),
        ),
        actions: [
          material.TextButton(
            onPressed: () => material.Navigator.of(context).pop(),
            child: const material.Text('Close'),
          ),
        ],
      ),
    );
  }
}

class VerticalCalculatorTab extends ConsumerStatefulWidget {
  final UserModel user;
  final bool canUseMultipleRafters;
  final bool canUseAdvancedOptions;
  final bool canExport;
  final bool canAccessDatabase;

  const VerticalCalculatorTab({
    super.key,
    required this.user,
    required this.canUseMultipleRafters,
    required this.canUseAdvancedOptions,
    required this.canExport,
    required this.canAccessDatabase,
  });

  @override
  ConsumerState<VerticalCalculatorTab> createState() =>
      _VerticalCalculatorTabState();
}

class _VerticalCalculatorTabState extends ConsumerState<VerticalCalculatorTab> {
  final List<material.TextEditingController> _rafterControllers = [
    material.TextEditingController()
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
  material.Widget build(material.BuildContext context) {
    final calcState = ref.watch(calculatorProvider);
    final defaultTiles = ref.watch(defaultTilesProvider);

    return material.SingleChildScrollView(
      padding: const material.EdgeInsets.all(16.0),
      child: material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: [
          material.Text(
            'Select Tile',
            style: material.Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: material.FontWeight.bold,
                ),
          ),
          const material.SizedBox(height: 8),
          _buildTileSelector(defaultTiles),
          const material.SizedBox(height: 16),
          material.Text(
            'Options',
            style: material.Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: material.FontWeight.bold,
                ),
          ),
          const material.SizedBox(height: 8),
          material.Row(
            children: [
              const material.Expanded(
                flex: 3,
                child: material.Text('Gutter Overhang:'),
              ),
              material.Expanded(
                flex: 5,
                child: material.Slider(
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
              material.SizedBox(
                width: 50,
                child: material.Text('${_gutterOverhang.round()} mm'),
              ),
            ],
          ),
          material.Row(
            children: [
              const material.Expanded(
                flex: 3,
                child: material.Text('Use Dry Ridge:'),
              ),
              material.Expanded(
                flex: 5,
                child: material.Row(
                  children: [
                    material.Radio<String>(
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
                    const material.Text('Yes'),
                    const material.SizedBox(width: 16),
                    material.Radio<String>(
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
                    const material.Text('No'),
                  ],
                ),
              ),
            ],
          ),
          const material.SizedBox(height: 24),
          material.Row(
            mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
            children: [
              material.Text(
                'Rafter Height',
                style:
                    material.Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: material.FontWeight.bold,
                        ),
              ),
              if (widget.canUseMultipleRafters)
                material.TextButton.icon(
                  onPressed: _addRafter,
                  icon: const material.Icon(material.Icons.add, size: 18),
                  label: const material.Text('Add Rafter'),
                ),
            ],
          ),
          const material.SizedBox(height: 8),
          ..._buildRafterInputs(),
          if (!widget.canUseMultipleRafters)
            material.Container(
              margin: const material.EdgeInsets.symmetric(vertical: 16),
              padding: const material.EdgeInsets.all(12),
              decoration: material.BoxDecoration(
                color: material.Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.5),
                borderRadius: material.BorderRadius.circular(8),
                border: material.Border.all(
                  color:
                      material.Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
              child: material.Row(
                children: [
                  material.Icon(
                    material.Icons.workspace_premium,
                    color: material.Theme.of(context).colorScheme.secondary,
                  ),
                  const material.SizedBox(width: 12),
                  material.Expanded(
                    child: material.Column(
                      crossAxisAlignment: material.CrossAxisAlignment.start,
                      children: [
                        material.Text(
                          'Pro Feature',
                          style: material.TextStyle(
                            fontWeight: material.FontWeight.bold,
                            color: material.Theme.of(context)
                                .colorScheme
                                .secondary,
                          ),
                        ),
                        const material.Text(
                          'Upgrade to Pro to calculate multiple rafters at once',
                          style: material.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  material.TextButton(
                    onPressed: () {
                      context.go('/subscription');
                    },
                    child: const material.Text('Upgrade'),
                  ),
                ],
              ),
            ),
          if (calcState.verticalResult != null) _buildResultsCard(calcState),
          if (calcState.errorMessage != null)
            material.Container(
              margin: const material.EdgeInsets.only(top: 16),
              padding: const material.EdgeInsets.all(12),
              decoration: material.BoxDecoration(
                color: material.Theme.of(context).colorScheme.errorContainer,
                borderRadius: material.BorderRadius.circular(8),
              ),
              child: material.Row(
                children: [
                  material.Icon(
                    material.Icons.error_outline,
                    color: material.Theme.of(context).colorScheme.error,
                  ),
                  const material.SizedBox(width: 12),
                  material.Expanded(
                    child: material.Text(
                      calcState.errorMessage!,
                      style: material.TextStyle(
                        color: material.Theme.of(context)
                            .colorScheme
                            .onErrorContainer,
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

  material.Widget _buildResultsCard(CalculatorState calcState) {
    final result = calcState.verticalResult!;

    return material.Card(
      margin: const material.EdgeInsets.symmetric(vertical: 16),
      child: material.Padding(
        padding: const material.EdgeInsets.all(16.0),
        child: material.Column(
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: [
            material.Row(
              mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
              children: [
                material.Text(
                  'Vertical Calculation Results',
                  style: material.Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: material.FontWeight.bold,
                      ),
                ),
                material.Text(
                  result.solution,
                  style: material.TextStyle(
                    color: material.Theme.of(context).colorScheme.primary,
                    fontWeight: material.FontWeight.bold,
                  ),
                ),
              ],
            ),
            const material.Divider(),
            material.GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const material.NeverScrollableScrollPhysics(),
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
            if (result.warning != null)
              material.Container(
                margin: const material.EdgeInsets.only(top: 16),
                padding: const material.EdgeInsets.all(12),
                decoration: material.BoxDecoration(
                  color: material.Colors.amber.withOpacity(0.2),
                  borderRadius: material.BorderRadius.circular(8),
                  border: material.Border.all(color: material.Colors.amber),
                ),
                child: material.Row(
                  children: [
                    const material.Icon(material.Icons.warning_amber,
                        color: material.Colors.amber),
                    const material.SizedBox(width: 8),
                    material.Expanded(child: material.Text(result.warning!)),
                  ],
                ),
              ),
            const material.SizedBox(height: 16),
            material.Row(
              mainAxisAlignment: material.MainAxisAlignment.end,
              children: [
                material.OutlinedButton.icon(
                  onPressed: widget.canExport
                      ? () {
                          // TODO: Save calculation
                        }
                      : null,
                  icon: const material.Icon(material.Icons.bookmark_border),
                  label: const material.Text('Save'),
                ),
                const material.SizedBox(width: 8),
                material.OutlinedButton.icon(
                  onPressed: widget.canExport
                      ? () {
                          // TODO: Share calculation
                        }
                      : null,
                  icon: const material.Icon(material.Icons.share),
                  label: const material.Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  material.Widget _resultItem(String label, String value) {
    return material.Row(
      mainAxisAlignment: material.MainAxisAlignment.start,
      crossAxisAlignment: material.CrossAxisAlignment.start,
      children: [
        material.Expanded(
          flex: 1,
          child: material.Text(
            '$label:',
            style:
                const material.TextStyle(fontWeight: material.FontWeight.bold),
          ),
        ),
        const material.SizedBox(width: 8),
        material.Expanded(
          flex: 1,
          child: material.Text(value),
        ),
      ],
    );
  }

  List<material.Widget> _buildRafterInputs() {
    final List<material.Widget> rafterInputs = [];
    final int displayCount =
        widget.canUseMultipleRafters ? _rafterControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      rafterInputs.add(
        material.Padding(
          padding: const material.EdgeInsets.only(bottom: 16.0),
          child: material.Row(
            children: [
              if (widget.canUseMultipleRafters) ...[
                material.Expanded(
                  flex: 3,
                  child: material.TextField(
                    controller:
                        material.TextEditingController(text: _rafterNames[i]),
                    decoration: const material.InputDecoration(
                      isDense: true,
                      contentPadding: material.EdgeInsets.symmetric(
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
                const material.SizedBox(width: 16),
              ],
              material.Expanded(
                flex: widget.canUseMultipleRafters ? 5 : 8,
                child: material.TextField(
                  controller: _rafterControllers[i],
                  decoration: material.InputDecoration(
                    labelText: widget.canUseMultipleRafters
                        ? null
                        : 'Rafter height in mm',
                    hintText: 'e.g., 6000',
                    suffixText: 'mm',
                    isDense: true,
                  ),
                  keyboardType: const material.TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              if (widget.canUseMultipleRafters &&
                  _rafterControllers.length > 1) ...[
                const material.SizedBox(width: 8),
                material.IconButton(
                  onPressed: () => _removeRafter(i),
                  icon: const material.Icon(material.Icons.delete_outline),
                  color: material.Theme.of(context).colorScheme.error,
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

  material.Widget _buildTileSelector(List<TileModel> tiles) {
    final calculatorNotifier = ref.read(calculatorProvider.notifier);
    final selectedTile = ref.watch(calculatorProvider).selectedTile;

    if (!widget.canAccessDatabase) {
      return material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: [
          const material.Text(
              'Free users must input tile measurements manually'),
          const material.SizedBox(height: 12),
          _buildManualTileInputs(),
        ],
      );
    }

    return material.DropdownButtonFormField<String>(
      decoration: const material.InputDecoration(
        border: material.OutlineInputBorder(),
        contentPadding: material.EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      value: selectedTile?.id,
      hint: const material.Text('Select tile type'),
      items: tiles.map<material.DropdownMenuItem<String>>((tile) {
        return material.DropdownMenuItem<String>(
          value: tile.id,
          child: material.Text('${tile.name} (${tile.materialTypeString})'),
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
    if (!widget.canUseMultipleRafters) return;

    setState(() {
      _rafterControllers.add(material.TextEditingController());
      _rafterNames.add('Rafter ${_rafterControllers.length}');
    });
  }

  void _removeRafter(int index) {
    if (!widget.canUseMultipleRafters) return;
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
      material.ScaffoldMessenger.of(context).showSnackBar(
        const material.SnackBar(
          content: material.Text('Please select a tile type first'),
        ),
      );
      return;
    }

    final List<double> rafterHeights = [];
    final displayCount =
        widget.canUseMultipleRafters ? _rafterControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      final heightText = _rafterControllers[i].text.trim();
      if (heightText.isEmpty) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text(
                'Please enter a height for ${widget.canUseMultipleRafters ? _rafterNames[i] : 'the rafter'}'),
          ),
        );
        return;
      }

      final double? height = double.tryParse(heightText);
      if (height == null) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text(
                'Invalid height value for ${widget.canUseMultipleRafters ? _rafterNames[i] : 'the rafter'}'),
          ),
        );
        return;
      }

      rafterHeights.add(height);
    }

    ref.read(calculatorProvider.notifier).calculateVertical(rafterHeights);
  }

  material.Widget _buildManualTileInputs() {
    final calculatorNotifier = ref.read(calculatorProvider.notifier);
    final nameController = material.TextEditingController(text: 'Custom Tile');
    final heightController = material.TextEditingController();
    final widthController = material.TextEditingController();
    final minGaugeController = material.TextEditingController();
    final maxGaugeController = material.TextEditingController();
    final minSpacingController = material.TextEditingController();
    final maxSpacingController = material.TextEditingController();

    return material.Column(
      children: [
        material.TextFormField(
          controller: heightController,
          decoration: const material.InputDecoration(
            labelText: 'Tile Height/Length (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 12),
        material.TextFormField(
          controller: widthController,
          decoration: const material.InputDecoration(
            labelText: 'Tile Cover Width (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 12),
        material.TextFormField(
          controller: minGaugeController,
          decoration: const material.InputDecoration(
            labelText: 'Min Gauge (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 12),
        material.TextFormField(
          controller: maxGaugeController,
          decoration: const material.InputDecoration(
            labelText: 'Max Gauge (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 12),
        material.TextFormField(
          controller: minSpacingController,
          decoration: const material.InputDecoration(
            labelText: 'Min Spacing (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 12),
        material.TextFormField(
          controller: maxSpacingController,
          decoration: const material.InputDecoration(
            labelText: 'Max Spacing (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 16),
        material.ElevatedButton(
          onPressed: () {
            if (heightController.text.isNotEmpty &&
                widthController.text.isNotEmpty &&
                minGaugeController.text.isNotEmpty &&
                maxGaugeController.text.isNotEmpty &&
                minSpacingController.text.isNotEmpty &&
                maxSpacingController.text.isNotEmpty) {
              final now = DateTime.now();
              final tempTile = TileModel(
                id: 'temp_manual_tile_${now.millisecondsSinceEpoch}',
                name: nameController.text,
                manufacturer: 'Manual Input',
                materialType: MaterialType.unknown,
                description: 'Manually entered tile specifications',
                isPublic: false,
                isApproved: false,
                createdById: 'temp_user',
                createdAt: now,
                updatedAt: now,
                slateTileHeight: double.tryParse(heightController.text) ?? 0,
                tileCoverWidth: double.tryParse(widthController.text) ?? 0,
                minGauge: double.tryParse(minGaugeController.text) ?? 0,
                maxGauge: double.tryParse(maxGaugeController.text) ?? 0,
                minSpacing: double.tryParse(minSpacingController.text) ?? 0,
                maxSpacing: double.tryParse(maxSpacingController.text) ?? 0,
                defaultCrossBonded: false,
              );

              calculatorNotifier.setTile(tempTile);

              material.ScaffoldMessenger.of(context).showSnackBar(
                const material.SnackBar(
                  content: material.Text('Tile specifications applied'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              material.ScaffoldMessenger.of(context).showSnackBar(
                const material.SnackBar(
                  content: material.Text(
                      'Please fill in all tile specification fields'),
                  backgroundColor: material.Colors.red,
                ),
              );
            }
          },
          child: const material.Text('Apply Specifications'),
        ),
        const material.SizedBox(height: 16),
        material.Container(
          padding: const material.EdgeInsets.all(12),
          decoration: material.BoxDecoration(
            color: material.Colors.amber.shade100,
            borderRadius: material.BorderRadius.circular(8),
            border: material.Border.all(color: material.Colors.amber.shade300),
          ),
          child: material.Column(
            crossAxisAlignment: material.CrossAxisAlignment.start,
            children: [
              material.Row(
                children: [
                  material.Icon(material.Icons.info_outline,
                      color: material.Colors.amber.shade800),
                  const material.SizedBox(width: 8),
                  material.Text(
                    'Pro Feature',
                    style: material.TextStyle(
                      fontWeight: material.FontWeight.bold,
                      color: material.Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              const material.SizedBox(height: 8),
              const material.Text(
                'Pro users have access to our complete tile database with predefined measurements for all standard UK roofing tiles.',
                style: material.TextStyle(fontSize: 12),
              ),
              const material.SizedBox(height: 8),
              material.OutlinedButton(
                onPressed: () {
                  context.go('/subscription');
                },
                style: material.OutlinedButton.styleFrom(
                  foregroundColor: material.Colors.amber.shade900,
                ),
                child: const material.Text('Upgrade to Pro'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HorizontalCalculatorTab extends ConsumerStatefulWidget {
  final UserModel user;
  final bool canUseMultipleWidths;
  final bool canUseAdvancedOptions;
  final bool canExport;
  final bool canAccessDatabase;

  const HorizontalCalculatorTab({
    super.key,
    required this.user,
    required this.canUseMultipleWidths,
    required this.canUseAdvancedOptions,
    required this.canExport,
    required this.canAccessDatabase,
  });

  @override
  ConsumerState<HorizontalCalculatorTab> createState() =>
      _HorizontalCalculatorTabState();
}

class _HorizontalCalculatorTabState
    extends ConsumerState<HorizontalCalculatorTab> {
  final List<material.TextEditingController> _widthControllers = [
    material.TextEditingController()
  ];
  final List<String> _widthNames = ['Width 1'];
  String _useDryVerge = 'NO';
  String _abutmentSide = 'NONE';
  String _useLHTile = 'NO';
  String _crossBonded = 'NO';

  @override
  void dispose() {
    for (final controller in _widthControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  material.Widget build(material.BuildContext context) {
    final calcState = ref.watch(calculatorProvider);
    final defaultTiles = ref.watch(defaultTilesProvider);

    return material.SingleChildScrollView(
      padding: const material.EdgeInsets.all(16.0),
      child: material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: [
          material.Text(
            'Select Tile',
            style: material.Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: material.FontWeight.bold,
                ),
          ),
          const material.SizedBox(height: 8),
          _buildTileSelector(defaultTiles),
          const material.SizedBox(height: 16),
          material.Text(
            'Options',
            style: material.Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: material.FontWeight.bold,
                ),
          ),
          const material.SizedBox(height: 8),
          material.Row(
            children: [
              const material.Expanded(
                flex: 3,
                child: material.Text('Use Dry Verge:'),
              ),
              material.Expanded(
                flex: 5,
                child: material.Row(
                  children: [
                    material.Radio<String>(
                      value: 'YES',
                      groupValue: _useDryVerge,
                      onChanged: (value) {
                        setState(() {
                          _useDryVerge = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseDryVerge(value!);
                      },
                    ),
                    const material.Text('Yes'),
                    const material.SizedBox(width: 16),
                    material.Radio<String>(
                      value: 'NO',
                      groupValue: _useDryVerge,
                      onChanged: (value) {
                        setState(() {
                          _useDryVerge = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseDryVerge(value!);
                      },
                    ),
                    const material.Text('No'),
                  ],
                ),
              ),
            ],
          ),
          material.Row(
            children: [
              const material.Expanded(
                flex: 3,
                child: material.Text('Abutment Side:'),
              ),
              material.Expanded(
                flex: 5,
                child: material.DropdownButton<String>(
                  value: _abutmentSide,
                  isExpanded: true,
                  items: const [
                    material.DropdownMenuItem(
                        value: 'NONE', child: material.Text('None')),
                    material.DropdownMenuItem(
                        value: 'LEFT', child: material.Text('Left')),
                    material.DropdownMenuItem(
                        value: 'RIGHT', child: material.Text('Right')),
                    material.DropdownMenuItem(
                        value: 'BOTH', child: material.Text('Both')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _abutmentSide = value!;
                    });
                    ref
                        .read(calculatorProvider.notifier)
                        .setAbutmentSide(value!);
                  },
                ),
              ),
            ],
          ),
          material.Row(
            children: [
              const material.Expanded(
                flex: 3,
                child: material.Text('Use LH Tile:'),
              ),
              material.Expanded(
                flex: 5,
                child: material.Row(
                  children: [
                    material.Radio<String>(
                      value: 'YES',
                      groupValue: _useLHTile,
                      onChanged: (value) {
                        setState(() {
                          _useLHTile = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseLHTile(value!);
                      },
                    ),
                    const material.Text('Yes'),
                    const material.SizedBox(width: 16),
                    material.Radio<String>(
                      value: 'NO',
                      groupValue: _useLHTile,
                      onChanged: (value) {
                        setState(() {
                          _useLHTile = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseLHTile(value!);
                      },
                    ),
                    const material.Text('No'),
                  ],
                ),
              ),
            ],
          ),
          material.Row(
            children: [
              const material.Expanded(
                flex: 3,
                child: material.Text('Cross Bonded:'),
              ),
              material.Expanded(
                flex: 5,
                child: material.Row(
                  children: [
                    material.Radio<String>(
                      value: 'YES',
                      groupValue: _crossBonded,
                      onChanged: (value) {
                        setState(() {
                          _crossBonded = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setCrossBonded(value!);
                      },
                    ),
                    const material.Text('Yes'),
                    const material.SizedBox(width: 16),
                    material.Radio<String>(
                      value: 'NO',
                      groupValue: _crossBonded,
                      onChanged: (value) {
                        setState(() {
                          _crossBonded = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setCrossBonded(value!);
                      },
                    ),
                    const material.Text('No'),
                  ],
                ),
              ),
            ],
          ),
          const material.SizedBox(height: 24),
          material.Row(
            mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
            children: [
              material.Text(
                'Width Measurement',
                style:
                    material.Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: material.FontWeight.bold,
                        ),
              ),
              if (widget.canUseMultipleWidths)
                material.TextButton.icon(
                  onPressed: _addWidth,
                  icon: const material.Icon(material.Icons.add, size: 18),
                  label: const material.Text('Add Width'),
                ),
            ],
          ),
          const material.SizedBox(height: 8),
          ..._buildWidthInputs(),
          if (!widget.canUseMultipleWidths)
            material.Container(
              margin: const material.EdgeInsets.symmetric(vertical: 16),
              padding: const material.EdgeInsets.all(12),
              decoration: material.BoxDecoration(
                color: material.Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.5),
                borderRadius: material.BorderRadius.circular(8),
                border: material.Border.all(
                  color:
                      material.Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
              child: material.Row(
                children: [
                  material.Icon(
                    material.Icons.workspace_premium,
                    color: material.Theme.of(context).colorScheme.secondary,
                  ),
                  const material.SizedBox(width: 12),
                  material.Expanded(
                    child: material.Column(
                      crossAxisAlignment: material.CrossAxisAlignment.start,
                      children: [
                        material.Text(
                          'Pro Feature',
                          style: material.TextStyle(
                            fontWeight: material.FontWeight.bold,
                            color: material.Theme.of(context)
                                .colorScheme
                                .secondary,
                          ),
                        ),
                        const material.Text(
                          'Upgrade to Pro to calculate multiple widths at once',
                          style: material.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  material.TextButton(
                    onPressed: () {
                      context.go('/subscription');
                    },
                    child: const material.Text('Upgrade'),
                  ),
                ],
              ),
            ),
          if (calcState.horizontalResult != null)
            _buildHorizontalResultsCard(calcState),
          if (calcState.errorMessage != null)
            material.Container(
              margin: const material.EdgeInsets.only(top: 16),
              padding: const material.EdgeInsets.all(12),
              decoration: material.BoxDecoration(
                color: material.Theme.of(context).colorScheme.errorContainer,
                borderRadius: material.BorderRadius.circular(8),
              ),
              child: material.Row(
                children: [
                  material.Icon(
                    material.Icons.error_outline,
                    color: material.Theme.of(context).colorScheme.error,
                  ),
                  const material.SizedBox(width: 12),
                  material.Expanded(
                    child: material.Text(
                      calcState.errorMessage!,
                      style: material.TextStyle(
                        color: material.Theme.of(context)
                            .colorScheme
                            .onErrorContainer,
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

  List<material.Widget> _buildWidthInputs() {
    final List<material.Widget> widthInputs = [];
    final int displayCount =
        widget.canUseMultipleWidths ? _widthControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      widthInputs.add(
        material.Padding(
          padding: const material.EdgeInsets.only(bottom: 16.0),
          child: material.Row(
            children: [
              if (widget.canUseMultipleWidths) ...[
                material.Expanded(
                  flex: 3,
                  child: material.TextField(
                    controller:
                        material.TextEditingController(text: _widthNames[i]),
                    decoration: const material.InputDecoration(
                      isDense: true,
                      contentPadding: material.EdgeInsets.symmetric(
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
                const material.SizedBox(width: 16),
              ],
              material.Expanded(
                flex: widget.canUseMultipleWidths ? 5 : 8,
                child: material.TextField(
                  controller: _widthControllers[i],
                  decoration: material.InputDecoration(
                    labelText:
                        widget.canUseMultipleWidths ? null : 'Width in mm',
                    hintText: 'e.g., 5000',
                    suffixText: 'mm',
                    isDense: true,
                  ),
                  keyboardType: const material.TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              if (widget.canUseMultipleWidths &&
                  _widthControllers.length > 1) ...[
                const material.SizedBox(width: 8),
                material.IconButton(
                  onPressed: () => _removeWidth(i),
                  icon: const material.Icon(material.Icons.delete_outline),
                  color: material.Theme.of(context).colorScheme.error,
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

  material.Widget _buildTileSelector(List<TileModel> tiles) {
    final calculatorNotifier = ref.read(calculatorProvider.notifier);
    final selectedTile = ref.watch(calculatorProvider).selectedTile;

    if (!widget.canAccessDatabase) {
      return material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: [
          const material.Text(
              'Free users must input tile measurements manually'),
          const material.SizedBox(height: 12),
          _buildManualTileInputs(),
        ],
      );
    }

    return material.DropdownButtonFormField<String>(
      decoration: const material.InputDecoration(
        border: material.OutlineInputBorder(),
        contentPadding: material.EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      value: selectedTile?.id,
      hint: const material.Text('Select tile type'),
      items: tiles.map<material.DropdownMenuItem<String>>((tile) {
        return material.DropdownMenuItem<String>(
          value: tile.id,
          child: material.Text('${tile.name} (${tile.materialTypeString})'),
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

  void _addWidth() {
    if (!widget.canUseMultipleWidths) return;

    setState(() {
      _widthControllers.add(material.TextEditingController());
      _widthNames.add('Width ${_widthControllers.length}');
    });
  }

  void _removeWidth(int index) {
    if (!widget.canUseMultipleWidths) return;
    if (_widthControllers.length <= 1) return;

    setState(() {
      _widthControllers[index].dispose();
      _widthControllers.removeAt(index);
      _widthNames.removeAt(index);
    });
  }

  void calculate() {
    final calculatorState = ref.read(calculatorProvider);
    if (calculatorState.selectedTile == null) {
      material.ScaffoldMessenger.of(context).showSnackBar(
        const material.SnackBar(
          content: material.Text('Please select a tile type first'),
        ),
      );
      return;
    }

    final List<double> widths = [];
    final displayCount =
        widget.canUseMultipleWidths ? _widthControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      final widthText = _widthControllers[i].text.trim();
      if (widthText.isEmpty) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text(
                'Please enter a width for ${widget.canUseMultipleWidths ? _widthNames[i] : 'the width'}'),
          ),
        );
        return;
      }

      final double? width = double.tryParse(widthText);
      if (width == null) {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text(
                'Invalid width value for ${widget.canUseMultipleWidths ? _widthNames[i] : 'the width'}'),
          ),
        );
        return;
      }

      widths.add(width);
    }

    ref.read(calculatorProvider.notifier).calculateHorizontal(widths);
  }

  material.Widget _buildHorizontalResultsCard(CalculatorState calcState) {
    final result = calcState.horizontalResult!;

    return material.Card(
      margin: const material.EdgeInsets.symmetric(vertical: 16),
      child: material.Padding(
        padding: const material.EdgeInsets.all(16.0),
        child: material.Column(
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: [
            material.Row(
              mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
              children: [
                material.Text(
                  'Horizontal Calculation Results',
                  style: material.Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: material.FontWeight.bold,
                      ),
                ),
                material.Text(
                  result.solution,
                  style: material.TextStyle(
                    color: material.Theme.of(context).colorScheme.primary,
                    fontWeight: material.FontWeight.bold,
                  ),
                ),
              ],
            ),
            const material.Divider(),
            material.GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const material.NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                _resultItem('Width', '${result.width} mm'),
                if (result.lhOverhang != null)
                  _resultItem('LH Overhang', '${result.lhOverhang} mm'),
                if (result.rhOverhang != null)
                  _resultItem('RH Overhang', '${result.rhOverhang} mm'),
                if (result.cutTile != null)
                  _resultItem('Cut Tile', '${result.cutTile} mm'),
                _resultItem('First Mark', '${result.firstMark} mm'),
                if (result.secondMark != null)
                  _resultItem('Second Mark', '${result.secondMark} mm'),
                _resultItem('Marks', result.marks),
                if (result.splitMarks != null)
                  _resultItem('Split Marks', result.splitMarks!),
              ],
            ),
            const material.SizedBox(height: 16),
            material.Row(
              mainAxisAlignment: material.MainAxisAlignment.end,
              children: [
                material.OutlinedButton.icon(
                  onPressed: widget.canExport
                      ? () {
                          // TODO: Save calculation
                        }
                      : null,
                  icon: const material.Icon(material.Icons.bookmark_border),
                  label: const material.Text('Save'),
                ),
                const material.SizedBox(width: 8),
                material.OutlinedButton.icon(
                  onPressed: widget.canExport
                      ? () {
                          // TODO: Share calculation
                        }
                      : null,
                  icon: const material.Icon(material.Icons.share),
                  label: const material.Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  material.Widget _resultItem(String label, String value) {
    return material.Row(
      mainAxisAlignment: material.MainAxisAlignment.start,
      crossAxisAlignment: material.CrossAxisAlignment.start,
      children: [
        material.Expanded(
          flex: 1,
          child: material.Text(
            '$label:',
            style:
                const material.TextStyle(fontWeight: material.FontWeight.bold),
          ),
        ),
        const material.SizedBox(width: 8),
        material.Expanded(
          flex: 1,
          child: material.Text(value),
        ),
      ],
    );
  }

  material.Widget _buildManualTileInputs() {
    final calculatorNotifier = ref.read(calculatorProvider.notifier);
    final nameController = material.TextEditingController(text: 'Custom Tile');
    final heightController = material.TextEditingController();
    final widthController = material.TextEditingController();
    final minGaugeController = material.TextEditingController();
    final maxGaugeController = material.TextEditingController();
    final minSpacingController = material.TextEditingController();
    final maxSpacingController = material.TextEditingController();

    return material.Column(
      children: [
        material.TextFormField(
          controller: heightController,
          decoration: const material.InputDecoration(
            labelText: 'Tile Height/Length (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 12),
        material.TextFormField(
          controller: widthController,
          decoration: const material.InputDecoration(
            labelText: 'Tile Cover Width (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 12),
        material.TextFormField(
          controller: minGaugeController,
          decoration: const material.InputDecoration(
            labelText: 'Min Gauge (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 12),
        material.TextFormField(
          controller: maxGaugeController,
          decoration: const material.InputDecoration(
            labelText: 'Max Gauge (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 12),
        material.TextFormField(
          controller: minSpacingController,
          decoration: const material.InputDecoration(
            labelText: 'Min Spacing (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 12),
        material.TextFormField(
          controller: maxSpacingController,
          decoration: const material.InputDecoration(
            labelText: 'Max Spacing (mm) *',
            border: material.OutlineInputBorder(),
          ),
          keyboardType: material.TextInputType.number,
        ),
        const material.SizedBox(height: 16),
        material.ElevatedButton(
          onPressed: () {
            if (heightController.text.isNotEmpty &&
                widthController.text.isNotEmpty &&
                minGaugeController.text.isNotEmpty &&
                maxGaugeController.text.isNotEmpty &&
                minSpacingController.text.isNotEmpty &&
                maxSpacingController.text.isNotEmpty) {
              final now = DateTime.now();
              final tempTile = TileModel(
                id: 'temp_manual_tile_${now.millisecondsSinceEpoch}',
                name: nameController.text,
                manufacturer: 'Manual Input',
                materialType: MaterialType.unknown,
                description: 'Manually entered tile specifications',
                isPublic: false,
                isApproved: false,
                createdById: 'temp_user',
                createdAt: now,
                updatedAt: now,
                slateTileHeight: double.tryParse(heightController.text) ?? 0,
                tileCoverWidth: double.tryParse(widthController.text) ?? 0,
                minGauge: double.tryParse(minGaugeController.text) ?? 0,
                maxGauge: double.tryParse(maxGaugeController.text) ?? 0,
                minSpacing: double.tryParse(minSpacingController.text) ?? 0,
                maxSpacing: double.tryParse(maxSpacingController.text) ?? 0,
                defaultCrossBonded: false,
              );

              calculatorNotifier.setTile(tempTile);

              material.ScaffoldMessenger.of(context).showSnackBar(
                const material.SnackBar(
                  content: material.Text('Tile specifications applied'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              material.ScaffoldMessenger.of(context).showSnackBar(
                const material.SnackBar(
                  content: material.Text(
                      'Please fill in all tile specification fields'),
                  backgroundColor: material.Colors.red,
                ),
              );
            }
          },
          child: const material.Text('Apply Specifications'),
        ),
        const material.SizedBox(height: 16),
        material.Container(
          padding: const material.EdgeInsets.all(12),
          decoration: material.BoxDecoration(
            color: material.Colors.amber.shade100,
            borderRadius: material.BorderRadius.circular(8),
            border: material.Border.all(color: material.Colors.amber.shade300),
          ),
          child: material.Column(
            crossAxisAlignment: material.CrossAxisAlignment.start,
            children: [
              material.Row(
                children: [
                  material.Icon(material.Icons.info_outline,
                      color: material.Colors.amber.shade800),
                  const material.SizedBox(width: 8),
                  material.Text(
                    'Pro Feature',
                    style: material.TextStyle(
                      fontWeight: material.FontWeight.bold,
                      color: material.Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              const material.SizedBox(height: 8),
              const material.Text(
                'Pro users have access to our complete tile database with predefined measurements for all standard UK roofing tiles.',
                style: material.TextStyle(fontSize: 12),
              ),
              const material.SizedBox(height: 8),
              material.OutlinedButton(
                onPressed: () {
                  context.go('/subscription');
                },
                style: material.OutlinedButton.styleFrom(
                  foregroundColor: material.Colors.amber.shade900,
                ),
                child: const material.Text('Upgrade to Pro'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
