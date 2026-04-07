import 'package:envied/envied.dart';

part 'Env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'DRUPAL_URL')
  static const String DRUPAL_URL = _Env.DRUPAL_URL;
  @EnviedField(varName: 'OAUTH_CLIENT_ID')
  static const String OAUTH_CLIENT_ID = _Env.OAUTH_CLIENT_ID;
  @EnviedField(varName: 'OAUTH_CLIENT_SECRET', obfuscate: true)
  static final String OAUTH_CLIENT_SECRET = _Env.OAUTH_CLIENT_SECRET;
  @EnviedField(varName: 'GENERATE_HASH', obfuscate: true)
  static final String GENERATE_HASH = _Env.GENERATE_HASH;
}
