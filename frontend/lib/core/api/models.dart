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
  final bool isOnline;

  const RemoteUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl = '',
    this.locale = '',
    this.emailVerified = false,
    this.isOnline = false,
  });

  factory RemoteUser.fromJson(Map<String, dynamic> json) => RemoteUser(
        id: (json['id'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        displayName: (json['displayName'] as String?) ?? '',
        avatarUrl: (json['avatarUrl'] as String?) ?? '',
        locale: (json['locale'] as String?) ?? '',
        emailVerified: (json['emailVerified'] as bool?) ?? false,
        isOnline: (json['isOnline'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'locale': locale,
        'emailVerified': emailVerified,
        'isOnline': isOnline,
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
  final List<RemoteUser> friends;
  final List<Friendship> pendingRequests;

  const FriendsResult({
    required this.friends,
    required this.pendingRequests,
  });

  factory FriendsResult.fromJson(Map<String, dynamic> json) {
    return FriendsResult(
      friends: ((json['friends'] as List?) ?? const [])
          .map((e) => RemoteUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingRequests: ((json['pendingRequests'] as List?) ?? const [])
          .map((e) => Friendship.fromJson(e as Map<String, dynamic>))
          .toList(),
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

  factory FeedEntry.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final type = _parseFeedType(typeStr);
    
    // Extraer datos del usuario autor
    final userJson = json['user'] as Map<String, dynamic>?;
    final userDisplayName = userJson != null ? (userJson['displayName'] as String? ?? '') : '';
    final userEmail = userJson != null ? (userJson['email'] as String? ?? '') : '';
    final authorName = userDisplayName.isNotEmpty ? userDisplayName : (userEmail.isNotEmpty ? userEmail : 'Alguien');

    String title = authorName;
    String description = '';
    
    if (type == FeedEntryType.achievement) {
      final ach = json['achievement'] as Map<String, dynamic>?;
      if (ach != null) {
        final achTitle = ach['title'] as String? ?? 'un logro';
        description = 'desbloqueó el logro "$achTitle"';
      } else {
        description = 'desbloqueó un logro';
      }
    } else if (type == FeedEntryType.activity) {
      final act = json['activity'] as Map<String, dynamic>?;
      if (act != null) {
        final actDesc = act['description'] as String? ?? '';
        description = actDesc.isNotEmpty ? actDesc : 'completó una actividad';
      } else {
        description = 'completó una actividad';
      }
    } else if (type == FeedEntryType.share) {
      final sh = json['share'] as Map<String, dynamic>?;
      if (sh != null) {
        final shTitle = sh['title'] as String? ?? 'un mazo';
        description = 'compartió el mazo "$shTitle"';
      } else {
        description = 'compartió un mazo';
      }
    } else {
      description = 'realizó una acción';
    }

    return FeedEntry(
      id: (json['id'] as String?) ?? '',
      type: type,
      userId: (json['userId'] as String?) ?? '',
      title: title,
      description: description,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
    );
  }
}

class RemoteAchievement {
  final String id;
  final String code;
  final String title;
  final String description;
  final String emoji;
  final DateTime? unlockedAt;

  const RemoteAchievement({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.emoji,
    this.unlockedAt,
  });

  factory RemoteAchievement.fromJson(Map<String, dynamic> json) => RemoteAchievement(
        id: (json['id'] as String?) ?? '',
        code: (json['code'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        emoji: (json['emoji'] as String?) ?? '🏆',
        unlockedAt: DateTime.tryParse((json['unlockedAt'] as String?) ?? ''),
      );
}

class UserProfileResult {
  final RemoteUser user;
  final List<RemoteAchievement> achievements;
  final int sharedCount;
  final int achievementsCount;

  const UserProfileResult({
    required this.user,
    required this.achievements,
    this.sharedCount = 0,
    this.achievementsCount = 0,
  });

  factory UserProfileResult.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    return UserProfileResult(
      user: RemoteUser.fromJson(json['user'] as Map<String, dynamic>? ?? const {}),
      achievements: ((json['achievements'] as List?) ?? const [])
          .map((e) => RemoteAchievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      sharedCount: (stats['sharedCount'] as int?) ?? 0,
      achievementsCount: (stats['achievementsCount'] as int?) ?? 0,
    );
  }
}
