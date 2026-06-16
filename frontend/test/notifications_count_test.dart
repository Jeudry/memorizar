import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/app_state.dart';

void main() {
  group('AppStore unread notifications (badge contract)', () {
    test('setUnreadNotifications updates the count and notifies', () {
      final store = AppStore(enableDatabasePersistence: false);
      var notified = 0;
      store.addListener(() => notified++);

      expect(store.unreadNotifications, 0);

      store.setUnreadNotifications(3);
      expect(store.unreadNotifications, 3);
      expect(notified, 1);

      // Setear el mismo valor no vuelve a notificar (evita rebuilds inútiles).
      store.setUnreadNotifications(3);
      expect(notified, 1);

      store.setUnreadNotifications(0);
      expect(store.unreadNotifications, 0);
      expect(notified, 2);
    });

    test('refreshNotificationCount resets to 0 when logged out', () async {
      final store = AppStore(enableDatabasePersistence: false);
      store.setUnreadNotifications(5);
      expect(store.unreadNotifications, 5);

      // Sin sesión no se pega al backend: el conteo se limpia a 0.
      await store.refreshNotificationCount();
      expect(store.isLoggedIn, isFalse);
      expect(store.unreadNotifications, 0);
    });
  });
}
