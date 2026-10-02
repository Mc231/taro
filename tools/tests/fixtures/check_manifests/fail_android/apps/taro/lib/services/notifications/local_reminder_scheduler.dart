Future<bool?> ask(p) => p.requestNotificationsPermission();
Future<bool?> askIos(p) => p.requestPermissions(alert: true);
