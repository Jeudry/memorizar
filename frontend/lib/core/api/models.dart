/// Modelos serializados que vienen del backend Go (paquete
/// `backend/internal/social/domain`). Cada clase tiene un `fromJson` que
/// tolera campos opcionales para sobrevivir cambios menores en el server.
class RemoteUser {
  final String id;
  final String email;
  final String displayName;
  final String avatarUrl;
  final String locale;
  final bool emailVerified;

  const RemoteUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl = '',
    this.locale = '',
    this.emailVerified = false,
  });

  factory RemoteUser.fromJson(Map<String, dynamic> json) => RemoteUser(
        id: (json['id'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        displayName: (json['displayName'] as String?) ?? '',
        avatarUrl: (json['avatarUrl'] as String?) ?? '',
        locale: (json['locale'] as String?) ?? '',
        emailVerified: (json['emailVerified'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'locale': locale,
        'emailVerified': emailVerified,
      };

  String get initial =>
      displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?';
}

class Session {
  final String token;
  final String userId;
  final String provider;
  final DateTime? expiresAt;

  const Session({
    required this.token,
    required this.userId,
    required this.provider,
    this.expiresAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        token: (json['token'] as String?) ?? '',
        userId: (json['userId'] as String?) ?? '',
        provider: (json['provider'] as String?) ?? '',
        expiresAt: DateTime.tryParse((json['expiresAt'] as String?) ?? ''),
      );
}

class SessionResult {
  final RemoteUser user;
  final Session session;

  const SessionResult({required this.user, required this.session});

  factory SessionResult.fromJson(Map<String, dynamic> json) => SessionResult(
        user: RemoteUser.fromJson(
          (json['user'] as Map<String, dynamic>? ?? const {}),
        ),
        session: Session.fromJson(
          (json['session'] as Map<String, dynamic>? ?? const {}),
        ),
      );
}

enum FriendshipStatus { pending, accepted, unknown }

FriendshipStatus _parseFriendshipStatus(String? raw) {
  switch (raw) {
    case 'pending':
      return FriendshipStatus.pending;
    case 'accepted':
      return FriendshipStatus.accepted;
    default:
      return FriendshipStatus.unknown;
  }
}

class Friendship {
  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;

  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
        id: (json['id'] as String?) ?? '',
        requesterId: (json['requesterId'] as String?) ?? '',
        addresseeId: (json['addresseeId'] as String?) ?? '',
        status: _parseFriendshipStatus(json['status'] as String?),
      );
}

class FriendsResult {
  final List<Friendship> friends;
  final List<Friendship> pendingRequests;

  const FriendsResult({
    required this.friends,
    required this.pendingRequests,
  });

  factory FriendsResult.fromJson(Map<String, dynamic> json) {
    List<Friendship> parse(String key) =>
        ((json[key] as List?) ?? const [])
            .map((e) => Friendship.fromJson(e as Map<String, dynamic>))
            .toList();
    return FriendsResult(
      friends: parse('friends'),
      pendingRequests: parse('pendingRequests'),
    );
  }
}

enum FeedEntryType { achievement, activity, share, unknown }

FeedEntryType _parseFeedType(String? raw) {
  switch (raw) {
    case 'achievement':
      return FeedEntryType.achievement;
    case 'activity':
      return FeedEntryType.activity;
    case 'share':
      return FeedEntryType.share;
    default:
      return FeedEntryType.unknown;
  }
}

class FeedEntry {
  final String id;
  final FeedEntryType type;
  final String userId;
  final String title;
  final String description;
  final DateTime? createdAt;

  const FeedEntry({
    required this.id,
    required this.type,
    required this.userId,
    required this.title,
    required this.description,
    this.createdAt,
  });

  factory FeedEntry.fromJson(Map<String, dynamic> json) => FeedEntry(
        id: (json['id'] as String?) ?? '',
        type: _parseFeedType(json['type'] as String?),
        userId: (json['userId'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
      );
}
