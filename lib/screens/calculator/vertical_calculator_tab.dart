import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import '../../app/auth/models/user_model.dart';
import '../../app/calculator/providers/calculator_provider.dart';
import '../../app/calculator/models/vertical_calculation_input.dart';
import '../../app/calculator/models/vertical_calculation_result.dart';
import '../../app/auth/services/permissions_service.dart';
import '../../app/theme/app_theme.dart';

class VerticalCalculatorTab extends StatefulWidget {
  final UserModel user;
  final bool canUseMultipleRafters;
  final bool canUseAdvancedOptions;
  final bool canExport;

  const VerticalCalculatorTab({
    Key? key,
    required this.user,
    required this.canUseMultipleRafters,
    required this.canUseAdvancedOptions,
    required this.canExport,
  }) : super(key: key);

  @override
  State<VerticalCalculatorTab> createState() => _VerticalCalculatorTabState();
}

class _VerticalCalculatorTabState extends State<VerticalCalculatorTab> {
  final _formKey = GlobalKey<FormState>();
  final _roofLengthController = TextEditingController();
  final _rafterController = TextEditingController();
  final _eaveOverhangController = TextEditingController();
  final _ridgeThicknessController = TextEditingController();

  final List<double> _additionalRafters = [];
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    // Set default values
    _rafterController.text = '40.0';
    _roofLengthController.text = '5000';
    _eaveOverhangController.text = '50';
    _ridgeThicknessController.text = '25';
  }

  @override
  void dispose() {
    _roofLengthController.dispose();
    _rafterController.dispose();
    _eaveOverhangController.dispose();
    _ridgeThicknessController.dispose();
    super.dispose();
  }

  void _addAdditionalRafter() {
    if (!widget.canUseMultipleRafters) {
      _showProFeatureDialog('Multiple Rafters');
      return;
    }

    if (_additionalRafters.length >=
        PermissionsService.getMaxAllowedRafters(widget.user) - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Maximum ${PermissionsService.getMaxAllowedRafters(widget.user)} rafters allowed for your account type'),
        ),
      );
      return;
    }

    setState(() {
      _additionalRafters.add(40.0);
    });
  }

  void _removeAdditionalRafter(int index) {
    setState(() {
      _additionalRafters.removeAt(index);
    });
  }

  void _updateAdditionalRafter(int index, double value) {
    setState(() {
      _additionalRafters[index] = value;
    });
  }

  void _showProFeatureDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$featureName is a Pro Feature'),
        content: Text(
            'Upgrade to Pro to use $featureName and unlock all advanced features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to upgrade screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upgrade screen coming soon!')),
              );
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _calculateVertical() {
    if (_formKey.currentState!.validate()) {
      final calculatorProvider =
          Provider.of<CalculatorProvider>(context, listen: false);

      final input = VerticalCalculationInput(
        roofLength: double.parse(_roofLengthController.text),
        rafterGauge: double.parse(_rafterController.text),
        eaveOverhang: double.parse(_eaveOverhangController.text),
        ridgeThickness: _showAdvancedOptions
            ? double.parse(_ridgeThicknessController.text)
            : 25.0,
        additionalRafters: _additionalRafters,
      );

      final result = calculatorProvider.calculateVertical(input);
      _showResultDialog(result);
    }
  }

  void _showResultDialog(VerticalCalculationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calculation Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _resultItem(
                  'Number of Battens:', result.numberOfBattens.toString()),
              _resultItem('Batten Gauge:',
                  '${result.battenGauge.toStringAsFixed(2)} mm'),
              _resultItem('Adjusted Rafter Gauge:',
                  '${result.adjustedRafterGauge.toStringAsFixed(2)} mm'),
              if (result.additionalRafterAdjustments.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Additional Rafters Adjustments:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...result.additionalRafterAdjustments.map((adjustment) =>
                    _resultItem(
                        'Rafter ${result.additionalRafterAdjustments.indexOf(adjustment) + 2}:',
                        '${adjustment.toStringAsFixed(2)} mm')),
              ],
            ],
          ),
        ),
        actions: [
          if (widget.canExport)
            TextButton(
              onPressed: () => _exportResults(result),
              child: const Text('Export Results'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _resultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _exportResults(VerticalCalculationResult result) {
    if (!widget.canExport) {
      _showProFeatureDialog('Exporting Results');
      return;
    }

    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vertical Calculator (Batten Gauge)',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Roof Length Field
            TextFormField(
              controller: _roofLengthController,
              decoration: const InputDecoration(
                labelText: 'Roof Length (mm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the roof length';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Rafter Gauge Field
            TextFormField(
              controller: _rafterController,
              decoration: const InputDecoration(
                labelText: 'Rafter Gauge (mm)',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the rafter gauge';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Additional Rafters
            if (_additionalRafters.isNotEmpty)
              ...List.generate(_additionalRafters.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _additionalRafters[index].toString(),
                          decoration: InputDecoration(
                            labelText: 'Additional Rafter ${index + 2} (mm)',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$')),
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _updateAdditionalRafter(
                                  index, double.parse(value));
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeAdditionalRafter(index),
                      ),
                    ],
                  ),
                );
              }),

            ElevatedButton.icon(
              onPressed: _addAdditionalRafter,
              icon: const Icon(Icons.add),
              label: const Text('Add Additional Rafter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Advanced Options Toggle
            CheckboxListTile(
              title: const Text('Show Advanced Options'),
              value: _showAdvancedOptions,
              onChanged: (value) {
                if (value == true && !widget.canUseAdvancedOptions) {
                  _showProFeatureDialog('Advanced Options');
                  return;
                }
                setState(() {
                  _showAdvancedOptions = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // Advanced Options
            if (_showAdvancedOptions) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _eaveOverhangController,
                decoration: const InputDecoration(
                  labelText: 'Eave Overhang (mm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the eave overhang';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ridgeThicknessController,
                decoration: const InputDecoration(
                  labelText: 'Ridge Thickness (mm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the ridge thickness';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),

            // Calculate Button
            FilledButton(
              onPressed: _calculateVertical,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'CALCULATE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Pro Features Callout
            if (!PermissionsService.isPro(widget.user))
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Card(
                  color: Colors.amber.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pro Features Available:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('• Multiple additional rafters'),
                        const Text('• Advanced measurement options'),
                        const Text('• Export calculations to PDF'),
                        const Text('• Save calculation history'),
                        const SizedBox(height: 16),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Navigate to upgrade screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Upgrade screen coming soon!')),
                              );
                            },
                            icon: const Icon(Icons.star),
                            label: const Text('Upgrade to Pro'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber.shade900,
                              side: BorderSide(color: Colors.amber.shade700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
