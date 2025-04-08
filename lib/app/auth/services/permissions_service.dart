import 'package:roofgrid_uk/app/auth/models/user_model.dart';

class PermissionsService {
  // Constants for maximum allowed features by user type
  static const int _maxRaftersForFree = 1;
  static const int _maxWidthsForFree = 1;
  static const int _maxTilesForFree = 3;
  static const bool _allowCustomTilesForFree = false;
  static const bool _allowExportForFree = false;
  static const bool _allowSaveProjectsForFree = false;
  static const bool _allowAdvancedOptionsForFree = false;
  static const int TRIAL_DURATION_DAYS = 7;
  static const int WARNING_DAYS = 2;

  // User type specific permissions
  // Free users: Input all data manually, tiles and results don't save
  // Pro users: Can select/edit default tiles and save modified versions to personal tiles
  // Admin users: Full control over default tiles, can import tiles, approve user-submitted tiles

  // Maximum allowed rafters based on user type
  static int getMaxAllowedRafters(UserModel? user) {
    if (user == null) return _maxRaftersForFree;
    if (user.isPro || user.isAdmin || user.isInProTrial) return 10;
    return _maxRaftersForFree;
  }

  // Maximum allowed width measurements based on user type
  static int getMaxAllowedWidths(UserModel? user) {
    if (user == null) return _maxWidthsForFree;
    if (user.isPro || user.isAdmin || user.isInProTrial) return 10;
    return _maxWidthsForFree;
  }

  // Check if user can use custom tiles
  static bool canUseCustomTiles(UserModel? user) {
    if (user == null) return _allowCustomTilesForFree;
    return user.isPro ||
        user.isAdmin ||
        user.isInProTrial ||
        _allowCustomTilesForFree;
  }

  // Check if user can export results
  static bool canExportResults(UserModel? user) {
    if (user == null) return _allowExportForFree;
    return user.isPro ||
        user.isAdmin ||
        user.isInProTrial ||
        _allowExportForFree;
  }

  // Check if user can save projects
  static bool canSaveProjects(UserModel? user) {
    if (user == null) return _allowSaveProjectsForFree;
    return user.isPro ||
        user.isAdmin ||
        user.isInProTrial ||
        _allowSaveProjectsForFree;
  }

  // Check if user can use advanced calculation options
  static bool canUseAdvancedOptions(UserModel? user) {
    if (user == null) return _allowAdvancedOptionsForFree;
    return user.isPro ||
        user.isAdmin ||
        user.isInProTrial ||
        _allowAdvancedOptionsForFree;
  }

  // Check if user can manage all default tiles (admin only)
  static bool canManageDefaultTiles(UserModel? user) {
    if (user == null) return false;
    return user.isAdmin;
  }

  // Check if user can edit and save tiles to personal collection
  static bool canEditAndSavePersonalTiles(UserModel? user) {
    if (user == null) return false;
    return user.isPro || user.isAdmin || user.isInProTrial;
  }

  // Check if user can submit tiles for admin approval
  static bool canSubmitTilesToAdmin(UserModel? user) {
    if (user == null) return false;
    return user.isPro || user.isAdmin || user.isInProTrial;
  }

  // Check if user can approve user-submitted tiles (admin only)
  static bool canApproveUserTiles(UserModel? user) {
    if (user == null) return false;
    return user.isAdmin;
  }

  // Check if user can import tiles via CSV (admin only)
  static bool canImportTilesViaCSV(UserModel? user) {
    if (user == null) return false;
    return user.isAdmin;
  }

  // Check if user can save calculation results
  static bool canSaveCalculationResults(UserModel? user) {
    if (user == null) return false;
    return user.isPro || user.isAdmin || user.isInProTrial;
  }

  // Check if user has access to analytics (admin only)
  static bool canAccessAnalytics(UserModel? user) {
    if (user == null) return false;
    return user.isAdmin;
  }

  // Get remaining trial days
  static int getRemainingTrialDays(UserModel? user) {
    if (user == null || !user.isInProTrial) return 0;

    final now = DateTime.now();
    final end = user.proTrialEndDate;
    if (end == null) return 0;

    return end.difference(now).inDays + 1; // +1 to include current day
  }

  // Check if user is about to expire (within 5 days)
  static bool isTrialAboutToExpire(UserModel? user) {
    final remainingDays = getRemainingTrialDays(user);
    return remainingDays > 0 && remainingDays <= 5;
  }

  // Get the restriction message based on user type
  static String getRestrictionMessage(UserModel? user) {
    if (user == null || user.isFree) {
      return 'Upgrade to Pro to unlock all features';
    } else if (user.isInProTrial) {
      final days = getRemainingTrialDays(user);
      return 'Pro Trial: $days ${days == 1 ? 'day' : 'days'} remaining';
    } else if (user.isPro) {
      return 'Pro Features Unlocked';
    } else if (user.isAdmin) {
      return 'Admin Access';
    }
    return '';
  }

  // Check if user has an active subscription
  static bool isSubscriptionActive(UserModel? user) {
    if (user == null) return false;

    // Check if user has valid subscription
    if (user.isSubscribed) return true;

    // If not subscribed, check if trial is active
    return isTrialActive(user);
  }

  // Check if user has an active trial
  static bool isTrialActive(UserModel? user) {
    if (user == null) return false;

    // If user already subscribed, trial is not relevant
    if (user.isSubscribed) return false;

    return getRemainingTrialDays(user) > 0;
  }

  // Check if trial is about to expire (within warning days)
  static bool isTrialAboutToExpire(UserModel? user) {
    if (user == null) return false;

    if (!isTrialActive(user)) return false;

    int remaining = getRemainingTrialDays(user);
    return remaining <= WARNING_DAYS && remaining > 0;
  }

  // Calculate remaining trial days
  static int getRemainingTrialDays(UserModel? user) {
    if (user == null) return 0;

    if (user.registrationDate == null) return TRIAL_DURATION_DAYS;

    final now = DateTime.now();
    final regDate = user.registrationDate!;
    final difference = now.difference(regDate).inDays;

    int remaining = TRIAL_DURATION_DAYS - difference;
    return remaining < 0 ? 0 : remaining;
  }
}
