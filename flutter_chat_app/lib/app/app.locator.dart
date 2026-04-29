import 'package:get_it/get_it.dart';
import 'package:stacked_services/stacked_services.dart';

import '../core/services/api_service.dart';
import '../core/services/call_service.dart';
import '../core/services/session_service.dart';
import '../core/services/socket_service.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => DialogService());
  locator.registerLazySingleton(() => SessionService());
  locator.registerLazySingleton(() => ApiService(locator<SessionService>()));
  locator.registerLazySingleton(() => SocketService());
  locator.registerLazySingleton(() => CallService(locator<SocketService>()));
}
