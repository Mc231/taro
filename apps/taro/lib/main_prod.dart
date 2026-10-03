import 'package:taro/bootstrap/bootstrap.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/bootstrap/taro_environment.dart';
import 'package:taro/firebase_options_prod.dart';

void main() => bootstrap(
  ProductionEnvironment(
    Flavor.prod,
    firebaseOptions: () => DefaultFirebaseOptions.currentPlatform,
  ),
);
