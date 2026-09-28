import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobAdsService {
  Future<void> initialize() => MobileAds.instance.initialize();
}
