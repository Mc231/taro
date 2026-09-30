import 'package:taro/bootstrap/bootstrap.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/bootstrap/taro_environment.dart';

void main() => bootstrap(ProductionEnvironment(Flavor.dev));
