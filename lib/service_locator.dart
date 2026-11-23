// lib/service_locator.dart
import 'package:videodownloader/services/twitter_down_service/twitter_down_service.dart';
import 'package:videodownloader/services/object_box/object_box_service.dart';
import 'package:get_it/get_it.dart';


final getIt = GetIt.instance;      
Future<void> setupServiceLocator() async {
  // 1. Register ObjectBox FIRST with a retry loop (async channel might fail in release)
  ObjectBox? objectBox;
  int retries = 3;
  while (retries > 0) {
    try {
      objectBox = await ObjectBox.create();
      getIt.registerSingleton<ObjectBox>(objectBox);
      break;
    } catch (e) {
      retries--;
      if (retries == 0) rethrow; // Let it fail on last try
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // 2. Now register everything that depends on ObjectBox
  getIt.registerLazySingleton<TwitterDownService>(() => TwitterDownService());



  print('Service Locator: ALL REGISTERED SUCCESSFULLY');
}