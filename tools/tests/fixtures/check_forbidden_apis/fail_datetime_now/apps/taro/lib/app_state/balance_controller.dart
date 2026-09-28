bool isStale(DateTime fetchedAt) =>
    DateTime.now().difference(fetchedAt).inMinutes > 5;
