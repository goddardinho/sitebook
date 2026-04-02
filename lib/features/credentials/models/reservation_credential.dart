/// Model for a reservation system credential
class ReservationCredential {
  final String id;
  final String name;
  final String url;
  final String username;
  final String password; // Store encrypted in secure storage

  const ReservationCredential({
    required this.id,
    required this.name,
    required this.url,
    required this.username,
    required this.password,
  });

  ReservationCredential copyWith({
    String? id,
    String? name,
    String? url,
    String? username,
    String? password,
  }) {
    return ReservationCredential(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  factory ReservationCredential.fromJson(Map<String, dynamic> json) {
    return ReservationCredential(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'username': username,
      'password': password,
    };
  }
}
