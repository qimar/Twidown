import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:videodownloader/models/video_downloaded_model/video_downloaded_model.dart';
import 'package:videodownloader/providers/downloaded_video_list_provider/downloaded_video_list_provider.dart';
import 'package:videodownloader/screens/video_player_screen/video_player_screen.dart';

class VideoListItemWidget extends StatelessWidget {
  final VideoDownloadedModel videoDownloadedModel;
  const VideoListItemWidget({super.key, required this.videoDownloadedModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.0.h),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      videoDownloadedModel.thumbnail,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.video_library_outlined,
                          color: Colors.grey,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // title
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Download Twitter Videos Online",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.copyWith(fontSize: 16.sp),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Text(videoDownloadedModel.videoQuality,
                          //     style:
                          //         Theme.of(context).textTheme.bodyMedium),
                          // const SizedBox(width: 5),
                          Text(
                            videoDownloadedModel.videoFileSize,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 83),
                          Text(
                            videoDownloadedModel.getFormattedDownloadedDate(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // play icon
                          // const SizedBox(width: 5),
                          IconButton(
                            onPressed: () {
                              // final adProvider = Provider.of<AdProvider>(
                                // context,
                                // listen: false,
                              // );

                              // Placement 2: before video playback
                              // final adShown = adProvider.tryShowAd(
                                // onDismissed: () {
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VideoPlayerScreen(
                                          video: videoDownloadedModel,
                                        ),
                                      ),
                                    );
                                  }
                            },
                            icon: const Icon(
                              Icons.play_circle_outlined,
                              size: 28,
                              color: Color(0xFF3B82F6),
                            ),
                          ),

                          IconButton(
                            onPressed: () async {
                              final filePath = videoDownloadedModel.videoPath
                                  .trim();
                              final file = XFile(filePath);
                              await Share.shareXFiles([
                                file,
                              ], text: 'Check out this video!');
                            },
                            icon: const Icon(
                              Icons.share_outlined,
                              size: 28,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 5),
                          // delete icon
                          IconButton(
                            onPressed: () {
                              context
                                  .read<DownloadedVideoListProvider>()
                                  .deleteVideo(videoDownloadedModel, context);
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 28,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}
