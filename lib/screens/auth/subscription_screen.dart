import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roofgridk_app/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;

  Future<void> _upgradeToProSubscription() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.upgradeToProStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upgrade successful! You now have Pro access.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error upgrading: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isPro = authProvider.isPro;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPro ? Icons.verified : Icons.star,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ).animate().scale().fadeIn(),
              const SizedBox(height: 24),
              Text(
                isPro ? 'You\'re a Pro!' : 'Upgrade to Pro',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              Text(
                isPro
                    ? 'Thank you for being a Pro subscriber! Enjoy all of our premium features.'
                    : 'Get access to all premium features with a Pro subscription.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
              _buildFeaturesList().animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 32),
              if (!isPro) _buildPricingCard().animate().fadeIn(delay: 500.ms),
              if (!isPro) const SizedBox(height: 24),
              isPro
                  ? ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Return to App'),
                    ).animate().fadeIn(delay: 600.ms)
                  : ElevatedButton(
                      onPressed: _isLoading ? null : _upgradeToProSubscription,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Subscribe Now'),
                    ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: [
        _buildFeatureItem('Unlimited calculations', Icons.calculate),
        const SizedBox(height: 16),
        _buildFeatureItem('Save & export results', Icons.save),
        const SizedBox(height: 16),
        _buildFeatureItem('Premium support', Icons.support_agent),
        const SizedBox(height: 16),
        _buildFeatureItem('Advanced analytics', Icons.analytics),
      ],
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              '£9.99/month',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'or £99.99/year',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '14-day free trial',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cancel anytime',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
