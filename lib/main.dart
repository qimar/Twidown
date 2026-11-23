import 'dart:io';
import 'package:videodownloader/providers/ad_provider/ads_provider.dart';
import 'package:videodownloader/providers/downloaded_video_list_provider/downloaded_video_list_provider.dart';
import 'package:videodownloader/providers/home_download_provider/home_download_provider.dart';
import 'package:videodownloader/providers/theme_provider/theme_provider.dart';
import 'package:videodownloader/screens/downloaded/downloaded_list_screen.dart';
import 'package:videodownloader/screens/home/home_screen.dart';
import 'package:videodownloader/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Give Android channels a tiny bit of time to register in release mode
  await Future.delayed(const Duration(milliseconds: 300));

  try {
    await setupServiceLocator();
    debugPrint('[main] Service locator setup complete');
  } catch (e) {
    debugPrint('[main] ⚠️ Service locator setup failed (non-fatal): $e');
  }

  // initialize media store
  if (Platform.isAndroid) {
    try {
      MediaStore.appFolder = "TwiDown"; // Creates /Download/TwiDown
      await MediaStore.ensureInitialized();
      debugPrint('[main] MediaStore initialized');
    } catch (e) {
      debugPrint('[main] ⚠️ MediaStore init failed (non-fatal): $e');
    }
  }

  // Pre-create providers safely
  final themeProvider = ThemeProvider();
  final adProvider = AdProvider();
  final downloadedVideoListProvider = DownloadedVideoListProvider();
  final homeAndDownloadProvider = HomeAndDownloadProvider(
    downloadedVideoListProvider,
    adProvider,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<AdProvider>.value(value: adProvider),
        ChangeNotifierProvider<DownloadedVideoListProvider>.value(value: downloadedVideoListProvider),
        ChangeNotifierProvider<HomeAndDownloadProvider>.value(value: homeAndDownloadProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(
      context,
    ); // Listen to changes

    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TwiDown',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            colorScheme: const ColorScheme.dark().copyWith(
              primary: Colors.blueAccent,
              secondary: Colors.blueAccent,
            ),
          ),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: "/home",
          routes: {
            '/home': (context) => const HomeScreen(),
            '/downloaded': (context) => const DownloadedListScreen(),
          },
        );
      },
    );
  }
}
