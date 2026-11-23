import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:videodownloader/models/video_meta_model/video_model.dart';
import 'package:videodownloader/providers/home_download_provider/home_download_provider.dart';

Future<void> bottomVideoMetaBottomSheet({
  required BuildContext context,
  required String userUrl,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
    ),
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter modalSetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Consumer<HomeAndDownloadProvider>(
              builder: (context, provider, _) {
                final meta = provider.videoMetaDataModel;
                if (meta == null || meta.hasScrappingError == true) {
                  return _buildErrorState(sheetContext);
                }
                return _buildDownloadOptions(
                  sheetContext: sheetContext,
                  provider: provider,
                  meta: meta,
                  modalSetState: modalSetState,
                  userUrl: userUrl,
                );
              },
            ),
          );
        },
      );
    },
  );
}

// Error State
Widget _buildErrorState(BuildContext context) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Download Options",
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'No video found.\nCheck the link and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
        ),
        SizedBox(height: 3.h),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text("Retry"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        ),
      ],
    ),
  );
}

// Dynamic Download Options - Shows ALL scraped qualities
Widget _buildDownloadOptions({
  required BuildContext sheetContext,
  required HomeAndDownloadProvider provider,
  required VideoMetaDataModel meta,
  required StateSetter modalSetState,
  required String userUrl,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.5.h),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Available Resolutions",
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: () => Navigator.pop(sheetContext),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // // Show ALL scraped qualities (no filtering)
        // ...meta.videoLinks.asMap().entries.map((entry) {
        //   final index = entry.key;
        //   final link = entry.value;

        //   return Container(
        //     margin: EdgeInsets.symmetric(vertical: 0.7.h),
        //     decoration: BoxDecoration(
        //       borderRadius: BorderRadius.circular(12),
        //       color: provider.selectedLinkIndex == index ? Colors.blue.shade50 : Colors.grey.shade100,
        //       border: Border.all(
        //         color: provider.selectedLinkIndex == index ? Colors.blueAccent : Colors.grey.shade300,
        //         width: 1.5,
        //       ),
        //     ),
        //     child: RadioListTile<int>(
        //       value: index,
        //       groupValue: provider.selectedLinkIndex,
        //       activeColor: Colors.blueAccent,
        //       dense: true,
        //       contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        //       title: Text(
        //         link.quality,           // Shows exact quality like "1920x1080", "1280x720", etc.
        //         style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
        //       ),
        //       onChanged: (int? val) {
        //         provider.selectedLinkIndex = val!;
        //         modalSetState(() {});
        //       },
        //     ),
        //   );
        // }),

        // Resolutions List - All qualities, highest first
        ...meta.videoLinks.asMap().entries.map((entry) {
          final index = entry.key;
          final link = entry.value;

          return Container(
            margin: EdgeInsets.symmetric(vertical: 0.7.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: provider.selectedLinkIndex == index
                  ? Colors.blue.shade50
                  : Colors.grey.shade100,
              border: Border.all(
                color: provider.selectedLinkIndex == index
                    ? Colors.blueAccent
                    : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: RadioListTile<int>(
              value: index,
              groupValue: provider.selectedLinkIndex,
              activeColor: Colors.blueAccent,
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text(
                link.quality, // Clean quality name (no ": mp4")
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              onChanged: (int? val) {
                provider.selectedLinkIndex = val!;
                modalSetState(() {});
              },
            ),
          );
        }),
        SizedBox(height: 3.h),

        // Download Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: provider.isDownloading
                ? null
                : () async {
                    Navigator.pop(sheetContext); // close bottom sheet
                    _showDownloadProgressDialog(
                      sheetContext,
                      userUrl: userUrl,
                      selectedLinkIndex: provider.selectedLinkIndex,
                      provider: provider,
                    );
                    await provider.downloadVideo(
                      userUrl: userUrl,
                      selectedLinkIndex: provider.selectedLinkIndex,
                      context: sheetContext,
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.isDownloading
                  ? Colors.grey
                  : Colors.blueAccent,
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            label: Text(
              provider.isDownloading ? "Downloading..." : "Download",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: 1.h),
      ],
    ),
  );
}

// Progress Dialog (unchanged)
// Replace the old _showDownloadProgressDialog with this:
void _showDownloadProgressDialog(
  BuildContext context, {
  required String userUrl,
  required int selectedLinkIndex,
  required HomeAndDownloadProvider provider,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => WillPopScope(
      onWillPop: () async => false,
      child: Consumer<HomeAndDownloadProvider>(
        builder: (dialogContext, provider, _) {
          final status = provider.downloadStatus;

          // Auto-close on success after a short delay
          if (status == DownloadStatus.success) {
            Future.microtask(() async {
              await Future.delayed(const Duration(milliseconds: 1200));
              if (Navigator.canPop(ctx)) Navigator.pop(ctx);
            });
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: _buildDialogContent(
              context: ctx,
              provider: provider,
              status: status,
              userUrl: userUrl,
              selectedLinkIndex: selectedLinkIndex,
            ),
          );
        },
      ),
    ),
  );
}

Widget _buildDialogContent({
  required BuildContext context,
  required HomeAndDownloadProvider provider,
  required DownloadStatus status,
  required String userUrl,
  required int selectedLinkIndex,
}) {
  // SUCCESS
  if (status == DownloadStatus.success) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 52),
        SizedBox(height: 1.5.h),
        Text(
          "Download Complete!",
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 0.5.h),
        Text(
          "Video saved to Downloads/TwiDown",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ERROR
  if (status == DownloadStatus.error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_rounded, color: Colors.redAccent, size: 52),
        SizedBox(height: 1.5.h),
        Text(
          "Download Failed",
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 0.8.h),
        Text(
          provider.errorMessage ?? "Something went wrong. Please try again.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            // Dismiss
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 1.2.h),
                ),
                child: Text(
                  "Dismiss",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13.sp),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            // Retry
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await provider.downloadVideo(
                    userUrl: userUrl,
                    selectedLinkIndex: selectedLinkIndex,
                    context: context,
                  );
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  "Retry",
                  style: TextStyle(color: Colors.white, fontSize: 13.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 1.2.h),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // DOWNLOADING (default)
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CircularProgressIndicator(strokeWidth: 5, color: Colors.blueAccent),
      SizedBox(height: 2.h),
      Text(
        "Downloading Video...",
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      SizedBox(height: 2.h),
      LinearProgressIndicator(
        value: provider.downloadProgress > 0 && provider.downloadProgress < 1
            ? provider.downloadProgress
            : null,
        minHeight: 8,
        backgroundColor: Colors.grey[300],
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        borderRadius: BorderRadius.circular(4),
      ),
      SizedBox(height: 1.h),
      Text(
        "${(provider.downloadProgress * 100).toStringAsFixed(1)}%",
        style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
      ),
    ],
  );
}
