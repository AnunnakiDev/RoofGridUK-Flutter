import '../models/user_model.dart';

class PermissionsService {
  // Constants for maximum allowed features by user type
  static const int _maxRaftersForFree = 1;
  static const int _maxWidthsForFree = 1;
  static const int _maxTilesForFree =
      0; // Free users don't get access to tile database
  static const bool _allowCustomTilesForFree = false;
  static const bool _allowExportForFree = false;
  static const bool _allowSaveProjectsForFree =
      false; // Free users cannot save results
  static const bool _allowAdvancedOptionsForFree = false;
  static const bool _allowTileDatabaseAccessForFree =
      false; // New permission for tile database access
  static const int TRIAL_DURATION_DAYS = 14;
  static const int WARNING_DAYS = 7;

  /// Determines if a user can save results
  static bool canSaveCalculationResults(UserModel user) {
    return _allowSaveProjectsForFree || user.isPro || user.isTrialActive;
  }

  /// Determines if a user can use advanced calculation options
  static bool canUseAdvancedOptions(UserModel? user) {
    if (user == null) return _allowAdvancedOptionsForFree;
    return user.isPro || user.isTrialActive || _allowAdvancedOptionsForFree;
  }

  /// Gets the maximum number of rafters a user can calculate with
  static int getMaxAllowedRafters(UserModel? user) {
    if (user == null) return _maxRaftersForFree;
    if (user.isPro || user.isTrialActive)
      return 10; // Pro users can use up to 10 rafters
    return _maxRaftersForFree; // Free users can only use 1 rafter
  }

  /// Gets the maximum number of width measurements a user can use
  static int getMaxAllowedWidths(UserModel? user) {
    if (user == null) return _maxWidthsForFree;
    if (user.isPro || user.isTrialActive) return 10;
    return _maxWidthsForFree;
  }

  /// Determines if a user can export results
  static bool canExportResults(UserModel? user) {
    if (user == null) return _allowExportForFree;
    return user.isPro || user.isTrialActive || _allowExportForFree;
  }

  /// Determines if a user can create custom tiles
  static bool canCreateCustomTiles(UserModel? user) {
    if (user == null) return _allowCustomTilesForFree;
    return user.isPro || user.isTrialActive || _allowCustomTilesForFree;
  }

  /// Determines if a user can access the tile database
  static bool canAccessTileDatabase(UserModel? user) {
    if (user == null) return _allowTileDatabaseAccessForFree;
    return user.isPro || user.isTrialActive || _allowTileDatabaseAccessForFree;
  }

  /// Gets the maximum number of custom tiles a user can create
  static int getMaxAllowedCustomTiles(UserModel? user) {
    if (user == null) return _maxTilesForFree;
    if (user.isPro) return 100; // Pro users get lots of tiles
    if (user.isTrialActive) return 10; // Trial users get some tiles
    return _maxTilesForFree; // Free users can't create custom tiles
  }
}
