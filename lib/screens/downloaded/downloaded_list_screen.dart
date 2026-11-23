// DownloadedListScreen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:videodownloader/providers/downloaded_video_list_provider/downloaded_video_list_provider.dart';
import 'package:videodownloader/screens/downloaded/widgets/video_list_item_widget.dart';

class DownloadedListScreen extends StatefulWidget {
  const DownloadedListScreen({super.key});

  @override
  State<DownloadedListScreen> createState() => _DownloadedListScreenState();
}

class _DownloadedListScreenState extends State<DownloadedListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideos();
    });
  }

Future<void> _loadVideos() async {
  Provider.of<DownloadedVideoListProvider>(context, listen: false)
      .loadDownloadedVideos(forceRefresh: true);
}

@override
Widget build(BuildContext context) {
  return Consumer<DownloadedVideoListProvider>(
    builder: (context, provider, child) {
      final videos = provider.downloadedVideos;

      return RefreshIndicator(
        onRefresh: _loadVideos,
        color: const Color(0xFF3B82F6),
        // Always a scrollable — RefreshIndicator needs it even when empty
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (videos.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  vertical: 2.0.h,
                  horizontal: 3.0.w,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => VideoListItemWidget(
                      videoDownloadedModel: videos[index],
                    ),
                    childCount: videos.length,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/icon/empty_folder.png', width: 160),
          const SizedBox(height: 16),
          Text(
            "No video history",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF738BAB),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Downloaded videos will appear here",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList({required List<dynamic> videos}) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.0.h, horizontal: 3.0.w),
      physics: const AlwaysScrollableScrollPhysics(), // Critical for RefreshIndicator
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoListItemWidget(videoDownloadedModel: videos[index]);
      },
    );
  }
}