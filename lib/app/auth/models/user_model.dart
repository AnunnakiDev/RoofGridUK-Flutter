import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  free,
  pro,
  admin,
}

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final UserRole role;
  final DateTime? proTrialStartDate;
  final DateTime? proTrialEndDate;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.role,
    this.proTrialStartDate,
    this.proTrialEndDate,
    required this.createdAt,
    required this.lastLoginAt,
  });
  bool get isAdmin => role == UserRole.admin;
  bool get isFree => role == UserRole.free;
  bool get isPro => role == UserRole.pro;

  // Check if user has paid subscription
  bool get hasPaidSubscription =>
      role == UserRole.pro || role == UserRole.admin;

  bool get isInProTrial {
    if (proTrialStartDate == null || proTrialEndDate == null) {
      return false;
    }
    final now = DateTime.now();
    return now.isAfter(proTrialStartDate!) && now.isBefore(proTrialEndDate!);
  }

  int get remainingTrialDays {
    if (proTrialStartDate == null || proTrialEndDate == null) {
      return 0;
    }
    final now = DateTime.now();
    if (now.isAfter(proTrialEndDate!)) {
      return 0;
    }
    return proTrialEndDate!.difference(now).inDays;
  }

  // Fix the return type error by ensuring it returns a bool
  bool get isSubscribed {
    // Make sure to return a boolean value
    return subscriptionEndDate != null &&
        subscriptionEndDate!.isAfter(DateTime.now());
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      role: UserRole.values.firstWhere(
        (r) => r.toString() == data['role'] ?? 'UserRole.free',
        orElse: () => UserRole.free,
      ),
      proTrialStartDate: data['proTrialStartDate'] != null
          ? (data['proTrialStartDate'] as Timestamp).toDate()
          : null,
      proTrialEndDate: data['proTrialEndDate'] != null
          ? (data['proTrialEndDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.toString(),
      'proTrialStartDate': proTrialStartDate != null
          ? Timestamp.fromDate(proTrialStartDate!)
          : null,
      'proTrialEndDate':
          proTrialEndDate != null ? Timestamp.fromDate(proTrialEndDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
    DateTime? proTrialStartDate,
    DateTime? proTrialEndDate,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      proTrialStartDate: proTrialStartDate ?? this.proTrialStartDate,
      proTrialEndDate: proTrialEndDate ?? this.proTrialEndDate,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
