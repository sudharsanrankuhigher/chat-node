import 'package:get_it/get_it.dart';
import 'package:stacked_services/stacked_services.dart';

import '../services/call_service.dart';
import '../services/socket_service.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => DialogService());
  locator.registerLazySingleton(() => SocketService());
  locator.registerLazySingleton(() => CallService(locator<SocketService>()));
}
