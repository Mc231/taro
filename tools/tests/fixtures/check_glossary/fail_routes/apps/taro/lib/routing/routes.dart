abstract final class Routes {
  static const home = '/today';
  static const question = '/reading/question?spread=';
  static const learnSpreads = '/learn/spreads';
  static const learnSpread = '/learn/spreads/:spreadId';
  static const root = '/';
  static String reading(String id) => '/reading/$id';
}
