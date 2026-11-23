import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:videodownloader/providers/ad_provider/ads_provider.dart';
import 'package:videodownloader/screens/appbar/appbar.dart';
import 'package:videodownloader/screens/downloaded/downloaded_list_screen.dart';
import 'package:videodownloader/screens/home/home_video_fetch_and_list_screen.dart';
import 'package:videodownloader/screens/menu_bottom_sheet/menu_bottom_sheet.dart';
import 'package:videodownloader/services/twitter_down_service/twitter_down_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TwitterDownService twitterDownService = GetIt.I<TwitterDownService>();
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeVideoFetchAndListScreen(),
    DownloadedListScreen(),
  ];

  final List<String> _titles = ["Home", "Downloads"];

  @override
  void initState() {
    super.initState();
    twitterDownService.initWebView();
    WidgetsBinding.instance.addObserver(this); // ← for app resume
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Placement 5: app resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final adProvider = Provider.of<AdProvider>(context, listen: false);
      if (adProvider.shouldShowAdOnResume()) {
        adProvider.tryShowAd();
      }
    }
  }

  // Placement 1: tab switch
  void _onTabSwitch(int index) {
    if (index == _selectedIndex) return;

    final adProvider = Provider.of<AdProvider>(context, listen: false);

    // Show ad then switch tab
    final adShown = adProvider.tryShowAd(
      onDismissed: () {
        if (mounted) setState(() => _selectedIndex = index);
      },
    );

    // If no ad available, switch immediately
    if (!adShown) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDownloadsScreen = _selectedIndex == 1;

    return Scaffold(
      appBar: CustomAppBar(
        title: _titles[_selectedIndex],
        showBackButton: isDownloadsScreen,
        onBackPressed: isDownloadsScreen
            ? () => _onTabSwitch(0) // ← goes through ad gate
            : null,
        onMenuPressed: isDownloadsScreen
            ? null
            : () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const CustomBottomMenuSheet(),
                );
              },
        onDownloadsPressed: isDownloadsScreen
            ? null
            : () => _onTabSwitch(1), // ← goes through ad gate
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }
}