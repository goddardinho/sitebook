/// User model representing authenticated user data
class User {
  final String id;
  final String email;
  final String name;
  final String? location;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserProfile? profile;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.location,
    this.avatarUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.profile,
  });

  /// Factory constructor from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'location': location,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'profile': profile?.toJson(),
    };
  }

  /// Create copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? location,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserProfile? profile,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profile: profile ?? this.profile,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User{id: $id, email: $email, name: $name}';
  }
}

/// Extended user profile information
class UserProfile {
  final int totalReservations;
  final int totalNights;
  final int favoriteParks;
  final Map<String, dynamic> preferences;
  final List<String> savedCampgrounds;

  const UserProfile({
    required this.totalReservations,
    required this.totalNights,
    required this.favoriteParks,
    this.preferences = const {},
    this.savedCampgrounds = const [],
  });

  /// Factory constructor from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      totalReservations: json['totalReservations'] as int? ?? 0,
      totalNights: json['totalNights'] as int? ?? 0,
      favoriteParks: json['favoriteParks'] as int? ?? 0,
      preferences: Map<String, dynamic>.from(json['preferences'] as Map? ?? {}),
      savedCampgrounds: List<String>.from(
        json['savedCampgrounds'] as List? ?? [],
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalReservations': totalReservations,
      'totalNights': totalNights,
      'favoriteParks': favoriteParks,
      'preferences': preferences,
      'savedCampgrounds': savedCampgrounds,
    };
  }

  /// Create copy with updated fields
  UserProfile copyWith({
    int? totalReservations,
    int? totalNights,
    int? favoriteParks,
    Map<String, dynamic>? preferences,
    List<String>? savedCampgrounds,
  }) {
    return UserProfile(
      totalReservations: totalReservations ?? this.totalReservations,
      totalNights: totalNights ?? this.totalNights,
      favoriteParks: favoriteParks ?? this.favoriteParks,
      preferences: preferences ?? this.preferences,
      savedCampgrounds: savedCampgrounds ?? this.savedCampgrounds,
    );
  }
}
